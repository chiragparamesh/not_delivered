import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/clock.dart';
import '../../../core/services/store.dart';
import '../../notifications/data/notifications_controller.dart';
import '../domain/rewards.dart';

class RewardsState {
  const RewardsState({this.points = 0, this.lastSpin});

  final int points;
  final DateTime? lastSpin;
}

/// Reward points from scratch cards and the daily spin wheel.
class RewardsController extends Notifier<RewardsState> {
  static const _key = 'rewards';

  @override
  RewardsState build() {
    final j = ref.read(storeProvider).read(_key);
    if (j is! Map) return const RewardsState();
    return RewardsState(
      points: j['points'] as int? ?? 0,
      lastSpin: j['lastSpin'] == null ? null : DateTime.parse(j['lastSpin'] as String),
    );
  }

  void _save(RewardsState s) {
    state = s;
    ref.read(storeProvider).write(_key, {'points': s.points, 'lastSpin': s.lastSpin?.toIso8601String()});
  }

  void addPoints(int p) => _save(RewardsState(points: state.points + p, lastSpin: state.lastSpin));

  bool get canSpin => canSpinToday(state.lastSpin, ref.read(clockProvider)());

  /// Picks the winning segment index and records today's spin (once per day).
  int? spin() {
    if (!canSpin) return null;
    final i = ref.read(randomProvider).nextInt(spinPrizes.length);
    final prize = spinPrizes[i];
    _save(RewardsState(points: state.points + prize, lastSpin: ref.read(clockProvider)()));
    ref.read(notificationsProvider.notifier).push(
          '🎡',
          prize > 0 ? 'Spin win: $prize points!' : 'No luck today',
          prize > 0 ? 'Added to your rewards.' : 'Come back tomorrow for another spin.',
        );
    return i;
  }

  void reset() => _save(const RewardsState());
}

final rewardsProvider = NotifierProvider<RewardsController, RewardsState>(RewardsController.new);
