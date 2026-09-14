# 13 · Persistence wiring

Replaces the in-memory mock providers with real Supabase-backed queries, so the
cards you generate actually flow through vetting → review → Retention, and every
grade/status change is persisted.

## Run / stop the app

From the project root (`C:\Users\mohsi\Desktop\Projects\flashMemo`):

```powershell
flutter run -d <device-id>   # e.g. flutter run -d R8YY80GL0FY
```

In the running session: `r` hot reload, `R` hot restart, `q` quit. This feature
touches only Dart, so a hot restart (`R`) picks it up; no rebuild needed.

Requires the backend from `docs/testing-on-mobile.md` step 0 (schema deployed,
signed in, Dropbox connected, at least one `#flashcard` note).

## What changed

Every screen now reads the real `cards` table (RLS-scoped to the signed-in user)
instead of a hard-coded list. The mock files are gone
(`mock_pending.dart`, `mock_cards.dart`, `mock_deck.dart`).

| Screen | Reads | Persists |
|--------|-------|----------|
| Vetting | `CardsRepository.pendingToVet()` | accept → `approved`, discard → `discarded`, edit → wording + `approved` |
| Review | `dueCards()` (in full) + `newCards(limit)` (throttled by the settings knob) | grade → FSRS state + review log in one `record_review` RPC; flag → `disliked` + `remake_pending` |
| Retention | `approvedDeck()` → `computeDeckStats` | — (read-only analytics) |
| Remake pile | `remakePile()` | keep → `approved`, delete → `discarded`, regenerate all → back to `pending` |

## Design

- **Controllers load their own data.** Each `StateNotifier` (vetting, session,
  remake) fetches from its repo in the constructor and exposes `loading` / `error`
  on its state. Screens show a spinner while loading and a message on error,
  instead of silently rendering an empty queue. A `.seeded(...)` constructor
  keeps them unit-testable without Supabase.
- **Retention is a `FutureProvider`.** `deckStatsProvider` awaits the approved
  deck and computes stats; `RetentionScreen` renders it with `.when`.
- `computeDeckStats` stays pure (still unit-tested against a fixed fixture).

## End-to-end flow

1. Background generation writes cards as `pending`.
2. Open **Session** → the pending batch is vetted first; accepted cards become
   `approved` and review-ready.
3. Approved-but-unseen cards appear as **new** cards (capped by the daily knob);
   due cards are always served in full.
4. Grading updates FSRS state and appends a review log atomically.
5. **Retention** rolls the approved deck up by concept; **flagging** a bad card
   parks it in the **Remake pile**.

## Not yet

- Grades/status writes are fire-and-forget (snappy between cards); a failed
  write is not surfaced. Add a retry/queue if it proves lossy on flaky networks.
- Remake "regenerate all" resets cards to `pending` for re-vetting; wiring it to
  actual LLM re-generation is future work.
- The 90-day retention curve still waits on accumulated review-log history.
