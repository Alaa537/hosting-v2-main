import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/error_utils.dart';
import '../widgets/dialogs.dart';
import '../widgets/section_card.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});
  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 4, vsync: this);

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المحتوى'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: C.primary,
          labelColor: C.primary,
          unselectedLabelColor: C.muted,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dialogs'),
            Tab(text: 'التحديثات'),
            Tab(text: 'Banners'),
            Tab(text: 'Kill Switch'),
          ],
        ),
      ),
      body: SafeArea(child: TabBarView(
        controller: _tab,
        children: const [
          _ModalsTab(),
          _UpdatesTab(),
          _BannersTab(),
          _KillSwitchTab(),
        ],
      )),
    );
  }
}

// ============================ MODALS TAB ============================
class _ModalsTab extends StatefulWidget {
  const _ModalsTab();
  @override
  State<_ModalsTab> createState() => _ModalsTabState();
}

class _ModalsTabState extends State<_ModalsTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await context.read<AuthProvider>().api!
          .adminModals(activeOnly: true);
      if (!mounted) return;
      setState(() { _rows = r; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final type = await _pick(context, 'النوع',
        ['info', 'update', 'warning', 'error', 'success', 'promo', 'gift',
         'stop', 'maintenance']);
    if (type == null || !mounted) return;
    final title = await promptText(context, 'العنوان');
    if (title == null || title.isEmpty || !mounted) return;
    final msg = await promptText(context, 'الرسالة', maxLines: 5);
    if (msg == null || msg.isEmpty || !mounted) return;
    final icon = await _pick(context, 'الأيقونة',
        ['auto', 'download', 'warning', 'server', 'gift', 'info']);
    if (!mounted) return;
    final force = await confirm(context, 'إجباري (لا يمكن إغلاقه)؟');
    if (!mounted) return;
    final once = await confirm(context, 'يظهر مرة واحدة فقط؟');
    if (!mounted) return;
    final showTo = await _pick(context, 'الجمهور',
        ['all', 'new_users', 'paying', 'admin']);
    if (!mounted) return;

    // Buttons
    final buttons = <Map<String, dynamic>>[];
    while (await confirm(context, 'إضافة زر؟')) {
      if (!mounted) break;
      final text = await promptText(context, 'نص الزر');
      if (text == null || text.isEmpty || !mounted) break;
      final action = await _pick(context, 'الإجراء', ['close', 'url', 'copy']);
      if (!mounted) break;
      String? url;
      String? value;
      if (action == 'url') {
        url = await promptText(context, 'الرابط');
        if (!mounted) break;
      } else if (action == 'copy') {
        value = await promptText(context, 'النص المنسوخ');
        if (!mounted) break;
      }
      buttons.add({
        'text': text, 'style': 'primary',
        'action': action, if (url != null) 'url': url,
        if (value != null) 'value': value,
      });
    }
    if (!mounted) return;

    try {
      await context.read<AuthProvider>().api!.adminCreateModal({
        'type': type, 'title': title, 'message': msg, 'icon': icon,
        'buttons': buttons, 'force_show': force, 'show_once': once,
        'show_to': showTo,
      });
      if (mounted) { snack(context, 'تم الإنشاء'); _load(); }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  Future<String?> _pick(BuildContext ctx, String title, List<String> opts) async {
    return showModalBottomSheet<String>(
      context: ctx, backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: ListView(
        shrinkWrap: true, padding: const EdgeInsets.all(12),
        children: [
          Padding(padding: const EdgeInsets.all(8),
            child: Text(title, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800))),
          ...opts.map((o) => ListTile(
            title: Text(o),
            onTap: () => Navigator.pop(ctx, o))),
        ],
      )),
    );
  }

  Future<void> _delete(int id) async {
    if (!await confirm(context, 'حذف؟', danger: true)) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!.adminDeleteModal(id);
      if (mounted) { snack(context, 'تم الحذف'); _load(); }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: C.primary))
        : _rows.isEmpty
          ? const EmptyState(icon: Icons.chat_bubble_outline,
              title: 'لا توجد dialogs', subtitle: 'اضغط + للإنشاء')
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _rows.length,
              itemBuilder: (_, i) {
                final r = _rows[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: C.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.border),
                  ),
                  child: Row(children: [
                    Container(width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: C.accent.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.campaign_outlined,
                          color: C.accent, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['title']?.toString() ?? '—',
                            style: const TextStyle(fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        Text(r['type']?.toString() ?? '—',
                            style: const TextStyle(color: C.accent,
                                fontSize: 10, fontWeight: FontWeight.w700)),
                        if (r['force_show'] == true)
                          const Text('إجباري',
                              style: TextStyle(color: C.danger, fontSize: 9,
                                  fontWeight: FontWeight.w900)),
                      ],
                    )),
                    IconButton(
                      onPressed: () => _delete(r['id'] as int),
                      icon: const Icon(Icons.delete, color: C.danger, size: 18),
                    ),
                  ]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: C.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Dialog جديد',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ============================ UPDATES TAB ============================
class _UpdatesTab extends StatefulWidget {
  const _UpdatesTab();
  @override
  State<_UpdatesTab> createState() => _UpdatesTabState();
}

class _UpdatesTabState extends State<_UpdatesTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await context.read<AuthProvider>().api!.adminUpdates();
      if (!mounted) return;
      setState(() { _rows = r; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final version = await promptText(context, 'الإصدار (مثال: 1.2.0)');
    if (version == null || version.isEmpty || !mounted) return;
    final title = await promptText(context, 'العنوان');
    if (!mounted) return;
    final msg = await promptText(context, 'التفاصيل', maxLines: 5);
    if (!mounted) return;
    final url = await promptText(context, 'رابط التنزيل');
    if (!mounted) return;
    final force = await confirm(context, 'تحديث إجباري؟');
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!.adminCreateUpdate({
        'version': version,
        'title': title ?? 'تحديث جديد',
        'message': msg ?? 'متاح الآن',
        'download_url': url,
        'force': force,
        'platform': 'android',
      });
      if (mounted) { snack(context, 'تم النشر'); _load(); }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  Future<void> _delete(int id) async {
    if (!await confirm(context, 'حذف؟', danger: true)) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!.adminDeleteUpdate(id);
      if (mounted) { snack(context, 'تم الحذف'); _load(); }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: C.primary))
        : _rows.isEmpty
          ? const EmptyState(icon: Icons.system_update_alt,
              title: 'لا توجد تحديثات')
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _rows.length,
              itemBuilder: (_, i) {
                final r = _rows[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: C.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.border),
                  ),
                  child: Row(children: [
                    Container(width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: C.primary.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.system_update_alt,
                          color: C.primary, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('v${r['version']}',
                            style: const TextStyle(fontWeight: FontWeight.w800,
                                fontSize: 14, color: C.primary,
                                fontFamily: 'monospace')),
                        Text(r['title']?.toString() ?? '',
                            style: const TextStyle(fontSize: 12)),
                        if (r['force'] == true)
                          const Text('إجباري',
                              style: TextStyle(color: C.danger, fontSize: 10,
                                  fontWeight: FontWeight.w900)),
                      ],
                    )),
                    IconButton(
                      onPressed: () => _delete(r['id'] as int),
                      icon: const Icon(Icons.delete, color: C.danger, size: 18),
                    ),
                  ]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: C.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('نشر تحديث',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ============================ BANNERS TAB ============================
class _BannersTab extends StatefulWidget {
  const _BannersTab();
  @override
  State<_BannersTab> createState() => _BannersTabState();
}

class _BannersTabState extends State<_BannersTab> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await context.read<AuthProvider>().api!.adminBanners();
      if (!mounted) return;
      setState(() { _rows = r; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final text = await promptText(context, 'نص الـ banner');
    if (text == null || text.isEmpty || !mounted) return;
    final color = await showModalBottomSheet<String>(
      context: context, backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const ListTile(title: Text('اللون',
            style: TextStyle(fontWeight: FontWeight.w800))),
        ...['primary', 'warning', 'error', 'success', 'info'].map((c) =>
          ListTile(title: Text(c), onTap: () => Navigator.pop(context, c))),
      ])),
    );
    if (color == null || !mounted) return;
    final url = await promptText(context, 'رابط اختياري');
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!.adminCreateBanner({
        'text': text, 'color': color,
        if (url != null && url.isNotEmpty) 'action_url': url,
        'icon': 'info',
      });
      if (mounted) { snack(context, 'تم التعيين'); _load(); }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  Future<void> _delete(int id) async {
    if (!await confirm(context, 'تعطيل؟')) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!.adminDeleteBanner(id);
      if (mounted) { snack(context, 'تم'); _load(); }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: C.primary))
        : _rows.isEmpty
          ? const EmptyState(icon: Icons.flag_outlined, title: 'لا توجد banners')
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _rows.length,
              itemBuilder: (_, i) {
                final r = _rows[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: C.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.border),
                  ),
                  child: Row(children: [
                    Container(width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: C.info.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.flag, color: C.info, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['text']?.toString() ?? '',
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Text(r['color']?.toString() ?? '',
                            style: const TextStyle(color: C.muted,
                                fontSize: 10, fontFamily: 'monospace')),
                      ],
                    )),
                    IconButton(
                      onPressed: () => _delete(r['id'] as int),
                      icon: const Icon(Icons.block, color: C.danger, size: 18),
                    ),
                  ]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: C.info,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Banner جديد'),
      ),
    );
  }
}

// ============================ KILL SWITCH TAB ============================
class _KillSwitchTab extends StatefulWidget {
  const _KillSwitchTab();
  @override
  State<_KillSwitchTab> createState() => _KillSwitchTabState();
}

class _KillSwitchTabState extends State<_KillSwitchTab> {
  bool _busy = false;

  Future<void> _toggle(bool enabled) async {
    final reason = enabled
      ? await promptText(context, 'السبب الظاهر للمستخدم',
          initial: 'صيانة طارئة')
      : null;
    if (enabled && (reason == null || reason.isEmpty)) return;
    if (!mounted) return;
    if (!await confirm(context,
        enabled ? 'تفعيل الإيقاف الطارئ؟' : 'إلغاء الإيقاف؟',
        msg: enabled ? 'سيتوقف التطبيق فوراً عند كل المستخدمين.' : null,
        danger: enabled)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().api!
          .adminKillSwitch(enabled, reason: reason ?? '');
      if (mounted) snack(context, enabled ? 'تم التفعيل' : 'تم الإلغاء');
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: C.danger.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.danger.withValues(alpha: .4)),
        ),
        child: Column(children: [
          const Icon(Icons.power_settings_new, color: C.danger, size: 40),
          const SizedBox(height: 12),
          const Text('Kill Switch',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                  color: C.danger)),
          const SizedBox(height: 6),
          const Text(
            'تفعيل هذا يمنع كل المستخدمين من استخدام التطبيق فوراً.\n'
            'استخدمه بحذر شديد — فقط في الحالات الطارئة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: C.muted, fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _toggle(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.success,
                side: BorderSide(color: C.success.withValues(alpha: .5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('إلغاء', style: TextStyle(
                  fontWeight: FontWeight.w700)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(
              onPressed: _busy ? null : () => _toggle(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: C.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.stop),
              label: const Text('تفعيل', style: TextStyle(
                  fontWeight: FontWeight.w800)),
            )),
          ]),
        ]),
      ),
      const SizedBox(height: 20),
      SectionCard(title: 'ملاحظة', child: const Text(
        'عند التفعيل، أي مستخدم يفتح التطبيق سيرى شاشة الإيقاف '
        'ولن يتمكن من الوصول لأي شيء حتى تُلغيه.',
        style: TextStyle(color: C.muted, fontSize: 12, height: 1.6),
      )),
    ]);
  }
}
