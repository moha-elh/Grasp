import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';

/// Screen 07 · Session complete (FR-15, FR-30). A stopping point, not a reward
/// screen: what happened, when the next cards come due, and one line to stop.
/// No streak, no confetti, no "keep going".
class SessionCompleteView extends StatelessWidget {
  final int reviewed;
  final int flagged;
  final String nextDue; // e.g. "Next cards due tomorrow"
  final VoidCallback onDone;

  const SessionCompleteView({
    super.key,
    required this.reviewed,
    required this.flagged,
    required this.nextDue,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: T.gutter, vertical: T.s32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Done for today', style: Typo.display(34)),
            const SizedBox(height: T.s18),
            _line('$reviewed reviewed'),
            if (flagged > 0) _line('$flagged sent to the remake pile'),
            _line(nextDue),
            const SizedBox(height: T.s24),
            Text('That’s the session. Close the app — retention is about coming '
                'back tomorrow, not staying now.', style: Typo.body),
            const SizedBox(height: T.s32),
            GestureDetector(
              onTap: onDone,
              child: Text('Back to tabs',
                  style: Typo.label.copyWith(
                      color: T.accent, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String text) => Padding(
        padding: const EdgeInsets.only(bottom: T.s8),
        child: Row(children: [
          Text('— ', style: Typo.body),
          Flexible(child: Text(text, style: Typo.body)),
        ]),
      );
}
