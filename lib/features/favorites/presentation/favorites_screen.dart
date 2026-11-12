import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/data/catalog_repository.dart';
import '../../home/presentation/restaurant_card.dart';
import '../data/favorites_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);
    final catalog = ref.watch(catalogProvider).value;
    final list = catalog == null ? const [] : [for (final id in favs) ?catalog.restaurant(id)];
    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: list.isEmpty
          ? const Center(child: Text('Tap ♡ on a restaurant to save it here.'))
          : ListView(padding: const EdgeInsets.all(16), children: [for (final r in list) RestaurantCard(restaurant: r)]),
    );
  }
}
