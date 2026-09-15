import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/data/models/card.dart';
import 'package:grasp/data/models/review_log.dart';
import 'package:grasp/data/services/fsrs_service.dart';
import 'package:grasp/features/retention/analytics.dart';

GraspCard _c(String note, CardType type, double stability, int daysAgo) {
  final now = DateTime.now().toUtc();
  return GraspCard(
    id: '$note-${type.name}',
    userId: 'u',
    front: 'q',
    back: 'a',
    cardType: type,
    source: CardSource.notes,
    sourcePath: '/n/$note.md',
    status: CardStatus.approved,
    reps: 5,
    fsrs: {
      'cardId': now.microsecondsSinceEpoch,
      'state': 2,
      'step': null,
      'stability': stability,
      'difficulty': 5.0,
      'due': now.toIso8601String(),
      'lastReview': now.subtract(Duration(days: daysAgo)).toIso8601String(),
    },
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('concepts sort by widest name/mechanism gap; means stay in range', () {
    final f = FsrsService();
    final cards = [
      // Wide gap: strong anchor, weak mechanism.
      _c('Liskov', CardType.anchor, 60, 2),
      _c('Liskov', CardType.mechanism, 2, 9),
      // Balanced.
      _c('Idempotency', CardType.anchor, 40, 4),
      _c('Idempotency', CardType.mechanism, 35, 4),
    ];

    final s = computeDeckStats(cards, f);

    expect(s.concepts.first.concept, 'Liskov'); // widest gap first
    expect(s.concepts.first.gap, greaterThan(s.concepts.last.gap));
    for (final v in [s.nameRet, s.explainRet]) {
      expect(v, inInclusiveRange(0, 1));
    }
    // Anchors recall better than mechanisms in this fixture.
    expect(s.nameRet, greaterThan(s.explainRet));
  });

  test('computeTrend buckets weekly quality by ring axis and spans history', () {
    final now = DateTime.utc(2026, 3, 1);
    ReviewRecord r(CardType t, int rating, int daysAgo) => ReviewRecord(
          reviewedAt: now.subtract(Duration(days: daysAgo)),
          rating: rating,
          cardType: t,
        );
    final logs = [
      // 21 days ago (week 0): strong anchors, weak mechanisms.
      r(CardType.anchor, 4, 21), // quality 1.0
      r(CardType.anchor, 3, 21), // quality ~0.67 -> mean 0.833
      r(CardType.mechanism, 1, 21), // quality 0.0
      // 0 days ago (week 3): a single application review.
      r(CardType.application, 3, 0), // quality ~0.67
    ];

    final t = computeTrend(logs, now: now);

    expect(t.isEmpty, isFalse);
    expect(t.spanDays, 21);
    expect(t.name.length, 4); // 21-day span -> 4 weekly buckets
    expect(t.name[0], closeTo(0.8333, 0.001));
    expect(t.explain[0], 0.0); // mechanism -> explain series
    expect(t.name[3], isNull); // no anchor reviews in the latest week
    expect(t.apply[3], closeTo(0.6667, 0.001)); // application -> apply series

    expect(computeTrend([], now: now).isEmpty, isTrue);
  });
}
