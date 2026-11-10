import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class StaggeredList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsets padding;
  final ScrollPhysics? physics;
  final Axis scrollDirection;

  const StaggeredList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(12),
    this.physics,
    this.scrollDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: padding,
        itemCount: itemCount,
        physics: physics,
        scrollDirection: scrollDirection,
        itemBuilder: (ctx, i) => AnimationConfiguration.staggeredList(
          position: i,
          duration: const Duration(milliseconds: 350),
          child: SlideAnimation(
            horizontalOffset: scrollDirection == Axis.vertical ? 0 : 40,
            verticalOffset: scrollDirection == Axis.vertical ? 40 : 0,
            curve: Curves.easeOutCubic,
            child: FadeInAnimation(
              child: itemBuilder(ctx, i),
            ),
          ),
        ),
      ),
    );
  }
}
