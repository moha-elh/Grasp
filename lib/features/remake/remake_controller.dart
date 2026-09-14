import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/card.dart';
import '../../data/repositories/cards_repository.dart';

class RemakeState {
  final List<GraspCard> pile;
  final bool loading;
  final String? error;
  const RemakeState({this.pile = const [], this.loading = false, this.error});

  bool get isEmpty => pile.isEmpty;
  int get length => pile.length;
}

/// The Remake pile (FR-26): approved cards the user disliked (badly made) are
/// parked here as `remake_pending`, cleared in a batch - never mid-session.
/// Regenerated cards re-enter through swipe vetting.
final remakePileProvider =
    StateNotifierProvider.autoDispose<RemakePileController, RemakeState>(
  (ref) => RemakePileController(ref.watch(cardsRepoProvider)),
);

class RemakePileController extends StateNotifier<RemakeState> {
  final CardsRepository? _repo;

  RemakePileController(this._repo) : super(const RemakeState(loading: true)) {
    _load();
  }

  /// Seeded, repo-less constructor for tests (no persistence).
  RemakePileController.seeded(List<GraspCard> pile)
      : _repo = null,
        super(RemakeState(pile: pile));

  Future<void> _load() async {
    try {
      final pile = await _repo!.remakePile();
      if (mounted) state = RemakeState(pile: pile);
    } catch (e) {
      if (mounted) state = RemakeState(error: e.toString());
    }
  }

  /// One batch action (FR-26). Regenerated cards re-enter via vetting.
  /// ponytail: clears the pile locally; LLM re-generation → `pending` is wired
  /// with the generation pipeline, not here.
  void regenerateAll() {
    for (final c in state.pile) {
      _repo?.setStatus(c.id, CardStatus.pending);
    }
    state = const RemakeState();
  }

  /// "I was wrong, keep it": send the card straight back into the deck.
  void accept(String cardId) {
    _repo?.setStatus(cardId, CardStatus.approved);
    _remove(cardId);
  }

  /// Delete the card for good.
  void delete(String cardId) {
    _repo?.setStatus(cardId, CardStatus.discarded);
    _remove(cardId);
  }

  void _remove(String cardId) => state =
      RemakeState(pile: [for (final c in state.pile) if (c.id != cardId) c]);
}
