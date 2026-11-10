import 'package:flutter/material.dart';
import '../utils/constants.dart';

class PulseIcon extends StatefulWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const PulseIcon({
    super.key,
    required this.icon,
    required this.active,
    this.activeColor = C.primary,
    this.inactiveColor = C.muted,
    this.size = 24,
  });

  @override
  State<PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Icon(widget.icon, color: widget.inactiveColor, size: widget.size);
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = _c.value;
        return Stack(alignment: Alignment.center, children: [
          // Glow
          Container(
            width: widget.size * (1.2 + .4 * t),
            height: widget.size * (1.2 + .4 * t),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.activeColor.withValues(alpha: .18 * (1 - t)),
            ),
          ),
          child!,
        ]);
      },
      child: ShaderMask(
        shaderCallback: (r) => LinearGradient(colors: [
          widget.activeColor,
          C.accent,
        ]).createShader(r),
        child: Icon(widget.icon, color: Colors.white, size: widget.size),
      ),
    );
  }
}
