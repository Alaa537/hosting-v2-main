import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/dialogs.dart';
import '../widgets/section_card.dart';
import 'admin_devices_screen.dart';
import 'admin_sessions_screen.dart';
import 'admin_content_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  AdminStats? _stats;
  bool _loading = true;
  String? _err;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await context.read<AuthProvider>().api!.adminStats();
      if (!mounted) return;
      setState(() { _stats = s; _err = null; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _err = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin panel'),
        actions: [IconButton(onPressed: _load,
            icon: const Icon(Icons.refresh, color: C.primary))]),
      body: SafeArea(child: _loading
        ? const Center(child: CircularProgressIndicator(color: C.primary))
        : _err != null
          ? Center(child: Text(_err!, style: const TextStyle(color: C.danger)))
          : RefreshIndicator(onRefresh: _load, color: C.primary,
              backgroundColor: C.surface,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                if (_stats != null) _cards(_stats!),
                const SizedBox(height: 16),
                SectionCard(title: 'Manage', child: Column(children: [
                  _action(Icons.assignment_ind_outlined, 'Pending requests',
                      () => _requests()),
                  _action(Icons.people_outline, 'Users list', () => _users()),
                  _action(Icons.settings_suggest_outlined, 'System settings',
                      () => _settings()),
                  _action(Icons.campaign_outlined, 'Announcements',
                      () => _announcements()),
                  _action(Icons.receipt_long_outlined, 'Audit log',
                      () => _audit()),
                  _action(Icons.trending_up, 'Metrics', () => _metrics()),
                  _action(Icons.backup, 'Database backup', () => _dbBackup()),
                ])),
                const SizedBox(height: 30),
              ]),
            )),
    );
  }

  Widget _cards(AdminStats s) {
    final data = [
      ('Users', s.users, C.success),
      ('Pending', s.pending, C.warning),
      ('Banned', s.banned, C.danger),
      ('Free', s.poolFree, C.primary),
      ('Used', s.poolUsed, C.accent),
      ('Logins 24h', s.logins24h, C.info),
    ];
    return GridView.count(crossAxisCount: 3, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.1,
      children: data.map((d) {
        final (label, val, color) = d;
        return Container(
          decoration: BoxDecoration(color: C.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: .3))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$val', style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: C.muted, fontSize: 10,
                fontWeight: FontWeight.w600)),
          ]),
        );
      }).toList());
  }

  Widget _action(IconData ic, String t, VoidCallback onTap) =>
    ListTile(contentPadding: EdgeInsets.zero,
      leading: Icon(ic, color: C.primary, size: 20),
      title: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: C.muted),
      onTap: onTap);

  // ---- Requests ----
  Future<void> _requests() async {
    try {
      final list = await context.read<AuthProvider>().api!.adminRequests();
      if (!mounted) return;
      if (list.isEmpty) { snackInfo(context, 'No pending requests'); return; }
      await showModalBottomSheet(context: context, backgroundColor: C.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => DraggableScrollableSheet(expand: false,
          initialChildSize: .6, maxChildSize: .9,
          builder: (_, ctrl) => ListView(controller: ctrl, padding: const EdgeInsets.all(16),
            children: [
              Text('Pending requests (${list.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...list.map((r) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_add, color: C.warning),
                title: Text(r['username'] ?? '', style: const TextStyle(
                    fontWeight: FontWeight.w700)),
                subtitle: Text(fDate(r['created_at']),
                    style: const TextStyle(color: C.muted, fontSize: 10)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.close, color: C.danger),
                    onPressed: () => _reject(r['id'])),
                  IconButton(icon: const Icon(Icons.check, color: C.success),
                    onPressed: () => _approve(r['id'])),
                ]),
              )),
            ])));
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  Future<void> _approve(int uid) async {
    final days = await promptInt(context, 'Days (blank for no expiry)');
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!.adminApprove(uid, days: days);
      if (mounted) { Navigator.pop(context); snack(context, 'Approved'); _load(); }
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  Future<void> _reject(int uid) async {
    final r = await promptText(context, 'Reason', initial: 'not approved');
    if (r == null || !mounted) return;
    try {
      await context.read<AuthProvider>().api!.adminReject(uid, r);
      if (mounted) { Navigator.pop(context); snack(context, 'Rejected'); _load(); }
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  // ---- Users ----
  Future<void> _users() async {
    try {
      final list = await context.read<AuthProvider>().api!.adminUsers();
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => _UsersListScreen(users: list)));
      _load();
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  // ---- Settings ----
  Future<void> _settings() async {
    try {
      final s = await context.read<AuthProvider>().api!.adminSettings();
      if (!mounted) return;
      await showModalBottomSheet(context: context, backgroundColor: C.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => StatefulBuilder(builder: (ctx, setS) => SafeArea(
          child: Padding(padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('System settings', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Maintenance mode'),
                value: s['maintenance'] == true,
                activeColor: C.primary,
                onChanged: (v) async {
                  await context.read<AuthProvider>().api!
                      .adminSettingsUpdate({'maintenance': v});
                  setS(() => s['maintenance'] = v);
                }),
              SwitchListTile(
                title: const Text('Registration open'),
                value: s['registration_open'] == true,
                activeColor: C.primary,
                onChanged: (v) async {
                  await context.read<AuthProvider>().api!
                      .adminSettingsUpdate({'registration_open': v});
                  setS(() => s['registration_open'] = v);
                }),
              SwitchListTile(
                title: const Text('Require approval'),
                value: s['require_approval'] == true,
                activeColor: C.primary,
                onChanged: (v) async {
                  await context.read<AuthProvider>().api!
                      .adminSettingsUpdate({'require_approval': v});
                  setS(() => s['require_approval'] = v);
                }),
              ListTile(
                title: const Text('Invite code'),
                subtitle: Text('${s['invite_code'] ?? '—'}',
                    style: const TextStyle(color: C.muted)),
                trailing: const Icon(Icons.edit, color: C.primary, size: 18),
                onTap: () async {
                  final c = await promptText(context, 'Invite code (blank=disable)',
                      initial: s['invite_code'] ?? '');
                  if (c == null || !mounted) return;
                  await context.read<AuthProvider>().api!
                      .adminSettingsUpdate({'invite_code': c});
                  setS(() => s['invite_code'] = c);
                }),
            ])))));
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  // ---- Announcements ----
  Future<void> _announcements() async {
    final t = await promptText(context, 'Announcement text', maxLines: 4);
    if (t == null || t.isEmpty || !mounted) return;
    try {
      await context.read<AuthProvider>().api!.announce(t);
      if (mounted) snack(context, 'Posted');
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  Future<void> _audit() async {
    try {
      final list = await context.read<AuthProvider>().api!.adminAudit(limit: 200);
      if (!mounted) return;
      showModalBottomSheet(context: context, backgroundColor: C.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => DraggableScrollableSheet(expand: false,
          initialChildSize: .8, maxChildSize: .95,
          builder: (_, ctrl) => ListView(controller: ctrl, padding: const EdgeInsets.all(16),
            children: [
              Text('Audit log (${list.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...list.map((r) => ListTile(
                contentPadding: EdgeInsets.zero, dense: true,
                leading: const Icon(Icons.history, color: C.primary, size: 18),
                title: Text(r['action'] ?? '?', style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12)),
                subtitle: Text('${fDate(r['ts'])} · uid=${r['user_id'] ?? '—'}\n'
                    '${r['detail'] ?? ''}',
                    style: const TextStyle(color: C.muted, fontSize: 10)),
                isThreeLine: true,
              )),
            ])));
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  Future<void> _metrics() async {
    try {
      final list = await context.read<AuthProvider>().api!.adminMetrics(hours: 24);
      if (!mounted) return;
      showModalBottomSheet(context: context, backgroundColor: C.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => DraggableScrollableSheet(expand: false,
          initialChildSize: .8, maxChildSize: .95,
          builder: (_, ctrl) => ListView(controller: ctrl, padding: const EdgeInsets.all(16),
            children: [
              const Text('Metrics (last 24h)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (list.isEmpty) const EmptyState(icon: Icons.trending_up,
                  title: 'No metrics yet')
              else ...list.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${fDate(r['ts'])} · users=${r['users']} '
                  'pending=${r['pending']} '
                  'pool=${r['pool_used']}/${r['pool_total']} '
                  'run=${r['running']}',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace',
                      color: C.muted),
                ),
              )),
            ])));
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  Future<void> _dbBackup() async {
    if (!await confirm(context, 'Run database backup?', danger: true)) return;
    if (!mounted) return;
    try {
      final r = await context.read<AuthProvider>().api!.dbBackup();
      if (mounted) snackInfo(context, 'DB backup: ${r['file'] ?? 'done'}');
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }
}

// ---- Users list sub-screen ----
class _UsersListScreen extends StatefulWidget {
  final List<AdminUser> users;
  const _UsersListScreen({required this.users});
  @override
  State<_UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<_UsersListScreen> {
  late List<AdminUser> _u = widget.users;

  Future<void> _refresh() async {
    try {
      final l = await context.read<AuthProvider>().api!.adminUsers();
      if (mounted) setState(() => _u = l);
    } catch (_) {}
  }

  void _actions(AdminUser u) {
    showModalBottomSheet(context: context, backgroundColor: C.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: Text(u.username, style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 16)),
          subtitle: Text('uid=${u.id} · ${u.role} · ${u.status}')),
        const Divider(height: 1),
        ListTile(leading: Icon(u.banned ? Icons.check_circle : Icons.block,
          color: u.banned ? C.success : C.danger),
          title: Text(u.banned ? 'Unban' : 'Ban'),
          onTap: () async { Navigator.pop(context); await _toggleBan(u); }),
        ListTile(leading: const Icon(Icons.password, color: C.primary),
          title: const Text('Set password'),
          onTap: () async { Navigator.pop(context); await _setPassword(u); }),
        ListTile(leading: const Icon(Icons.admin_panel_settings, color: C.primary),
          title: const Text('Change role'),
          onTap: () async { Navigator.pop(context); await _setRole(u); }),
        ListTile(leading: const Icon(Icons.calendar_today, color: C.primary),
          title: const Text('Set expiry'),
          onTap: () async { Navigator.pop(context); await _setExpiry(u); }),
        ListTile(leading: const Icon(Icons.delete_outline, color: C.danger),
          title: const Text('Delete user', style: TextStyle(color: C.danger)),
          onTap: () async { Navigator.pop(context); await _delete(u); }),
      ])));
  }

  Future<void> _toggleBan(AdminUser u) async {
    try {
      final api = context.read<AuthProvider>().api!;
      if (u.banned) await api.adminUnban(u.id);
      else {
        final r = await promptText(context, 'Ban reason', initial: '');
        if (r == null || !mounted) return;
        await api.adminBan(u.id, r);
      }
      if (mounted) { snack(context, 'Updated'); _refresh(); }
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  Future<void> _setPassword(AdminUser u) async {
    final p = await promptText(context, 'New password', obscure: true);
    if (p == null || p.length < 8 || !mounted) return;
    try {
      await context.read<AuthProvider>().api!.adminSetPassword(u.id, p);
      if (mounted) snack(context, 'Password set');
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  Future<void> _setRole(AdminUser u) async {
    final r = await promptText(context, 'Role (user|admin)', initial: u.role);
    if (r == null || !['user', 'admin'].contains(r) || !mounted) return;
    try {
      await context.read<AuthProvider>().api!.adminSetRole(u.id, r);
      if (mounted) { snack(context, 'Role set'); _refresh(); }
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  Future<void> _setExpiry(AdminUser u) async {
    final d = await promptInt(context, 'Days from now (blank = clear)');
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!.adminSetExpiry(u.id, d);
      if (mounted) { snack(context, 'Expiry set'); _refresh(); }
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  Future<void> _delete(AdminUser u) async {
    if (!await confirm(context, 'Delete ${u.username}?', danger: true)) return;
    if (!mounted) return;
    final wipe = await confirm(context, 'Also wipe server files?');
    if (!mounted) return;
    try {
      await context.read<AuthProvider>().api!.adminDeleteUser(u.id, wipe: wipe);
      if (mounted) { snack(context, 'Deleted'); _refresh(); }
    } catch (e) { if (mounted) snack(context, e.toString(), error: true); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users (${_u.length})'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: C.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: C.primary,
          backgroundColor: C.surface,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _u.length,
            itemBuilder: (_, i) {
              final u = _u[i];
              final roleColor = u.isAdmin ? C.accent : C.primary;
              final exp = u.expiresAt != null
                  ? ' · exp ${fDate(u.expiresAt).split(" ").first}'
                  : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: C.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.border),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: roleColor.withValues(alpha: .2),
                    child: Text(
                      u.username[0].toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        u.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          u.role.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (u.banned) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.block, size: 12, color: C.danger),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    'uid=${u.id} · ${u.status}$exp',
                    style: const TextStyle(color: C.muted, fontSize: 10),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: C.muted,
                    size: 18,
                  ),
                  onTap: () => _actions(u),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
