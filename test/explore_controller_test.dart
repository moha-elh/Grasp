import 'package:flutter_test/flutter_test.dart';
import 'package:grasp/data/models/card.dart';
import 'package:grasp/features/explore/explore_feed.dart';

ExploreItem _i(String id) => ExploreItem(
      id: id,
      kind: ExploreKind.web,
      type: CardType.anchor,
      front: 'q',
      back: 'a',
      citation: 'src',
    );

void main() {
  test('verify and dismiss each remove exactly one item from the feed', () {
    final c = ExploreController([_i('a'), _i('b'), _i('c')]);

    c.verify('a');
    expect(c.state.items.map((e) => e.id), ['b', 'c']);

    c.dismiss('c');
    expect(c.state.items.map((e) => e.id), ['b']);
  });
}
