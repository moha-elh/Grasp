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
    // Subtle stacked peek behind the white card = cards remaining. No gray box;
    // the card itself matches the vetting card (white, rounded, shadowed).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (remaining > 2) _peek(top: 0, inset: 26, color: const Color(0xFFDDE1E6)),
        if (remaining > 1) _peek(top: 7, inset: 14, color: const Color(0xFFE9ECEF)),
        Padding(
          padding: EdgeInsets.only(top: remaining > 1 ? 16 : 0),
          child: _mainCard(),
        ),
      ],
    );
  }

  Widget _peek({required double top, required double inset, required Color color}) =>
      Positioned(
        top: top,
        left: inset,
        right: inset,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(T.rCard),
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
            border: Border.all(color: T.hairline),
            boxShadow: T.cardShadow,
          ),
          padding: const EdgeInsets.all(22),
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
            OutlinedButton.icon(
              onPressed: onOpenSource,
              style: OutlinedButton.styleFrom(
                foregroundColor: T.ink,
                side: const BorderSide(color: T.hairline),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                    horizontal: T.s12, vertical: T.s8),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.menu_book_outlined, size: 15),
              label: Text('Source note',
                  style: Typo.label.copyWith(fontSize: 13, color: T.ink)),
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
