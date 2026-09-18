import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:grasp/data/models/card.dart';
import 'package:grasp/data/services/fsrs_service.dart';

GraspCard _card(FsrsService s) {
  final now = DateTime.now().toUtc();
  return GraspCard(
    id: 'c1',
    userId: 'u1',
    front: 'q',
    back: 'a',
    cardType: CardType.mechanism,
    source: CardSource.notes,
    status: CardStatus.approved,
    fsrs: s.newCard(),
    createdAt: now,
    updatedAt: now,
  );
}

GraspCard _studied(DateTime lastReview, double stability) {
  final now = DateTime.now().toUtc();
  return GraspCard(
    id: 's1',
    userId: 'u1',
    front: 'q',
    back: 'a',
    cardType: CardType.anchor,
    source: CardSource.notes,
    status: CardStatus.approved,
    reps: 5,
    fsrs: {
      'cardId': now.microsecondsSinceEpoch,
      'state': 2,
      'step': null,
      'stability': stability,
      'difficulty': 5.0,
      'due': lastReview.add(Duration(days: stability.round())).toIso8601String(),
      'lastReview': lastReview.toIso8601String(),
    },
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final s = FsrsService();

  test('good review increments reps, no lapse, schedules into the future', () {
    final now = DateTime.now().toUtc();
    final r = s.review(_card(s), fsrs.Rating.good, at: now);
    expect(r.card.reps, 1);
    expect(r.card.lapses, 0);
    expect(r.card.due!.isAfter(now), isTrue);
    expect(r.log.rating, 3);
  });

  test('again counts a lapse', () {
    final r = s.review(_card(s), fsrs.Rating.again);
    expect(r.card.lapses, 1);
  });

  test('interval previews are positive and ordered Again < Good < Easy', () {
    final p = s.previewIntervals(_card(s));
    expect(p.length, 4);
    for (final d in p.values) {
      expect(d.inSeconds, greaterThan(0));
    }
    expect(p[fsrs.Rating.again]!, lessThan(p[fsrs.Rating.good]!));
    expect(p[fsrs.Rating.good]!, lessThanOrEqualTo(p[fsrs.Rating.easy]!));
  });

  test('recall strength tempers fresh retrievability with maturity', () {
    final now = DateTime.utc(2026, 1, 10);

    // Just graded: retrievability is ~1.0, but one review is not a memory yet.
    final fresh = _studied(now, 3);
    expect(s.retrievability(fresh, at: now), closeTo(1.0, 0.001));
    expect(s.recallStrength(fresh, at: now), lessThan(0.6),
        reason: 'a just-seen card must not read as fully retained');

    // Retained for weeks: high stability outranks the fresh card even a week on.
    final mature = _studied(now.subtract(const Duration(days: 7)), 60);
    expect(s.recallStrength(mature, at: now),
        greaterThan(s.recallStrength(fresh, at: now)));
    expect(s.recallStrength(mature, at: now), greaterThan(0.8));
  });
}
