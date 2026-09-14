import 'package:flutter/material.dart';

import '../tokens.dart';
import '../typography.dart';

/// Centered empty state: a soft icon tile, a display title, and one line of
/// body. Shared so empty screens read the same calm way as the session.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: T.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: T.surfaceSunk,
                borderRadius: BorderRadius.circular(T.rCard),
              ),
              child: Icon(icon, size: 32, color: T.inkMeta),
            ),
            const SizedBox(height: T.s24),
            Text(title, textAlign: TextAlign.center, style: Typo.display(26)),
            const SizedBox(height: T.s12),
            Text(message,
                textAlign: TextAlign.center,
                style: Typo.body.copyWith(color: T.inkMeta)),
          ],
        ),
      ),
    );
  }
}
