import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../remake/remake_controller.dart';
import '../remake/remake_pile_screen.dart';
import 'analytics.dart';
import 'concept_detail_screen.dart';
import 'widgets/dual_ring.dart';

String pct(double x) => '${(x * 100).round()}%';

/// Retention tab (screen 08, FR-27→FR-30). Dual ring (name vs explain), the
/// 90-day curve, then concept rows sorted by widest gap. Retention-focused,
/// not a productivity scoreboard.
class RetentionScreen extends ConsumerWidget {
  const RetentionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(deckStatsProvider);
    final f = ref.read(fsrsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(T.gutter, T.s32, T.gutter, T.s32),
        children: [
          Text('Retention', style: Typo.display(34)),
          const SizedBox(height: T.s24),
          Center(child: DualRing(name: stats.nameRet, explain: stats.explainRet)),
          const SizedBox(height: T.s24),
          _legend(stats),
          const SizedBox(height: T.s32),
          _curvePlaceholder(),
          const SizedBox(height: T.s18),
          _remakeEntry(context, ref),
          const SizedBox(height: T.s32),
          Text('BY CONCEPT — WIDEST GAP FIRST', style: Typo.mono(size: 10)),
          const SizedBox(height: T.s12),
          for (final c in stats.concepts) _conceptRow(context, c, f),
        ],
      ),
    );
  }

  /// Screen 10 is reachable from Retention only (FR-26), never mid-session.
  Widget _remakeEntry(BuildContext context, WidgetRef ref) {
    final count = ref.watch(remakePileProvider).length;
    return InkWell(
      borderRadius: BorderRadius.circular(T.rControl),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RemakePileScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(T.s18),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(T.rControl),
          border: Border.all(color: T.hairline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('Remake pile',
                  style: Typo.body.copyWith(color: T.ink)),
            ),
            Text(count == 0 ? 'clear' : '$count flagged',
                style: Typo.mono(size: 11, color: count == 0 ? T.inkMeta : T.remakeText)),
            const SizedBox(width: T.s8),
            const Icon(Icons.chevron_right, color: T.inkMeta, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _legend(DeckStats s) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(T.ringName, 'CAN NAME', s.nameRet),
          const SizedBox(width: T.s32),
          _legendItem(T.ringExplain, 'CAN EXPLAIN', s.explainRet),
        ],
      );

  Widget _legendItem(Color c, String label, double v) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: T.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Typo.mono(size: 9.5)),
              Text(pct(v), style: Typo.display(20)),
            ],
          ),
        ],
      );

  /// FR-30 defers long-range trends: the 90-day curve stays hidden until 14
  /// days of review history exist. Until logs are persisted, that's always now.
  Widget _curvePlaceholder() => Container(
        padding: const EdgeInsets.all(T.s18),
        decoration: BoxDecoration(
          color: T.surfaceSunk,
          borderRadius: BorderRadius.circular(T.rControl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('90-DAY TREND', style: Typo.mono(size: 10)),
            const SizedBox(height: T.s8),
            Text('Not enough history yet — the naming vs. mechanism trend '
                'appears after 14 days of reviews.', style: Typo.bodySmall),
          ],
        ),
      );

  Widget _conceptRow(BuildContext context, ConceptStats c, f) {
    return InkWell(
      borderRadius: BorderRadius.circular(T.rControl),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ConceptDetailScreen(concept: c)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: T.s12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.concept, style: Typo.body.copyWith(color: T.ink)),
                  const SizedBox(height: T.s4),
                  Text('name ${pct(c.nameRet)} · explain ${pct(c.explainRet)}',
                      style: Typo.meta),
                ],
              ),
            ),
            _gapChip(c.gap),
            const SizedBox(width: T.s8),
            const Icon(Icons.chevron_right, color: T.inkMeta, size: 20),
          ],
        ),
      ),
    );
  }

  /// A wide positive gap (names it, can't explain it) is the thing to fix.
  Widget _gapChip(double gap) {
    final pts = (gap * 100).round();
    final color = gap >= 0.30
        ? T.slipping
        : gap >= 0.15
            ? T.softening
            : T.inkMeta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(T.rBadge),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text('${pts >= 0 ? '+' : ''}$pts pt gap',
          style: Typo.mono(size: 9.5, color: color)),
    );
  }
}
