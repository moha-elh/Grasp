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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: T.inkMeta),
                    tooltip: 'How to read this',
                    onPressed: () => _showGuide(context),
                  ),
                  const SettingsButton(),
                ],
              ),
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

  /// Explains what the numbers mean and how the app works. Opened from the
  /// help icon beside Settings.
  void _showGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: T.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(T.rCard)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(T.gutter, T.s4, T.gutter, T.s32),
          children: [
            Text('HOW TO READ THIS', style: Typo.mono(size: 10)),
            const SizedBox(height: T.s8),
            Text('Reading your retention', style: Typo.display(28)),
            const SizedBox(height: T.s8),
            Text('What the numbers mean, and how the app decides what you see.',
                style: Typo.bodySmall.copyWith(color: T.inkMeta)),
            const SizedBox(height: T.s24),

            // The three rings, shown as the actual colored legend.
            _guideCard(
              icon: Icons.donut_large,
              tint: T.accent,
              title: 'The three rings',
              body: 'Each ring is one way of knowing a concept. Weeks later, '
                  'explaining beats naming, so the app pushes you past NAME '
                  'toward EXPLAIN and APPLY.',
              extra: Column(
                children: [
                  _ringLegend(T.ringName, 'NAME', 'can name it'),
                  const SizedBox(height: T.s8),
                  _ringLegend(T.ringExplain, 'EXPLAIN', 'can say why / how'),
                  const SizedBox(height: T.s8),
                  _ringLegend(T.appText, 'APPLY', 'knows when to use it'),
                ],
              ),
            ),

            // The gap, shown with real sample chips.
            _guideCard(
              icon: Icons.compare_arrows,
              tint: T.slipping,
              title: 'The pt gap',
              body: 'The gap is EXPLAIN minus NAME for one concept, in '
                  'percentage points. A wide positive gap means you can name it '
                  'but not yet explain it, so those concepts sort to the top.',
              extra: Row(
                children: [
                  const Tag('+32 pt gap', T.slipping),
                  const SizedBox(width: T.s8),
                  Flexible(
                    child: Text('fix this first', style: Typo.meta),
                  ),
                  const SizedBox(width: T.s12),
                  const Tag('+4 pt gap', T.inkMeta),
                  const SizedBox(width: T.s8),
                  Flexible(
                    child: Text('balanced', style: Typo.meta),
                  ),
                ],
              ),
            ),

            _guideCard(
              icon: Icons.bolt_outlined,
              tint: T.softening,
              title: 'How recall is scored',
              body: 'Each card tracks retrievability (how likely you recall it '
                  'right now) and maturity (how long it has held). Recall '
                  'strength blends the two, so a card known for weeks counts for '
                  'more than one just learned.',
            ),

            _guideCard(
              icon: Icons.school_outlined,
              tint: T.accent,
              title: 'The daily session',
              body: 'Due reviews are always served in full, because spacing '
                  'them out is what makes memories stick. New cards are '
                  'throttled by your "new cards per day" setting, and you can '
                  'cap the whole session in Settings.',
            ),

            _guideCard(
              icon: Icons.show_chart,
              tint: T.ringExplain,
              title: '90-day trend',
              body: 'After 14 days of history, a weekly curve shows how NAME, '
                  'EXPLAIN and APPLY move over time.',
            ),

            _guideCard(
              icon: Icons.build_outlined,
              tint: T.remakeText,
              title: 'Remake pile',
              body: 'Cards you flag as badly made land here, not back in your '
                  'deck. Flag means poorly written, not hard. Hard cards stay.',
            ),
          ],
        ),
      ),
    );
  }

  /// One explainer card: a tinted icon badge, a title, body copy, and an
  /// optional visual sample ([extra]) that shows the real thing being described.
  Widget _guideCard({
    required IconData icon,
    required Color tint,
    required String title,
    required String body,
    Widget? extra,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: T.s12),
        padding: const EdgeInsets.all(T.s18),
        decoration: BoxDecoration(
          color: T.surfaceSunk,
          borderRadius: BorderRadius.circular(T.rControl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(T.rControl),
                  ),
                  child: Icon(icon, size: 19, color: tint),
                ),
                const SizedBox(width: T.s12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: T.s4),
                    child: Text(title,
                        style: Typo.body
                            .copyWith(color: T.ink, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: T.s12),
            Text(body, style: Typo.bodySmall),
            if (extra != null) ...[
              const SizedBox(height: T.s18),
              extra,
            ],
          ],
        ),
      );

  /// A single ring's legend line: colored dot, axis name, plain-words meaning.
  Widget _ringLegend(Color c, String label, String meaning) => Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: T.s12),
          SizedBox(width: 72, child: Text(label, style: Typo.mono(size: 10))),
          Expanded(child: Text(meaning, style: Typo.meta)),
        ],
      );

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
      _streak(ref),
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

  /// Contribution-grid of study days: a column per week over the last 14 weeks,
  /// a cell per day. Reviewed days are filled, missed days are faint, days before
  /// the first review (or in the future) are blank.
  Widget _streak(WidgetRef ref) {
    final s = ref.watch(streakProvider).asData?.value;
    return Container(
      padding: const EdgeInsets.all(T.s18),
      decoration: BoxDecoration(
        color: T.surfaceSunk,
        borderRadius: BorderRadius.circular(T.rControl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('REVIEW STREAK', style: Typo.mono(size: 10)),
              if (s != null && s.streak > 0)
                Text('${s.streak} day${s.streak == 1 ? '' : 's'} in a row',
                    style: Typo.mono(size: 10, color: T.softening)),
            ],
          ),
          const SizedBox(height: T.s12),
          if (s == null)
            Text('Loading your history...', style: Typo.bodySmall)
          else if (s.first == null)
            Text('No reviews yet. Your streak starts on your first session.',
                style: Typo.bodySmall)
          else ...[
            Center(child: _grid(s)),
            const SizedBox(height: T.s12),
            Row(
              children: [
                _streakKey(T.softening, 'reviewed'),
                const SizedBox(width: T.s12),
                _streakKey(T.slipping.withValues(alpha: 0.22), 'missed'),
                const Spacer(),
                Text(
                    '${s.reviewedDays} day${s.reviewedDays == 1 ? '' : 's'} studied',
                    style: Typo.meta),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _grid(StreakData s) {
    const weeks = 14, rows = 7, total = weeks * rows;
    const cell = 13.0, gap = 4.0;
    final today = streakDay(DateTime.now());
    // The very last cell (bottom-right) is today; earlier cells walk backward
    // day by day, so the grid always ends on the current day.
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var w = 0; w < weeks; w++) ...[
          Column(
            children: [
              for (var r = 0; r < rows; r++) ...[
                _cell(
                    DateTime(today.year, today.month,
                        today.day - (total - 1 - (w * rows + r))),
                    s,
                    cell),
                if (r < rows - 1) const SizedBox(height: gap),
              ],
            ],
          ),
          if (w < weeks - 1) const SizedBox(width: gap),
        ],
      ],
    );
  }

  Widget _cell(DateTime date, StreakData s, double size) {
    Color c;
    if (date.isBefore(s.first!)) {
      c = T.hairline.withValues(alpha: 0.4); // before the first review
    } else if (s.done.contains(date)) {
      c = T.softening; // reviewed (orange)
    } else {
      c = T.slipping.withValues(alpha: 0.22); // missed
    }
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
    );
  }

  Widget _streakKey(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: T.s8),
          Text(label, style: Typo.meta),
        ],
      );

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
