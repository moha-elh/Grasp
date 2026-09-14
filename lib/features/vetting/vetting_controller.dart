import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/card.dart';
import 'mock_pending.dart';

/// One vetting outcome per swipe (FR-14).
enum VetAction { accept, discard }

class VettingState {
  final List<GraspCard> queue;
  final int index;
  final int accepted;
  final int discarded;

  const VettingState({
    required this.queue,
    this.index = 0,
    this.accepted = 0,
    this.discarded = 0,
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
      );
}

/// Drives the bounded swipe-vetting batch (FR-14, FR-15). Against mock pending
/// cards for now; outcomes don't persist yet — see the TODOs.
final vettingControllerProvider =
    StateNotifierProvider.autoDispose<VettingController, VettingState>(
  (ref) => VettingController(ref.watch(pendingQueueProvider)),
);

class VettingController extends StateNotifier<VettingState> {
  VettingController(List<GraspCard> queue) : super(VettingState(queue: queue));

  /// Swipe right (FR-14): accept into the Retention deck (status → approved).
  void accept() {
    if (state.isComplete) return;
    // TODO(auth): CardsRepository.setStatus(current.id, approved)
    state = state.copyWith(index: state.index + 1, accepted: state.accepted + 1);
  }

  /// Swipe left (FR-14): discard.
  void discard() {
    if (state.isComplete) return;
    // TODO(auth): CardsRepository.setStatus(current.id, discarded)
    state = state.copyWith(index: state.index + 1, discarded: state.discarded + 1);
  }

  /// Swipe up (FR-14): accept, but with edited wording first.
  void acceptEdited(String front, String back) {
    if (state.isComplete) return;
    // TODO(auth): CardsRepository.update(front/back) + setStatus(approved)
    state.queue[state.index] =
        state.current!.copyWith(front: front, back: back);
    accept();
  }
}
