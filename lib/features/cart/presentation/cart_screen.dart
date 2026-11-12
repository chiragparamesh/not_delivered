import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../orders/data/orders_controller.dart';
import '../data/cart_controller.dart';
import '../domain/coupons.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  static const tips = [0, 20, 30, 50];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final catalog = ref.watch(catalogProvider).value;
    final bill = ref.watch(cartBillProvider);
    final theme = Theme.of(context);

    if (cart.isEmpty || catalog == null || bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🍽️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            const Text('Your cart is emptier than a Monday-morning office.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => context.go(AppRoutes.home), child: const Text('Browse restaurants')),
          ]),
        ),
      );
    }
    final r = catalog.restaurant(cart.restaurantId!)!;
    final ctrl = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(r.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                for (final e in cart.lines.entries)
                  if (catalog.dish(e.key) case final d?)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        VegMark(isVeg: d.isVeg),
                        const SizedBox(width: 8),
                        Expanded(child: Text(d.name)),
                        QtyButton(qty: e.value, onAdd: () => ctrl.add(d), onRemove: () => ctrl.remove(d)),
                        SizedBox(width: 64, child: Text('₹${d.price * e.value}', textAlign: TextAlign.right)),
                      ]),
                    ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              key: const Key('coupons'),
              leading: const Icon(Icons.local_offer_outlined, color: AppColors.maroon),
              title: Text(bill.coupon != null ? '${bill.coupon!.code} applied' : 'Apply a coupon'),
              subtitle: bill.coupon != null
                  ? Text('You save ₹${bill.discount}', style: const TextStyle(color: AppColors.veg, fontWeight: FontWeight.w600))
                  : bill.couponProblem != null
                      ? Text(bill.couponProblem!, style: const TextStyle(color: AppColors.nonVeg))
                      : const Text('One coupon at a time'),
              trailing: cart.couponCode != null
                  ? TextButton(onPressed: ctrl.removeCoupon, child: const Text('Remove'))
                  : const Icon(Icons.chevron_right),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const _CouponSheet(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tip your rider', style: theme.textTheme.titleMedium),
                const Text('100% goes to them. (Well, it would, if they existed.)', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  for (final t in tips)
                    ChoiceChip(
                      key: ValueKey('tip-$t'),
                      label: Text(t == 0 ? 'No tip' : '₹$t'),
                      selected: cart.tip == t,
                      onSelected: (_) => ctrl.setTip(t),
                    ),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                _row('Item total', '₹${bill.itemTotal}'),
                _row(
                  'Delivery fee',
                  bill.deliveryFee == 0 ? 'FREE' : '₹${bill.deliveryFee}',
                  note: bill.deliveryFee == 0 ? null : 'Add ₹${freeDeliveryFrom - bill.itemTotal} more for free delivery',
                ),
                if (bill.discount > 0) _row('Coupon (${bill.coupon!.code})', '-₹${bill.discount}', color: AppColors.veg),
                if (bill.tip > 0) _row('Rider tip', '₹${bill.tip}'),
                const Divider(),
                _row('To pay', '₹${bill.total}', bold: true),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            key: const Key('to-checkout'),
            onPressed: () => context.push(AppRoutes.checkout),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            child: Text('Proceed to checkout · ₹${bill.total}'),
          ),
        ),
      ),
    );
  }

  Widget _row(String l, String v, {String? note, bool bold = false, Color? color}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400, fontSize: bold ? 16 : 14, color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: style),
            if (note != null) Text(note, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ),
        Text(v, style: style),
      ]),
    );
  }
}

class _CouponSheet extends ConsumerWidget {
  const _CouponSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final catalog = ref.watch(catalogProvider).value!;
    final bill = ref.watch(cartBillProvider)!;
    final ctx = CouponContext(
      itemTotal: bill.itemTotal,
      isFirstOrder: ref.watch(ordersProvider).isEmpty,
      isDessertOrBakery: catalog.restaurant(cart.restaurantId!)!.isDessertOrBakery,
    );
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text('Coupons', style: Theme.of(context).textTheme.titleLarge),
          const Text('One coupon at a time.'),
          const SizedBox(height: 8),
          for (final c in allCoupons)
            Builder(builder: (_) {
              final res = evaluateCoupon(c, ctx);
              final applied = cart.couponCode == c.code;
              return Card(
                child: ListTile(
                  key: ValueKey('coupon-${c.code}'),
                  title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                  subtitle: Text(
                    res.eligible ? '${c.title}\nYou save ₹${res.discount}' : '${c.title}\n${res.reason}',
                    style: TextStyle(color: res.eligible ? null : Colors.black45),
                  ),
                  isThreeLine: true,
                  trailing: applied
                      ? const Icon(Icons.check_circle, color: AppColors.veg)
                      : TextButton(
                          onPressed: res.eligible
                              ? () {
                                  ref.read(cartProvider.notifier).applyCoupon(c.code);
                                  Navigator.pop(context);
                                }
                              : null,
                          child: const Text('APPLY'),
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
