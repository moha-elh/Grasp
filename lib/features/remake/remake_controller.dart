import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/card.dart';

/// The Remake pile (FR-26): approved cards the user disliked (badly made) are
/// pulled from review and parked here as `remake_pending`, cleared in a batch
/// - never mid-session. Regenerated cards re-enter through swipe vetting.
///
/// Mock pile for now; replace `_seed` with a CardsRepository query for
/// `status = remake_pending` once auth lands. Regeneration is stubbed to just
/// empty the pile - wire it to LLM regenerate → `pending` when generation exists.
final remakePileProvider =
    StateNotifierProvider.autoDispose<RemakePileController, List<GraspCard>>(
  (ref) => RemakePileController(_seed(ref)),
);

class RemakePileController extends StateNotifier<List<GraspCard>> {
  RemakePileController(super.pile);

  /// One batch action (FR-26). Regenerated cards re-enter via vetting.
  void regenerateAll() {
    // TODO(gen): for each card, LLM.regenerate(sourceExcerpt) → insert as pending
    state = const [];
  }

  /// "I was wrong, keep it": send the card straight back into the deck.
  void accept(String cardId) {
    // TODO(auth): CardsRepository.setStatus(cardId, approved) + clear quality
    _remove(cardId);
  }

  /// Delete the card for good.
  void delete(String cardId) {
    // TODO(auth): CardsRepository.setStatus(cardId, discarded) (or hard delete)
    _remove(cardId);
  }

  void _remove(String cardId) =>
      state = [for (final c in state) if (c.id != cardId) c];
}

List<GraspCard> _seed(Ref ref) {
  final fsrs = ref.watch(fsrsProvider);
  final now = DateTime.now().toUtc();

  GraspCard card({
    required String id,
    required String note,
    required CardType type,
    required String front,
    required String back,
  }) =>
      GraspCard(
        id: id,
        userId: 'mock',
        front: front,
        back: back,
        cardType: type,
        source: CardSource.notes,
        sourcePath: '/6 - Main Notes/$note.md',
        sourceExcerpt: '',
        status: CardStatus.remakePending,
        quality: Quality.disliked,
        fsrs: fsrs.newCard(),
        createdAt: now,
        updatedAt: now,
      );

  return [
    card(
      id: 'r1',
      note: 'Hash Table',
      type: CardType.mechanism,
      front: 'Explain everything about how hash tables handle collisions.',
      back: 'Chaining stores colliding keys in a per-bucket list; open '
          'addressing probes for the next free slot. (Too broad, split it.)',
    ),
    card(
      id: 'r2',
      note: 'TCP',
      type: CardType.anchor,
      front: 'What is TCP?',
      back: 'A protocol. (Vague, says nothing testable.)',
    ),
  ];
}
