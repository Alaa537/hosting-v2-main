import 'package:flutter/material.dart';
import 'constants.dart';

String fSize(num? n) {
  if (n == null) return '—';
  double v = n.toDouble();
  const u = ['B', 'KB', 'MB', 'GB', 'TB'];
  int i = 0;
  while (v >= 1024 && i < u.length - 1) { v /= 1024; i++; }
  return i == 0 ? '${v.toInt()} ${u[i]}' : '${v.toStringAsFixed(1)} ${u[i]}';
}

String fTime(num? secs) {
  if (secs == null || secs == 0) return '—';
  int s = secs.toInt();
  if (s < 60) return '${s}s';
  int m = s ~/ 60; s %= 60;
  if (m < 60) return '${m}m ${s}s';
  int h = m ~/ 60; m %= 60;
  if (h < 24) return '${h}h ${m}m';
  int d = h ~/ 24; h %= 24;
  return '${d}d ${h}h';
}

String stateIcon(String s) {
  switch (s) {
    case 'running': return '●';
    case 'starting': case 'restarting': return '◐';
    case 'crashed': case 'missing': case 'unreachable': return '✖';
    case 'stopped': case 'offline': case 'exited':
    case 'launcher_offline': return '○';
    default: return '•';
  }
}

Color stateColor(String s) {
  switch (s) {
    case 'running': return C.success;
    case 'starting': case 'restarting': return C.warning;
    case 'crashed': case 'missing': case 'unreachable': return C.danger;
    default: return C.muted;
  }
}

Color logColor(String line) {
  final u = line.toUpperCase();
  if (u.contains('ERROR') || u.contains('TRACEBACK') || u.contains('CRITICAL')) return C.danger;
  if (u.contains('WARN') || u.contains('DEPRECAT')) return C.warning;
  if (u.contains('INFO') || u.contains('STARTED')) return C.primary;
  if (u.contains('DEBUG')) return C.muted;
  return Colors.white;
}

String fDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  return iso.replaceFirst('T', ' ').split('.').first;
}
