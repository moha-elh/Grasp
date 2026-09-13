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
}
