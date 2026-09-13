import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/card.dart';
import '../models/review_log.dart';

/// Persists a graded review. Card-state update + log insert happen in ONE
/// transaction via the `record_review` Postgres function (§8), so a card's
/// FSRS state and its log can never drift apart.
class ReviewsRepository {
  final SupabaseClient _db;
  ReviewsRepository(this._db);

  Future<void> record(GraspCard updated, ReviewLog log) async {
    await _db.rpc('record_review', params: {
      'p_card_id': updated.id,
      'p_fsrs': updated.fsrs,
      'p_due': updated.due?.toIso8601String(),
      'p_reps': updated.reps,
      'p_lapses': updated.lapses,
      'p_card_state': updated.cardState,
      'p_rating': log.rating,
      'p_elapsed_days': log.elapsedDays,
      'p_scheduled_days': log.scheduledDays,
    });
  }
}
