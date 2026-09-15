import 'package:flutter/material.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../../design/format.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';

/// Four FSRS grades (FR-22). Only Again is filled; each chip shows the interval
/// it would schedule, computed before tapping. Below sits the quality signal
/// (FR-24) as a text link so it can't be mistaken for a fifth grade.
class GradingChips extends StatelessWidget {
  final Map<fsrs.Rating, Duration> intervals;
  final ValueChanged<fsrs.Rating> onGrade;
  final VoidCallback onFlag;

  const GradingChips({
    super.key,
    required this.intervals,
    required this.onGrade,
    required this.onFlag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(T.rControl),
        border: Border.all(color: T.hairline),
      ),
      padding: const EdgeInsets.all(T.s18),
      child: Column(
        children: [
          Row(
            children: [
              _chip(fsrs.Rating.again, 'Again', T.again, filled: true),
              const SizedBox(width: T.s8),
              _chip(fsrs.Rating.hard, 'Hard', T.softening),
              const SizedBox(width: T.s8),
              _chip(fsrs.Rating.good, 'Good', T.accent),
              const SizedBox(width: T.s8),
              _chip(fsrs.Rating.easy, 'Easy', T.appText),
            ],
          ),
          const SizedBox(height: T.s12),
          Divider(height: 1, color: T.hairline),
          const SizedBox(height: T.s12),
          // A calm, clearly separate utility, never a fifth grade (FR-25).
          OutlinedButton.icon(
            onPressed: onFlag,
            style: OutlinedButton.styleFrom(
              foregroundColor: T.inkMeta,
              side: BorderSide(color: T.hairline),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                  horizontal: T.s18, vertical: T.s8),
            ),
            icon: const Icon(Icons.outlined_flag, size: 16, color: T.inkMeta),
            label: Text('Flag as badly made',
                style: Typo.meta.copyWith(color: T.inkMeta)),
          ),
        ],
      ),
    );
  }

  // Each grade carries its own semantic color: Again is a solid danger chip,
  // the rest are soft tinted pills (amber / blue / green) so the row reads as a
  // designed set rather than one loud button beside three plain ones.
  Widget _chip(fsrs.Rating rating, String label, Color color,
      {bool filled = false}) {
    final interval = intervals[rating];
    final fg = filled ? T.surface : color;
    return Expanded(
      child: GestureDetector(
        onTap: () => onGrade(rating),
        child: Container(
          height: T.hitChip,
          decoration: BoxDecoration(
            color: filled ? color : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(T.rControl),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: Typo.label.copyWith(fontSize: 14.5, color: fg)),
              const SizedBox(height: 3),
              Text(
                interval == null ? '' : formatInterval(interval),
                style: Typo.mono(
                    size: 10,
                    color: filled ? const Color(0xD9FFFFFF) : T.inkMeta),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
