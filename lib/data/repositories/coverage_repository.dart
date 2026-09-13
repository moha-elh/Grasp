import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/note_coverage.dart';

/// Drives coverage-aware generation rotation (FR-7): pick under-carded /
/// not-yet-carded notes next.
class CoverageRepository {
  final SupabaseClient _db;
  CoverageRepository(this._db);

  SupabaseQueryBuilder get _t => _db.from('note_coverage');

  Future<List<NoteCoverage>> all() async {
    final rows = await _t.select();
    return rows.map(NoteCoverage.fromJson).toList();
  }

  /// Given every eligible note path, return them ordered so the least-covered
  /// (never generated, then oldest last_generated_at) come first.
  Future<List<String>> nextToGenerate(List<String> eligiblePaths) async {
    final coverage = {for (final c in await all()) c.sourcePath: c};
    final sorted = [...eligiblePaths]..sort((a, b) {
        final ca = coverage[a], cb = coverage[b];
        if (ca == null && cb == null) return 0;
        if (ca == null) return -1; // never carded first
        if (cb == null) return 1;
        final ta = ca.lastGeneratedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = cb.lastGeneratedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ta.compareTo(tb); // oldest first
      });
    return sorted;
  }

  Future<void> markGenerated(String userId, String sourcePath, int addedCards) async {
    await _t.upsert({
      'user_id': userId,
      'source_path': sourcePath,
      'last_generated_at': DateTime.now().toUtc().toIso8601String(),
      'cards_generated': addedCards,
    }, onConflict: 'user_id,source_path');
  }
}
