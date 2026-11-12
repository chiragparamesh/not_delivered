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
    // A 35-minute order whose kitchen needs 15 minutes.
    TrackingStatus st(int sec, {bool egg = false}) =>
        trackingStatus(placedAt: t0, now: t0.add(Duration(seconds: sec)), easterEgg: egg, etaMins: 35, prepMins: 15);

    test('stages follow a realistic timeline that ends at the ETA', () {
      expect(st(0).stage, TrackingStage.placed);
      expect(st(60).stage, TrackingStage.confirmed);
      expect(st(5 * 60).stage, TrackingStage.preparing);
      expect(st(17 * 60).stage, TrackingStage.pickedUp);
      expect(st(25 * 60).stage, TrackingStage.onTheWay);
      expect(st(35 * 60 - 1).stage, TrackingStage.onTheWay);
      expect(st(35 * 60).stage, TrackingStage.delivered);
      expect(st(10 * 60).secondsLeft, 25 * 60);
    });

    test('stage order holds for short and long ETAs', () {
      for (final (eta, prep) in [(20, 10), (25, 22), (60, 20), (90, 15)]) {
        final s = stageStarts(etaMins: eta, prepMins: prep);
        final times = TrackingStage.values.map((x) => s[x]!).toList();
        for (var i = 1; i < times.length; i++) {
          expect(times[i], greaterThan(times[i - 1]), reason: 'eta $eta prep $prep');
        }
        expect(times.last, eta * 60);
      }
    });

    test('Silk Board message shows up on the way', () {
      final msgs = {for (var sec = 17 * 60; sec < 35 * 60; sec += 20) st(sec).message};
      expect(msgs.any((m) => m.contains('Silk Board')), isTrue);
    });

    test('easter egg plays just before delivery, only for lucky orders', () {
      expect(st(35 * 60 - 4, egg: true).showEasterEgg, isTrue);
      expect(st(35 * 60 - 4).showEasterEgg, isFalse);
      expect(st(35 * 60, egg: true).showEasterEgg, isFalse);
      expect(st(20 * 60, egg: true).showEasterEgg, isFalse);
    });

    test('a delivered order stays delivered', () {
      final s = trackingStatus(placedAt: t0, now: t0.add(const Duration(seconds: 5)), easterEgg: false, etaMins: 35, prepMins: 15, deliveredAt: t0);
      expect(s.stage, TrackingStage.delivered);
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
    test('GPS fix maps to the nearest of ~50 localities; far away = null', () {
      expect(nearestArea(12.9355, 77.6250)!.$1.name, 'Koramangala');
      expect(nearestArea(12.9940, 77.5405)!.$1.name, 'Basaveshwaranagar');
      expect(nearestArea(13.1000, 77.5960)!.$1.name, 'Yelahanka');
      expect(nearestArea(12.9940, 77.5405)!.$2, lessThan(1));
      expect(nearestArea(19.0760, 72.8777), isNull); // Mumbai
    });

    test('realistic ETA: kitchen + distance + traffic, never under 20 min', () {
      final offPeak = DateTime(2026, 11, 12, 14); // Thursday afternoon
      final peak = DateTime(2026, 11, 12, 19); // Thursday evening
      expect(estimateDelivery(baseMins: 20, km: 0.5, now: offPeak).totalMins, 20);
      final far = estimateDelivery(baseMins: 30, km: 8, now: offPeak);
      expect(far.prepMins, 20);
      expect(far.totalMins, 20 + 5 + 32);
      expect(estimateDelivery(baseMins: 30, km: 8, now: peak).totalMins, greaterThan(far.totalMins));
      expect(far.label, '57–62 mins');
    });
  });
}
