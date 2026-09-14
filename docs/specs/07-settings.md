# 07 · Settings (screen 12)

**Branch:** `feat/settings`
**Status:** done

## How to run the app yourself

From the project root (`C:\Users\mohsi\Desktop\Projects\flashMemo`):

```powershell
flutter run -d chrome
#   or: flutter run -d web-server --web-port 5610  → open the printed URL
```

**To stop it:** press `q` in the terminal (or `Ctrl+C`). Port stuck? use `--web-port 5611`.

**Note:** newly-added files need a full recompile — a browser hard-reload isn't
enough. Press **`R`** (hot restart) in the `flutter run` terminal, or `q` then
`flutter run` again.

Reach it from the **Retention** tab → the **gear icon** (top-right).

## What this delivers

Settings (screen 12, FR-8 / FR-17):

- **New cards per day** — the only session-sizing knob (FR-17), a 5–30 slider
  defaulting to 10, with the load tradeoff spelled out (more now = heavier
  review load later).
- **Read-only reminder:** due reviews are always served in full and never capped.
- **Dropbox status** — connection phase (Connected / Not connected / Error),
  the scoped notes folder, tagged-note count when known, and a Disconnect link.
- **Generation mix** — read-only target proportions (Anchor 25 / Mechanism 50 /
  Application 25), mechanism-weighted toward the explaining goal.
- **Sign out** — present but inert for now (snackbar): auth is the last thing to
  wire.

## Key files

- `lib/features/settings/settings_controller.dart` — `newCardsPerDayProvider`
  (`StateProvider<int>`, default `Config.defaultNewCardsPerDay`). In-memory;
  persist to Supabase / shared_preferences later.
- `lib/features/settings/settings_screen.dart` — screen 12.
- `lib/features/retention/retention_screen.dart` — gear entry point in the header.

## Verified

- `flutter analyze` clean (2 pre-existing info lints in `cards_repository.dart`).
- `flutter test` — 7 pass (no new test: the screen is display + a state knob,
  no branching logic worth a unit test).

## What's next

- **Persist the throttle** and feed it into the session queue's new-card cap
  (currently the queue is mock). Needs the real session builder + storage.
- **Sign-in + persistence (the deferred "last bit")** — wire real auth, then
  turn every mock provider (session, vetting, deck, remake) into
  Supabase-backed queries and activate Sign out here.
- Explore tab (screen 11, Phase 1b) — adjacency + web-sourced cited cards.
