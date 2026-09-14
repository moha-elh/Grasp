import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/card.dart';
import '../services/fsrs_service.dart';
import '../services/llm_service.dart';

/// Card persistence + the queries the daily session needs (FR-16, FR-17).
/// RLS scopes every query to the current user, so no user_id filter is needed.
class CardsRepository {
  final SupabaseClient _db;
  CardsRepository(this._db);

  SupabaseQueryBuilder get _t => _db.from('cards');

  /// Store freshly generated cards as `pending` (FR-7). FSRS state seeded now
  /// so the card is review-ready the moment it's approved.
  Future<void> insertGenerated({
    required String userId,
    required String sourcePath,
    required String sourceExcerpt,
    required List<GeneratedCard> cards,
    required FsrsService fsrs,
  }) async {
    if (cards.isEmpty) return;
    final now = DateTime.now().toUtc();
    await _t.insert([
      for (final c in cards)
        {
          'user_id': userId,
          'front': c.front,
          'back': c.back,
          'card_type': c.type.name,
          'source': CardSource.notes.name,
          'source_path': sourcePath,
          'source_excerpt': sourceExcerpt,
          'status': 'pending',
          'fsrs': fsrs.newCard(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        }
    ]);
  }

  /// Pending cards awaiting vetting, drawn across all notes (FR-14).
  Future<List<GraspCard>> pendingToVet({int limit = 20}) async {
    final rows = await _t
        .select()
        .eq('status', 'pending')
        .order('created_at')
        .limit(limit);
    return rows.map(GraspCard.fromJson).toList();
  }

  int get pendingQueueLimit => 20;

  /// Count of pending cards - background generation pauses at the target (FR-7).
  Future<int> pendingCount() async {
    final rows = await _t.select('id').eq('status', 'pending').count();
    return rows.count;
  }

  /// Cards due for review now - served IN FULL, never capped (FR-17).
  Future<List<GraspCard>> dueCards() async {
    final rows = await _t
        .select()
        .eq('status', 'approved')
        .gt('reps', 0)
        .lte('due', DateTime.now().toUtc().toIso8601String())
        .order('due');
    return rows.map(GraspCard.fromJson).toList();
  }

  /// Approved-but-never-reviewed cards, capped by the daily NEW intake (FR-17).
  Future<List<GraspCard>> newCards({required int limit}) async {
    final rows = await _t
        .select()
        .eq('status', 'approved')
        .eq('reps', 0)
        .order('created_at')
        .limit(limit);
    return rows.map(GraspCard.fromJson).toList();
  }

  Future<void> setStatus(String cardId, CardStatus status) => _t.update({
        'status': status == CardStatus.remakePending ? 'remake_pending' : status.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', cardId);

  /// Edit wording on swipe-up accept (FR-14).
  Future<void> updateWording(String cardId, {String? front, String? back}) => _t.update({
        if (front != null) 'front': front,
        if (back != null) 'back': back,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', cardId);

  /// Like/dislike quality signal (FR-24). Disliking an in-deck card moves it to
  /// the Remake pile (FR-26) - the caller decides that; this just sets fields.
  Future<void> setQuality(String cardId, Quality quality) => _t.update({
        'quality': quality.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', cardId);

  Future<List<GraspCard>> remakePile() async {
    final rows = await _t.select().eq('status', 'remake_pending');
    return rows.map(GraspCard.fromJson).toList();
  }

  /// Whole approved deck (any review state) for the Retention analytics (FR-27).
  Future<List<GraspCard>> approvedDeck() async {
    final rows = await _t.select().eq('status', 'approved').order('created_at');
    return rows.map(GraspCard.fromJson).toList();
  }
}
