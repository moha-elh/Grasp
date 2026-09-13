# 01 · Design system + app shell

**Branch:** `feat/design-system-shell`
**Status:** done

## What this is
Translates the design system (`docs/Grasp Design System.dc.html`) into Flutter
tokens + theme, and builds the Session · Retention · Explore navigation shell
everything else renders into. No auth, no data — pure UI foundation.

## What was done
- **`lib/design/tokens.dart`** — the porcelain palette, spacing (4·8·12·18·24·32),
  radius (card 22 / control 16 / pill / badge 4), the single card shadow, motion
  durations, hit targets, and `T.health(retrievability)` (≥.80 solid / .50–.79
  softening / <.50 slipping). oklch colors were precomputed to sRGB hex.
- **`lib/design/typography.dart`** — Fugaz One (display/numbers only, clamped
  13–56), Work Sans (body/UI), IBM Plex Mono (labels/intervals), via
  `google_fonts`. Roles match §02 (answer 22/1.45, concept name 19/1.2, etc.).
- **`lib/design/theme.dart`** — `buildGraspTheme()`: light-only M3 theme, ground
  background, ink primary, hairline dividers.
- **`lib/design/widgets/type_badge.dart`** — outline-only badges for card type
  (FR-8) + remake/pending states.
- **`lib/features/shell/app_shell.dart`** — IndexedStack + custom bottom tab bar
  (sunk surface, hairline top, ink-active), with a hook to hide the bar during
  an active session (§14).
- **`lib/features/{session,retention,explore}/*_screen.dart`** — placeholder
  screens that exercise the theme so it's visibly validated.
- `app.dart` now mounts the theme + shell.

## Verification
- `flutter analyze` — clean (2 pre-existing info lints in cards_repository).
- `flutter test` — shell boot test + FSRS tests pass.
- On device: fonts fetch via google_fonts on first launch.

## What's next
Sign-in is deferred to last (user's call). Recommended next feature branch:
**Dropbox connect + note reading** (screen 01, FR-1→FR-3) — has its own OAuth,
independent of Supabase auth, and unblocks background generation. After that the
**review loop** (screens 02/03) can be built against mock data, then wired to
Supabase once sign-in exists.

Components still to build with their features: study card (stacked), grading
chips, concept row, dual ring + 90-day curve charts, source-note sheet.
