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
  void accept() {
    if (state.isComplete) return;
    _repo?.setStatus(state.current!.id, CardStatus.approved);
    state = state.copyWith(index: state.index + 1, accepted: state.accepted + 1);
  }

  /// Swipe left (FR-14): discard.
  void discard() {
    if (state.isComplete) return;
    _repo?.setStatus(state.current!.id, CardStatus.discarded);
    state = state.copyWith(index: state.index + 1, discarded: state.discarded + 1);
  }

  /// Swipe up (FR-14): accept, but with edited wording first.
  void acceptEdited(String front, String back) {
    if (state.isComplete) return;
    final card = state.current!;
    _repo?.updateWording(card.id, front: front, back: back);
    state.queue[state.index] = card.copyWith(front: front, back: back);
    accept();
  }
}
