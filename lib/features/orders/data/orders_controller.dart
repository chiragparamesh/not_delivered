import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/clock.dart';
import '../../../core/services/store.dart';
import '../../catalog/domain/models.dart';
import '../../cart/domain/coupons.dart';
import '../../notifications/data/notifications_controller.dart';
import '../../rewards/domain/rewards.dart';
import '../../tracking/domain/tracking.dart' show easterEggChance;
import '../domain/order.dart';

const riderNames = ['Raju', 'Manjunath', 'Suresh', 'Imran', 'Venkatesh', 'Anil', 'Shivu', 'Prakash'];

/// Order history (newest first), persisted in Hive.
class OrdersController extends Notifier<List<Order>> {
  static const _key = 'orders';

  @override
  List<Order> build() =>
      [for (final j in ref.read(storeProvider).read(_key) as List? ?? const []) Order.fromJson(j as Map)];

  void _save(List<Order> orders) {
    state = orders;
    ref.read(storeProvider).write(_key, [for (final o in orders) o.toJson()]);
  }

  Order place({
    required Restaurant restaurant,
    required List<(Dish, int)> items,
    required Bill bill,
    required String payment,
    required String address,
    required int etaMins,
    required int prepMins,
  }) {
    final now = ref.read(clockProvider)();
    final rnd = ref.read(randomProvider);
    final order = Order(
      id: 'ND${now.millisecondsSinceEpoch}',
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      restaurantCategory: restaurant.category,
      cuisine: restaurant.cuisines.first,
      lines: [
        for (final (d, q) in items) OrderLine(dishId: d.id, name: d.name, price: d.price, qty: q, isVeg: d.isVeg),
      ],
      itemTotal: bill.itemTotal,
      deliveryFee: bill.deliveryFee,
      discount: bill.discount,
      tip: bill.tip,
      couponCode: bill.coupon?.code,
      placedAt: now,
      payment: payment,
      address: address,
      riderName: riderNames[rnd.nextInt(riderNames.length)],
      easterEgg: rnd.nextDouble() < easterEggChance,
      etaMins: etaMins,
      prepMins: prepMins,
    );
    _save([order, ...state]);
    ref.read(notificationsProvider.notifier).push('🧾', 'Order placed', '${restaurant.name} is on it. Arriving in about $etaMins mins. Total ₹${order.total}.');
    return order;
  }

  /// Marks every order whose timer has run out as delivered, and announces new badges.
  void deliverDueOrders() {
    final now = ref.read(clockProvider)();
    _deliver({
      for (final o in state)
        if (!o.isDelivered && !now.isBefore(o.expectedAt)) o.id: o.expectedAt,
    });
  }

  /// Skip the wait (demo button on the tracking screen).
  void deliverNow(String orderId) => _deliver({orderId: ref.read(clockProvider)()});

  void _deliver(Map<String, DateTime> deliveredAt) {
    final due = state.where((o) => !o.isDelivered && deliveredAt.containsKey(o.id)).toList();
    if (due.isEmpty) return;
    final now = ref.read(clockProvider)();
    final before = earnedBadges(state, now);
    _save([for (final o in state) due.contains(o) ? o.copyWith(deliveredAt: deliveredAt[o.id]) : o]);
    final notes = ref.read(notificationsProvider.notifier);
    for (final o in due) {
      notes.push('✅', 'Delivered!', 'Your ${o.restaurantName} order has arrived. Scratch your card!');
    }
    for (final id in earnedBadges(state, now).difference(before)) {
      final b = allBadges.firstWhere((b) => b.id == id);
      notes.push(b.emoji, 'Badge unlocked: ${b.title}', b.description);
    }
  }

  void setScratchReward(String orderId, int points) =>
      _save([for (final o in state) o.id == orderId ? o.copyWith(scratchReward: points) : o]);

  Order? byId(String id) {
    for (final o in state) {
      if (o.id == id) return o;
    }
    return null;
  }
}

final ordersProvider = NotifierProvider<OrdersController, List<Order>>(OrdersController.new);
