import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design/tokens.dart';

/// Dual ring (design §05). Outer arc = anchor-card retrievability, inner arc =
/// mechanism retrievability — each a distinct fixed color (name = blue,
/// explain = violet) so the two arcs never blend. The visible gap between arcs
/// IS the FR-28 name/mechanism gap. Stroke 11, round cap, starts at 12 o'clock.
class DualRing extends StatelessWidget {
  final double name; // outer, 0..1
  final double explain; // inner, 0..1
  final double size;

  const DualRing({
    super.key,
    required this.name,
    required this.explain,
    this.size = 168,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(name: name, explain: explain),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double name;
  final double explain;
  const _RingPainter({required this.name, required this.explain});

  static const _stroke = 11.0;
  static const _start = -math.pi / 2; // 12 o'clock

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerR = size.width / 2 - _stroke / 2;
    final innerR = outerR - _stroke - 6;

    _arc(canvas, center, outerR, 1, T.hairline); // track
    _arc(canvas, center, outerR, name.clamp(0, 1), T.ringName);

    _arc(canvas, center, innerR, 1, T.hairline); // track
    _arc(canvas, center, innerR, explain.clamp(0, 1), T.ringExplain);
  }

  void _arc(Canvas c, Offset center, double r, double frac, Color color) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    c.drawArc(Rect.fromCircle(center: center, radius: r), _start,
        frac * 2 * math.pi, false, p);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.name != name || old.explain != explain;
}
