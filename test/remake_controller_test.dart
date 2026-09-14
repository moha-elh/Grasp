import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/data/models/card.dart';
import 'package:grasp/features/remake/remake_controller.dart';

GraspCard _c(String id) {
  final now = DateTime.now().toUtc();
  return GraspCard(
    id: id,
    userId: 'u',
    front: 'q',
    back: 'a',
    cardType: CardType.anchor,
    source: CardSource.notes,
    status: CardStatus.remakePending,
    quality: Quality.disliked,
    fsrs: const {},
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('regenerateAll empties the pile in one batch', () {
    final ctrl = RemakePileController([_c('r1'), _c('r2')]);
    expect(ctrl.state.length, 2);
    ctrl.regenerateAll();
    expect(ctrl.state, isEmpty);
  });

  test('accept and delete each remove one card', () {
    final ctrl = RemakePileController([_c('r1'), _c('r2'), _c('r3')]);
    ctrl.accept('r1');
    expect(ctrl.state.map((c) => c.id), ['r2', 'r3']);
    ctrl.delete('r3');
    expect(ctrl.state.map((c) => c.id), ['r2']);
  });
}
