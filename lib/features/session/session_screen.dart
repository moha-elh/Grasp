import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';

/// Default launch surface (§ screen 02, FR-16). Placeholder until the review
/// loop feature lands. [onActiveChanged] lets the shell hide the tab bar once
/// a session is running.
class SessionScreen extends StatelessWidget {
  final ValueChanged<bool> onActiveChanged;
  const SessionScreen({super.key, required this.onActiveChanged});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: T.gutter, vertical: T.s32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GRASP', style: Typo.mono(size: 11, color: T.accent)),
            const SizedBox(height: T.s18),
            Text('Session', style: Typo.display(40)),
            const SizedBox(height: T.s12),
            Text('Opens straight into the day’s cards — due reviews, a few new, '
                'a handful to vet. Built next.', style: Typo.body),
          ],
        ),
      ),
    );
  }
}
