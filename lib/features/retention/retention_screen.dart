import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/tag.dart';
import '../remake/remake_controller.dart';
import '../remake/remake_pile_screen.dart';
import '../settings/settings_button.dart';
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
    final statsAsync = ref.watch(deckStatsProvider);
    final f = ref.read(fsrsProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(T.gutter, T.s32, T.gutter, T.s32),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Retention', style: Typo.display(34)),
              const SettingsButton(),
            ],
          ),
          const SizedBox(height: T.s24),
          ...statsAsync.when(
            loading: () => [
              const SizedBox(height: T.s32),
              const Center(child: CircularProgressIndicator()),
            ],
            error: (e, _) => [
              const SizedBox(height: T.s32),
              Text('Could not load your deck.\n$e',
                  textAlign: TextAlign.center,
                  style: Typo.bodySmall.copyWith(color: T.slipping)),
            ],
            data: (stats) => _deck(context, ref, stats, f),
          ),
        ],
      ),
    );
  }

  List<Widget> _deck(
      BuildContext context, WidgetRef ref, DeckStats stats, f) {
    return [
      Center(
        child: TripleRing(
          name: stats.nameRet,
          explain: stats.explainRet,
          apply: stats.applyRet,
        ),
      ),
      const SizedBox(height: T.s24),
      _legend(stats),
      const SizedBox(height: T.s32),
      _trend(ref),
      const SizedBox(height: T.s18),
      _remakeEntry(context, ref),
      const SizedBox(height: T.s32),
      if (stats.concepts.isNotEmpty) ...[
        Text('BY CONCEPT · WIDEST GAP FIRST', style: Typo.mono(size: 10)),
        const SizedBox(height: T.s12),
        for (final c in stats.concepts) _conceptRow(context, c, f),
      ],
    ];
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(T.ringName, 'NAME', s.nameRet),
          _legendItem(T.ringExplain, 'EXPLAIN', s.explainRet),
          _legendItem(T.appText, 'APPLY', s.applyRet),
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
  /// days of review history exist, then draws a weekly quality sparkline split
  /// by the name / explain / apply axis.
  Widget _trend(WidgetRef ref) {
    final trend = ref.watch(reviewTrendProvider).asData?.value;
    final ready = trend != null && !trend.isEmpty && trend.spanDays >= 14;
    return Container(
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
          if (!ready)
            Text('Not enough history yet. The naming vs. mechanism trend '
                'appears after 14 days of reviews.', style: Typo.bodySmall)
          else
            SizedBox(
              height: 64,
              width: double.infinity,
              child: CustomPaint(painter: _TrendPainter(trend)),
            ),
        ],
      ),
    );
  }

  Widget _conceptRow(BuildContext context, ConceptStats c, f) {
    return Container(
      margin: const EdgeInsets.only(bottom: T.s12),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(T.rControl),
        border: Border.all(color: T.hairline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(T.rControl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          hoverColor: T.accent.withValues(alpha: 0.06),
          splashColor: T.accent.withValues(alpha: 0.10),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ConceptDetailScreen(concept: c)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(T.s18),
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
    return Tag('${pts >= 0 ? '+' : ''}$pts pt gap', color);
  }
}

/// Three weekly quality polylines (name / explain / apply), y = 0..1 quality.
/// Null weeks are skipped, connecting across gaps so a sparse series still reads.
class _TrendPainter extends CustomPainter {
  final TrendSeries t;
  const _TrendPainter(this.t);

  static const _inset = 3.0; // keep round caps off the top/bottom edge

  @override
  void paint(Canvas canvas, Size size) {
    _line(canvas, size, t.name, T.ringName);
    _line(canvas, size, t.explain, T.ringExplain);
    _line(canvas, size, t.apply, T.appText);
  }

  void _line(Canvas c, Size size, List<double?> pts, Color color) {
    if (pts.length < 2) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final usable = size.height - _inset * 2;
    final dx = size.width / (pts.length - 1);
    Path? path;
    for (var i = 0; i < pts.length; i++) {
      final v = pts[i];
      if (v == null) continue;
      final x = i * dx;
      final y = _inset + (1 - v.clamp(0, 1)) * usable;
      if (path == null) {
        path = Path()..moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    if (path != null) c.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.t != t;
}
