import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

/// Animated Telegram support floating button.
class TelegramFab extends StatefulWidget {
  const TelegramFab({super.key});
  @override
  State<TelegramFab> createState() => _TelegramFabState();
}

class _TelegramFabState extends State<TelegramFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Future<void> _open() async {
    try {
      await launchUrl(Uri.parse('https://t.me/ahrgq'),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Transform.translate(
          offset: Offset(0, -4 * t),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _open,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF29B6F6).withValues(alpha: .5 + .3 * t),
                      blurRadius: 14 + 8 * t,
                      spreadRadius: 1 + 2 * t,
                    ),
                  ],
                ),
                child: const Icon(Icons.telegram,
                    color: Colors.white, size: 28),
              ),
            ),
          ),
        );
      },
    );
  }
}
