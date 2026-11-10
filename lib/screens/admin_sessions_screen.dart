import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/error_utils.dart';
import '../widgets/dialogs.dart';
import '../widgets/section_card.dart';

class AdminSessionsScreen extends StatefulWidget {
  const AdminSessionsScreen({super.key});
  @override
  State<AdminSessionsScreen> createState() => _AdminSessionsScreenState();
}

class _AdminSessionsScreenState extends State<AdminSessionsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<AuthProvider>().api!
          .adminSessions(activeOnly: true, limit: 300);
      final list = (data['sessions'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() { _rows = list; _err = null; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _err = friendlyError(e); _loading = false; });
    }
  }

  Future<void> _revoke(Map<String, dynamic> r) async {
    if (!await confirm(context, 'إلغاء الجلسة؟', danger: true)) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!
          .adminRevokeSession(r['id'] as int);
      if (mounted) { snack(context, 'تم الإلغاء'); _load(); }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الجلسات النشطة (${_rows.length})'),
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
                    itemBuilder: (_, i) => _card(_rows[i]),
                  ),
            )),
    );
  }

  Widget _card(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: C.primary.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.devices, color: C.primary, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(r['username']?.toString() ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: C.primary.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('ID ${r['id']}',
                    style: const TextStyle(color: C.primary, fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 3),
            Text(
              '${r['device_id']?.toString().substring(0, (r['device_id']?.toString().length ?? 0) > 20 ? 20 : (r['device_id']?.toString().length ?? 0))} · ${r['ip'] ?? '—'}',
              style: const TextStyle(color: C.muted, fontSize: 10,
                  fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
            if (r['last_used'] != null)
              Text('آخر استخدام: ${(r['last_used']?.toString() ?? '').split('T').first}',
                  style: const TextStyle(color: C.muted, fontSize: 10)),
          ],
        )),
        IconButton(
          onPressed: () => _revoke(r),
          icon: const Icon(Icons.logout, color: C.danger, size: 20),
        ),
      ]),
    );
  }
}
