import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../catalog/domain/models.dart';
import '../../favorites/data/favorites_controller.dart';
import '../../location/domain/areas.dart';
import '../../settings/data/settings_controller.dart';

/// Delivery estimate from the chosen area to this restaurant.
final etaProvider = Provider.family<int, Restaurant>((ref, r) {
  final area = areaByName(ref.watch(settingsProvider).area ?? 'Koramangala');
  return deliveryMinutes(r.baseDeliveryMins, distanceKm(area.lat, area.lon, r.lat, r.lon));
});

class RestaurantCard extends ConsumerWidget {
  const RestaurantCard({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = restaurant;
    final fav = ref.watch(favoritesProvider).contains(r.id);
    final eta = ref.watch(etaProvider(r));
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('restaurant-${r.id}'),
      child: InkWell(
        onTap: () => context.push(AppRoutes.restaurant(r.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            EmojiTile(emoji: r.emoji, color: Color(r.color), size: 84),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(r.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: fav ? 'Remove favourite' : 'Add favourite',
                    onPressed: () => ref.read(favoritesProvider.notifier).toggle(r.id),
                    icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: AppColors.maroon),
                  ),
                ]),
                Row(children: [
                  RatingPill(rating: r.rating),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('$eta mins · ₹${r.priceForTwo} for two',
                        style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(r.cuisines.join(', '), style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(r.area, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                if (r.pureVeg)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Row(children: [VegMark(isVeg: true, size: 12), SizedBox(width: 4), Text('Pure veg', style: TextStyle(fontSize: 12, color: AppColors.veg))]),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
