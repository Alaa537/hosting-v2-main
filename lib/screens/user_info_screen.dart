import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/error_utils.dart';
import '../widgets/dialogs.dart';
import '../widgets/section_card.dart';
import 'sessions_screen.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});
  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab = TabController(length: 3, vsync: this);

  Map<String, dynamic>? _usage;
  List<Map<String, dynamic>> _activity = [];
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = context.read<AuthProvider>().api!;
    try {
      final u = await api.usage();
      final a = await api.activity(limit: 100);
      final al = await api.alerts(limit: 100);
      if (!mounted) return;
      setState(() {
        _usage = u;
        _activity = (a['activity'] as List? ?? []).cast<Map<String, dynamic>>();
        _alerts = (al['alerts'] as List? ?? []).cast<Map<String, dynamic>>();
        _err = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _err = friendlyError(e); _loading = false; });
    }
  }

  Future<void> _markAlertsRead() async {
    try {
      await context.read<AuthProvider>().api!.alertsRead();
      if (mounted) { snack(context, 'تم تعليم الكل كمقروء'); _load(); }
    } catch (e) {
      if (mounted) snack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معلوماتي'),
        actions: [
          IconButton(onPressed: _load,
              icon: const Icon(Icons.refresh, color: C.primary)),
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SessionsScreen())),
            icon: const Icon(Icons.devices_other, color: C.primary),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: C.primary,
          labelColor: C.primary,
          unselectedLabelColor: C.muted,
          tabs: const [
            Tab(text: 'الاستخدام', icon: Icon(Icons.pie_chart_outline, size: 18)),
            Tab(text: 'النشاط', icon: Icon(Icons.history, size: 18)),
            Tab(text: 'التنبيهات', icon: Icon(Icons.notifications_none, size: 18)),
          ],
        ),
      ),
      body: SafeArea(child: _loading
        ? const Center(child: CircularProgressIndicator(color: C.primary))
        : _err != null
          ? Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_err!, textAlign: TextAlign.center,
                  style: const TextStyle(color: C.danger))))
          : TabBarView(
              controller: _tab,
              children: [_usageTab(), _activityTab(), _alertsTab()],
            )),
    );
  }

  // ---------- USAGE ----------
  Widget _usageTab() {
    if (_usage == null) return const EmptyState(icon: Icons.pie_chart, title: 'لا توجد بيانات');
    final u = _usage!;
    final srv = u['server'] as Map<String, dynamic>?;
    final bots = u['bots'] as Map<String, dynamic>?;
    final bks = u['backups'] as Map<String, dynamic>?;

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (u['days_left'] != null)
        SectionCard(title: 'الحساب', child: Column(children: [
          KVRow(k: 'الأيام المتبقية',
              v: Text('${u['days_left']}',
                  style: const TextStyle(color: C.warning,
                      fontWeight: FontWeight.w900, fontSize: 16))),
        ])),
      if (srv != null && srv.isNotEmpty) ...[
        const SizedBox(height: 14),
        SectionCard(title: 'السيرفر', child: Column(children: [
          KVRow(k: 'الحالة', v: Text(srv['state']?.toString() ?? '—',
              style: TextStyle(
                  color: srv['state'] == 'running' ? C.success : C.warning,
                  fontWeight: FontWeight.w700))),
          KVRow(k: 'CPU',
              v: Text('${(srv['cpu_percent'] as num?)?.toStringAsFixed(1) ?? '—'}%')),
          KVRow(k: 'RAM', v: Text(
              '${fSize(srv['memory_bytes'] as num?)} / ${fSize(srv['memory_limit'] as num?)}')),
          KVRow(k: 'Disk', v: Text(
              '${fSize(srv['disk_bytes'] as num?)} / ${fSize(srv['disk_limit'] as num?)}')),
          KVRow(k: 'Net',
              v: Text('▼ ${fSize(srv['rx_bytes'] as num?)}  ▲ ${fSize(srv['tx_bytes'] as num?)}')),
          KVRow(k: 'Uptime', v: Text(fTime(srv['uptime_seconds'] as num?))),
        ])),
      ],
      if (bots != null && bots.isNotEmpty) ...[
        const SizedBox(height: 14),
        SectionCard(title: 'البوتات', child: Column(children: [
          KVRow(k: 'الكل', v: Text('${bots['total'] ?? 0}')),
          KVRow(k: 'يعمل', v: Text('${bots['running'] ?? 0}',
              style: const TextStyle(color: C.success, fontWeight: FontWeight.w700))),
          KVRow(k: 'انهيارات', v: Text('${bots['crashed'] ?? 0}',
              style: const TextStyle(color: C.danger, fontWeight: FontWeight.w700))),
        ])),
      ],
      if (bks != null && bks.isNotEmpty) ...[
        const SizedBox(height: 14),
        SectionCard(title: 'النسخ الاحتياطي', child: Column(children: [
          KVRow(k: 'العدد', v: Text('${bks['count'] ?? 0} / ${bks['limit'] ?? '—'}')),
        ])),
      ],
      const SizedBox(height: 30),
    ]);
  }

  // ---------- ACTIVITY ----------
  Widget _activityTab() {
    if (_activity.isEmpty) {
      return const EmptyState(icon: Icons.history, title: 'لا يوجد نشاط بعد');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _activity.length,
      itemBuilder: (_, i) {
        final r = _activity[i];
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
              child: const Icon(Icons.bolt, color: C.primary, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['action']?.toString() ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w700,
                        fontSize: 12.5, color: C.accent)),
                if ((r['detail'] ?? '').toString().isNotEmpty)
                  Text(r['detail'].toString(),
                      style: const TextStyle(color: C.muted, fontSize: 11),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            )),
            Text((r['ts']?.toString() ?? '').length > 16
                ? r['ts'].toString().substring(11, 16)
                : '',
                style: const TextStyle(color: C.muted, fontSize: 10,
                    fontFamily: 'monospace')),
          ]),
        );
      },
    );
  }

  // ---------- ALERTS ----------
  Widget _alertsTab() {
    if (_alerts.isEmpty) {
      return const EmptyState(icon: Icons.notifications_none,
          title: 'لا توجد تنبيهات');
    }
    final unread = _alerts.where((a) => a['is_read'] != true).length;
    return Column(children: [
      if (unread > 0)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(children: [
            Text('$unread غير مقروء',
                style: const TextStyle(color: C.accent, fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: _markAlertsRead,
              icon: const Icon(Icons.done_all, size: 16, color: C.success),
              label: const Text('تعليم الكل',
                  style: TextStyle(color: C.success, fontSize: 12)),
            ),
          ]),
        ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _alerts.length,
          itemBuilder: (_, i) {
            final a = _alerts[i];
            final isRead = a['is_read'] == true;
            final level = a['level']?.toString() ?? 'info';
            final color = _levelColor(level);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRead ? C.surface : color.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isRead ? C.border : color.withValues(alpha: .35),
                ),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(_levelIcon(level), color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      if (!isRead)
                        Container(width: 6, height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                              color: C.accent, shape: BoxShape.circle)),
                      Expanded(child: Text(a['title']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700,
                              fontSize: 13))),
                    ]),
                    if ((a['text'] ?? '').toString().isNotEmpty)
                      Padding(padding: const EdgeInsets.only(top: 4),
                        child: Text(a['text'].toString(),
                            style: const TextStyle(color: C.muted,
                                fontSize: 12, height: 1.45))),
                    const SizedBox(height: 4),
                    Text((a['ts']?.toString() ?? '').replaceFirst('T', ' '),
                        style: const TextStyle(color: C.muted, fontSize: 10)),
                  ],
                )),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'warning': return C.warning;
      case 'error': return C.danger;
      case 'success': return C.success;
      default: return C.info;
    }
  }

  IconData _levelIcon(String level) {
    switch (level) {
      case 'warning': return Icons.warning_amber_rounded;
      case 'error': return Icons.error_outline;
      case 'success': return Icons.check_circle_outline;
      default: return Icons.info_outline;
    }
  }
}
