# 05 · Retention analytics (screens 08 / 09)

**Branch:** `feat/retention-analytics`
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

Skip Dropbox, clear the session (or wait for the tab bar), then tap **Retention**.

## What this delivers

The Retention tab — retention-focused, not a productivity scoreboard
(FR-27→FR-30) — over an in-memory approved deck (5 concepts). Two screens:

- **08 — Retention:** dual ring (CAN NAME = anchor retrievability, CAN EXPLAIN
  = mechanism retrievability); the 90-day trend in its "not enough history yet"
  empty state (FR-30 defers it until 14 days of logs exist); concept rows sorted
  by **widest name/mechanism gap first**, each with a gap chip → tap opens detail.
- **09 — Concept detail:** per-concept dual ring, a by-type breakdown (Naming /
  Mechanism / Application bars), the weakest cards, and a **"seen N× ·
  retrievability X%"** detail line — with the "cards may be too fat, split them"
  reading when recall is low despite many views (FR-29). Primary action: Open note.

## Design deviation (per request)

The design system spec says the inner ring takes the health color. Per the
user's request, **each ring now uses a distinct fixed color** — outer (name) =
accent blue, inner (explain) = violet (`T.ringExplain`) — so the two arcs never
blend when both are high. Health color still drives the by-type bars, the
weakest-card beads, and the gap chip.

## Key files

- `lib/features/retention/mock_deck.dart` — `deckProvider` (approved cards with
  seeded FSRS state). Replace with a `CardsRepository` `status = approved` query.
- `lib/features/retention/analytics.dart` — pure rollup: `computeDeckStats` →
  `DeckStats` / `ConceptStats` (name/explain means, per-type means, gap, seen);
  `deckStatsProvider`.
- `lib/features/retention/widgets/dual_ring.dart` — two-arc `CustomPainter`.
- `lib/features/retention/retention_screen.dart` — screen 08.
- `lib/features/retention/concept_detail_screen.dart` — screen 09.
- `lib/design/tokens.dart` — `ringName` / `ringExplain`.

## Verified

- `flutter analyze` clean (2 pre-existing info lints in `cards_repository.dart`).
- `flutter test` — 6 pass, incl. `analytics_test` (concepts sort by widest gap;
  deck means in range; anchors recall above mechanisms in the fixture).

## What's next

- **The 90-day curve** — needs persisted review logs (weekly buckets, recalled =
  rating 3/4). Build the real chart once history exists (post-auth).
- Wire to the real `approved` deck (swap `mock_deck.dart`) once auth lands.
- Remake pile (screen 10) — reachable from Retention.
- Settings (screen 12): new-card throttle, Dropbox status, sign-out.
