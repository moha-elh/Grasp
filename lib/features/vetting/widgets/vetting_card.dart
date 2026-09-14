import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/card.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/type_badge.dart';

/// Swipe-vetting card (design §04, screen 05). Both front and back are visible;
/// the type badge shows from the start. Follows the finger with a 12° max tilt.
/// Right → accept, left → discard, up → accept + edit. Buttons mirror swipes.
///
/// ponytail: instant snap-back on a short drag (no spring animation) and no
/// fly-off exit — the next card just replaces this one. Add a fling animation
/// if the motion feels abrupt on device.
///
/// NOTE: pan/swipe is unreliable with a mouse on web — verify and tune the
/// gesture on a real touch device. The mirror buttons in [VettingView] are the
/// working path everywhere in the meantime.
class VettingCard extends StatefulWidget {
  final GraspCard card;
  final VoidCallback onAccept;
  final VoidCallback onDiscard;
  final VoidCallback onEdit;

  const VettingCard({
    super.key,
    required this.card,
    required this.onAccept,
    required this.onDiscard,
    required this.onEdit,
  });

  @override
  State<VettingCard> createState() => _VettingCardState();
}

class _VettingCardState extends State<VettingCard> {
  Offset _drag = Offset.zero;
  static const _threshold = 96.0;

  void _end(double width) {
    if (_drag.dy < -_threshold && _drag.dy.abs() > _drag.dx.abs()) {
      widget.onEdit();
    } else if (_drag.dx > _threshold) {
      widget.onAccept();
    } else if (_drag.dx < -_threshold) {
      widget.onDiscard();
    }
    setState(() => _drag = Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final tilt = (_drag.dx / width) * (T.swipeMaxTiltDeg * math.pi / 180);
    // Directional hint: green-ish accept / red discard tint at the edges.
    final hint = _drag.dx > 24
        ? T.appText
        : _drag.dx < -24
            ? T.slipping
            : T.hairline;

    return GestureDetector(
      onPanUpdate: (d) => setState(() => _drag += d.delta),
      onPanEnd: (_) => _end(width),
      child: Transform.translate(
        offset: _drag,
        child: Transform.rotate(
          angle: tilt,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: T.surface,
              borderRadius: BorderRadius.circular(T.rCard),
              border: Border.all(color: hint),
              boxShadow: T.cardShadow,
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TypeBadge.type(widget.card.cardType),
                    TypeBadge.pending(),
                  ],
                ),
                const SizedBox(height: T.s18),
                Text(widget.card.front,
                    style: Typo.answer.copyWith(fontSize: 20, height: 1.35)),
                const SizedBox(height: T.s18),
                Container(height: 1, color: T.hairline),
                const SizedBox(height: T.s18),
                Text(widget.card.back, style: Typo.body),
                const SizedBox(height: T.s18),
                Text(widget.card.conceptName, style: Typo.meta),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
