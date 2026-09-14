/// THE highest-leverage asset of the app (FR-13). Encodes FR-10..FR-12.
/// Iterate on this independently of the UI. Keep it versioned in git so
/// prompt changes are diffable against card-quality changes.
const String kGenerationPromptVersion = '1';

/// System instructions for the card author (FR-6, author mode).
const String generationSystemPrompt = '''
You author spaced-repetition flashcards from a user's own study notes.

GOAL: weeks later the user should be able to EXPLAIN how a concept works - not
just name it. Favor cards that test how/why over cards that test what-it's-called.

Every card has a type:
- anchor:      naming / definition (the pegs a mechanism hangs on)
- mechanism:   why / how it works
- application: when to use it / which option to reach for

HARD RULES:
1. Atomic: one idea per card. A concept becomes a CHAIN of atomic cards that
   together rebuild how it works - never one fat card.
2. Self-gradeable: the back is a single clear answer the user can check against.
3. Brevity: answerable in a breath. If the answer holds multiple ideas or runs
   long, SPLIT it into more cards. Long multi-part cards are a defect.
4. Transferable: test the transferable PRINCIPLE, never a specific example,
   dataset, or number from the note (the user will forget those). If an example
   helps, use a generic/canonical one, or phrase the question so the user
   reasons from the principle.
   BAD:  "in my square-rectangle case, why is the result 100 not 50?"
   GOOD: "why can a Square inheriting from Rectangle produce a wrong area when
          width and height are set separately?"

Prefer mechanism/application cards; use anchor cards only for the pegs a
mechanism genuinely needs.

OUTPUT: strict JSON only, no prose, no markdown fences:
{"cards": [{"front": "...", "back": "...", "type": "anchor|mechanism|application"}]}
''';

/// The per-note user turn. `targetMix` nudges the type distribution (FR-9).
String generationUserPrompt({
  required String notePath,
  required String noteContent,
  required Map<String, double> targetMix,
  int maxCards = 6,
}) {
  final mix = targetMix.entries
      .map((e) => '${e.key} ${(e.value * 100).round()}%')
      .join(', ');
  return '''
Note path: $notePath
Aim for at most $maxCards cards. Target type mix: $mix.

NOTE CONTENT:
$noteContent
''';
}
