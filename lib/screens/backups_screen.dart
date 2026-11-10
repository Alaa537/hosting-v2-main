import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/error_utils.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton.dart';
import '../utils/haptics.dart';

class BackupsScreen extends StatefulWidget {
  const BackupsScreen({super.key});
  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  List<BackupInfo> _items = [];
  int? _limit;
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await context.read<AuthProvider>().api!.backups();
      if (!mounted) return;
      setState(() {
        _items = (r['backups'] as List? ?? [])
            .map((e) => BackupInfo.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _limit = r['limit'] as int?;
        _err = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final n = await promptText(context, 'اسم النسخة (فارغ = تلقائي)');
    if (n == null || !mounted) return;
    try {
      await context.read<AuthProvider>().api!.backupCreate(n);
      if (mounted) {
        snack(context, 'بدأ النسخ الاحتياطي');
        _load();
      }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  Future<void> _policy() async {
    try {
      final p = await context.read<AuthProvider>().api!.backupPolicyGet();
      if (!mounted) return;
      final enabled = await confirm(
        context,
        'تفعيل النسخ التلقائي؟',
        msg: 'الحالي: ${p['enabled'] == true ? "مُفعّل" : "متوقف"}\n'
             'الفاصل: ${p['interval_hours']}س\n'
             'الاحتفاظ: ${p['keep']}',
      );
      if (!mounted) return;
      final hours = await promptInt(
        context,
        'الفاصل (ساعات)',
        initial: (p['interval_hours'] as num?)?.toInt() ?? 24,
      );
      if (hours == null || !mounted) return;
      final keep = await promptInt(
        context,
        'عدد النسخ المحفوظة',
        initial: (p['keep'] as num?)?.toInt() ?? 3,
      );
      if (keep == null || !mounted) return;
      await context.read<AuthProvider>().api!
          .backupPolicySet(enabled, hours, keep);
      if (mounted) snack(context, 'تم الحفظ');
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  void _showActions(BackupInfo b) {
    Haptics.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: C.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: C.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.backup_outlined, color: C.primary),
              ),
              title: Text(
                b.name.isEmpty ? b.uuid.substring(0, 8) : b.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${fSize(b.bytes)} · ${fDate(b.createdAt)}',
                style: const TextStyle(color: C.muted, fontSize: 11),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.restore, color: C.warning),
              title: const Text('استرجاع'),
              onTap: () {
                Navigator.pop(ctx);
                _restore(b);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: C.danger),
              title: const Text('حذف',
                  style: TextStyle(color: C.danger)),
              onTap: () {
                Navigator.pop(ctx);
                _delete(b);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(BackupInfo b) async {
    if (!await confirm(
      context,
      'استرجاع النسخة؟',
      msg: 'سيتم استبدال حالة السيرفر الحالية.',
      danger: true,
    )) {
      return;
    }
    if (!mounted) return;

    final truncate = await confirm(
      context,
      'مسح الملفات أولاً؟',
      msg: 'إذا اخترت نعم، ستُحذف الملفات الحالية قبل الاسترجاع.',
    );
    if (!mounted) return;

    try {
      await context.read<AuthProvider>().api!
          .backupRestore(b.uuid, truncate: truncate);
      if (mounted) {
        Haptics.success();
        snack(context, 'بدأ الاسترجاع');
      }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  Future<void> _delete(BackupInfo b) async {
    if (!await confirm(context, 'حذف النسخة؟', danger: true)) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!.backupDelete(b.uuid);
      if (mounted) {
        snack(context, 'تم الحذف');
        _load();
      }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('النسخ الاحتياطي'),
        actions: [
          IconButton(
            onPressed: _policy,
            icon: const Icon(Icons.tune, color: C.primary),
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: C.primary),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        backgroundColor: C.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('نسخة جديدة',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const SkeletonList(count: 5);

    if (_err != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: C.danger, size: 48),
              const SizedBox(height: 12),
              Text(_err!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: C.danger)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: const Text('إعادة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return BeautifulEmpty(
        icon: Icons.backup_outlined,
        title: 'لا توجد نسخ احتياطية',
        subtitle: 'اضغط + لإنشاء أول نسخة',
        actionLabel: 'نسخة جديدة',
        onAction: _create,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: C.primary,
      backgroundColor: C.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          if (_limit != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'الحد الأقصى: $_limit نسخة',
                style: const TextStyle(color: C.muted, fontSize: 12),
              ),
            ),
          ..._items.map((b) => _card(b)),
        ],
      ),
    );
  }

  Widget _card(BackupInfo b) {
    final c = b.state == 'done'
        ? C.success
        : b.state == 'running'
            ? C.warning
            : C.danger;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        accent: c,
        padding: EdgeInsets.zero,
        onTap: () => _showActions(b),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  b.locked ? Icons.lock : Icons.backup,
                  color: c, size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.name.isEmpty ? b.uuid.substring(0, 8) : b.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: c, shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          b.state,
                          style: TextStyle(
                            color: c, fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          fSize(b.bytes),
                          style: const TextStyle(
                            color: C.muted, fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fDate(b.createdAt),
                            style: const TextStyle(
                              color: C.muted, fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: C.muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
