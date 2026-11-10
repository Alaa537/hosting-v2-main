import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/error_utils.dart';
import '../widgets/dialogs.dart';
import '../widgets/section_card.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});
  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<AuthProvider>().api!.sessions();
      final list = (data['sessions'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() { _rows = list; _err = null; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _err = friendlyError(e); _loading = false; });
    }
  }

  Future<void> _revoke(Map<String, dynamic> row) async {
    if (!await confirm(context, 'إلغاء الجلسة؟',
        msg: 'سيتم تسجيل الخروج من هذا الجهاز.',
        danger: true)) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!.revokeSession(row['id'] as int);
      if (mounted) { snack(context, 'تم إلغاء الجلسة'); _load(); }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جلساتي'),
        actions: [
          IconButton(onPressed: _load,
              icon: const Icon(Icons.refresh, color: C.primary)),
        ],
      ),
      body: SafeArea(child: _loading
        ? const Center(child: CircularProgressIndicator(color: C.primary))
        : _err != null
          ? Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_err!, textAlign: TextAlign.center,
                  style: const TextStyle(color: C.danger))))
          : RefreshIndicator(
              onRefresh: _load,
              color: C.primary,
              backgroundColor: C.surface,
              child: _rows.isEmpty
                ? ListView(children: const [SizedBox(height: 100),
                    EmptyState(icon: Icons.devices_other,
                        title: 'لا توجد جلسات')])
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _rows.length,
                    itemBuilder: (_, i) => _sessionCard(_rows[i]),
                  ),
            )),
    );
  }

  Widget _sessionCard(Map<String, dynamic> r) {
    final isCurrent = r['is_current'] == true;
    final color = isCurrent ? C.success : C.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? C.success.withValues(alpha: .5)
              : C.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(isCurrent ? Icons.phone_android : Icons.devices,
                color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(
              r['device_id']?.toString() ?? 'جهاز',
              style: const TextStyle(fontWeight: FontWeight.w700,
                  fontSize: 13, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            )),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: C.success.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('الحالية',
                    style: TextStyle(color: C.success, fontSize: 9,
                        fontWeight: FontWeight.w900)),
              ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 4, children: [
            _info(Icons.desktop_windows, r['platform']?.toString() ?? '—'),
            _info(Icons.network_check, r['ip']?.toString() ?? '—'),
            _info(Icons.access_time,
                (r['created_at']?.toString() ?? '').substring(0,
                    (r['created_at']?.toString() ?? '').length > 19 ? 19 : (r['created_at']?.toString() ?? '').length)),
            _info(Icons.update,
                (r['last_used']?.toString() ?? '').substring(0,
                    (r['last_used']?.toString() ?? '').length > 19 ? 19 : (r['last_used']?.toString() ?? '').length)),
          ]),
          if (!isCurrent) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _revoke(r),
                icon: const Icon(Icons.logout, color: C.danger, size: 16),
                label: const Text('إلغاء',
                    style: TextStyle(color: C.danger, fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _info(IconData i, String v) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(i, size: 12, color: C.muted),
    const SizedBox(width: 4),
    Text(v, style: const TextStyle(color: C.muted, fontSize: 11,
        fontFamily: 'monospace')),
  ]);
}
