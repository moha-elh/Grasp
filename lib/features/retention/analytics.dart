import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/card.dart';
import '../../data/models/review_log.dart';
import '../../data/services/fsrs_service.dart';

/// Per-concept retention rollup (FR-27, FR-28). A "concept" is one source note.
class ConceptStats {
  final String concept; // note name
  final String? notePath;
  final double nameRet; // mean retrievability of anchor cards (0..1)
  final double explainRet; // mean retrievability of mechanism cards
  final int timesSeen; // sum of reps across the concept (FR-29, a detail)
  final List<GraspCard> cards;

  const ConceptStats({
    required this.concept,
    required this.notePath,
    required this.nameRet,
    required this.explainRet,
    required this.timesSeen,
    required this.cards,
  });

  /// The FR-28 name/mechanism gap: knows the name, not the mechanism.
  double get gap => nameRet - explainRet;

  double meanRet(FsrsService f) =>
      cards.isEmpty ? 0 : _mean(cards.map((c) => f.retrievability(c)));

  double retOfType(CardType t, FsrsService f) {
    final subset = cards.where((c) => c.cardType == t);
    return subset.isEmpty ? 0 : _mean(subset.map((c) => f.retrievability(c)));
  }
}

/// Deck-level strength by card type (the ring, design §05).
class DeckStats {
  final double nameRet; // outer ring - all anchor cards
  final double explainRet; // middle ring - all mechanism cards
  final double applyRet; // inner ring - all application cards
  final List<ConceptStats> concepts; // sorted by widest gap first
  const DeckStats(this.nameRet, this.explainRet, this.applyRet, this.concepts);
}

double _mean(Iterable<double> xs) {
  var sum = 0.0, n = 0;
  for (final x in xs) {
    sum += x;
    n++;
  }
  return n == 0 ? 0 : sum / n;
}

double _typeMean(List<GraspCard> cards, CardType t, FsrsService f) =>
    _mean(cards.where((c) => c.cardType == t).map((c) => f.retrievability(c)));

DeckStats computeDeckStats(List<GraspCard> cards, FsrsService f) {
  final byConcept = <String, List<GraspCard>>{};
  for (final c in cards) {
    byConcept.putIfAbsent(c.conceptName, () => []).add(c);
  }

  final concepts = byConcept.entries.map((e) {
    return ConceptStats(
      concept: e.key,
      notePath: e.value.first.sourcePath,
      nameRet: _typeMean(e.value, CardType.anchor, f),
      explainRet: _typeMean(e.value, CardType.mechanism, f),
      timesSeen: e.value.fold(0, (s, c) => s + c.reps),
      cards: e.value,
    );
  }).toList()
    ..sort((a, b) => b.gap.compareTo(a.gap)); // widest gap first

  return DeckStats(
    _typeMean(cards, CardType.anchor, f),
    _typeMean(cards, CardType.mechanism, f),
    _typeMean(cards, CardType.application, f),
    concepts,
  );
}

/// Weekly review-quality trend split by the ring axis (anchor -> name,
/// mechanism -> explain, application -> apply). Each list is one point per
/// week, oldest first; a null week means no reviews of that type that week.
class TrendSeries {
  final List<double?> name;
  final List<double?> explain;
  final List<double?> apply;
  final int spanDays; // history span, so the screen can gate on >= 14 days
  const TrendSeries(this.name, this.explain, this.apply, this.spanDays);

  bool get isEmpty => name.isEmpty;
}

/// Rating (1..4) as a 0..1 quality proxy: again=0, easy=1.
double _quality(int rating) => ((rating - 1) / 3).clamp(0, 1).toDouble();

/// Pure: bucket review logs into weekly mean-quality points per ring axis.
/// [now] is injectable for tests.
TrendSeries computeTrend(List<ReviewRecord> logs, {DateTime? now}) {
  if (logs.isEmpty) return const TrendSeries([], [], [], 0);
  final end = now ?? DateTime.now().toUtc();
  final start = logs
      .map((r) => r.reviewedAt)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  final spanDays = end.difference(start).inDays;
  final weeks = spanDays ~/ 7 + 1;

  final sums = {
    for (final t in CardType.values) t: List<double>.filled(weeks, 0),
  };
  final counts = {
    for (final t in CardType.values) t: List<int>.filled(weeks, 0),
  };

  for (final r in logs) {
    final w = (r.reviewedAt.difference(start).inDays ~/ 7).clamp(0, weeks - 1);
    sums[r.cardType]![w] += _quality(r.rating);
    counts[r.cardType]![w] += 1;
  }

  List<double?> series(CardType t) => [
        for (var w = 0; w < weeks; w++)
          counts[t]![w] == 0 ? null : sums[t]![w] / counts[t]![w],
      ];

  return TrendSeries(
    series(CardType.anchor),
    series(CardType.mechanism),
    series(CardType.application),
    spanDays,
  );
}

/// Weekly retention/quality trend over the last 90 days of review logs.
final reviewTrendProvider = FutureProvider.autoDispose<TrendSeries>((ref) async {
  final logs = await ref.watch(reviewsRepoProvider).recentLogs();
  return computeTrend(logs);
});

/// The approved deck (all review states) from Supabase.
final deckCardsProvider = FutureProvider.autoDispose<List<GraspCard>>(
    (ref) => ref.watch(cardsRepoProvider).approvedDeck());

/// Retention analytics over the approved deck.
final deckStatsProvider = FutureProvider.autoDispose<DeckStats>((ref) async {
  final cards = await ref.watch(deckCardsProvider.future);
  return computeDeckStats(cards, ref.watch(fsrsProvider));
});
