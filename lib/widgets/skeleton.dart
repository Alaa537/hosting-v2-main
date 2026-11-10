import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const Skeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: C.surfaceHi,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          color: C.primary.withValues(alpha: .14),
        );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    // Column instead of ListView to avoid nested scroll issues
    return Column(
      children: List.generate(count, (i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: C.surface.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.border),
          ),
          child: Row(children: [
            const Skeleton(width: 46, height: 46, radius: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(
                    width: 160 + (i % 3) * 20.0,
                    height: 14,
                  ),
                  const SizedBox(height: 10),
                  Skeleton(
                    width: 100 + (i % 2) * 30.0,
                    height: 11,
                  ),
                ],
              ),
            ),
          ]),
        )
            .animate()
            .fadeIn(duration: 300.ms, delay: (80 * i).ms)
            .slideY(begin: .08, end: 0, duration: 350.ms, delay: (80 * i).ms);
      }),
    );
  }
}
