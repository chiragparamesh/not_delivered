/// Timer-based order tracking. No backend: the stage is a pure function of
/// how long ago the order was placed, so it survives app restarts.
enum TrackingStage { placed, confirmed, preparing, pickedUp, onTheWay, delivered }

/// Stage start times (seconds after placing) for an order with this ETA.
/// Confirmed after ~1 min, kitchen from 2 min until [prepMins] (+2), rider
/// picks up, then rides until the ETA. Monotonic for any ETA >= 20 min.
Map<TrackingStage, int> stageStarts({required int etaMins, required int prepMins}) {
  final eta = etaMins * 60;
  final pickup = ((prepMins + 2) * 60).clamp(180, eta - 300);
  return {
    TrackingStage.placed: 0,
    TrackingStage.confirmed: 60,
    TrackingStage.preparing: 120,
    TrackingStage.pickedUp: pickup,
    TrackingStage.onTheWay: pickup + 90,
    TrackingStage.delivered: eta,
  };
}

/// The rare "Not Delivered… just kidding!" moment plays for this long before delivery.
const easterEggSec = 6;

/// Chance that an order gets the easter egg.
const easterEggChance = 0.02;

const stageLabels = <TrackingStage, String>{
  TrackingStage.placed: 'Order placed',
  TrackingStage.confirmed: 'Restaurant confirmed',
  TrackingStage.preparing: 'Preparing your food',
  TrackingStage.pickedUp: 'Rider picked it up',
  TrackingStage.onTheWay: 'On the way',
  TrackingStage.delivered: 'Delivered',
};

const funnyMessages = <TrackingStage, List<String>>{
  TrackingStage.placed: ['Sending your order by pigeon… just kidding, it\'s 5G.', 'Order received. Stomach notified.'],
  TrackingStage.confirmed: ['The chef read your order and nodded seriously.', 'Restaurant said "on it" in three languages.'],
  TrackingStage.preparing: [
    'Chef is adding love. And a bit more salt.',
    'Your food is getting its photo taken for Instagram.',
    'Onions are being chopped. Someone is crying.',
  ],
  TrackingStage.pickedUp: ['Rider checked the bag twice. Respect.', 'Rider is doing the helmet-and-go.'],
  TrackingStage.onTheWay: [
    'Rider stuck at Silk Board… negotiating with destiny.',
    'Taking a shortcut through 3 cross, 4th main, 5th block.',
    'Rider overtook a BMTC bus. Bold move.',
    'Waiting at the signal. Rider is using the time to hum.',
  ],
  TrackingStage.delivered: ['Food has landed. Bon appétit!'],
};

class TrackingStatus {
  const TrackingStatus({
    required this.stage,
    required this.elapsedSec,
    required this.showEasterEgg,
    required this.message,
    required this.totalSec,
  });

  final TrackingStage stage;
  final int elapsedSec;

  /// True during the "Not Delivered… just kidding!" moment.
  final bool showEasterEgg;
  final String message;
  final int totalSec;

  int get secondsLeft => (totalSec - elapsedSec).clamp(0, 1 << 30);
  double get progress => (elapsedSec / totalSec).clamp(0.0, 1.0);
}

TrackingStatus trackingStatus({
  required DateTime placedAt,
  required DateTime now,
  required bool easterEgg,
  required int etaMins,
  required int prepMins,
  DateTime? deliveredAt,
}) {
  final starts = stageStarts(etaMins: etaMins, prepMins: prepMins);
  final elapsed = now.difference(placedAt).inSeconds;
  var stage = TrackingStage.placed;
  for (final s in TrackingStage.values) {
    if (elapsed >= starts[s]!) stage = s;
  }
  if (deliveredAt != null) stage = TrackingStage.delivered;
  final deliverAt = starts[TrackingStage.delivered]!;
  final egg = easterEgg && deliveredAt == null && elapsed >= deliverAt - easterEggSec && elapsed < deliverAt;
  final msgs = funnyMessages[stage]!;
  final message = egg ? 'Not Delivered… 😱' : msgs[(elapsed ~/ 20).abs() % msgs.length];
  return TrackingStatus(stage: stage, elapsedSec: elapsed, showEasterEgg: egg, message: message, totalSec: deliverAt);
}
