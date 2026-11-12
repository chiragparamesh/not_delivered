import 'package:flutter_test/flutter_test.dart';
import 'package:not_delivered/features/location/domain/areas.dart';
import 'package:not_delivered/features/orders/domain/order.dart';
import 'package:not_delivered/features/rewards/domain/rewards.dart';
import 'package:not_delivered/features/tracking/domain/tracking.dart';

Order order(DateTime placed, {bool delivered = true, String cat = 'restaurant', String cuisine = 'Biryani', int discount = 0}) => Order(
      id: placed.toIso8601String(), restaurantId: 'r', restaurantName: 'R', restaurantCategory: cat, cuisine: cuisine,
      lines: const [OrderLine(dishId: 'd', name: 'D', price: 100, qty: 1, isVeg: true)],
      itemTotal: 100, deliveryFee: 30, discount: discount, tip: 0, couponCode: null, placedAt: placed,
      payment: 'UPI', address: 'x', riderName: 'Raju', easterEgg: false,
      deliveredAt: delivered ? placed.add(const Duration(minutes: 3)) : null,
    );

void main() {
  final t0 = DateTime(2026, 11, 12, 13);

  group('tracking', () {
    TrackingStage at(int s, {bool egg = false}) =>
        trackingStatus(placedAt: t0, now: t0.add(Duration(seconds: s)), easterEgg: egg).stage;

    test('stages follow the timeline', () {
      expect(at(0), TrackingStage.placed);
      expect(at(8), TrackingStage.confirmed);
      expect(at(30), TrackingStage.preparing);
      expect(at(70), TrackingStage.pickedUp);
      expect(at(100), TrackingStage.onTheWay);
      expect(at(150), TrackingStage.delivered);
    });

    test('Silk Board message shows up on the way', () {
      final msgs = {
        for (var s = 75; s < 150; s++) trackingStatus(placedAt: t0, now: t0.add(Duration(seconds: s)), easterEgg: false).message,
      };
      expect(msgs.any((m) => m.contains('Silk Board')), isTrue);
    });

    test('easter egg plays just before delivery, only for lucky orders', () {
      bool egg(int s, bool lucky) => trackingStatus(placedAt: t0, now: t0.add(Duration(seconds: s)), easterEgg: lucky).showEasterEgg;
      expect(egg(146, true), isTrue);
      expect(egg(146, false), isFalse);
      expect(egg(150, true), isFalse);
      expect(egg(100, true), isFalse);
    });

    test('a delivered order stays delivered', () {
      final st = trackingStatus(placedAt: t0, now: t0.add(const Duration(seconds: 5)), easterEgg: false, deliveredAt: t0);
      expect(st.stage, TrackingStage.delivered);
    });
  });

  group('rewards', () {
    test('streak counts consecutive days ending today or yesterday', () {
      final days = [0, 1, 2, 4].map((d) => order(t0.subtract(Duration(days: d)))).toList();
      expect(orderStreak(days, t0), 3);
      expect(orderStreak(days, t0.add(const Duration(days: 1))), 3); // still alive the next day
      expect(orderStreak(days, t0.add(const Duration(days: 2))), 0);
    });

    test('badges are derived from history', () {
      expect(earnedBadges([], t0), isEmpty);
      expect(earnedBadges([order(t0)], t0), contains('first_bite'));
      final sweet = List.generate(3, (i) => order(t0.subtract(Duration(days: i * 3)), cat: 'bakery'));
      expect(earnedBadges(sweet, t0), contains('sweet_tooth'));
      expect(earnedBadges([order(DateTime(2026, 11, 12, 23, 30))], t0), contains('night_owl'));
      final cuisines = ['Biryani', 'Pizza', 'Chinese', 'Desserts', 'Healthy'];
      expect(earnedBadges([for (var i = 0; i < 5; i++) order(t0.subtract(Duration(hours: i * 30)), cuisine: cuisines[i])], t0),
          containsAll(['explorer', 'regular']));
      expect(earnedBadges([order(t0, discount: 100), order(t0, discount: 100)], t0), contains('big_saver'));
    });

    test('savings counter sums coupon discounts', () {
      expect(totalSavings([order(t0, discount: 75), order(t0, discount: 20)]), 95);
    });

    test('one spin per calendar day', () {
      expect(canSpinToday(null, t0), isTrue);
      expect(canSpinToday(t0.subtract(const Duration(hours: 1)), t0), isFalse);
      expect(canSpinToday(t0.subtract(const Duration(days: 1)), t0), isTrue);
    });
  });

  group('location', () {
    test('GPS fix maps to the nearest area; far away = null', () {
      expect(nearestArea(12.9355, 77.6250)?.name, 'Koramangala');
      expect(nearestArea(13.0040, 77.5700)?.name, 'Malleshwaram');
      expect(nearestArea(19.0760, 72.8777), isNull); // Mumbai
    });

    test('delivery minutes grow with distance', () {
      expect(deliveryMinutes(20, 0), 20);
      expect(deliveryMinutes(20, 8), 40);
      expect(deliveryMinutes(5, 0), 15);
    });
  });
}
