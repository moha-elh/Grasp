import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/card.dart';
import '../../data/repositories/cards_repository.dart';
import '../../data/services/fsrs_service.dart';
import '../../data/services/llm_service.dart';

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
  (ref) => RemakePileController(
    ref.watch(cardsRepoProvider),
    llm: ref.watch(llmProvider),
    fsrs: ref.watch(fsrsProvider),
    userId: ref.watch(userIdProvider),
  ),
);

/// FR-8 target type mix for regeneration, mirroring GenerationService.
const _remakeTargetMix = {
  'anchor': 0.34,
  'mechanism': 0.33,
  'application': 0.33,
};

class RemakePileController extends StateNotifier<RemakeState> {
  final CardsRepository? _repo;
  final LlmService? _llm;
  final FsrsService? _fsrs;
  final String? _userId;

  RemakePileController(this._repo, {LlmService? llm, FsrsService? fsrs, String? userId})
      : _llm = llm,
        _fsrs = fsrs,
        _userId = userId,
        super(const RemakeState(loading: true)) {
    _load();
  }

  /// Seeded, repo-less constructor for tests (no persistence).
  RemakePileController.seeded(List<GraspCard> pile)
      : _repo = null,
        _llm = null,
        _fsrs = null,
        _userId = null,
        super(RemakeState(pile: pile));

  Future<void> _load() async {
    try {
      final pile = await _repo!.remakePile();
      if (mounted) state = RemakeState(pile: pile);
    } catch (e) {
      if (mounted) state = RemakeState(error: e.toString());
    }
  }

  /// One batch action (FR-26). Re-authors each parked card via the LLM and
  /// stores the fresh cards as `pending` so they re-enter swipe vetting, then
  /// discards the old card. Repo-less (seeded/test) mode just clears the pile.
  Future<void> regenerateAll() async {
    final pile = state.pile;
    final llm = _llm, repo = _repo, fsrs = _fsrs, userId = _userId;
    if (llm == null || repo == null || fsrs == null || userId == null) {
      state = const RemakeState();
      return;
    }
    state = RemakeState(pile: pile, loading: true);
    try {
      for (final c in pile) {
        final content = c.sourceExcerpt?.isNotEmpty == true
            ? c.sourceExcerpt!
            : '${c.front}\n${c.back}';
        final cards = await llm.generate(
          notePath: c.sourcePath ?? '',
          noteContent: content,
          targetMix: _remakeTargetMix,
          maxCards: 3,
        );
        await repo.insertGenerated(
          userId: userId,
          sourcePath: c.sourcePath ?? '',
          sourceExcerpt: c.sourceExcerpt ?? '',
          cards: cards,
          fsrs: fsrs,
        );
        await repo.setStatus(c.id, CardStatus.discarded);
      }
      if (mounted) state = const RemakeState();
    } catch (e) {
      if (mounted) state = RemakeState(pile: pile, error: e.toString());
    }
  }

  /// "I was wrong, keep it": send the card straight back into the deck.
  Future<void> accept(String cardId) async {
    _remove(cardId);
    // Supabase's builder is lazy: the write only fires when awaited.
    await _repo?.setStatus(cardId, CardStatus.approved);
  }

  /// Delete the card for good.
  Future<void> delete(String cardId) async {
    _remove(cardId);
    await _repo?.setStatus(cardId, CardStatus.discarded);
  }

  void _remove(String cardId) => state =
      RemakeState(pile: [for (final c in state.pile) if (c.id != cardId) c]);
}
