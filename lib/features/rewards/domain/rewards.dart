import '../../orders/domain/order.dart';

class Achievement {
  const Achievement(this.id, this.emoji, this.title, this.description);

  final String id;
  final String emoji;
  final String title;
  final String description;
}

const allBadges = <Achievement>[
  Achievement('first_bite', '🍽️', 'First Bite', 'Get your first order delivered'),
  Achievement('regular', '🏅', 'Regular', '5 orders delivered'),
  Achievement('streak_3', '🔥', 'On a Roll', 'Order 3 days in a row'),
  Achievement('sweet_tooth', '🧁', 'Sweet Tooth', '3 dessert or bakery orders'),
  Achievement('night_owl', '🦉', 'Night Owl', 'Order between 11 pm and 4 am'),
  Achievement('explorer', '🧭', 'Explorer', 'Try 5 different cuisines'),
  Achievement('big_saver', '💰', 'Big Saver', 'Save ₹200 with coupons'),
];

DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

/// Consecutive days with at least one order, ending today or yesterday.
int orderStreak(List<Order> orders, DateTime now) {
  final days = {for (final o in orders) _day(o.placedAt)};
  var day = _day(now);
  if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
  var streak = 0;
  while (days.contains(day)) {
    streak++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return streak;
}

int totalSavings(List<Order> orders) => orders.fold(0, (s, o) => s + o.savings);

/// Badges are derived from order history (never stored), so they can't drift.
Set<String> earnedBadges(List<Order> orders, DateTime now) {
  final delivered = orders.where((o) => o.isDelivered).toList();
  return {
    if (delivered.isNotEmpty) 'first_bite',
    if (delivered.length >= 5) 'regular',
    if (orderStreak(orders, now) >= 3) 'streak_3',
    if (delivered.where((o) => o.restaurantCategory == 'dessert' || o.restaurantCategory == 'bakery').length >= 3)
      'sweet_tooth',
    if (orders.any((o) => o.placedAt.hour >= 23 || o.placedAt.hour < 4)) 'night_owl',
    if ({for (final o in delivered) o.cuisine}.length >= 5) 'explorer',
    if (totalSavings(orders) >= 200) 'big_saver',
  };
}

/// Daily spin wheel prizes (reward points). 0 = "try again tomorrow".
const spinPrizes = <int>[10, 0, 20, 5, 50, 0, 15, 100];

const spinLabels = <String>['10 pts', 'Try tmrw', '20 pts', '5 pts', '50 pts', 'Try tmrw', '15 pts', '100 pts'];

/// Scratch card rewards after delivery (points). 0 = "better luck next time".
const scratchRewards = <int>[0, 10, 15, 20, 25, 30, 50];

bool canSpinToday(DateTime? lastSpin, DateTime now) => lastSpin == null || _day(lastSpin) != _day(now);
