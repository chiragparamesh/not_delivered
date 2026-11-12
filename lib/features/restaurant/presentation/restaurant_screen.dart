import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/haptics.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../cart/data/cart_controller.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/models.dart';
import '../../favorites/data/favorites_controller.dart';
import '../../home/presentation/restaurant_card.dart';

class RestaurantScreen extends ConsumerStatefulWidget {
  const RestaurantScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends ConsumerState<RestaurantScreen> {
  var _vegOnly = false;

  Future<void> _add(Dish d) async {
    Haptics.tap();
    final cart = ref.read(cartProvider.notifier);
    if (cart.add(d) == AddResult.added) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Start a new cart?'),
        content: const Text('Your cart has food from another restaurant. Replace it with this dish?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep old cart')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Start new')),
        ],
      ),
    );
    if (ok == true) cart.startNewCart(d);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider).value;
    final r = catalog?.restaurant(widget.id);
    if (catalog == null || r == null) {
      return Scaffold(appBar: AppBar(), body: Center(child: catalog == null ? const CircularProgressIndicator() : const Text('Restaurant not found')));
    }
    final cart = ref.watch(cartProvider);
    final fav = ref.watch(favoritesProvider).contains(r.id);
    final eta = ref.watch(etaProvider(r));
    final menu = catalog.menu(r.id).where((d) => !_vegOnly || d.isVeg).toList();
    final sections = <String, List<Dish>>{};
    for (final d in menu) {
      sections.putIfAbsent(d.section, () => []).add(d);
    }
    final bill = ref.watch(cartBillProvider);
    final cartHere = cart.restaurantId == r.id && !cart.isEmpty;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 200,
          backgroundColor: Color(r.color),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Favourite',
              onPressed: () => ref.read(favoritesProvider.notifier).toggle(r.id),
              icon: Icon(fav ? Icons.favorite : Icons.favorite_border),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(r.name, style: const TextStyle(fontFamily: AppTheme.headingFont, fontWeight: FontWeight.w700, color: Colors.white)),
            background: Container(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(r.color), Color(r.color).withValues(alpha: 0.6)])),
              alignment: Alignment.center,
              child: Text(r.emoji, style: const TextStyle(fontSize: 80)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                RatingPill(rating: r.rating),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('(${r.ratingCount}+ ratings) · ₹${r.priceForTwo} for two',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 6),
              Text('${r.cuisines.join(', ')} · ${r.area}', style: theme.textTheme.bodyMedium),
              Text('🛵 $eta mins · free delivery on ₹199+', style: theme.textTheme.bodySmall),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _vegOnly,
                onChanged: r.pureVeg ? null : (v) => setState(() => _vegOnly = v),
                secondary: const VegMark(isVeg: true),
                title: Text(r.pureVeg ? 'Pure veg restaurant' : 'Veg only'),
              ),
            ]),
          ),
        ),
        for (final e in sections.entries) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('${e.key} (${e.value.length})', style: theme.textTheme.titleMedium),
            ),
          ),
          SliverList.list(children: [
            for (final d in e.value)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        VegMark(isVeg: d.isVeg),
                        if (d.bestseller) ...[
                          const SizedBox(width: 6),
                          const Text('★ Bestseller', style: TextStyle(color: Color(0xFFE65100), fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ]),
                      const SizedBox(height: 2),
                      Text(d.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text('₹${d.price}'),
                      if (d.description.isNotEmpty)
                        Text(d.description, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Column(children: [
                    EmojiTile(emoji: d.emoji, color: Color(r.color), size: 72),
                    const SizedBox(height: 6),
                    QtyButton(
                      addKey: ValueKey('add-${d.id}'),
                      qty: cart.restaurantId == r.id ? cart.qty(d.id) : 0,
                      onAdd: () => _add(d),
                      onRemove: () => ref.read(cartProvider.notifier).remove(d),
                    ),
                  ]),
                ]),
              ),
          ]),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ]),
      bottomNavigationBar: cartHere && bill != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  key: const Key('view-cart'),
                  onPressed: () => context.push(AppRoutes.cart),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  child: Row(children: [
                    Expanded(
                      child: Text('${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'} · ₹${bill.itemTotal}',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const Text('View cart'),
                    const Icon(Icons.chevron_right),
                  ]),
                ),
              ),
            )
          : null,
    );
  }
}
