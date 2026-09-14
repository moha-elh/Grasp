# 03 · Review loop (screens 02 / 03 / 07)

**Branch:** `feat/review-loop`
**Status:** done

## How to run the app yourself

From the project root (`C:\Users\mohsi\Desktop\Projects\flashMemo`):

```powershell
# Chrome (opens a browser window, hot reload with 'r'):
flutter run -d chrome

# Or a plain web server (open the printed URL yourself):
flutter run -d web-server --web-port 5610
#   → then open http://127.0.0.1:5610 in Chrome
```

**To stop it:** press `q` in the terminal where it's running (or `Ctrl+C`).
If a port is stuck as "already in use", pick another (`--web-port 5611`).

On web, use **"Skip for now (debug)"** on the Dropbox screen to reach the shell.
The app boots straight into a Session with 4 mock cards.

## What this delivers

The daily review loop (FR-16, FR-21→FR-26) against in-memory mock cards —
fully testable before sign-in / Supabase land. Three design-system screens:

- **02 — question:** stacked study card, recall bead colored by retrievability
  (`T.health`), reconstruct prompt, "TAP TO REVEAL".
- **03 — revealed:** answer + `TypeBadge`, "Source note" link (read-only bottom
  sheet showing the excerpt + path), and four grading chips.
- **07 — session complete:** counts reviewed / flagged, next-due line, one
  "you're done" sentence. No streak, no confetti.

Grading chips show **real FSRS interval previews** (Again / Hard / Good / Easy),
computed from the card's current state. "Badly made card? Flag it" removes the
card to the remake pile and shows the FR-25 rule (dislike = badly made, never
because it's hard). The tab bar hides while a session is active (§14) and
returns on the complete/empty screen.

## Key files

- `lib/features/review/mock_cards.dart` — `sessionQueueProvider` (4 seeded
  `GraspCard`s). Replace with a `CardsRepository`-backed query later; UI unchanged.
- `lib/features/review/session_controller.dart` — `SessionController`
  (`reveal` / `grade` / `flag` / `restart`), `SessionState`.
- `lib/features/review/widgets/study_card.dart` — stacked card + reveal.
- `lib/features/review/widgets/grading_chips.dart` — 4 chips + flag link.
- `lib/features/review/session_complete_view.dart` — screen 07.
- `lib/features/session/session_screen.dart` — runs the loop, drives the shell.
- `lib/data/services/fsrs_service.dart` — added `previewIntervals()`.
- `lib/design/format.dart` — `formatInterval(Duration)` ("10m", "2d", "3mo").

## Verified

- `flutter analyze` clean (2 pre-existing info lints in `cards_repository.dart`).
- `flutter test` — 4 pass, incl. `previewIntervals` ordering (Again < Good ≤ Easy).
- Web: revealed a card, saw four interval labels, graded to the complete view,
  confirmed tab bar hides mid-session and returns; flag shows the rule + drops
  the card.

## What's next

- **Persistence (needs auth):** `grade`/`flag` have `// TODO(auth)` — wire
  `FsrsService.review` → `ReviewsRepository.record` and
  `CardsRepository.setQuality` once sign-in exists. Then swap `mock_cards.dart`
  for the real due/new query.
- Swipe vetting of the pending queue (screens 05 / 06).
- Retention analytics (screens 08 / 09) — the currently-empty second tab.
- Remake pile (screen 10).
