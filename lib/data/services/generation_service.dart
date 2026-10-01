import '../../core/config.dart';
import '../models/card.dart';
import '../repositories/cards_repository.dart';
import '../repositories/coverage_repository.dart';
import 'dropbox_service.dart';
import 'fsrs_service.dart';
import 'llm_service.dart';

/// Background card generation (FR-7). Rotates through eligible notes
/// coverage-aware, generates a small batch per note via the LLM, and stores
/// them as `pending` - pausing once the pending queue is full so the user is
/// never flooded. Decoupled from review: this just fills the queue ahead.
class GenerationService {
  final DropboxService _dropbox;
  final LlmService _llm;
  final CardsRepository _cards;
  final CoverageRepository _coverage;
  final FsrsService _fsrs;

  GenerationService(
      this._dropbox, this._llm, this._cards, this._coverage, this._fsrs);

  /// FR-9 target type mix: starts at an even split, then self-adjusts toward the
  /// card types the user likes and away from ones they flag. ponytail: linear
  /// nudge with a floor, no learning-rate schedule.
  Future<Map<String, double>> _targetMix() async {
    final net = await _cards.qualityBalanceByType();
    const base = 0.33, step = 0.03, floor = 0.15;
    final raw = {
      for (final t in CardType.values)
        t.name: (base + step * net[t]!).clamp(floor, 1.0),
    };
    final sum = raw.values.reduce((a, b) => a + b);
    return {for (final e in raw.entries) e.key: e.value / sum};
  }

  /// Run one bounded pass. Returns how many cards were added. [cardsTotal]
  /// is the user's target for the whole pass (the "Cards per pass" setting).
  /// [notesPerPass] only sets the per-note cap (so no single note is stuffed);
  /// the pass visits as many notes as it takes to reach the target, since the
  /// LLM often returns fewer than asked per note, then stops at the target or
  /// the pending-queue cap.
  Future<int> runPass({
    required String userId,
    int cardsTotal = Config.defaultCardsPerGeneration,
    int notesPerPass = Config.generationNotesPerPass,
  }) async {
    if (await _cards.pendingCount() >= Config.pendingQueueTarget) return 0;

    final notes = await _dropbox.eligibleNotes();
    if (notes.isEmpty) return 0;
    final byPath = {for (final n in notes) n.path: n};
    final order = await _coverage.nextToGenerate(byPath.keys.toList());

    final maxPerNote = (cardsTotal / notesPerPass).ceil();
    final targetMix = await _targetMix();
    var budget = cardsTotal;
    var added = 0;
    for (final path in order) {
      if (budget <= 0) break;
      if (await _cards.pendingCount() >= Config.pendingQueueTarget) break;
      final note = byPath[path];
      if (note == null) continue;

      final generated = await _llm.generate(
        notePath: path,
        noteContent: note.content,
        targetMix: targetMix,
        maxCards: budget < maxPerNote ? budget : maxPerNote,
      );
      if (generated.isEmpty) {
        await _coverage.markGenerated(userId, path, 0);
        continue;
      }
      await _cards.insertGenerated(
        userId: userId,
        sourcePath: path,
        sourceExcerpt: _excerpt(note.content),
        cards: generated,
        fsrs: _fsrs,
      );
      await _coverage.markGenerated(userId, path, generated.length);
      added += generated.length;
      budget -= generated.length;
    }
    return added;
  }

  /// A short trust-layer snippet of the note (FR-20), whitespace-collapsed.
  String _excerpt(String content, {int max = 280}) {
    final flat = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= max ? flat : '${flat.substring(0, max)}...';
  }
}
