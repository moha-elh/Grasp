import 'package:flutter/widgets.dart';

import '../tokens.dart';
import '../typography.dart';

/// A small tinted tag: soft color wash behind colored mono text, pill-shaped.
/// Used for card-type, lifecycle, and source labels so they read as quiet
/// metadata, not actions (filled ink pills stay reserved for actions).
class Tag extends StatelessWidget {
  final String label;
  final Color color;
  const Tag(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(T.rPill),
      ),
      child: Text(
        label.toUpperCase(),
        style: Typo.mono(size: 9.5, color: color).copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
