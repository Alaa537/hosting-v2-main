import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../models/app_models.dart';
import '../services/storage.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/error_utils.dart';
import '../widgets/dialogs.dart';
import '../widgets/section_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton.dart';
import 'live_console_screen.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/animated_counter.dart';
import '../utils/haptics.dart';
import '../services/audio_service.dart';
import 'files_screen.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});
  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  AppStatus? _st;
  bool _loading = true;
  String? _err;
  bool _pendingRestart = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _loadPendingRestart();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPendingRestart() async {
    final v = await Store.getPendingRestart();
    if (mounted) setState(() => _pendingRestart = v);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final st = await context.read<AuthProvider>().api!.appStatus();
      if (!mounted) return;
      setState(() { _st = st; _err = null; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _err = friendlyError(e); _loading = false; });
    }
  }

  Future<void> _start() async {
    Haptics.medium();
    try {
      await context.read<AuthProvider>().api!.appStart();
      AudioService.playStart();
      if (mounted) { snack(context, 'بدأ التشغيل'); _load(); }
    } catch (e) { if (mounted) snack(context, friendlyError(e), error: true); }
  }

  Future<void> _restart() async {
    try {
      await context.read<AuthProvider>().api!.appRestart();
      AudioService.playStart();
      await Store.setPendingRestart(false);
      if (mounted) {
        setState(() => _pendingRestart = false);
        snack(context, 'جاري إعادة التشغيل…');
        _pollUntilRunning();
      }
    } catch (e) { if (mounted) snack(context, friendlyError(e), error: true); }
  }

  void _pollUntilRunning() {
    _pollTimer?.cancel();
    var attempts = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (t) async {
      attempts++;
      if (attempts > 30) { t.cancel(); return; }
      try {
        final st = await context.read<AuthProvider>().api!.appStatus();
        if (!mounted) { t.cancel(); return; }
        setState(() => _st = st);
        if (st.state == 'running') {
          t.cancel();
          if (mounted) snack(context, '✅ التطبيق يعمل الآن');
        }
      } catch (_) {}
    });
  }

  Future<void> _stop() async {
    Haptics.medium();
    if (!await confirm(context, 'إيقاف التطبيق؟')) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!.appStop();
      AudioService.playStop();
      if (mounted) { snack(context, 'تم الإيقاف'); _load(); }
    } catch (e) { if (mounted) snack(context, friendlyError(e), error: true); }
  }

  Future<void> _kill() async {
    if (!await confirm(context, 'إجبار الإيقاف (Kill)؟', danger: true)) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!.appKill();
      if (mounted) { snack(context, 'تم الإيقاف'); _load(); }
    } catch (e) { if (mounted) snack(context, friendlyError(e), error: true); }
  }

  Future<void> _command() async {
    final c = await promptText(context, 'أرسل أمر للتطبيق');
    if (c == null || c.isEmpty || !mounted) return;
    try {
      await context.read<AuthProvider>().api!.appCommand(c);
      if (mounted) snack(context, 'تم الإرسال');
    } catch (e) { if (mounted) snack(context, friendlyError(e), error: true); }
  }

  // ============================================================
  //  UPLOAD — with requirements preview + post-upload dialog
  // ============================================================
  Future<void> _upload() async {
    try {
      // 1) اختر app.py
      final appResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['py'],
        withData: false,
      );
      if (appResult == null || appResult.files.isEmpty) return;
      final appPath = appResult.files.single.path;
      if (appPath == null) return;

      final appFile = File(appPath);
      if (!await appFile.exists()) {
        if (mounted) snack(context, 'app.py غير موجود', error: true);
        return;
      }
      final appSize = await appFile.length();
      if (appSize > 25 * 1024 * 1024) {
        if (mounted) snack(context, 'حجم app.py يتجاوز 25MB', error: true);
        return;
      }
      if (!mounted) return;

      // 2) اختر requirements.txt (اختياري)
      File? reqFile;
      final addReq = await confirm(
        context,
        'إضافة requirements.txt؟',
        msg: 'سيثبّت السيرفر كل الحزم تلقائياً عند التشغيل التالي.',
      );
      if (addReq) {
        final reqResult = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['txt'],
          withData: true,
        );
        if (reqResult != null && reqResult.files.isNotEmpty) {
          final reqPath = reqResult.files.single.path;
          if (reqPath != null) {
            reqFile = File(reqPath);
          }
        }
      }
      if (!mounted) return;

      // 3) عرض معاينة الحزم قبل الرفع
      List<String> previewPkgs = [];
      if (reqFile != null && await reqFile.exists()) {
        final text = await reqFile.readAsString();
        previewPkgs = _parseRequirements(text);
      }

      if (previewPkgs.isNotEmpty && mounted) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => _packagePreviewDialog(previewPkgs),
        );
        if (ok != true) return;
      }
      if (!mounted) return;

      // 4) رفع
      snackInfo(context, 'جاري الرفع…');
      final resp = await context.read<AuthProvider>().api!
          .appUpload(appFile, requirements: reqFile);

      if (!mounted) return;

      // 5) Confetti + Haptics
      Haptics.success();
      ConfettiBurst.fire(context);

      // 6) عرض النتيجة
      final reqs = resp['requirements'];
      final needsRestart = resp['needs_restart'] == true;

      if (needsRestart) {
        await Store.setPendingRestart(true);
        if (mounted) setState(() => _pendingRestart = true);
      }

      if (mounted) {
        await _showUploadResultDialog(
          merged: _getStringList(reqs, 'merged'),
          added: _getStringList(reqs, 'added'),
          error: reqs is Map ? reqs['error']?.toString() : null,
          needsRestart: needsRestart,
        );
      }
      _load();
    } catch (e) {
      if (mounted) snack(context, 'فشل: ${friendlyError(e)}', error: true);
    }
  }

  List<String> _getStringList(dynamic reqs, String key) {
    if (reqs is! Map) return [];
    final v = reqs[key];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  /// Parse requirements.txt locally — mirrors server logic
  List<String> _parseRequirements(String text) {
    final result = <String>[];
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      // اقطع عند أول حرف خاص
      var pkg = line;
      for (final c in ['[', '<', '>', '=', '!', '~', ';', ' ', '\t']) {
        final idx = pkg.indexOf(c);
        if (idx > 0) pkg = pkg.substring(0, idx);
      }
      pkg = pkg.trim();
      if (pkg.isNotEmpty && !result.contains(pkg)) result.add(pkg);
    }
    return result;
  }

  Widget _packagePreviewDialog(List<String> packages) {
    return AlertDialog(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: C.info.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.inventory_2_outlined,
              color: C.info, size: 20),
        ),
        const SizedBox(width: 10),
        const Text('الحزم التي ستُثبَّت',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ]),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'سيتم تثبيت هذه الحزم على السيرفر عند إعادة التشغيل:',
                style: TextStyle(color: C.muted, fontSize: 12.5, height: 1.5),
              ),
              const SizedBox(height: 12),
              ...packages.map((pkg) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: C.surfaceHi,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: C.primary.withValues(alpha: .25)),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle,
                      color: C.success, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(pkg,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ))),
                ]),
              )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء',
              style: TextStyle(color: C.muted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('رفع (${packages.length} حزمة)'),
        ),
      ],
    );
  }

  Future<void> _showUploadResultDialog({
    required List<String> merged,
    required List<String> added,
    String? error,
    required bool needsRestart,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: C.success.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle,
                color: C.success, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('تم الرفع بنجاح',
              style: TextStyle(fontWeight: FontWeight.w800,
                  fontSize: 16)),
        ]),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تم حفظ app.py.',
                    style: TextStyle(fontSize: 13)),
                if (added.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('✅ حزم جديدة (${added.length}):',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: C.success)),
                  const SizedBox(height: 6),
                  ...added.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      const Icon(Icons.add, color: C.success, size: 14),
                      const SizedBox(width: 6),
                      Text(p,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 12)),
                    ]),
                  )),
                ] else if (merged.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('ℹ️ كل الحزم مثبتة مسبقاً.',
                      style: TextStyle(
                          fontSize: 12.5, color: C.info)),
                ],
                if (error != null && error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: C.warning.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('⚠️ $error',
                        style: const TextStyle(
                            color: C.warning, fontSize: 12)),
                  ),
                ],
                if (needsRestart) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: C.warning.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: C.warning.withValues(alpha: .35)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline,
                          color: C.warning, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'يجب إعادة التشغيل لتثبيت الحزم.',
                        style: TextStyle(
                            color: C.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      )),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لاحقاً',
                style: TextStyle(color: C.muted)),
          ),
          if (needsRestart)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _restart();
              },
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('إعادة التشغيل'),
            ),
        ],
      ),
    );
  }

  // ============================================================
  //  EDIT
  // ============================================================
  Future<void> _edit() async {
    try {
      final original = await context.read<AuthProvider>().api!.appRead();
      if (!mounted) return;
      final ctrl = TextEditingController(text: original);
      final edited = await showDialog<String>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: C.bg,
          insetPadding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * .85),
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Icon(Icons.code, color: C.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('app.py',
                    style: TextStyle(fontWeight: FontWeight.w800,
                        fontSize: 15))),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: C.muted)),
              ]),
              const SizedBox(height: 8),
              Expanded(child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.border),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: ctrl, maxLines: null, expands: true,
                  style: const TextStyle(fontFamily: 'monospace',
                      fontSize: 12.5, color: Colors.white, height: 1.5),
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'اكتب الكود هنا…'),
                ),
              )),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: C.muted,
                    side: const BorderSide(color: C.border),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('إلغاء'),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, ctrl.text),
                  child: const Text('حفظ'),
                )),
              ]),
            ]),
          ),
        ),
      );
      if (edited == null || edited == original || !mounted) return;
      await context.read<AuthProvider>().api!.appWrite(edited);
      if (mounted) {
        snack(context, 'تم الحفظ');
        await Store.setPendingRestart(true);
        setState(() => _pendingRestart = true);
        snackInfo(context, 'أعد التشغيل لتطبيق التغييرات');
      }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  // ============================================================
  //  BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بوتي'),
        actions: [
          IconButton(onPressed: _load,
              icon: const Icon(Icons.refresh, color: C.primary)),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const SkeletonList(count: 4);

    return RefreshIndicator(
      onRefresh: _load,
      color: C.primary,
      backgroundColor: C.surface,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Pending restart banner
        if (_pendingRestart) _pendingBanner(),
        if (_err != null && !_pendingRestart) _errCard(),
        if (_st != null) ...[
          _statusCard(_st!),
          const SizedBox(height: 14),
          SectionCard(
            title: 'التحكم',
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _action(Icons.play_arrow, 'تشغيل', C.success, _start),
              _action(Icons.restart_alt, 'إعادة', C.warning, _restart),
              _action(Icons.stop, 'إيقاف', C.info, _stop),
              _action(Icons.power_settings_new, 'Kill', C.danger, _kill),
            ]),
          ),
          const SizedBox(height: 14),
          SectionCard(title: 'الأدوات', child: Column(children: [
            _listAction(Icons.terminal, 'LOG BOT',
                () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const LiveConsoleScreen()))),
            _listAction(Icons.upload_file, 'رفع app.py جديد', _upload),
            _listAction(Icons.edit_document, 'تعديل app.py', _edit),
            _listAction(Icons.keyboard_command_key, 'إرسال أمر', _command),
            _listAction(Icons.folder_outlined, 'ملفات البوت',
                () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const FilesScreen()))),
          ])),
        ],
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _pendingBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.warning.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.warning.withValues(alpha: .4)),
        boxShadow: [
          BoxShadow(
              color: C.warning.withValues(alpha: .15),
              blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: Row(children: [
        const Icon(Icons.pending_actions,
            color: C.warning, size: 24),
        const SizedBox(width: 12),
        const Expanded(child: Text(
          '⚠️ هناك تغييرات معلّقة.\nأعد التشغيل لتثبيت الحزم.',
          style: TextStyle(
              color: C.warning, fontSize: 12.5,
              fontWeight: FontWeight.w600, height: 1.4),
        )),
        TextButton(
          onPressed: _restart,
          style: TextButton.styleFrom(
            backgroundColor: C.warning.withValues(alpha: .20),
            foregroundColor: C.warning,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
          ),
          child: const Text('إعادة',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  Widget _errCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: C.danger.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: C.danger.withValues(alpha: .4)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: C.danger, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(_err!,
          style: const TextStyle(color: C.danger, fontSize: 12))),
    ]),
  );

  Widget _statusCard(AppStatus st) {
    final c = stateColor(st.state);
    final r = st.resources;
    return GlassCard(
      accent: c,
      glow: st.state == 'running',
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(st.name,
              style: const TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w700))),
          Text(st.state.toUpperCase(),
              style: TextStyle(color: c, fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 1)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.timer_outlined, size: 14, color: C.muted),
          const SizedBox(width: 4),
          Text(fTime(st.uptimeSeconds),
              style: const TextStyle(color: C.muted, fontSize: 12)),
        ]),
        const SizedBox(height: 18),
        _bar('CPU', r.cpuPercent, null, null, suffix: '%'),
        const SizedBox(height: 12),
        _bar('MEM', r.memoryPercent, r.memoryBytes, r.memoryLimit),
        const SizedBox(height: 12),
        _bar('DISK', r.diskPercent, r.diskBytes, r.diskLimit),
        const SizedBox(height: 14),
        Row(children: [
          _net('▼', fSize(r.rxBytes), C.success),
          const SizedBox(width: 20),
          _net('▲', fSize(r.txBytes), C.accent),
        ]),
        const SizedBox(height: 16),
        Divider(color: C.border),
        const SizedBox(height: 8),
        Row(children: [
          Icon(st.app.exists ? Icons.check_circle : Icons.cancel,
              color: st.app.exists ? C.success : C.danger, size: 16),
          const SizedBox(width: 6),
          Text('app.py ${st.app.exists ? "موجود" : "غير موجود"}',
              style: TextStyle(
                  color: st.app.exists ? C.success : C.danger,
                  fontSize: 12, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(fSize(st.app.size),
              style: const TextStyle(color: C.muted, fontSize: 11,
                  fontFamily: 'monospace')),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Icon(st.app.requirements
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: st.app.requirements ? C.success : C.muted,
              size: 16),
          const SizedBox(width: 6),
          Text('requirements.txt',
              style: const TextStyle(color: C.muted, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _bar(String label, double? pct, int? used, int? limit,
      {String suffix = ''}) {
    final v = pct ?? 0;
    final c = v < 75 ? C.success : v < 90 ? C.warning : C.danger;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        SizedBox(width: 42, child: Text(label,
            style: const TextStyle(color: C.muted, fontSize: 11,
                fontWeight: FontWeight.w700))),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: (v / 100).clamp(0, 1),
              minHeight: 6, backgroundColor: C.border,
              valueColor: AlwaysStoppedAnimation(c)))),
        const SizedBox(width: 10),
        SizedBox(width: 52, child: Text('${v.toStringAsFixed(1)}$suffix',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11,
                fontWeight: FontWeight.w700))),
      ]),
      if (limit != null && limit > 0) Padding(
        padding: const EdgeInsets.only(left: 42, top: 3),
        child: Text('${fSize(used)} / ${fSize(limit)}',
            style: const TextStyle(color: C.muted, fontSize: 10)),
      ),
    ]);
  }

  Widget _net(String a, String v, Color c) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text(a, style: TextStyle(color: c, fontSize: 14)),
        const SizedBox(width: 4),
        Text(v, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w600)),
      ]);

  Widget _action(IconData ic, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: .35)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(ic, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ),
      ),
    );
  }

  Widget _listAction(IconData ic, String t, VoidCallback onTap,
      {bool danger = false}) =>
    ListTile(contentPadding: EdgeInsets.zero,
      leading: Icon(ic, color: danger ? C.danger : C.primary, size: 20),
      title: Text(t, style: TextStyle(fontSize: 13.5,
          color: danger ? C.danger : null, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: C.muted, size: 18),
      onTap: onTap);
}
