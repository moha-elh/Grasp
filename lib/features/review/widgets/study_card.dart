import 'package:flutter/material.dart';

import '../../../data/models/card.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/type_badge.dart';

/// Stacked study card (design §04, screens 02/03). Two peeking layers behind =
/// session remaining. Tap the question to reveal the answer.
class StudyCard extends StatelessWidget {
  final GraspCard card;
  final bool revealed;
  final double retrievability; // 0..1
  final int remaining;
  final VoidCallback onReveal;
  final VoidCallback onOpenSource;

  const StudyCard({
    super.key,
    required this.card,
    required this.revealed,
    required this.retrievability,
    required this.remaining,
    required this.onReveal,
    required this.onOpenSource,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: T.surfaceSunk,
        borderRadius: BorderRadius.circular(T.rControl),
      ),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Stack(
        children: [
          if (remaining > 2) _peek(top: 0, inset: 24, color: const Color(0xFFDDE1E6)),
          if (remaining > 1) _peek(top: 6, inset: 14, color: const Color(0xFFE9ECEF)),
          Padding(
            padding: EdgeInsets.only(top: remaining > 1 ? 14 : 0),
            child: _mainCard(),
          ),
        ],
      ),
    );
  }

  Widget _peek({required double top, required double inset, required Color color}) =>
      Positioned(
        top: top,
        left: inset,
        right: inset,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: T.hairline),
          ),
        ),
      );

  Widget _mainCard() {
    return GestureDetector(
      onTap: revealed ? null : onReveal,
      child: AnimatedSize(
        duration: T.mReveal,
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: T.surface,
            borderRadius: BorderRadius.circular(T.rCard),
            border: Border.all(color: const Color(0x14141A22)),
            boxShadow: T.cardShadow,
          ),
          padding: const EdgeInsets.all(20),
          child: revealed ? _revealed() : _question(),
        ),
      ),
    );
  }

  Widget _question() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RECONSTRUCT IT ALOUD', style: Typo.mono(size: 9.5)),
            _bead(),
          ],
        ),
        const SizedBox(height: T.s18),
        Text(card.front, style: Typo.answer.copyWith(fontSize: 20, height: 1.35)),
        const SizedBox(height: T.s18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(card.conceptName, style: Typo.meta)),
            Text('TAP TO REVEAL', style: Typo.mono(size: 10)),
          ],
        ),
      ],
    );
  }

  Widget _revealed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question shrinks to a header.
        Text(card.front, style: Typo.meta.copyWith(height: 1.4)),
        const SizedBox(height: T.s12),
        Text(card.back, style: Typo.answer),
        const SizedBox(height: T.s18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TypeBadge.type(card.cardType),
            GestureDetector(
              onTap: onOpenSource,
              child: Text('Source note',
                  style: Typo.meta.copyWith(
                      color: T.ink, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bead() {
    final c = T.health(retrievability);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text('${(retrievability * 100).round()}%', style: Typo.mono(size: 9.5)),
    ]);
  }
}
