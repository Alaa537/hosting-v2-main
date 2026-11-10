import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

/// Full-screen block shown when the backend kill switch is ON.
class KillSwitchScreen extends StatelessWidget {
  final String reason;
  final VoidCallback? onRetry;
  const KillSwitchScreen({super.key, required this.reason, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: C.danger.withValues(alpha: .12),
                    border: Border.all(
                      color: C.danger.withValues(alpha: .5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: C.danger.withValues(alpha: .35),
                        blurRadius: 40, spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🛑', style: TextStyle(fontSize: 54)),
                  ),
                ),
                const SizedBox(height: 28),
                const Text('الخدمة متوقفة مؤقتاً',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5,
                    )),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: C.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: C.danger.withValues(alpha: .35)),
                  ),
                  child: Text(
                    reason.isEmpty
                        ? 'هذه الخدمة غير متاحة في الوقت الحالي.\nحاول مرة أخرى لاحقاً.'
                        : reason,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                if (onRetry != null)
                  SizedBox(
                    width: 200, height: 48,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: C.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await launchUrl(Uri.parse('https://t.me/'),
                          mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.telegram, color: C.primary),
                  label: const Text('قناة التحديثات',
                      style: TextStyle(color: C.primary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen block for maintenance mode.
class MaintenanceScreen extends StatelessWidget {
  final String? message;
  const MaintenanceScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: C.warning.withValues(alpha: .12),
                    border: Border.all(color: C.warning.withValues(alpha: .5), width: 2),
                  ),
                  child: const Center(
                    child: Text('🔧', style: TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('صيانة مجدولة',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text(
                  message ?? 'الخدمة تحت الصيانة حالياً.\nسنعود قريباً جداً.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: C.muted, fontSize: 14, height: 1.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
