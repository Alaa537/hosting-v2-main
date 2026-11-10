import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Glassmorphism card with blur, subtle border, and inner glow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? accent;
  final double blur;
  final double radius;
  final VoidCallback? onTap;
  final bool glow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accent,
    this.blur = 18,
    this.radius = 18,
    this.onTap,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final a = accent ?? C.primary;
    final box = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: a.withValues(alpha: .22), width: 1),
        boxShadow: glow
            ? [
                BoxShadow(
                    color: a.withValues(alpha: .28),
                    blurRadius: 24,
                    spreadRadius: 1),
                BoxShadow(
                    color: a.withValues(alpha: .10),
                    blurRadius: 48,
                    spreadRadius: 4),
              ]
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: .25),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  C.surface.withValues(alpha: .85),
                  C.surfaceHi.withValues(alpha: .65),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: a.withValues(alpha: .15),
        highlightColor: a.withValues(alpha: .06),
        child: box,
      ),
    );
  }
}
