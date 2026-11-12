import 'package:flutter/services.dart';

/// Haptics are a no-op on web, so this is safe everywhere.
class Haptics {
  static Future<void> celebrate() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
  }

  static Future<void> tap() => HapticFeedback.selectionClick();
}
