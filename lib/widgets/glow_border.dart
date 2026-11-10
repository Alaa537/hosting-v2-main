import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Card with a rotating border glow.
class GlowBorderCard extends StatefulWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double borderWidth;
  final double intensity;

  const GlowBorderCard({
    super.key,
    required this.child,
    this.color = C.primary,
    this.radius = 18,
    this.borderWidth = 1.5,
    this.intensity = 1.0,
  });

  @override
  State<GlowBorderCard> createState() => _GlowBorderCardState();
}

class _GlowBorderCardState extends State<GlowBorderCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 4))
    ..repeat();

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final angle = _c.value * 2 * math.pi;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: SweepGradient(
              transform: GradientRotation(angle),
              colors: [
                widget.color.withValues(alpha: .8 * widget.intensity),
                widget.color.withValues(alpha: .1),
                widget.color.withValues(alpha: .8 * widget.intensity),
              ],
              stops: const [0, 0.5, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: .35 * widget.intensity),
                blurRadius: 24, spreadRadius: 1,
              ),
            ],
          ),
          padding: EdgeInsets.all(widget.borderWidth),
          child: Container(
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.circular(widget.radius),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
