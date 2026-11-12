import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/clock.dart';
import '../../../core/theme/app_theme.dart';
import '../../cart/data/cart_controller.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../tracking/domain/tracking.dart';
import '../data/orders_controller.dart';
import '../domain/order.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  void _reorder(BuildContext context, WidgetRef ref, Order o) {
    final catalog = ref.read(catalogProvider).value;
    if (catalog == null) return;
    final lines = {
      for (final l in o.lines)
        if (catalog.dish(l.dishId) != null) l.dishId: l.qty,
    };
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Those dishes are no longer on the menu.')));
      return;
    }
    ref.read(cartProvider.notifier).replaceWith(o.restaurantId, lines);
    context.push(AppRoutes.cart);
  }

  String _date(DateTime t) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '${t.day} ${m[t.month - 1]}, $h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'am' : 'pm'}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final now = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: orders.isEmpty
          ? const Center(child: Text('No orders yet. Your future self is hungry.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final o in orders)
                  Card(
                    key: ValueKey('order-${o.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(o.restaurantName, style: Theme.of(context).textTheme.titleMedium)),
                          Chip(
                            label: Text(o.isDelivered
                                ? 'Delivered'
                                : stageLabels[trackingStatus(placedAt: o.placedAt, now: now, easterEgg: false, etaMins: o.etaMins, prepMins: o.prepMins).stage]!),
                            backgroundColor: o.isDelivered ? AppColors.veg.withValues(alpha: 0.12) : AppColors.gold.withValues(alpha: 0.3),
                          ),
                        ]),
                        Text(o.lines.map((l) => '${l.qty} × ${l.name}').join(', '), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('${_date(o.placedAt)} · ₹${o.total}${o.discount > 0 ? ' · saved ₹${o.discount}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Row(children: [
                          if (!o.isDelivered)
                            OutlinedButton(onPressed: () => context.push(AppRoutes.track(o.id)), child: const Text('Track')),
                          if (o.isDelivered && o.scratchReward == null)
                            OutlinedButton(onPressed: () => context.push(AppRoutes.track(o.id)), child: const Text('Scratch card 🎁')),
                          const Spacer(),
                          FilledButton.tonal(
                            key: ValueKey('reorder-${o.id}'),
                            onPressed: () => _reorder(context, ref, o),
                            child: const Text('Reorder'),
                          ),
                        ]),
                      ]),
                    ),
                  ),
              ],
            ),
    );
  }
}
