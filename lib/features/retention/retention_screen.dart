import 'package:flutter/material.dart';

import '../../data/models/card.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/type_badge.dart';

/// Retention tab (§ screen 08, FR-27→FR-30). Placeholder until analytics lands.
class RetentionScreen extends StatelessWidget {
  const RetentionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: T.gutter, vertical: T.s32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Retention', style: Typo.display(40)),
            const SizedBox(height: T.s12),
            Text('What’s solid, what’s slipping, and where the name/mechanism '
                'gap is. Built after the review loop.', style: Typo.body),
            const SizedBox(height: T.s24),
            // Design-system check: type badges render with correct palette.
            Wrap(spacing: T.s8, runSpacing: T.s8, children: [
              TypeBadge.type(CardType.anchor),
              TypeBadge.type(CardType.mechanism),
              TypeBadge.type(CardType.application),
              TypeBadge.remake(),
              TypeBadge.pending(),
            ]),
          ],
        ),
      ),
    );
  }
}
