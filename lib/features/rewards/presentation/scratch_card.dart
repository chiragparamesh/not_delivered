import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Scratch-to-reveal card: drag a finger to clear the gold cover.
/// Reveals itself once ~45% of the cover is scratched (or on "Scratch for me").
class ScratchCard extends StatefulWidget {
  const ScratchCard({super.key, required this.child, required this.onRevealed, this.size = 220});

  final Widget child;
  final VoidCallback onRevealed;
  final double size;

  @override
  State<ScratchCard> createState() => _ScratchCardState();
}

class _ScratchCardState extends State<ScratchCard> {
  static const grid = 12;
  final _points = <Offset>[];
  final _cells = <int>{};
  var _revealed = false;

  void _scratch(Offset p) {
    if (_revealed) return;
    final s = widget.size;
    if (p.dx < 0 || p.dy < 0 || p.dx > s || p.dy > s) return;
    setState(() {
      _points.add(p);
      final cx = (p.dx / s * grid).floor().clamp(0, grid - 1);
      final cy = (p.dy / s * grid).floor().clamp(0, grid - 1);
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          final x = cx + dx, y = cy + dy;
          if (x >= 0 && y >= 0 && x < grid && y < grid) _cells.add(y * grid + x);
        }
      }
    });
    if (_cells.length >= grid * grid * 0.45) _reveal();
  }

  void _reveal() {
    if (_revealed) return;
    setState(() => _revealed = true);
    widget.onRevealed();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: s,
          height: s,
          child: Stack(fit: StackFit.expand, children: [
            Container(color: Colors.white, alignment: Alignment.center, child: widget.child),
            AnimatedOpacity(
              opacity: _revealed ? 0 : 1,
              duration: const Duration(milliseconds: 400),
              child: IgnorePointer(
                ignoring: _revealed,
                child: GestureDetector(
                  key: const Key('scratch-area'),
                  onPanStart: (d) => _scratch(d.localPosition),
                  onPanUpdate: (d) => _scratch(d.localPosition),
                  child: CustomPaint(painter: _CoverPainter(List.of(_points)), size: Size(s, s)),
                ),
              ),
            ),
          ]),
        ),
      ),
      if (!_revealed)
        TextButton(key: const Key('scratch-for-me'), onPressed: _reveal, child: const Text('Scratch for me')),
    ]);
  }
}

class _CoverPainter extends CustomPainter {
  _CoverPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.saveLayer(rect, Paint());
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(colors: [AppColors.gold, Color(0xFFFFD54F), AppColors.gold]).createShader(rect),
    );
    final tp = TextPainter(
      text: const TextSpan(text: '🎁\nScratch me!', style: TextStyle(color: AppColors.maroon, fontSize: 22, fontWeight: FontWeight.w800)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
    final clear = Paint()..blendMode = BlendMode.clear;
    for (final p in points) {
      canvas.drawCircle(p, 22, clear);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoverPainter old) => old.points.length != points.length;
}
