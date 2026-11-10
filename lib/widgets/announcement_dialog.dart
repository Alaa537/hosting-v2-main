import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bootstrap.dart';
import '../utils/constants.dart';

/// Builds a beautifully styled dialog from a [ModalInfo] received from
/// the backend. Returns `true` if shown, `false` if user dismissed.
Future<void> showAnnouncementDialog(
  BuildContext context,
  ModalInfo modal, {
  VoidCallback? onDismiss,
}) async {
  final isForce = modal.forceShow;
  final color = _colorFor(modal.type);
  final icon = _iconFor(modal.type, modal.icon);

  await showDialog<void>(
    context: context,
    barrierDismissible: !isForce,
    barrierColor: Colors.black.withValues(alpha: .75),
    builder: (ctx) => PopScope(
      canPop: !isForce,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: C.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withValues(alpha: .45), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .25),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // ---- header ----
            Container(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: .18),
                    color.withValues(alpha: .04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
              ),
              child: Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .18),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: .5), width: 1.5),
                  ),
                  child: Center(child: Text(icon,
                      style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _typeLabel(modal.type),
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      modal.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ],
                )),
              ]),
            ),
            // ---- message ----
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
              child: Text(
                modal.message,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: Colors.white70,
                ),
              ),
            ),
            // ---- buttons ----
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: [
                if (modal.buttons.isEmpty)
                  _button(
                    ctx: ctx,
                    label: 'حسناً',
                    color: color,
                    style: 'primary',
                    onTap: () => Navigator.pop(ctx),
                  )
                else
                  ...modal.buttons.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _button(
                      ctx: ctx,
                      label: b.text,
                      color: _buttonColor(b.style, color),
                      style: b.style,
                      onTap: () async {
                        switch (b.action) {
                          case 'url':
                            if (b.url != null) {
                              await _openUrl(b.url!);
                            }
                            if (!isForce) Navigator.pop(ctx);
                            break;
                          case 'copy':
                            if (b.value != null) {
                              Clipboard.setData(ClipboardData(text: b.value!));
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('تم النسخ'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            break;
                          default:
                            Navigator.pop(ctx);
                        }
                      },
                    ),
                  )),
              ]),
            ),
          ]),
        ),
      ),
    ),
  );
  onDismiss?.call();
}

Widget _button({
  required BuildContext ctx,
  required String label,
  required Color color,
  required String style,
  required VoidCallback onTap,
}) {
  final isPrimary = style == 'primary';
  final isDanger = style == 'danger';
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: isPrimary || isDanger
        ? ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? C.danger : color,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: .5,
                )),
          )
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: .5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                )),
          ),
  );
}

Future<void> _openUrl(String url) async {
  try {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

Color _colorFor(String type) {
  switch (type) {
    case 'warning': return C.warning;
    case 'error': return C.danger;
    case 'success': return C.success;
    case 'update': return C.primary;
    case 'promo':
    case 'gift': return C.accent;
    case 'stop':
    case 'maintenance': return C.danger;
    default: return C.primary;
  }
}

Color _buttonColor(String style, Color fallback) {
  switch (style) {
    case 'danger': return C.danger;
    case 'primary': return fallback;
    default: return fallback;
  }
}

String _typeLabel(String type) {
  switch (type) {
    case 'warning': return 'تحذير';
    case 'error': return 'خطأ';
    case 'success': return 'تم';
    case 'update': return 'تحديث';
    case 'promo': return 'إعلان';
    case 'gift': return 'هدية';
    case 'stop': return 'إيقاف';
    case 'maintenance': return 'صيانة';
    default: return 'معلومة';
  }
}

String _iconFor(String type, String icon) {
  if (icon != 'auto' && icon.isNotEmpty) {
    switch (icon) {
      case 'download': return '⬇️';
      case 'warning': return '⚠️';
      case 'server': return '🖥️';
      case 'gift': return '🎁';
      case 'info': return 'ℹ️';
    }
  }
  switch (type) {
    case 'warning': return '⚠️';
    case 'error': return '❌';
    case 'success': return '✅';
    case 'update': return '⬇️';
    case 'promo': return '📢';
    case 'gift': return '🎁';
    case 'stop': return '🛑';
    case 'maintenance': return '🔧';
    default: return 'ℹ️';
  }
}
