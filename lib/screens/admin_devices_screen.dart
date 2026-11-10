import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/error_utils.dart';
import '../widgets/dialogs.dart';
import '../widgets/section_card.dart';

class AdminDevicesScreen extends StatefulWidget {
  const AdminDevicesScreen({super.key});
  @override
  State<AdminDevicesScreen> createState() => _AdminDevicesScreenState();
}

class _AdminDevicesScreenState extends State<AdminDevicesScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _err;
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await context.read<AuthProvider>().api!
          .adminDevices(search: _search.text.trim());
      final list = (data['devices'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() { _rows = list; _err = null; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _err = friendlyError(e); _loading = false; });
    }
  }

  Future<void> _revoke(Map<String, dynamic> d) async {
    if (!await confirm(context, 'إلغاء الجهاز؟',
        msg: 'لن يتمكن المستخدم من استخدام هذا الجهاز لفتح التطبيق.',
        danger: true)) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!
          .adminDeleteDevice(d['device_id'] as String);
      if (mounted) { snack(context, 'تم الإلغاء'); _load(); }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأجهزة'),
        actions: [
          IconButton(onPressed: _load,
              icon: const Icon(Icons.refresh, color: C.primary)),
        ],
      ),
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'بحث باسم المستخدم أو الـ device id…',
              prefixIcon: const Icon(Icons.search, color: C.primary),
              suffixIcon: IconButton(
                onPressed: _load,
                icon: const Icon(Icons.arrow_forward, color: C.primary),
              ),
            ),
          ),
        ),
        Expanded(child: _loading
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
                          title: 'لا توجد أجهزة')])
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _rows.length,
                      itemBuilder: (_, i) => _deviceCard(_rows[i]),
                    ),
              )),
      ])),
    );
  }

  Widget _deviceCard(Map<String, dynamic> d) {
    final revoked = d['revoked'] == true;
    final color = revoked ? C.muted : C.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(revoked ? Icons.phone_disabled : Icons.phone_android,
                  color: color, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d['device_id']?.toString() ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 12, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(d['username']?.toString() ?? 'غير مربوط',
                    style: TextStyle(color: color, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            )),
            if (!revoked)
              IconButton(
                onPressed: () => _revoke(d),
                icon: const Icon(Icons.block, color: C.danger, size: 20),
              ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 12, children: [
            _info(Icons.desktop_windows, d['platform']?.toString() ?? '—'),
            _info(Icons.access_time,
                (d['created_at']?.toString() ?? '').split('T').first),
            _info(Icons.update,
                (d['last_seen']?.toString() ?? '').split('T').first),
          ]),
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
