import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Now" and randomness, injectable for tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
final randomProvider = Provider<math.Random>((ref) => math.Random());
