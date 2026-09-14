# 04 · Swipe vetting (screens 05 / 06)

**Branch:** `feat/swipe-vetting`
**Status:** done (swipe gesture pending on-device verification)

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

On web, use **"Skip for now (debug)"** on the Dropbox screen. The session now
opens with **vetting** first, then flows into the review loop.

## What this delivers

Unified swipe vetting (FR-14, FR-15) woven into the front of the daily session,
against in-memory mock pending cards — testable before background generation /
auth land. Two design-system screens:

- **05 — swipe vetting:** a bounded batch (header `Vet N` + dot row of what
  remains). Both front and back visible, type badge + `PENDING` badge from the
  start. Card follows the finger with a 12° max tilt; edges tint green (accept)
  / red (discard). Right = accept, left = discard, up = accept + edit. **Three
  mirror buttons (Discard / Edit / Accept) do the same** — no infinite feed.
- **06 — wording editor:** swipe-up / Edit opens a bottom sheet to edit
  front + back, then "Save & accept".

When the batch is cleared it rolls straight into the review loop (screens
02/03/07). The tab bar stays hidden across both phases (§14).

## Known limitation

**Swipe/pan gestures are unreliable with a mouse on web** — they need a real
touch device to verify and tune. The **mirror buttons are the working path**
everywhere, so the flow is fully usable on the laptop today; swipe-gesture
tuning is deferred to on-device testing (when the phone is connected).

## Key files

- `lib/features/vetting/mock_pending.dart` — `pendingQueueProvider` (3 pending
  `GraspCard`s). Replace with a `CardsRepository` `status = pending` query later.
- `lib/features/vetting/vetting_controller.dart` — `VettingController`
  (`accept` / `discard` / `acceptEdited`), `VettingState`.
- `lib/features/vetting/widgets/vetting_card.dart` — draggable card, tilt, hints.
- `lib/features/vetting/vetting_view.dart` — header, dot row, mirror buttons,
  wording-editor sheet (screen 06).
- `lib/features/session/session_screen.dart` — vetting phase before review.
- `lib/data/models/card.dart` — `copyWith` now takes `front`/`back` (editor).

## Verified

- `flutter analyze` clean (2 pre-existing info lints in `cards_repository.dart`).
- `flutter test` — 5 pass, incl. a vetting-controller test (accept/discard
  advance + count, edit rewrites wording then accepts, no-op past the end).
- Web: vetted the batch via the buttons + wording editor, rolled into review,
  reached "Done for today"; tab bar hidden throughout. Swipe drag renders/tilts
  but pan recognition on web mouse is unreliable — deferred to device.

## What's next

- **On device:** verify/tune the swipe gesture (right/left/up thresholds, fling
  animation). Then wire persistence (needs auth): accept/discard/edit have
  `// TODO(auth)` — `CardsRepository.setStatus` / update, and swap
  `mock_pending.dart` for the real bounded `pending` query (FR-15).
- Retention analytics (screens 08 / 09) — the currently-empty second tab.
- Remake pile (screen 10).
