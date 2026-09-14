# 08 · Explore tab (screen 11)

**Branch:** `feat/explore`
**Status:** UI done (mock feed) — Phase 1b adjacency/web sourcing pending

## How to run the app yourself

From the project root (`C:\Users\mohsi\Desktop\Projects\flashMemo`):

```powershell
flutter run -d chrome
#   or: flutter run -d web-server --web-port 5610  → open the printed URL
```

**To stop it:** press `q` in the terminal (or `Ctrl+C`). Port stuck? use `--web-port 5611`.

**Note:** new files need a recompile — press **`R`** (hot restart) in the
`flutter run` terminal, or `q` then `flutter run` again. Open the **Explore** tab.

## What this delivers

The Explore tab (FR-19, FR-20) — *candidates for exposure, not memory*. Over a
mock feed for now:

- **Cards** mixing **adjacent concepts** (semantic neighbours of the user's
  notes) and **web-sourced** material, each with a distinct kind badge
  (ADJACENT amber / WEB blue) and a card-type badge.
- **A visible source on every card** (the citation panel) — a card without one
  is a bug (FR-20 trust gate).
- **Verify → add to Retention** — the trust gate's single-action quick path
  (FR-20); plus Dismiss. The intro copy still points to the **stronger path**:
  dive in, write a note, let the `#flashcard` tag flow it in on its own.
- Empty state when the feed is cleared.

## Also in this branch

Concept-detail graph colors (separate commit): the by-type bars now use one
**distinct** design-system color each — Naming = blue (outer ring), Mechanism =
amber `oklch(.62 .14 60)` (inner ring), Application = app green — so they no
longer share the health color.

## Key files

- `lib/features/explore/mock_explore.dart` — `ExploreItem` /
  `exploreFeedProvider` / `ExploreController` (`verify`, `dismiss`). Replace the
  seed with adjacency (embeddings over the vault) + web-sourced cited cards.
- `lib/features/explore/explore_screen.dart` — screen 11.

## Verified

- `flutter analyze` clean (2 pre-existing info lints in `cards_repository.dart`).
- `flutter test` — 8 pass, incl. `explore_controller_test` (verify/dismiss each
  remove one item).

## What's next (Phase 1b proper)

- **Adjacency:** embeddings over the `#flashcard` vault to surface true semantic
  neighbours (not a hand-written seed).
- **Web sourcing:** fetch + cite real new material (every card keeps a real URL).
- **Verify wiring:** promote a verified card into Retention as an approved
  `source = explore` card (keeping its `reference_url`) — needs auth + persistence.
- Then the deferred **sign-in + persistence** turns every mock provider real.
