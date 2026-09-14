import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/data/models/card.dart';
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
}
