import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/card.dart';
import '../../data/services/fsrs_service.dart';
import '../../design/tokens.dart';
import '../../design/typography.dart';
import '../../design/widgets/primary_button.dart';
import '../../design/widgets/type_badge.dart';
import '../review/widgets/source_note_sheet.dart';
import 'analytics.dart';
import 'retention_screen.dart' show pct;
import 'widgets/dual_ring.dart';

/// Concept detail (screen 09, FR-28/FR-29). Per-concept dual ring, a breakdown
/// by card type, the weakest cards, and "seen N× / X%" as a detail line - never
/// a headline. Primary action: open the note.
class ConceptDetailScreen extends ConsumerWidget {
  final ConceptStats concept;
  const ConceptDetailScreen({super.key, required this.concept});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.read(fsrsProvider);
    final mean = concept.meanRet(f);
    final weakest = [...concept.cards]
      ..sort((a, b) => f.retrievability(a).compareTo(f.retrievability(b)));

    return Scaffold(
      backgroundColor: T.ground,
      appBar: AppBar(
        backgroundColor: T.ground,
        surfaceTintColor: Colors.transparent,
        title: Text(concept.concept, style: Typo.display(20)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(T.gutter, T.s18, T.gutter, T.s32),
          children: [
            Center(
              child: TripleRing(
                name: concept.nameRet,
                explain: concept.explainRet,
                apply: concept.retOfType(CardType.application, f),
                size: 156,
              ),
            ),
            const SizedBox(height: T.s18),
            _ringLegend(),
            const SizedBox(height: T.s24),
            _typeBreakdown(f),
            const SizedBox(height: T.s24),
            _seenLine(mean),
            const SizedBox(height: T.s24),
            Text('WEAKEST CARDS', style: Typo.mono(size: 10)),
            const SizedBox(height: T.s12),
            for (final c in weakest.take(3)) _weakCard(c, f),
            const SizedBox(height: T.s32),
            if (concept.cards.isNotEmpty)
              PrimaryButton('Open note', onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: T.surface,
                  showDragHandle: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(T.rCard)),
                  ),
                  builder: (_) => SourceNoteSheet(concept.cards.first),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _ringLegend() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(T.ringName, 'Naming'),
          const SizedBox(width: T.s18),
          _legendDot(T.ringExplain, 'Mechanism'),
          const SizedBox(width: T.s18),
          _legendDot(T.appText, 'Application'),
        ],
      );

  Widget _legendDot(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: Typo.meta),
        ],
      );

  // Distinct color per card type so the three bars never blend. Ties Naming to
  // the outer ring (blue) and Mechanism to the inner ring (amber, oklch .62 .14
  // 60); Application takes the app-type green.
  Color _typeColor(CardType t) => switch (t) {
        CardType.anchor => T.ringName,
        CardType.mechanism => T.ringExplain,
        CardType.application => T.appText,
      };

  Widget _typeBreakdown(FsrsService f) {
    Widget row(CardType t, String label) {
      final has = concept.cards.any((c) => c.cardType == t);
      final v = concept.retOfType(t, f);
      return Padding(
        padding: const EdgeInsets.only(bottom: T.s12),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(label, style: Typo.meta)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(T.rPill),
                child: LinearProgressIndicator(
                  value: has ? v : 0,
                  minHeight: 8,
                  backgroundColor: T.hairline,
                  valueColor: AlwaysStoppedAnimation(_typeColor(t)),
                ),
              ),
            ),
            const SizedBox(width: T.s12),
            Text(has ? pct(v) : 'n/a', style: Typo.mono(size: 11)),
          ],
        ),
      );
    }

    return Column(children: [
      row(CardType.anchor, 'Naming'),
      row(CardType.mechanism, 'Mechanism'),
      row(CardType.application, 'Application'),
    ]);
  }

  /// FR-29: times-seen is a detail, paired with retrievability - and a reading.
  Widget _seenLine(double mean) {
    final tooFat = concept.timesSeen >= 8 && mean < 0.6;
    return Container(
      padding: const EdgeInsets.all(T.s18),
      decoration: BoxDecoration(
        color: T.surfaceSunk,
        borderRadius: BorderRadius.circular(T.rControl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('seen ${concept.timesSeen}× · retrievability ${pct(mean)}',
              style: Typo.body.copyWith(color: T.ink)),
          if (tooFat) ...[
            const SizedBox(height: T.s8),
            Text('Seen a lot but recall is low. The cards may be too fat. '
                'Split them into smaller, atomic cards.', style: Typo.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _weakCard(GraspCard c, FsrsService f) {
    final r = f.retrievability(c);
    return Container(
      margin: const EdgeInsets.only(bottom: T.s12),
      padding: const EdgeInsets.all(T.s18),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(T.rControl),
        border: Border.all(color: T.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TypeBadge.type(c.cardType),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration:
                      BoxDecoration(color: T.health(r), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(pct(r), style: Typo.mono(size: 9.5)),
              ]),
            ],
          ),
          const SizedBox(height: T.s12),
          Text(c.front, style: Typo.body.copyWith(color: T.ink)),
        ],
      ),
    );
  }
}
