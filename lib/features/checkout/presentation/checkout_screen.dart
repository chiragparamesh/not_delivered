import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/haptics.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_constants.dart';
import '../../cart/data/cart_controller.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../home/presentation/restaurant_card.dart';
import '../../orders/data/orders_controller.dart';
import '../../settings/data/settings_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  var _payment = 'UPI';
  var _paying = false;

  static const methods = [
    ('UPI', Icons.qr_code_2, 'Pay with any UPI app (demo)'),
    ('Card', Icons.credit_card, 'Credit / debit card (demo)'),
    ('Cash', Icons.payments_outlined, 'Cash on delivery (good luck with that)'),
  ];

  Future<void> _place() async {
    final cart = ref.read(cartProvider);
    final bill = ref.read(cartBillProvider);
    final catalog = ref.read(catalogProvider).value;
    if (bill == null || catalog == null) return;
    setState(() => _paying = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200)); // "processing" the demo payment
    if (!mounted) return;
    final s = ref.read(settingsProvider);
    final restaurant = catalog.restaurant(cart.restaurantId!)!;
    final eta = ref.read(etaProvider(restaurant));
    final order = ref.read(ordersProvider.notifier).place(
          restaurant: restaurant,
          etaMins: eta.totalMins,
          prepMins: eta.prepMins,
          items: [
            for (final e in cart.lines.entries)
              if (catalog.dish(e.key) case final d?) (d, e.value),
          ],
          bill: bill,
          payment: _payment,
          address: [s.address, s.area ?? ''].where((x) => x.isNotEmpty).join(', '),
        );
    ref.read(cartProvider.notifier).clear();
    Haptics.celebrate();
    context.go(AppRoutes.track(order.id, celebrate: true));
  }

  @override
  Widget build(BuildContext context) {
    final bill = ref.watch(cartBillProvider);
    final s = ref.watch(settingsProvider);
    if (bill == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Cart is empty')));
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            key: const Key('demo-banner'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppColors.maroon),
              SizedBox(width: 8),
              Expanded(child: Text(AppConstants.demoPaymentNote, style: TextStyle(fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: AppColors.maroon),
              title: Text('Deliver to ${s.area ?? '-'}'),
              subtitle: Text(s.address.isEmpty ? 'Add flat / street on the location screen' : s.address),
              trailing: TextButton(onPressed: () => context.push(AppRoutes.location), child: const Text('Change')),
            ),
          ),
          const SizedBox(height: 8),
          Text('Payment method', style: Theme.of(context).textTheme.titleMedium),
          RadioGroup<String>(
            groupValue: _payment,
            onChanged: (v) => setState(() => _payment = v ?? _payment),
            child: Column(children: [
              for (final (id, icon, label) in methods)
                Card(
                  child: RadioListTile<String>(
                    value: id,
                    secondary: Icon(icon),
                    title: Text(id),
                    subtitle: Text(label),
                  ),
                ),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            key: const Key('place-order'),
            onPressed: _paying ? null : _place,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            child: _paying
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('Processing demo payment…'),
                  ])
                : Text('Place order · ₹${bill.total} (demo)'),
          ),
        ),
      ),
    );
  }
}
