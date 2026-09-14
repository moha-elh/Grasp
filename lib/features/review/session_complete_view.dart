import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/typography.dart';

/// Screen 07 · Session complete (FR-15, FR-30). A stopping point, not a reward
/// screen: what happened, when the next cards come due, and one line to stop.
/// No streak, no confetti, no "keep going". The tab bar is already back, so
/// there's no explicit "back" action.
class SessionCompleteView extends StatelessWidget {
  final int reviewed;
  final int flagged;
  final String nextDue; // e.g. "Next cards due tomorrow"

  const SessionCompleteView({
    super.key,
    required this.reviewed,
    required this.flagged,
    required this.nextDue,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: T.gutter, vertical: T.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: T.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: T.surface, size: 44),
            ),
            const SizedBox(height: T.s24),
            Text('Done for today',
                textAlign: TextAlign.center, style: Typo.display(34)),
            const SizedBox(height: T.s32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _stat('$reviewed', 'reviewed', T.accent),
                if (flagged > 0) ...[
                  const SizedBox(width: T.s32),
                  _stat('$flagged', 'to remake', T.remakeText),
                ],
              ],
            ),
            const SizedBox(height: T.s24),
            Text(nextDue, textAlign: TextAlign.center, style: Typo.body),
            const SizedBox(height: T.s12),
            Text('Close the app. Retention is about coming back tomorrow, not '
                'staying now.',
                textAlign: TextAlign.center,
                style: Typo.bodySmall.copyWith(color: T.inkMeta)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, Color color) => Column(
        children: [
          Text(value, style: Typo.display(40).copyWith(color: color)),
          const SizedBox(height: T.s4),
          Text(label.toUpperCase(), style: Typo.mono(size: 10)),
        ],
      );
}
