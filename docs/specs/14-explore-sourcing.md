# 14 · Explore real sourcing

Replaces the hard-coded Explore feed with real candidates built from what the
user already studies: adjacent concepts authored by the LLM, plus web-sourced
cards that carry a genuine cited URL.

## Run / stop the app

Explore now loads from the network, so a full run is best:

```powershell
flutter run -d <device-id>
```

Web cards need a Tavily key in `.env` (`SEARCH_API_KEY`); without it, the feed
still shows adjacent-concept cards and web sourcing silently skips.

## What changed

- `SearchService` (Tavily) returns real web hits with URLs. Trust layer: every
  web card cites a real source, never an LLM-invented one (FR-20).
- `LlmService.authorExplore` authors ONE card, either an adjacent concept or a
  card built strictly from web source text. Shares a `_chat` round-trip with
  `generate`. Prompt lives in `generation_prompt.dart` (`exploreSystemPrompt` /
  `explorePrompt`).
- `ExploreService` seeds from the approved deck's concept names, requests a few
  adjacent + a few web candidates. Web is best-effort: a missing key or failed
  query never blocks the adjacent cards.
- `ExploreController` now loads on open with `loading` / `error` state (was a
  hard-coded `_seed`). File renamed `mock_explore.dart` -> `explore_feed.dart`.
  Verify still persists an approved, explore-sourced card (from feature 13a).

## Flow

1. Open Explore -> service reads your approved concepts, authors adjacent cards,
   searches the web per concept, authors one card per hit with its URL.
2. Verify promotes a candidate into Retention as an `approved` NEW card.
3. Dismiss drops it from the feed.

## Not yet

- Adjacency is LLM-proposed from concept NAMES, not embeddings over note bodies.
  Good enough for exposure; swap in a vector index if quality needs it.
- No dedup against cards you already have; a proposed concept could overlap an
  existing one.
