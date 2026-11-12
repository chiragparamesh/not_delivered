import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_delivered/app.dart';
import 'package:not_delivered/core/services/clock.dart';
import 'package:not_delivered/core/services/store.dart';
import 'package:not_delivered/features/location/data/location_service.dart';

class _NoGps implements LocationService {
  @override
  Future<(double, double)?> currentPosition() async => null;
}

class _Clock {
  DateTime now = DateTime(2026, 11, 12, 13, 0);
}

Widget _app(KeyValueStore store, _Clock clock) => ProviderScope(
      overrides: [
        storeProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => clock.now),
        randomProvider.overrideWithValue(math.Random(1)),
        locationServiceProvider.overrideWithValue(_NoGps()),
      ],
      child: const App(),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 100));
    if (i >= 2 && find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
}

Future<void> _tapKey(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(find.byKey(key), 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(find.byKey(key));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(rootBundle.clear);

  testWidgets('first run: splash -> onboarding -> location -> home -> order -> track -> delivered', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final store = MemoryStore();
    final clock = _Clock();

    await tester.pumpWidget(_app(store, clock));
    expect(find.text('Not Delivered'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500)); // splash timer
    await tester.pump(const Duration(milliseconds: 500));

    // Onboarding: 3 slides.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
    }

    // Location: GPS unavailable -> manual fallback.
    await tester.tap(find.byKey(const Key('use-gps')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Pick your area'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('area-Jayanagar')));
    await _settle(tester);

    // Home with cuisine chips and filters.
    expect(find.textContaining("Hungry? We'll fix that."), findsOneWidget);
    expect(find.byKey(const Key('spin-banner')), findsOneWidget);
    await tester.tap(find.byKey(const Key('filter-veg')));
    await tester.pump();
    expect(find.textContaining('10 restaurants'), findsOneWidget);
    await tester.tap(find.byKey(const Key('filter-veg')));
    await tester.pump();

    // Open a restaurant and add two dishes (₹90 + ₹110 = ₹200 → free delivery).
    await tester.scrollUntilVisible(find.byKey(const ValueKey('restaurant-namma_dosa_mane')), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('restaurant-namma_dosa_mane')));
    await _settle(tester);
    await _tapKey(tester, const ValueKey('add-namma_dosa_mane__masala_dosa'));
    await _tapKey(tester, const ValueKey('add-namma_dosa_mane__benne_dosa'));
    await tester.tap(find.byKey(const Key('view-cart')));
    await _settle(tester);

    // Cart: apply WELCOME50 (first order) and a tip.
    expect(find.text('FREE'), findsOneWidget);
    await tester.tap(find.byKey(const Key('coupons')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('coupon-WELCOME50')), matching: find.text('APPLY')));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME50 applied'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tip-20')));
    await tester.pump();

    // Checkout: demo payment banner.
    await tester.tap(find.byKey(const Key('to-checkout')));
    await _settle(tester);
    expect(find.byKey(const Key('demo-banner')), findsOneWidget);
    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 500));

    // Tracking.
    expect(find.textContaining('Arriving in'), findsOneWidget);
    clock.now = clock.now.add(const Duration(seconds: 90));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('On the way'), findsWidgets);
    await tester.tap(find.byKey(const Key('skip-delivery')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Delivered! 🎉'), findsOneWidget);

    // Scratch card.
    await tester.scrollUntilVisible(find.byKey(const Key('scratch-for-me')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('scratch-for-me')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('scratch-result')), findsOneWidget);
    await tester.pump(const Duration(seconds: 3)); // let confetti finish
  });

  testWidgets('returning user skips onboarding; profile shows savings and badges', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final store = MemoryStore({
      'settings': {'onboarded': true, 'area': 'Koramangala', 'address': '', 'name': 'Chirag'},
      'orders': [
        {
          'id': 'o1', 'restaurantId': 'namma_dosa_mane', 'restaurantName': 'Namma Dosa Mane', 'restaurantCategory': 'restaurant',
          'cuisine': 'South Indian', 'lines': [{'dishId': 'namma_dosa_mane__masala_dosa', 'name': 'Masala Dosa', 'price': 90, 'qty': 2, 'isVeg': true}],
          'itemTotal': 180, 'deliveryFee': 30, 'discount': 90, 'tip': 0, 'couponCode': 'WELCOME50',
          'placedAt': '2026-11-12T12:00:00.000', 'payment': 'UPI', 'address': 'Koramangala', 'riderName': 'Raju', 'easterEgg': false,
          'deliveredAt': '2026-11-12T12:02:30.000', 'scratchReward': 20,
        },
      ],
    });
    await tester.pumpWidget(_app(store, _Clock()));
    await tester.pump(const Duration(milliseconds: 1500));
    await _settle(tester);
    expect(find.textContaining('Hi Chirag'), findsOneWidget);

    await tester.tap(find.text('Orders'));
    await _settle(tester);
    expect(find.text('Namma Dosa Mane'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reorder-o1')));
    await _settle(tester);
    expect(find.textContaining('Proceed to checkout'), findsOneWidget);
    await tester.pageBack();
    await _settle(tester);

    await tester.tap(find.text('Profile'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('₹90'), findsOneWidget); // savings counter
    expect(find.text('First Bite'), findsOneWidget);
  });
}
