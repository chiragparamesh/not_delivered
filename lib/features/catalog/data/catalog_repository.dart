import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';

/// Loads assets/data/restaurants.json and dishes.json.
final catalogProvider = FutureProvider<Catalog>((ref) async {
  final r = jsonDecode(await rootBundle.loadString('assets/data/restaurants.json')) as Map<String, dynamic>;
  final d = jsonDecode(await rootBundle.loadString('assets/data/dishes.json')) as Map<String, dynamic>;
  return Catalog(
    [for (final x in r['restaurants'] as List) Restaurant.fromJson(x as Map<String, dynamic>)],
    [for (final x in d['dishes'] as List) Dish.fromJson(x as Map<String, dynamic>)],
  );
});
