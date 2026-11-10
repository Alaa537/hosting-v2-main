import 'dart:async';
import 'package:flutter/widgets.dart';
import 'security_service.dart';

/// Calls SecurityService.verify() every 5 seconds.
/// All logic is native — this just polls.
class SecurityMonitor with WidgetsBindingObserver {
  static final SecurityMonitor I = SecurityMonitor._();
  SecurityMonitor._();

  static const _interval = Duration(seconds: 5);

  Timer? _timer;
  bool _running = false;
  bool _foreground = true;

  SecurityResult? lastResult;
  void Function(SecurityResult)? onFailure;
  VoidCallback? onRecovered;
  SecurityResult? _lastFailed;

  void start() {
    if (_running) return;
    _running = true;
    WidgetsBinding.instance.addObserver(this);
    _tick();
    _timer = Timer.periodic(_interval, (_) {
      if (_foreground) _tick();
    });
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
    try { WidgetsBinding.instance.removeObserver(this); } catch (_) {}
  }

  Future<void> poke() => _tick();

  Future<void> _tick() async {
    try {
      final r = await SecurityService.verify();
      lastResult = r;
      if (!r.isOk) {
        _lastFailed = r;
        onFailure?.call(r);
      } else if (_lastFailed != null) {
        _lastFailed = null;
        onRecovered?.call();
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) poke();
  }
}
