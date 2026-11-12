import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/common.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../home/presentation/restaurant_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _q = TextEditingController();

  static const suggestions = ['Biryani', 'Dosa', 'Pizza', 'Momos', 'Kulfi', 'Coffee', 'Thali', 'Shawarma'];

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider).value;
    final q = _q.text.trim().toLowerCase();
    final theme = Theme.of(context);
    final restaurants = catalog == null || q.isEmpty
        ? const []
        : catalog.restaurants
            .where((r) => r.name.toLowerCase().contains(q) || r.cuisines.any((c) => c.toLowerCase().contains(q)) || r.area.toLowerCase().contains(q))
            .toList();
    final dishes = catalog == null || q.isEmpty
        ? const []
        : catalog.dishes.where((d) => d.name.toLowerCase().contains(q) || d.section.toLowerCase().contains(q)).take(30).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('search-field'),
            controller: _q,
            autofocus: false,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Restaurants, dishes, cuisines, areas',
              suffixIcon: q.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(_q.clear)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (q.isEmpty) ...[
            Text('Popular searches', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in suggestions)
                ActionChip(label: Text(s), onPressed: () => setState(() => _q.text = s)),
            ]),
          ] else ...[
            if (restaurants.isEmpty && dishes.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Text('No results. Try "biryani" or "dosa".', textAlign: TextAlign.center)),
            if (restaurants.isNotEmpty) Text('Restaurants', style: theme.textTheme.titleMedium),
            for (final r in restaurants) RestaurantCard(restaurant: r),
            if (dishes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Dishes', style: theme.textTheme.titleMedium),
            ],
            for (final d in dishes)
              Card(
                child: ListTile(
                  leading: FoodImage(photo: d.photo, emoji: d.emoji, color: const Color(0xFF8B1E3F), size: 48, radius: 10),
                  title: Row(children: [VegMark(isVeg: d.isVeg), const SizedBox(width: 6), Expanded(child: Text(d.name))]),
                  subtitle: Text('₹${d.price} · ${catalog!.restaurant(d.restaurantId)?.name ?? ''}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.restaurant(d.restaurantId)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
