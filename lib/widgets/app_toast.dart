import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum ToastKind { success, error, info }

void showToast(BuildContext ctx, String msg, {ToastKind kind = ToastKind.info}) {
  final color = kind == ToastKind.success ? C.success
      : kind == ToastKind.error ? C.danger
      : C.primary;
  final icon = kind == ToastKind.success ? Icons.check_circle
      : kind == ToastKind.error ? Icons.error_outline
      : Icons.info_outline;

  final overlay = Overlay.of(ctx);
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => Positioned(
    top: MediaQuery.of(ctx).padding.top + 12,
    left: 16, right: 16,
    child: Material(
      color: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => Transform.translate(
          offset: Offset(0, -60 * (1 - v)),
          child: Opacity(opacity: v, child: child),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: .5)),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: .30),
                  blurRadius: 20, spreadRadius: 1),
            ],
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(msg,
                style: TextStyle(color: color,
                    fontSize: 13, fontWeight: FontWeight.w700))),
          ]),
        ),
      ),
    ),
  ));
  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 3), () {
    try { entry.remove(); } catch (_) {}
  });
}
