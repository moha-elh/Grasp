import '../../core/config.dart';
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

  /// FR-8 target type mix: an even split across the three card types.
  static const _targetMix = {
    'anchor': 0.34,
    'mechanism': 0.33,
    'application': 0.33,
  };

  /// Run one bounded pass. Returns how many cards were added. [cardsTotal]
  /// is the user's target for the whole pass (the "Cards per pass" setting),
  /// spread across [notesPerPass] notes up to the pending-queue target.
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
    var budget = cardsTotal;
    var added = 0;
    for (final path in order.take(notesPerPass)) {
      if (budget <= 0) break;
      if (await _cards.pendingCount() >= Config.pendingQueueTarget) break;
      final note = byPath[path];
      if (note == null) continue;

      final generated = await _llm.generate(
        notePath: path,
        noteContent: note.content,
        targetMix: _targetMix,
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
