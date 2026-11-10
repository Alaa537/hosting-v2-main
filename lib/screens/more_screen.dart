import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/haptics.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass_card.dart';
import 'profile_screen.dart';
import 'backups_screen.dart';
import 'notifications_screen.dart';
import 'admin_screen.dart';
import 'settings_screen.dart';
import 'ai_assistant_screen.dart';
import 'developer_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildHeader(user),
            const SizedBox(height: 22),
            _sectionLabel('الحساب'),
            _tile(
              context,
              Icons.person_outline_rounded,
              'الملف الشخصي',
              'معلومات الحساب والنشاط',
              () => _push(context, const ProfileScreen()),
            ),
            _tile(
              context,
              Icons.notifications_outlined,
              'الإشعارات',
              user != null && user.unreadNotifications > 0
                  ? '${user.unreadNotifications} غير مقروء'
                  : 'الوارد',
              () => _push(context, const NotificationsScreen()),
              badge: user?.unreadNotifications ?? 0,
            ),
            _tile(
              context,
              Icons.settings_outlined,
              'الإعدادات',
              'كلمة المرور · الجلسات',
              () => _push(context, const SettingsScreen()),
            ),
            const SizedBox(height: 8),
            _sectionLabel('أدوات'),
            _tile(
              context,
              Icons.auto_awesome_rounded,
              'BIMEX AI',
              'مساعدك الذكي · اسأل أي شيء',
              () => _push(context, const AIAssistantScreen()),
              accent: true,
            ),
            _tile(
              context,
              Icons.backup_outlined,
              'النسخ الاحتياطي',
              'إنشاء / استرجاع',
              () => _push(context, const BackupsScreen()),
            ),
            if (user?.isAdmin == true) ...[
              const SizedBox(height: 8),
              _sectionLabel('الإدارة'),
              _tile(
                context,
                Icons.admin_panel_settings_rounded,
                'لوحة الأدمن',
                'المستخدمين · الأجهزة · المحتوى',
                () => _push(context, const AdminScreen()),
                accent: true,
              ),
            ],
            const SizedBox(height: 8),
            _sectionLabel('حول'),
            _tile(
              context,
              Icons.code_rounded,
              'المطور',
              'Alaa Rafeek · Founder',
              () => _push(context, const DeveloperScreen()),
              accent: true,
            ),
            const SizedBox(height: 18),
            GlassCard(
              accent: C.danger,
              padding: EdgeInsets.zero,
              onTap: () async {
                Haptics.medium();
                final ok = await confirm(
                  context,
                  'تسجيل الخروج',
                  msg: 'هل تريد تسجيل الخروج من هذا الجهاز؟',
                  danger: true,
                );
                if (ok == true && context.mounted) {
                  await context.read<AuthProvider>().logout();
                }
              },
              child: const ListTile(
                leading: Icon(Icons.logout_rounded, color: C.danger),
                title: Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: C.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: C.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4, right: 4),
        child: Text(
          t,
          style: const TextStyle(
            color: C.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: .6,
          ),
        ),
      );

  Widget _buildHeader(user) {
    return GlassCard(
      accent: C.primary,
      glow: true,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [C.primary, C.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: C.primary.withValues(alpha: .4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              (user?.username ?? '?')[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.username ?? '—',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: user?.isAdmin == true
                          ? [C.accent, C.accentDim]
                          : [C.primary, C.primaryDim],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (user?.role ?? 'user').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                ),
                if (user != null && user.unreadNotifications > 0) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: C.accent.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: C.accent.withValues(alpha: .4)),
                    ),
                    child: Text(
                      '${user.unreadNotifications} إشعار',
                      style: const TextStyle(
                        color: C.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _tile(
    BuildContext ctx,
    IconData ic,
    String title,
    String sub,
    VoidCallback onTap, {
    bool accent = false,
    int badge = 0,
  }) {
    final color = accent ? C.accent : C.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        accent: color,
        padding: EdgeInsets.zero,
        onTap: () {
          Haptics.select();
          onTap();
        },
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: .25)),
            ),
            child: Icon(ic, color: color, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          subtitle: Text(
            sub,
            style: const TextStyle(color: C.muted, fontSize: 11.5),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge > 0)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: C.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right_rounded, color: C.muted),
            ],
          ),
        ),
      ),
    );
  }

  void _push(BuildContext c, Widget w) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => w));
}
