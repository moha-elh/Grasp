import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/card.dart';
import '../../data/repositories/cards_repository.dart';

/// One vetting outcome per swipe (FR-14).
enum VetAction { accept, discard }

class VettingState {
  final List<GraspCard> queue;
  final int index;
  final int accepted;
  final int discarded;
  final bool loading;
  final String? error;

  const VettingState({
    required this.queue,
    this.index = 0,
    this.accepted = 0,
    this.discarded = 0,
    this.loading = false,
    this.error,
  });

  bool get isEmpty => queue.isEmpty;
  bool get isComplete => index >= queue.length;
  GraspCard? get current => isComplete ? null : queue[index];
  int get total => queue.length;

  VettingState copyWith({int? index, int? accepted, int? discarded}) =>
      VettingState(
        queue: queue,
        index: index ?? this.index,
        accepted: accepted ?? this.accepted,
        discarded: discarded ?? this.discarded,
        loading: loading,
        error: error,
      );
}

/// Drives the bounded swipe-vetting batch (FR-14, FR-15) over the real pending
/// cards, persisting each outcome to `status` in Supabase.
final vettingControllerProvider =
    StateNotifierProvider.autoDispose<VettingController, VettingState>(
  (ref) => VettingController(ref.watch(cardsRepoProvider)),
);

class VettingController extends StateNotifier<VettingState> {
  final CardsRepository? _repo;

  VettingController(this._repo)
      : super(const VettingState(queue: [], loading: true)) {
    _load();
  }

  /// Seeded, repo-less constructor for tests (no persistence).
  VettingController.seeded(List<GraspCard> queue)
      : _repo = null,
        super(VettingState(queue: queue));

  Future<void> _load() async {
    try {
      final cards = await _repo!.pendingToVet();
      if (mounted) state = VettingState(queue: cards);
    } catch (e) {
      if (mounted) state = VettingState(queue: const [], error: e.toString());
    }
  }

  /// Swipe right (FR-14): accept into the Retention deck (status → approved).
  Future<void> accept() async {
    if (state.isComplete) return;
    final id = state.current!.id;
    state = state.copyWith(index: state.index + 1, accepted: state.accepted + 1);
    // Supabase's PostgrestBuilder is lazy — it only issues the request when
    // awaited. Advancing first keeps the swipe instant; the await guarantees
    // the status write actually reaches the DB (a failed write leaves the card
    // pending, so it resurfaces next pass rather than being silently lost).
    await _repo?.setStatus(id, CardStatus.approved);
  }

  /// Swipe left (FR-14): discard.
  Future<void> discard() async {
    if (state.isComplete) return;
    final id = state.current!.id;
    state = state.copyWith(index: state.index + 1, discarded: state.discarded + 1);
    await _repo?.setStatus(id, CardStatus.discarded);
  }

  /// Swipe up (FR-14): accept, but with edited wording first.
  Future<void> acceptEdited(String front, String back) async {
    if (state.isComplete) return;
    final card = state.current!;
    state.queue[state.index] = card.copyWith(front: front, back: back);
    // Advance first (accept() mutates state synchronously before its await),
    // then persist. Awaiting the write before accept() would defer the state
    // change to a later microtask.
    await accept();
    await _repo?.updateWording(card.id, front: front, back: back);
  }
}
