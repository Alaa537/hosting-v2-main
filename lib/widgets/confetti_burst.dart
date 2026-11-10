import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Utility to show a one-shot confetti from the top.
class ConfettiBurst {
  static void fire(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _Burst(onDone: () => entry.remove()));
    overlay.insert(entry);
  }
}

class _Burst extends StatefulWidget {
  final VoidCallback onDone;
  const _Burst({required this.onDone});
  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> {
  late final ConfettiController _ctrl = ConfettiController(
      duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    _ctrl.play();
    Future.delayed(const Duration(milliseconds: 2000), widget.onDone);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _ctrl,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          gravity: 0.35,
          emissionFrequency: 0.05,
          colors: const [
            Color(0xFF00D7FF), Color(0xFFFF5FD7),
            Color(0xFF5FFF87), Color(0xFFFFD75F),
          ],
        ),
      )),
    );
  }
}
