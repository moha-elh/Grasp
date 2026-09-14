import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/card.dart';
import '../../data/services/fsrs_service.dart';
import 'mock_deck.dart';

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

/// Retention analytics over the (currently mock) approved deck.
final deckStatsProvider = Provider<DeckStats>((ref) {
  return computeDeckStats(ref.watch(deckProvider), ref.watch(fsrsProvider));
});
