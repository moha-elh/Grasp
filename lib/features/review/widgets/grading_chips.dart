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
  final VoidCallback onLike;
  final bool liked;

  const GradingChips({
    super.key,
    required this.intervals,
    required this.onGrade,
    required this.onFlag,
    required this.onLike,
    this.liked = false,
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
          // Calm, clearly separate quality utilities, never a fifth grade
          // (FR-24/FR-25). Like marks a good card; Flag sends a badly-made one
          // to the remake pile. Both are a separate axis from the grade.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: _utility(
                  onTap: onLike,
                  icon: liked ? Icons.favorite : Icons.favorite_border,
                  label: liked ? 'Good card' : 'Like',
                  color: liked ? T.accent : T.inkMeta,
                ),
              ),
              const SizedBox(width: T.s12),
              Flexible(
                child: _utility(
                  onTap: onFlag,
                  icon: Icons.outlined_flag,
                  label: 'Flag as badly made',
                  color: T.inkMeta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _utility({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
  }) =>
      OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: T.hairline),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: T.s18, vertical: T.s8),
        ),
        icon: Icon(icon, size: 16, color: color),
        label: Text(label,
            style: Typo.meta.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      );

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
