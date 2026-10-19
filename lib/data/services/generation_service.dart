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
  Future<Map<String, double>> targetMix() async {
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
  /// is the user's target for the whole pass (the "Cards per pass" setting),
  /// and the pass adds exactly that many unless every note runs dry.
  /// [notesPerPass] only sets the per-note cap (so no single note is stuffed);
  /// the pass cycles through the notes, least-covered first, until the target
  /// is met or a full round adds nothing. Each call is shown the note's
  /// existing card fronts, so revisiting a note yields new ideas, not repeats.
  Future<int> runPass({
    required String userId,
    int cardsTotal = Config.defaultCardsPerGeneration,
    int notesPerPass = Config.generationNotesPerPass,
  }) async {
    // Only gate the START of a pass on the pending cap, so a pass that runs
    // always delivers its full size instead of stopping at a random count.
    if (await _cards.pendingCount() >= Config.pendingQueueTarget) return 0;

    // Download in rotation order (least recently visited first) only until
    // [Config.notesScannedPerPass] tagged notes are in hand. Untagged notes
    // are stamped as visited so they rotate to the back and get re-checked
    // (for a newly added tag) once per lap, not on every pass.
    final byPath = <String, VaultNote>{};
    for (final path in await _coverage.nextToGenerate(await _dropbox.notePaths())) {
      if (byPath.length >= Config.notesScannedPerPass) break;
      final content = await _dropbox.downloadNote(path);
      if (content.contains(Config.flashcardTag)) {
        byPath[path] = VaultNote(path, content);
      } else {
        await _coverage.markGenerated(userId, path, 0);
      }
    }
    if (byPath.isEmpty) return 0;
    final order = byPath.keys.toList();

    final maxPerNote = (cardsTotal / notesPerPass).ceil();
    final targetMix = await this.targetMix();
    var budget = cardsTotal;
    var added = 0;
    // A mature vault answers "nothing new" a lot; bound the LLM calls so a
    // pass can't sweep hundreds of notes into the rate limit.
    // ponytail: flat cap, smarter would skip notes recently found exhausted.
    var calls = cardsTotal;
    try {
      while (budget > 0 && calls > 0) {
        final before = added;
        for (final path in order) {
          if (budget <= 0 || calls-- <= 0) break;
          final note = byPath[path]!;
          final existing = await _cards.frontsForNote(path);
          final seen = existing.map(_norm).toSet();
          final generated = (await _llm.generate(
            notePath: path,
            noteContent: note.content,
            targetMix: targetMix,
            maxCards: budget < maxPerNote ? budget : maxPerNote,
            existingFronts: existing,
          ))
              .where((c) => seen.add(_norm(c.front))) // drop exact repeats
              .take(budget) // the model sometimes overshoots "at most N"
              .toList();
          await _coverage.markGenerated(userId, path, generated.length);
          if (generated.isEmpty) continue;
          await _cards.insertGenerated(
            userId: userId,
            sourcePath: path,
            sourceExcerpt: _excerpt(note.content),
            cards: generated,
            fsrs: _fsrs,
          );
          added += generated.length;
          budget -= generated.length;
        }
        if (added == before) break; // every note is covered; nothing new left
      }
    } catch (_) {
      // Keep what a partly-finished pass already stored; only a pass that
      // produced nothing surfaces the error (e.g. Groq rate limit).
      if (added == 0) rethrow;
    }
    return added;
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  /// A short trust-layer snippet of the note (FR-20), whitespace-collapsed.
  String _excerpt(String content, {int max = 280}) {
    final flat = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= max ? flat : '${flat.substring(0, max)}...';
  }
}
