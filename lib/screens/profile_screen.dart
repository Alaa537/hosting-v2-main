import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _u;
  List<Announcement> _ann = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().api!;
    try {
      final r = await Future.wait([api.me(), api.announcements()]);
      if (!mounted) return;
      setState(() {
        _u = r[0] as User;
        _ann = r[1] as List<Announcement>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _err = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'),
        actions: [IconButton(onPressed: _load,
            icon: const Icon(Icons.refresh, color: C.primary))]),
      body: SafeArea(child: _loading
        ? const Center(child: CircularProgressIndicator(color: C.primary))
        : RefreshIndicator(onRefresh: _load, color: C.primary,
          backgroundColor: C.surface,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (_err != null) Text(_err!, style: const TextStyle(color: C.danger)),
            if (_u != null) ...[
              SectionCard(title: 'Account', child: Column(children: [
                KVRow(k: 'Username', v: Text(_u!.username,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
                KVRow(k: 'ID', v: Text('${_u!.id}')),
                KVRow(k: 'Role', v: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _u!.isAdmin ? C.accent : C.primary,
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(_u!.role.toUpperCase(),
                      style: const TextStyle(color: Colors.black,
                          fontSize: 10, fontWeight: FontWeight.w900)),
                )),
                KVRow(k: 'Created', v: Text(fDate(_u!.createdAt),
                    style: const TextStyle(color: C.muted, fontSize: 12))),
                KVRow(k: 'Expires', v: Text(_u!.expiresAt == null ? 'never' : fDate(_u!.expiresAt),
                    style: TextStyle(color: _u!.expiresAt == null ? C.success : C.warning,
                        fontSize: 12))),
                if (_u!.daysLeft != null)
                  KVRow(k: 'Days left', v: Text('${_u!.daysLeft}',
                      style: const TextStyle(color: C.warning,
                          fontWeight: FontWeight.w700))),
              ])),
              const SizedBox(height: 14),
              SectionCard(title: 'Resources', child: Column(children: [
                KVRow(k: 'Max bots', v: Text('${_u!.maxBots}')),
                KVRow(k: 'Has server', v: Text(_u!.hasServer ? 'yes' : 'no',
                    style: TextStyle(color: _u!.hasServer ? C.success : C.danger,
                        fontWeight: FontWeight.w700))),
                KVRow(k: 'Auto-restart', v: Text(_u!.autoRestart ? 'on' : 'off',
                    style: TextStyle(color: _u!.autoRestart ? C.success : C.muted))),
                KVRow(k: 'Unread', v: Text('${_u!.unreadNotifications}',
                    style: const TextStyle(color: C.accent,
                        fontWeight: FontWeight.w700))),
              ])),
              if (_ann.isNotEmpty) ...[
                const SizedBox(height: 14),
                SectionCard(title: 'Announcements', child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _ann.take(5).map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.campaign_outlined, size: 16, color: C.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.text, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(fDate(a.ts),
                              style: const TextStyle(color: C.muted, fontSize: 10)),
                        ],
                      )),
                    ]),
                  )).toList(),
                )),
              ],
            ],
            const SizedBox(height: 30),
          ]),
        )),
    );
  }
}
