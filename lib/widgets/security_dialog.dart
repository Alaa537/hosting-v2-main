import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/security_service.dart';
import '../utils/constants.dart';

class SecurityBlockScreen extends StatelessWidget {
  final SecurityResult result;
  const SecurityBlockScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final d = _details();
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: d.$4.withValues(alpha: .12),
              border: Border.all(color: d.$4.withValues(alpha: .55), width: 2),
            ),
            child: Center(child: Text(d.$1, style: const TextStyle(fontSize: 46))),
          ),
          const SizedBox(height: 20),
          Text(d.$2, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: d.$4.withValues(alpha: .35)),
            ),
            child: SelectableText(d.$3,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70,
                    fontSize: 12.5, height: 1.6, fontFamily: 'monospace')),
          ),
          if (result.debug.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text: const JsonEncoder.withIndent('  ').convert(result.debug)));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('تم نسخ التفاصيل'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating));
              },
              icon: const Icon(Icons.copy, size: 16, color: C.muted),
              label: const Text('نسخ التفاصيل',
                  style: TextStyle(color: C.muted, fontSize: 11)),
            ),
          ],
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () async {
              try {
                await launchUrl(Uri.parse('https://t.me/ahrgq'),
                    mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            icon: const Icon(Icons.telegram, color: C.primary),
            label: const Text('تواصل مع الدعم',
                style: TextStyle(color: C.primary)),
          ),
        ]),
      ))),
    );
  }

  (String, String, String, Color) _details() {
    switch (result.status) {
      case SecurityStatus.vpn:
        return ('🚫', 'VPN مكتشف', result.message ?? 'أوقف VPN', C.danger);
      case SecurityStatus.mitm:
        return ('🛡️', 'أداة مراقبة', result.message ?? 'أغلق Canary/Charles', C.danger);
      case SecurityStatus.tampered:
        return ('⚠️', 'تطبيق معدّل', result.message ?? 'التوقيع غير مطابق', C.danger);
      case SecurityStatus.ssl:
        return ('🔒', 'شهادة غير موثوقة', result.message ?? 'قد يكون هناك اعتراض', C.danger);
      case SecurityStatus.rooted:
        return ('🔓', 'الجهاز متجذّر', 'لا يعمل على جهاز Rooted', C.danger);
      case SecurityStatus.frida:
        return ('🎯', 'أداة تحليل', 'أغلق Frida', C.danger);
      case SecurityStatus.debugger:
        return ('🐛', 'تحت التصحيح', 'أغلق الـ Debugger', C.danger);
      case SecurityStatus.xposed:
        return ('🧩', 'Xposed مكتشف', 'أزل Xposed', C.danger);
      case SecurityStatus.emulator:
        return ('💻', 'محاكي مكتشف', 'لا يعمل على المحاكي', C.danger);
      case SecurityStatus.error:
        return ('⚠️', 'خطأ', result.message ?? 'غير معروف', C.warning);
      case SecurityStatus.ok:
        return ('✅', 'OK', '', C.success);
    }
  }
}
