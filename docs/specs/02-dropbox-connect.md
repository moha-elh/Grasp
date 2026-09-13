# 02 · Dropbox connect + note reading

**Branch:** `feat/dropbox-connect`
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

Notes:
- First web build takes ~30–60s; later reloads are instant.
- On **web**, "Connect Dropbox" fails on purpose — OAuth uses a mobile
  custom-scheme redirect (`grasp://auth`) browsers can't handle. Use the
  **"Skip for now (debug)"** link to reach the shell. Real connect works only
  on an Android/iOS build.
- Requires `.env` filled (SUPABASE_URL/KEY at minimum) or `main()` throws on boot.

---

## What this is
Screen 01 (FR-1 → FR-3): connect the Dropbox account holding the Obsidian vault
and read the `#flashcard`-tagged notes. Read-only; the vault is never written to.

## What was done
- **`lib/features/dropbox/dropbox_controller.dart`** — Riverpod state machine:
  `checking → disconnected → connecting → scanning → connected/error`, with
  scope-error detection (App-folder vs Full Dropbox, FR-3).
- **`lib/features/dropbox/dropbox_connect_screen.dart`** — one explanation, the
  "why full access" note, one button, plus scanning/error states. A debug-only
  "Skip for now" bypass so the shell is reachable on web/dev.
- **`lib/design/widgets/primary_button.dart`** — shared ink primary button
  (52 tall, radius 16) with a busy spinner.
- **`app.dart`** — now gates on Dropbox connection before showing the shell.
- Note reading itself already existed in `DropboxService.eligibleNotes()`
  (recursive list + `#flashcard` filter); the scan drives the connected count.

## Verification
- `flutter analyze` — clean (2 pre-existing info lints in cards_repository).
- Web: connect screen + error + skip-through to shell confirmed.
- Real OAuth + note scan: verify on an Android/iOS build (needs the Dropbox app
  key with Full Dropbox scope and `grasp://auth` as a redirect URI).

## What's next
**Review loop** (screens 02/03) against mock cards — the study card (stacked),
tap-to-reveal, grading chips with FSRS interval previews, and flag-it (FR-22,
FR-24, FR-25). Wire to Supabase once sign-in lands.
