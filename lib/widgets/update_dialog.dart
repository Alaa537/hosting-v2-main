import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bootstrap.dart';
import '../utils/constants.dart';

/// Shows update dialog. Returns `true` if user is allowed to continue,
/// `false` if the update is forced and the app must be blocked.
Future<bool> showUpdateDialog(BuildContext context, UpdateInfo upd) async {
  if (upd.force) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .85),
      builder: (ctx) => PopScope(
        canPop: false,
        child: _buildDialog(ctx, upd, forced: true),
      ),
    );
    return false;
  }

  // Optional update → dismissible
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _buildDialog(ctx, upd, forced: false),
  );
  return true;
}

Widget _buildDialog(BuildContext ctx, UpdateInfo upd, {required bool forced}) {
  final color = forced ? C.danger : C.primary;
  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    child: Container(
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: .5), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .3),
              blurRadius: 40, spreadRadius: 3),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: .2),
                color.withValues(alpha: .05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
          ),
          child: Column(children: [
            Container(
              width: 66, height: 66,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .18),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: .55), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.system_update_alt_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: .5)),
              ),
              child: Text(
                forced ? 'تحديث إجباري' : 'تحديث متاح',
                style: TextStyle(color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3),
              ),
            ),
            const SizedBox(height: 12),
            Text(upd.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: C.surfaceHi,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('v${upd.version}',
                    style: const TextStyle(
                      color: C.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    )),
              ),
            ]),
          ]),
        ),
        if (upd.message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.border),
              ),
              child: Text(upd.message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.6,
                    fontFamily: 'monospace',
                  )),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(children: [
            if (upd.downloadUrl != null)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await launchUrl(Uri.parse(upd.downloadUrl!),
                          mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('تنزيل التحديث',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            if (!forced) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('لاحقاً',
                      style: TextStyle(color: C.muted, fontWeight: FontWeight.w600)),
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              const Text('يجب التحديث للمتابعة',
                  style: TextStyle(color: C.danger, fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ]),
        ),
      ]),
    ),
  );
}
