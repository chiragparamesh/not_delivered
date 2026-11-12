import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/clock.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_constants.dart';
import '../../cart/data/cart_controller.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/models.dart';
import '../../notifications/data/notifications_controller.dart';
import '../../orders/data/orders_controller.dart';
import '../../rewards/data/rewards_controller.dart';
import '../../rewards/domain/rewards.dart';
import '../../settings/data/settings_controller.dart';
import 'restaurant_card.dart';

enum SortBy { relevance, rating, deliveryTime, costLow }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _cuisine;
  var _pureVeg = false;
  var _rating4 = false;
  var _fast = false;
  var _cheap = false;
  var _sort = SortBy.relevance;

  static const cuisineEmoji = {
    'South Indian': '🥞', 'Biryani': '🍛', 'North Indian': '🍲', 'Desserts': '🍨', 'Bakery': '🥐', 'Chinese': '🥡',
    'Pizza': '🍕', 'Burgers': '🍔', 'Rolls': '🌯', 'Italian': '🍝', 'Karnataka': '🍚', 'Healthy': '🥗',
    'Chaat': '🥙', 'Momos': '🥟', 'Cafe': '☕', 'Andhra': '🌶️', 'Kerala': '🐟', 'Arabian': '🥙', 'Ice Cream': '🍦',
  };

  @override
  void initState() {
    super.initState();
    // Orders placed before the app was closed may have "arrived" meanwhile.
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(ordersProvider.notifier).deliverDueOrders());
  }

  List<Restaurant> _apply(List<Restaurant> all) {
    final list = all.where((r) {
      if (_cuisine != null && !r.cuisines.contains(_cuisine)) return false;
      if (_pureVeg && !r.pureVeg) return false;
      if (_rating4 && r.rating < 4.2) return false;
      if (_fast && ref.read(etaProvider(r)).totalMins > 30) return false;
      if (_cheap && r.priceForTwo > 300) return false;
      return true;
    }).toList();
    switch (_sort) {
      case SortBy.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case SortBy.deliveryTime:
        list.sort((a, b) => ref.read(etaProvider(a)).totalMins.compareTo(ref.read(etaProvider(b)).totalMins));
      case SortBy.costLow:
        list.sort((a, b) => a.priceForTwo.compareTo(b.priceForTwo));
      case SortBy.relevance:
        list.sort((a, b) => (b.rating * 10 - ref.read(etaProvider(b)).totalMins / 3).compareTo(a.rating * 10 - ref.read(etaProvider(a)).totalMins / 3));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final settings = ref.watch(settingsProvider);
    final unread = ref.watch(unreadCountProvider);
    final rewards = ref.watch(rewardsProvider);
    final canSpin = canSpinToday(rewards.lastSpin, ref.watch(clockProvider)());
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: InkWell(
          key: const Key('change-location'),
          onTap: () => context.push(AppRoutes.location),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(settings.fromGps ? Icons.my_location : Icons.location_on, color: AppColors.maroon, size: 20),
              const SizedBox(width: 4),
              Text(settings.area == null ? 'Choose area' : '${settings.fromGps ? 'Near ' : ''}${settings.area}',
                  style: theme.textTheme.titleMedium),
              const Icon(Icons.keyboard_arrow_down),
            ]),
            if (settings.address.isNotEmpty)
              Text(settings.address, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_none)),
          ),
        ],
      ),
      floatingActionButton: cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.cart),
              backgroundColor: AppColors.maroon,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text('${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'} · View cart'),
            ),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load restaurants: $e')),
        data: (cat) {
          final list = _apply(cat.restaurants);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              Text('Hi ${settings.name}, ${AppConstants.tagline}', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => StatefulNavigationShell.of(context).goBranch(1),
                borderRadius: BorderRadius.circular(14),
                child: IgnorePointer(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: AppColors.maroon),
                      hintText: 'Search "biryani", "Namma Dosa"…',
                      enabled: false,
                      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),
              if (canSpin) ...[
                const SizedBox(height: 12),
                Card(
                  color: AppColors.gold.withValues(alpha: 0.25),
                  child: ListTile(
                    key: const Key('spin-banner'),
                    leading: const Text('🎡', style: TextStyle(fontSize: 30)),
                    title: const Text('Your daily spin is ready'),
                    subtitle: const Text('Win up to 100 reward points'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.spin),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text("What's on your mind?", style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 96,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final c in cat.cuisines.take(14))
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          key: ValueKey('cuisine-$c'),
                          borderRadius: BorderRadius.circular(40),
                          onTap: () => setState(() => _cuisine = _cuisine == c ? null : c),
                          child: Column(children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: _cuisine == c ? AppColors.gold : Colors.white,
                              child: Text(cuisineEmoji[c] ?? '🍽️', style: const TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(height: 4),
                            Text(c, style: TextStyle(fontSize: 12, fontWeight: _cuisine == c ? FontWeight.w700 : null)),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  PopupMenuButton<SortBy>(
                    initialValue: _sort,
                    onSelected: (s) => setState(() => _sort = s),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: SortBy.relevance, child: Text('Relevance')),
                      PopupMenuItem(value: SortBy.rating, child: Text('Rating')),
                      PopupMenuItem(value: SortBy.deliveryTime, child: Text('Delivery time')),
                      PopupMenuItem(value: SortBy.costLow, child: Text('Cost: low to high')),
                    ],
                    child: const Chip(avatar: Icon(Icons.sort, size: 18), label: Text('Sort')),
                  ),
                  const SizedBox(width: 8),
                  _filter('Pure veg', _pureVeg, (v) => _pureVeg = v, key: 'filter-veg'),
                  _filter('Rating 4.2+', _rating4, (v) => _rating4 = v),
                  _filter('Under 30 mins', _fast, (v) => _fast = v),
                  _filter('Under ₹300 for two', _cheap, (v) => _cheap = v),
                ]),
              ),
              const SizedBox(height: 8),
              Text('${list.length} restaurants${_cuisine != null ? ' · $_cuisine' : ''}', style: theme.textTheme.titleMedium),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Nothing matches. Even our imaginary chefs have limits.', textAlign: TextAlign.center),
                ),
              for (final r in list) RestaurantCard(restaurant: r),
            ],
          );
        },
      ),
    );
  }

  Widget _filter(String label, bool value, void Function(bool) set, {String? key}) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          key: key == null ? null : Key(key),
          label: Text(label),
          selected: value,
          onSelected: (v) => setState(() => set(v)),
        ),
      );
}
