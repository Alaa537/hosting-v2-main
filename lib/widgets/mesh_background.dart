import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Animated mesh gradient with 3 blurred blobs.
class MeshBackground extends StatefulWidget {
  final Widget child;
  final bool subtle;
  const MeshBackground({super.key, required this.child, this.subtle = false});

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 18))
    ..repeat();

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.subtle ? .15 : .30;
    return Stack(children: [
      const Positioned.fill(child: ColoredBox(color: C.bg)),
      AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value * 2 * math.pi;
          return Stack(children: [
            _blob(
              cx: 0.25 + 0.15 * math.cos(t * 0.7),
              cy: 0.20 + 0.10 * math.sin(t * 0.9),
              r: 380,
              color: C.primary.withValues(alpha: opacity),
            ),
            _blob(
              cx: 0.80 + 0.12 * math.sin(t * 1.1),
              cy: 0.55 + 0.15 * math.cos(t * 0.8),
              r: 340,
              color: C.accent.withValues(alpha: opacity),
            ),
            _blob(
              cx: 0.50 + 0.20 * math.sin(t * 0.5),
              cy: 0.90 + 0.08 * math.cos(t * 1.2),
              r: 280,
              color: const Color(0xFF6F5FFF).withValues(alpha: opacity * 0.7),
            ),
          ]);
        },
      ),
      Positioned.fill(child: widget.child),
    ]);
  }

  Widget _blob({required double cx, required double cy,
      required double r, required Color color}) {
    return LayoutBuilder(builder: (ctx, cons) {
      return Positioned(
        left: cons.maxWidth * cx - r,
        top: cons.maxHeight * cy - r,
        child: Container(
          width: r * 2, height: r * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color, color.withValues(alpha: color.a * .4),
              Colors.transparent,
            ], stops: const [0, .4, 1]),
          ),
        ),
      );
    });
  }
}
