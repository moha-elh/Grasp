import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';

/// Explore tab (§ screen 11, FR-19/20). Phase 1b — adjacency + cited web cards.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: T.gutter, vertical: T.s32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Explore', style: Typo.display(40)),
            const SizedBox(height: T.s12),
            Text('Adjacent concepts and cited web-sourced cards. Phase 1b — '
                'nothing enters Retention until it’s verified.', style: Typo.body),
          ],
        ),
      ),
    );
  }
}
