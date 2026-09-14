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
              _chip(fsrs.Rating.again, 'Again', filled: true),
              const SizedBox(width: T.s8),
              _chip(fsrs.Rating.hard, 'Hard'),
              const SizedBox(width: T.s8),
              _chip(fsrs.Rating.good, 'Good'),
              const SizedBox(width: T.s8),
              _chip(fsrs.Rating.easy, 'Easy'),
            ],
          ),
          const SizedBox(height: T.s12),
          GestureDetector(
            onTap: onFlag,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Badly made card? ', style: Typo.meta),
                Text('Flag it',
                    style: Typo.meta.copyWith(
                        color: T.ink, decoration: TextDecoration.underline)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(fsrs.Rating rating, String label, {bool filled = false}) {
    final interval = intervals[rating];
    final fg = filled ? T.surface : T.ink;
    return Expanded(
      child: GestureDetector(
        onTap: () => onGrade(rating),
        child: Container(
          height: T.hitChip,
          decoration: BoxDecoration(
            color: filled ? T.again : T.surface,
            borderRadius: BorderRadius.circular(T.rControl),
            border: filled ? null : Border.all(color: const Color(0x24141A22)),
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
