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

  /// This user's review logs from the last [days] days (RLS scopes to the user),
  /// with each card's type embedded via the `cards` FK. Feeds the trend curve.
  Future<List<ReviewRecord>> recentLogs({int days = 90}) async {
    final since = DateTime.now()
        .toUtc()
        .subtract(Duration(days: days))
        .toIso8601String();
    final rows = await _db
        .from('review_logs')
        .select('reviewed_at, rating, cards(card_type)')
        .gte('reviewed_at', since)
        .order('reviewed_at');
    final out = <ReviewRecord>[];
    for (final r in rows) {
      final card = r['cards'] as Map<String, dynamic>?;
      final typeName = card?['card_type'];
      if (typeName == null) continue; // card deleted / no join row
      out.add(ReviewRecord(
        reviewedAt: DateTime.parse(r['reviewed_at'] as String),
        rating: r['rating'] as int,
        cardType: CardType.values.firstWhere((e) => e.name == typeName),
      ));
    }
    return out;
  }
}
