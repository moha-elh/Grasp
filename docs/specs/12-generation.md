# 12 · Background generation pipeline

**Branch:** `feat/generation`
**Status:** done (orchestration); feeds the app once persistence is wired

## How to run / test it

Generation talks to real services, so it needs the backend live:

1. **Supabase schema applied** - run `supabase/schema.sql` in the Supabase SQL
   editor (creates `cards`, `review_logs`, `note_coverage`, RLS, `record_review`).
2. **`.env` filled** - `SUPABASE_URL`, `SUPABASE_KEY`, `DROPBOX_APP_KEY`,
   `GROQ_API_KEY`.
3. **Signed in** (an account exists) and **Dropbox connected** with notes tagged
   `#flashcard` in the scoped folder. On device:
   ```powershell
   flutter run -d chrome     # or a real device for Dropbox
   ```

It runs automatically once on entering the shell. To trigger it by hand and
watch the result: **Settings → Content → Generate cards now** (shows
"Added N cards last run" or the error).

Verify the rows in the Supabase dashboard (`cards` where `status = pending`).

## What this delivers

Background card generation (FR-7 to FR-13). The orchestrator ties together the
services that already existed:

- **Coverage-aware rotation** - `CoverageRepository.nextToGenerate` orders
  eligible notes so never-carded, then oldest-generated notes come first.
- **Bounded queue** - stops once `pending >= Config.pendingQueueTarget` (30), so
  the user is never flooded; decoupled from review.
- **Per note:** download from Dropbox → `LlmService.generate` (the FR-13 prompt,
  target mix Anchor 25 / Mechanism 50 / Application 25) → store as `pending`
  via `CardsRepository.insertGenerated` (FSRS state seeded) → mark coverage.
- **Triggers:** auto once on shell entry (no-op when signed out / queue full),
  plus a manual button in Settings with live status.

## Key files

- `lib/data/services/generation_service.dart` - the orchestrator (`runPass`).
- `lib/features/generation/generation_controller.dart` -
  `generationServiceProvider`, `generationControllerProvider` (idle/running/
  done/error), guarded so it's a quiet no-op without a signed-in Supabase client.
- `lib/features/shell/app_shell.dart` - auto-trigger on entry (now a
  `ConsumerStatefulWidget`).
- `lib/features/settings/settings_screen.dart` - manual trigger + status.
- Reused as-is: `DropboxService.eligibleNotes`, `LlmService`, the FR-13 prompt,
  `CardsRepository`, `CoverageRepository`.

## Verified

- `flutter analyze` clean (2 pre-existing info lints in `cards_repository.dart`).
- `flutter test` - 8 pass (generation trigger guarded so the widget test, which
  has no Supabase, stays green).
- End-to-end DB write needs the live backend + real vault (see above); not
  exercisable from the web mock harness.

## What's next (persistence)

Generated cards land in Supabase but the **vetting / review / deck screens still
read mock providers**. The next feature swaps those for the `CardsRepository`
queries (`pendingToVet`, `dueCards`, `newCards`, `remakePile`) and persists
grades/status/quality, so the generated cards actually flow through the app.
