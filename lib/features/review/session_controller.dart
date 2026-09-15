import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../../core/providers.dart';
import '../../data/models/card.dart';
import '../../data/repositories/cards_repository.dart';
import '../../data/repositories/reviews_repository.dart';
import '../../data/services/fsrs_service.dart';
import '../settings/settings_controller.dart';

class SessionState {
  final List<GraspCard> queue;
  final int index;
  final bool revealed;
  final int reviewed; // graded this session
  final int flagged; // sent to the remake pile this session
  final bool loading;
  final String? error;
  final String? writeError; // last grade/flag persistence failed (surfaced, non-blocking)

  const SessionState({
    required this.queue,
    this.index = 0,
    this.revealed = false,
    this.reviewed = 0,
    this.flagged = 0,
    this.loading = false,
    this.error,
    this.writeError,
  });

  bool get isComplete => index >= queue.length;
  bool get isEmpty => queue.isEmpty;
  GraspCard? get current => isComplete ? null : queue[index];
  int get remaining => queue.length - index;

  SessionState copyWith({
    int? index,
    bool? revealed,
    int? reviewed,
    int? flagged,
    String? writeError,
    bool clearWriteError = false,
  }) =>
      SessionState(
        queue: queue,
        index: index ?? this.index,
        revealed: revealed ?? this.revealed,
        reviewed: reviewed ?? this.reviewed,
        flagged: flagged ?? this.flagged,
        loading: loading,
        error: error,
        writeError: clearWriteError ? null : (writeError ?? this.writeError),
      );
}

/// Drives one review session (FR-16, FR-22, FR-25/26) over real cards: due
/// reviews in full plus a throttled slice of new cards, persisting each grade.
final sessionControllerProvider =
    StateNotifierProvider.autoDispose<SessionController, SessionState>(
  (ref) => SessionController(
    cards: ref.watch(cardsRepoProvider),
    reviews: ref.watch(reviewsRepoProvider),
    fsrs: ref.watch(fsrsProvider),
    newPerDay: ref.watch(newCardsPerDayProvider),
  ),
);

class SessionController extends StateNotifier<SessionState> {
  final CardsRepository? _cards;
  final ReviewsRepository? _reviews;
  final FsrsService? _fsrs;
  final int _newPerDay;

  SessionController({
    required CardsRepository cards,
    required ReviewsRepository reviews,
    required FsrsService fsrs,
    required int newPerDay,
  })  : _cards = cards,
        _reviews = reviews,
        _fsrs = fsrs,
        _newPerDay = newPerDay,
        super(const SessionState(queue: [], loading: true)) {
    _load();
  }

  /// Seeded, repo-less constructor for tests (no persistence).
  SessionController.seeded(List<GraspCard> queue)
      : _cards = null,
        _reviews = null,
        _fsrs = null,
        _newPerDay = 0,
        super(SessionState(queue: queue));

  Future<void> _load() async {
    try {
      // Due reviews are served IN FULL (FR-17); new cards are throttled.
      final due = await _cards!.dueCards();
      final fresh = await _cards.newCards(limit: _newPerDay);
      if (mounted) state = SessionState(queue: [...due, ...fresh]);
    } catch (e) {
      if (mounted) state = SessionState(queue: const [], error: e.toString());
    }
  }

  void reveal() => state = state.copyWith(revealed: true);

  /// Grade drives scheduling (FR-22): update FSRS state + log in one write.
  void grade(fsrs.Rating rating) {
    if (state.isComplete) return;
    final card = state.current!;
    // Advance immediately so the card-to-card flow stays snappy; the write
    // runs in the background and surfaces (not blocks) on failure.
    if (_fsrs != null && _reviews != null) {
      final result = _fsrs.review(card, rating);
      _persist(() => _reviews.record(result.card, result.log));
    }
    state = state.copyWith(
      index: state.index + 1,
      revealed: false,
      reviewed: state.reviewed + 1,
    );
  }

  /// Flag = badly made (FR-25). Removes the card from the session and parks it
  /// in the remake pile (FR-26) - never touches FSRS state.
  void flag() {
    if (state.isComplete) return;
    final card = state.current!;
    if (_cards != null) {
      _persist(() async {
        await _cards.setQuality(card.id, Quality.disliked);
        await _cards.setStatus(card.id, CardStatus.remakePending);
      });
    }
    state = state.copyWith(
      index: state.index + 1,
      revealed: false,
      flagged: state.flagged + 1,
    );
  }

  /// Run a persistence write in the background: retry ONCE, then surface the
  /// failure via writeError. Guards against disposal (autoDispose provider).
  // ponytail: single retry + surfaced error, no persistent retry queue.
  // Add a durable offline queue only if writes prove lossy in practice.
  Future<void> _persist(Future<void> Function() write) async {
    try {
      await write();
    } catch (_) {
      try {
        await write();
      } catch (e) {
        if (mounted) state = state.copyWith(writeError: e.toString());
        return;
      }
    }
    if (mounted && state.writeError != null) {
      state = state.copyWith(clearWriteError: true);
    }
  }

  void restart() => state = SessionState(queue: state.queue);
}
