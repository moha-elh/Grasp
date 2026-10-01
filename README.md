# Grasp

A personal spaced-repetition app that turns your own notes into flashcards and
schedules them with FSRS, with a focus on retention over raw card counts.

- **Notes in, cards out.** Reads tagged notes from Dropbox and authors cards
  from them with an LLM (Groq).
- **FSRS scheduling.** Due reviews are always served in full; new cards are
  throttled by a daily cap.
- **Vet before you study.** Generated cards land in a Vet tab to accept, edit,
  or discard before they enter the deck.
- **Explore.** Suggests cards on topics adjacent to your notes, some built from
  real web results with citations (Tavily).
- **Retention view.** Name / explain / apply rings, a 90-day trend, a review
  streak grid, and per-concept gaps sorted widest-first.

## Stack

Flutter + Riverpod, Supabase (Postgres + Auth + RLS), FSRS (`fsrs` package),
Dropbox OAuth (PKCE). The LLM and web-search keys live in Supabase Edge
Functions, never in the app.

## Setup

1. **Env.** Copy the template and fill it in:
   ```
   cp .env.example .env
   ```
   You need `SUPABASE_URL`, `SUPABASE_KEY` (the publishable key, not the secret
   one), and `DROPBOX_APP_KEY`. The Groq and Tavily keys are NOT stored here.

2. **Edge Functions.** Deploy the two proxies that hold the sensitive keys and
   set their secrets. See [`supabase/functions/README.md`](supabase/functions/README.md).
   Until these are deployed, card generation and Explore web cards will fail;
   the review loop, vetting, and analytics work regardless.

3. **Run.**
   ```
   flutter pub get
   flutter run
   ```

## Build a release APK

```
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`. The default config signs
with the debug key, which is fine for sideloading onto your own device; set up a
release keystore before distributing.

## Develop

```
flutter analyze
flutter test
```

The product requirements and screen specs live in [`docs/`](docs/)
(`grasp-requirements-spec.md` and `docs/specs/`).
