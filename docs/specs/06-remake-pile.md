# 06 · Remake pile (screen 10)

**Branch:** `feat/remake-pile`
**Status:** done

## How to run the app yourself

From the project root (`C:\Users\mohsi\Desktop\Projects\flashMemo`):

```powershell
flutter run -d chrome
#   or: flutter run -d web-server --web-port 5610  → open the printed URL
```

**To stop it:** press `q` in the terminal (or `Ctrl+C`). Port stuck? use `--web-port 5611`.

Skip Dropbox, clear the session (or wait for the tab bar), open **Retention** →
tap the **Remake pile** row.

## What this delivers

The Remake pile (FR-26): cards the user flagged as **badly made** (dislike, never
"too hard") are parked as `remake_pending` and cleared in **one batch** — never
mid-session. Regenerated cards re-enter through swipe vetting.

- **Entry point:** a "Remake pile · N flagged" row on the Retention tab
  (screen 10 is reachable from Retention only, never surfaced during a session).
- **Screen 10:** the flagged cards in a list (REMAKE badge, concept, front +
  back), one "Regenerate all (N)" batch button, and a "nothing to remake" empty
  state. Mock cards illustrate the two defect kinds (too-broad, too-vague).

## Key files

- `lib/features/remake/remake_controller.dart` — `remakePileProvider` +
  `RemakePileController.regenerateAll()`. Mock seed; `regenerateAll` is stubbed
  to empty the pile.
- `lib/features/remake/remake_pile_screen.dart` — screen 10.
- `lib/features/retention/retention_screen.dart` — the entry-point row.

## Verified

- `flutter analyze` clean (2 pre-existing info lints in `cards_repository.dart`).
- `flutter test` — 7 pass, incl. `remake_controller_test` (regenerateAll empties
  the pile).

## What's next

- **Wire the loop for real (needs auth + generation):** flagging an approved card
  in the review loop already has a `// TODO(auth)` to set `remake_pending`; this
  screen's `regenerateAll` has a `// TODO(gen)` to LLM-regenerate each card into
  `pending` (re-entering vetting). Swap the mock seed for a
  `CardsRepository` `status = remake_pending` query.
- Settings (screen 12): new-card throttle, Dropbox status, sign-out.
- Sign-in + persistence (the deferred "last bit").
