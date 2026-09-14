import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../data/models/card.dart';
import 'mock_cards.dart';

class SessionState {
  final List<GraspCard> queue;
  final int index;
  final bool revealed;
  final int reviewed; // graded this session
  final int flagged; // sent to the remake pile this session

  const SessionState({
    required this.queue,
    this.index = 0,
    this.revealed = false,
    this.reviewed = 0,
    this.flagged = 0,
  });

  bool get isComplete => index >= queue.length;
  bool get isEmpty => queue.isEmpty;
  GraspCard? get current => isComplete ? null : queue[index];
  int get remaining => queue.length - index;

  SessionState copyWith({int? index, bool? revealed, int? reviewed, int? flagged}) =>
      SessionState(
        queue: queue,
        index: index ?? this.index,
        revealed: revealed ?? this.revealed,
        reviewed: reviewed ?? this.reviewed,
        flagged: flagged ?? this.flagged,
      );
}

/// Drives one review session (FR-16, FR-22, FR-25/26). Against mock cards for
/// now; grading/flagging don't yet persist - see the TODOs.
final sessionControllerProvider =
    StateNotifierProvider.autoDispose<SessionController, SessionState>(
  (ref) => SessionController(ref.watch(sessionQueueProvider)),
);

class SessionController extends StateNotifier<SessionState> {
  SessionController(List<GraspCard> queue)
      : super(SessionState(queue: queue));

  void reveal() => state = state.copyWith(revealed: true);

  /// Grade drives scheduling only (FR-22). Advances to the next card.
  void grade(fsrs.Rating rating) {
    if (state.isComplete) return;
    // TODO(auth): fsrsService.review(current, rating) → ReviewsRepository.record
    state = state.copyWith(
      index: state.index + 1,
      revealed: false,
      reviewed: state.reviewed + 1,
    );
  }

  /// Flag = badly made (FR-25). Removes the card from the session and sends it
  /// to the remake pile (FR-26) - never touches FSRS state.
  void flag() {
    if (state.isComplete) return;
    // TODO(auth): CardsRepository.setQuality(disliked) + status=remake_pending
    state = state.copyWith(
      index: state.index + 1,
      revealed: false,
      flagged: state.flagged + 1,
    );
  }

  void restart() => state = SessionState(queue: state.queue);
}
