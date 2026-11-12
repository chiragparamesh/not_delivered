import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/clock.dart';
import '../../../core/services/haptics.dart';
import '../../../core/theme/app_theme.dart';
import '../data/rewards_controller.dart';
import '../domain/rewards.dart';

class SpinWheelScreen extends ConsumerStatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  ConsumerState<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends ConsumerState<SpinWheelScreen> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  late final _confetti = ConfettiController(duration: const Duration(seconds: 2));
  var _from = 0.0;
  var _to = 0.0;
  int? _result;

  @override
  void dispose() {
    _anim.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    final i = ref.read(rewardsProvider.notifier).spin();
    if (i == null) return;
    final seg = 2 * math.pi / spinPrizes.length;
    // Land segment i under the pointer at the top (12 o'clock).
    _from = _to % (2 * math.pi);
    _to = 6 * 2 * math.pi + (2 * math.pi - (i + 0.5) * seg);
    await _anim.forward(from: 0);
    if (!mounted) return;
    setState(() => _result = spinPrizes[i]);
    Haptics.celebrate();
    if (spinPrizes[i] > 0) _confetti.play();
  }

  @override
  Widget build(BuildContext context) {
    final rewards = ref.watch(rewardsProvider);
    final can = canSpinToday(rewards.lastSpin, ref.watch(clockProvider)());
    final spinning = _anim.isAnimating;
    return Scaffold(
      appBar: AppBar(title: const Text('Daily spin')),
      body: Stack(children: [
        ListView(padding: const EdgeInsets.all(24), children: [
          Text('${rewards.points} reward points', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 300,
              height: 320,
              child: Stack(alignment: Alignment.topCenter, children: [
                Positioned(
                  top: 20,
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (_, _) => Transform.rotate(
                      angle: _from + (_to - _from) * Curves.easeOutCubic.transform(_anim.value),
                      child: CustomPaint(size: const Size(290, 290), painter: _WheelPainter()),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 56, color: AppColors.ink),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          if (_result != null)
            Text(_result! > 0 ? '🎉 You won $_result points!' : '🙃 Not today. Try again tomorrow!',
                key: const Key('spin-result'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('spin-button'),
            onPressed: can && !spinning ? _spin : null,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            child: Text(can ? 'SPIN' : 'Come back tomorrow'),
          ),
        ]),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(confettiController: _confetti, blastDirectionality: BlastDirectionality.explosive),
        ),
      ]),
    );
  }
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final n = spinPrizes.length;
    final seg = 2 * math.pi / n;
    for (var i = 0; i < n; i++) {
      // Segment i spans [-pi/2 + i*seg, -pi/2 + (i+1)*seg] (starting at 12 o'clock).
      final start = -math.pi / 2 + i * seg;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, seg, true,
          Paint()..color = i.isEven ? AppColors.maroon : AppColors.gold);
      final tp = TextPainter(
        text: TextSpan(
          text: spinLabels[i],
          style: TextStyle(color: i.isEven ? Colors.white : AppColors.maroon, fontWeight: FontWeight.w800, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final mid = start + seg / 2;
      canvas.save();
      canvas.translate(c.dx + math.cos(mid) * r * 0.62, c.dy + math.sin(mid) * r * 0.62);
      canvas.rotate(mid + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = Colors.white);
    canvas.drawCircle(c, 22, Paint()..color = Colors.white);
    canvas.drawCircle(c, 14, Paint()..color = AppColors.maroon);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
