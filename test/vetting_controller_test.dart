import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/data/models/card.dart';
import 'package:grasp/features/vetting/vetting_controller.dart';

GraspCard _pending(String id) {
  final now = DateTime.now().toUtc();
  return GraspCard(
    id: id,
    userId: 'u',
    front: 'q',
    back: 'a',
    cardType: CardType.anchor,
    source: CardSource.notes,
    status: CardStatus.pending,
    fsrs: const {},
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('accept/discard advance and count; edit rewrites wording then accepts', () {
    final c = VettingController([_pending('a'), _pending('b'), _pending('c')]);

    c.accept();
    expect(c.state.accepted, 1);
    expect(c.state.index, 1);

    c.acceptEdited('new front', 'new back');
    expect(c.state.queue[1].front, 'new front');
    expect(c.state.accepted, 2);

    c.discard();
    expect(c.state.discarded, 1);
    expect(c.state.isComplete, isTrue);

    c.accept(); // no-op past the end
    expect(c.state.index, 3);
  });
}
