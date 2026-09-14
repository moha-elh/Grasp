import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design/tokens.dart';

/// One concentric arc: how full (0..1) and its color.
typedef RingArc = ({double value, Color color});

/// Concentric retention rings (design §05), outermost first. Stroke 11, round
/// cap, starting at 12 o'clock, each arc a distinct fixed color so they never
/// blend. The visible gap between arcs is the FR-28 name/mechanism gap.
class RetentionRing extends StatelessWidget {
  final List<RingArc> arcs; // outer -> inner
  final double size;
  const RetentionRing({super.key, required this.arcs, this.size = 168});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _RingPainter(arcs)),
      );
}

/// Deck-level ring (screen 08): name (blue) vs explain (amber).
class DualRing extends StatelessWidget {
  final double name;
  final double explain;
  final double size;
  const DualRing(
      {super.key, required this.name, required this.explain, this.size = 168});

  @override
  Widget build(BuildContext context) => RetentionRing(
        size: size,
        arcs: [
          (value: name, color: T.ringName),
          (value: explain, color: T.ringExplain),
        ],
      );
}

/// Per-concept ring (screen 09): naming, mechanism, application as three arcs.
class TripleRing extends StatelessWidget {
  final double name;
  final double explain;
  final double apply;
  final double size;
  const TripleRing({
    super.key,
    required this.name,
    required this.explain,
    required this.apply,
    this.size = 168,
  });

  @override
  Widget build(BuildContext context) => RetentionRing(
        size: size,
        arcs: [
          (value: name, color: T.ringName), // blue
          (value: explain, color: T.ringExplain), // amber
          (value: apply, color: T.appText), // green
        ],
      );
}

class _RingPainter extends CustomPainter {
  final List<RingArc> arcs;
  const _RingPainter(this.arcs);

  static const _stroke = 11.0;
  static const _gap = 6.0;
  static const _start = -math.pi / 2; // 12 o'clock

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < arcs.length; i++) {
      final r = size.width / 2 - _stroke / 2 - i * (_stroke + _gap);
      if (r <= 0) continue;
      _arc(canvas, center, r, 1, T.hairline); // track
      _arc(canvas, center, r, arcs[i].value.clamp(0, 1), arcs[i].color);
    }
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
  bool shouldRepaint(_RingPainter old) => old.arcs != arcs;
}
