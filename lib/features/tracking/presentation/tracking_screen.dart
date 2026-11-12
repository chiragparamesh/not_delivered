import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/clock.dart';
import '../../../core/services/haptics.dart';
import '../../../core/theme/app_theme.dart';
import '../../orders/data/orders_controller.dart';
import '../../rewards/data/rewards_controller.dart';
import '../../rewards/domain/rewards.dart' show scratchRewards;
import '../../rewards/presentation/scratch_card.dart';
import '../domain/tracking.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key, required this.orderId, this.celebrate = false});

  final String orderId;
  final bool celebrate;

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  late final _confetti = ConfettiController(duration: const Duration(seconds: 2));
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.celebrate) WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(ordersProvider.notifier).deliverDueOrders();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _revealScratch() {
    final rewards = scratchRewards;
    final points = rewards[ref.read(randomProvider).nextInt(rewards.length)];
    ref.read(ordersProvider.notifier).setScratchReward(widget.orderId, points);
    if (points > 0) {
      ref.read(rewardsProvider.notifier).addPoints(points);
      Haptics.celebrate();
      _confetti.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(ordersProvider).where((o) => o.id == widget.orderId).firstOrNull;
    if (order == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Order not found')));
    final now = ref.watch(clockProvider)();
    final st = trackingStatus(placedAt: order.placedAt, now: now, easterEgg: order.easterEgg, deliveredAt: order.deliveredAt);
    final delivered = st.stage == TrackingStage.delivered;
    final theme = Theme.of(context);
    final mm = (st.secondsLeft ~/ 60).toString();
    final ss = (st.secondsLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: Text(order.restaurantName),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.go(AppRoutes.orders)),
      ),
      body: Stack(children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: delivered ? AppColors.veg : AppColors.maroon,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(delivered ? 'Delivered! 🎉' : 'Arriving in $mm:$ss',
                      key: const Key('eta'),
                      style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(stageLabels[st.stage]!, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: st.progress,
                      minHeight: 8,
                      color: AppColors.gold,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ]),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Text('🛵', style: TextStyle(fontSize: 30)),
                title: Text('${order.riderName} is your rider'),
                subtitle: Text(st.message, key: const Key('funny-message')),
              ),
            ),
            if (delivered) ...[
              const SizedBox(height: 8),
              Center(child: Text('Your scratch card', style: theme.textTheme.titleMedium)),
              const SizedBox(height: 8),
              Center(
                child: order.scratchReward == null
                    ? ScratchCard(onRevealed: _revealScratch, child: const SizedBox())
                    : _RewardFace(points: order.scratchReward!),
              ),
            ] else ...[
              const SizedBox(height: 8),
              for (final s in TrackingStage.values)
                ListTile(
                  dense: true,
                  leading: Icon(
                    s.index <= st.stage.index ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: s.index <= st.stage.index ? AppColors.veg : Colors.black26,
                  ),
                  title: Text(stageLabels[s]!,
                      style: TextStyle(fontWeight: s == st.stage ? FontWeight.w700 : FontWeight.w400)),
                ),
              TextButton.icon(
                key: const Key('skip-delivery'),
                onPressed: () => ref.read(ordersProvider.notifier).deliverNow(order.id),
                icon: const Icon(Icons.fast_forward),
                label: const Text('Skip to delivery (demo)'),
              ),
            ],
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Order ${order.id}', style: theme.textTheme.titleSmall),
                  for (final l in order.lines) Text('${l.qty} × ${l.name}  ·  ₹${l.price * l.qty}'),
                  const Divider(),
                  if (order.discount > 0) Text('Saved ₹${order.discount} with ${order.couponCode}', style: const TextStyle(color: AppColors.veg)),
                  Text('Paid ₹${order.total} via ${order.payment} (demo)', style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ],
        ),
        if (st.showEasterEgg) _EasterEgg(elapsedInEgg: st.elapsedSec - (stageStartSec[TrackingStage.delivered]! - easterEggSec)),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            colors: const [AppColors.maroon, AppColors.gold, Colors.white, AppColors.veg],
          ),
        ),
      ]),
    );
  }
}

class _RewardFace extends StatelessWidget {
  const _RewardFace({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) => Container(
        width: 220,
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gold, width: 2)),
        child: Text(points > 0 ? '🎉 You won $points points!' : '🙃 Better luck next time',
            key: const Key('scratch-result'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      );
}

/// The rare "Not Delivered… just kidding!" moment.
class _EasterEgg extends StatelessWidget {
  const _EasterEgg({required this.elapsedInEgg});

  final int elapsedInEgg;

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: Container(
          key: const Key('easter-egg'),
          color: AppColors.maroon.withValues(alpha: 0.95),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('😱', style: TextStyle(fontSize: 80)),
            const Text('NOT DELIVERED…',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: AppTheme.headingFont)),
            if (elapsedInEgg >= 3)
              const Text('just kidding! 😄 It\'s at your door.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}
