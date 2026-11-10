import 'package:flutter/services.dart';

class Haptics {
  static void tap() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void success() => HapticFeedback.mediumImpact();
  static void error() => HapticFeedback.vibrate();
  static void select() => HapticFeedback.selectionClick();
}
