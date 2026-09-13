import 'package:flutter/widgets.dart';

import '../../data/models/card.dart';
import '../tokens.dart';
import '../typography.dart';

/// Outline-only badge for card type (FR-8) and lifecycle states. Filled pills
/// are reserved for actions, so these are always border + colored text.
/// Design system §04 Type badges.
class TypeBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color borderColor;

  const TypeBadge._(this.label, this.textColor, this.borderColor);

  factory TypeBadge.type(CardType type) {
    switch (type) {
      case CardType.anchor:
        return const TypeBadge._('ANCHOR', T.inkBody, T.hairline);
      case CardType.mechanism:
        return const TypeBadge._('MECHANISM', T.mechText, T.mechBorder);
      case CardType.application:
        return const TypeBadge._('APPLICATION', T.appText, T.appBorder);
    }
  }

  factory TypeBadge.remake() =>
      const TypeBadge._('REMAKE', T.remakeText, T.remakeBorder);
  factory TypeBadge.pending() =>
      const TypeBadge._('PENDING', T.inkMeta, Color(0x2E141A22));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(T.rBadge),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: Typo.mono(size: 9.5, color: textColor).copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
