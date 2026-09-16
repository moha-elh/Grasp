import 'package:fsrs/fsrs.dart' as fsrs;

import '../models/card.dart';
import '../models/review_log.dart';

/// Pure FSRS scheduling (FR-21, FR-22). No IO - persistence is the repo's job.
/// The single scheduler instance holds the model weights; swap in optimized
/// parameters here later without touching callers.
class FsrsService {
  final fsrs.Scheduler _scheduler;

  // No sub-day learning/relearning steps: this is a once-a-day review app, so
  // every grade schedules a day-scale interval (Again/Hard/Good/Easy spread out
  // as the card matures) instead of the default 1m/10m steps that resurface a
  // card minutes later and make all four grades look the same on a new card.
  FsrsService([fsrs.Scheduler? scheduler])
      : _scheduler = scheduler ??
            fsrs.Scheduler(
              learningSteps: const [],
              relearningSteps: const [],
            );

  /// A brand-new card's initial FSRS state (stored as jsonb on insert).
  Map<String, dynamic> newCard() => fsrs.Card(
        cardId: DateTime.now().millisecondsSinceEpoch,
      ).toMap();

  /// Apply a grade. Returns the card with refreshed FSRS state + promoted
  /// columns, and the review log to insert. Callers persist both in one
  /// transaction so state and log never drift (§8).
  ({GraspCard card, ReviewLog log}) review(
    GraspCard card,
    fsrs.Rating rating, {
    DateTime? at,
  }) {
    final now = (at ?? DateTime.now()).toUtc();
    final result = _scheduler.reviewCard(card.fsrsCard, rating, reviewDateTime: now);
    final updated = result.card;
    final rl = result.reviewLog;

    final isLapse = rating == fsrs.Rating.again;
    return (
      card: card.copyWith(
        fsrs: updated.toMap(),
        due: updated.due,
        reps: card.reps + 1,
        lapses: card.lapses + (isLapse ? 1 : 0),
        cardState: updated.state.name,
        updatedAt: now,
      ),
      log: ReviewLog(
        userId: card.userId,
        cardId: card.id,
        rating: rating.value,
        reviewedAt: now,
        elapsedDays: _elapsedDays(rl),
        scheduledDays: updated.due.difference(now).inDays,
      ),
    );
  }

  /// The interval each grade would schedule, WITHOUT persisting - shown on the
  /// grading chips before the user picks one (design §07 "grading intervals").
  Map<fsrs.Rating, Duration> previewIntervals(GraspCard card, {DateTime? at}) {
    final now = (at ?? DateTime.now()).toUtc();
    return {
      for (final r in fsrs.Rating.values)
        r: _scheduler
            .reviewCard(card.fsrsCard, r, reviewDateTime: now)
            .card
            .due
            .difference(now),
    };
  }

  /// Current recall probability (FR-28 recall strength). 0..1.
  double retrievability(GraspCard card, {DateTime? at}) =>
      _scheduler.getCardRetrievability(card.fsrsCard, currentDateTime: (at ?? DateTime.now()).toUtc());

  int _elapsedDays(fsrs.ReviewLog rl) {
    // ReviewLog stores the review datetime; elapsed since prior review isn't
    // exposed directly, so 0 is a safe default until we track lastReview here.
    // ponytail: elapsed_days=0 placeholder; wire from card.lastReview when analytics needs it.
    return 0;
  }
}
