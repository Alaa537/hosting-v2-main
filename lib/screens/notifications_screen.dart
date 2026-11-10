import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/dialogs.dart';
import '../widgets/section_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _items = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final l = await context.read<AuthProvider>().api!.notifications(limit: 100);
      if (!mounted) return;
      setState(() { _items = l; _err = null; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _err = e.toString(); _loading = false; });
    }
  }

  Future<void> _readAll() async {
    try {
      await context.read<AuthProvider>().api!.notificationsRead();
      if (mounted) { snack(context, 'All read');
        await context.read<AuthProvider>().refreshMe();
        _load();
      }
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  Future<void> _clearAll() async {
    if (!await confirm(context, 'Delete all notifications?', danger: true)) return;
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!.notificationsClear();
      if (mounted) { snack(context, 'Cleared');
        await context.read<AuthProvider>().refreshMe();
        _load();
      }
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), actions: [
        IconButton(onPressed: _readAll, icon: const Icon(Icons.done_all, color: C.success)),
        IconButton(onPressed: _clearAll, icon: const Icon(Icons.clear_all, color: C.danger)),
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: C.primary)),
      ]),
      body: SafeArea(child: _loading
        ? const Center(child: CircularProgressIndicator(color: C.primary))
        : _err != null
          ? Center(child: Text(_err!, style: const TextStyle(color: C.danger)))
          : RefreshIndicator(onRefresh: _load, color: C.primary,
              backgroundColor: C.surface,
              child: _items.isEmpty
                ? ListView(children: const [SizedBox(height: 100),
                    EmptyState(icon: Icons.notifications_none,
                        title: 'No notifications')])
                : ListView.builder(padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (_, i) => _card(_items[i])),
            )),
    );
  }

  Widget _card(NotificationItem n) {
    final color = n.isRead ? C.muted : C.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: n.isRead ? C.surface : C.accent.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: n.isRead ? C.border
            : C.accent.withValues(alpha: .3)),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (!n.isRead) Container(width: 8, height: 8,
            decoration: const BoxDecoration(color: C.accent, shape: BoxShape.circle)),
          if (!n.isRead) const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(20)),
            child: Text(n.kind.toUpperCase(),
                style: TextStyle(color: color, fontSize: 9,
                    fontWeight: FontWeight.w900, letterSpacing: .8))),
          const Spacer(),
          Text(fDate(n.ts),
              style: const TextStyle(color: C.muted, fontSize: 10)),
        ]),
        const SizedBox(height: 8),
        Text(n.text, style: const TextStyle(fontSize: 13, height: 1.4)),
      ])),
    );
  }
}
