# Software Requirements Specification — Grasp
**Name:** *Grasp*
**Author:** Moha (Mouhssine El Haouary)
**Version:** 1.2 — 2026-09-13
**Type:** Personal mobile application (single user)

---

## 1. Overview & Vision

A mobile application that turns notes the user has **already written** into a durable habit of not forgetting them.

The app reads the user's personal Obsidian knowledge base, uses AI to generate spaced-repetition flashcards from it, and drills them so that concepts are **retained and understood over the long term** — not merely recognized.

The guiding one-line definition of the product:

> *A tool that turns notes you've already written into a habit of not forgetting them.*

This is a **behavioral** tool (does the user retain knowledge?), not an **organizational** one (are the notes nicely stored?). Every design decision is judged against that distinction.

---

## 2. Primary Objective

The single success target, in the user's own words:

> *"Weeks after I study something, I can explain the concept to someone — not just remember the names of things, but how they actually work."*

This is a **transfer / mechanism** goal, not a **recognition** goal. It has a direct consequence for the whole design: the app must favor cards that test *how and why* something works, not cards that test *what something is called*.

---

## 3. User & Context

- **User:** single user (the author). No multi-tenant, no social features.
- **Existing workflow:** notes authored in Obsidian on PC, synced PC ↔ mobile via **Remotely Save + Dropbox**.
- **Devices:** primarily reviewed on mobile; notes authored on PC.

---

## 4. Scope

### In scope (v1)
Reading tagged notes from Dropbox, **automatic background** AI card generation, a unified swipe-based vetting flow, a spaced-repetition review loop, per-card quality feedback, retention-focused analytics, **and both tabs — Notes (Retention) and Explore.**

### Out of scope (v1, deferred)
Image / vision-based generation, automatic generator self-tuning beyond the basic mix adjustment, long-range trend charts, and interactive (turn-by-turn) decomposition. See §11.

---

## 5. Functional Requirements

### 5.1 Data Source (Notes)
- **FR-1** — The app reads notes from the user's Obsidian vault via the **Dropbox API** (OAuth). Dropbox is the single source of truth.
- **FR-2** — Notes are read from the path **`/Applications/remotely-save/Knowledge/6 - Main Notes`**, filtered to notes carrying the **`#flashcard` tag**. The folder scopes what is read; the tag is the per-note opt-in.
- **FR-3 — Dropbox access scope (critical):** Remotely Save stores the vault inside its **own Dropbox App folder** (`/Applications/remotely-save/…`). The app's Dropbox integration must therefore be registered with **Full Dropbox access**, *not* App-folder access — an app-folder-scoped app can only see its own sandbox and cannot read Remotely Save's folder.
- **FR-4** — Notes are treated as **read-only**. The app never writes back to the vault.
- **FR-5 — Text-only (v1).** Embedded images (code screenshots, diagrams) are **not** processed. Caveat: notes whose content lives only inside images will produce thin or no cards; vision/OCR is deferred.

### 5.2 Card Generation (AI)
- **FR-6** — The AI **authors** flashcards from a note's content (author mode).
- **FR-7 — Automatic background generation.** The user **never selects notes**. The app generates on its own: it rotates through the eligible notes (**coverage-aware** — prioritizing notes not yet carded or under-carded), takes 1–2 notes at a time, generates a small set of cards, and stores them in Supabase as `pending`. Generation is **decoupled from review** — it runs ahead and fills a **bounded queue**, pausing when enough pending cards exist so the user is never flooded.
- **FR-8** — Every card carries a **type** attribute (small enum):
  - `anchor` — naming / definition (the pegs a mechanism hangs on)
  - `mechanism` — why / how it works
  - `application` — when to use it / which option to reach for
- **FR-9 — Mix ratio.** Generation starts at **33% / 33% / 33%** across the three types and **self-adjusts over time** based on the user's like/dislike signal (§5.7).
- **FR-10 — Atomic & reconstructive.** Cards must be **atomic** (one idea), **self-gradeable**, and **reconstructive**: a concept is expressed as a *chain* of atomic cards that together rebuild how it works, not one large card.
- **FR-11 — Brevity.** A card must be answerable in a breath. If the answer runs long or holds multiple ideas, the generator **splits it** into smaller cards. Long, multi-part cards are a defect.
- **FR-12 — Transferable & example-independent.** A card must test the **transferable principle**, never a specific example, dataset, or numbers taken from the note (which the user will forget). When an example helps, the generator uses a **generic / canonical** one or phrases the question so the user reasons *from the principle*.
  *Example:* not *"in my square-rectangle case, why is the result 100 not 50?"* but *"why can a Square inheriting from Rectangle produce a wrong area when width and height are set separately?"*
- **FR-13** — The **generation prompt is the highest-leverage asset** of the app (FR-10 → FR-12 are its core instructions). It is iterated on independently of the UI.

### 5.3 Vetting (Swipe)
- **FR-14 — Unified swipe vetting.** Cards awaiting vetting are presented as a **single swipe stream drawn from across all notes** (not a per-note batch):
  - swipe **right** → accept into the Retention deck
  - swipe **left** → discard
  - swipe **up** → accept, then open for wording edit
- **FR-15** — Vetting is **woven into the daily session** as a handful of swipes alongside due reviews, and is **bounded** — no infinite feed, no streak-bait.

### 5.4 Daily Session (Loop)
- **FR-16 — Friction-free session.** Opening the app immediately starts a session with **no note-picking and no configuration**: due reviews plus a few new cards and pending cards to vet. The user clears the session and closes the app.
- **FR-17 — Session sizing (grounded default).** The adjustable throttle is the **daily NEW-card intake, defaulting to 10**. **Due reviews are always served in full and are never capped** — retention depends on them. So a session = (cards due today) + (new cards up to the daily cap), with pending cards to vet mixed in. Early sessions run ~10–15 cards and grow naturally as the deck matures. Any optional hard ceiling on total length must always serve due cards before new ones. Rationale in §6.

### 5.5 The Two Tabs
- **FR-18 — Notes (Retention) tab:** contains only cards derived from the user's own vetted notes. Where **full spaced repetition** happens and where the §2 goal is measured.
- **FR-19 — Explore tab:** surfaces **adjacent concepts** (semantic neighbours of the user's existing notes) and **web-sourced new material**, each card **always showing its reference/source**. These are *candidates for exposure*, not items drilled into memory.
- **FR-20 — The trust gate (non-negotiable):** nothing enters the **Retention** deck until it is trusted. A **single "verify" action is enough to promote** an Explore card into Retention (the quick path). The **preferred path** for a genuinely new concept, though, is to dive deep, **write a note**, and let it flow into Retention automatically through the `#flashcard` tag.

### 5.6 Review Loop
- **FR-21** — Scheduling uses the **FSRS algorithm** via the `fsrs` Dart package (an in-app library, not an external tool). It decides each card's next due date.
- **FR-22** — Each review is graded **Again / Hard / Good / Easy**; this grade drives **scheduling only**.
- **FR-23** — The review UX prompts the user to **answer out loud / reconstruct the answer before revealing**, reinforcing the mechanism goal.

### 5.7 Card Quality (Like / Dislike)
- **FR-24** — A per-card **quality signal** (like / dislike) exists **on a separate axis** from the FSRS grade:
  - FSRS grade answers *"how well did I recall this?"* → drives **scheduling**.
  - Like/dislike answers *"is this a good card?"* → drives **generation & deck hygiene** (feeds the FR-9 mix self-adjustment).
  - The two signals must never be conflated, or the scheduler breaks.
- **FR-25 — Dislike means "badly made"** (vague, wrong, redundant, wrong type), **never "this is hard."** Hard cards are the ones most worth keeping; difficulty must never suppress a card.
- **FR-26 — Remake pile.** Disliking a card that is **already in the Retention deck** removes it from active review and moves it to a **Remake pile** (`status = remake_pending`), cleared in a **batch later** — the daily session is never interrupted to regenerate. A remade card re-enters through normal swipe-vetting.

### 5.8 Analytics (Study Director)
- **FR-27** — The analytics view is **retention-focused, not activity-focused.** It answers *"what's solid, what's slipping, and where's the name/mechanism gap?"* — a study director, not a productivity scoreboard.
- **FR-28** — Core views:
  - **Recall strength per concept** — FSRS *retrievability* rolled up from card level to the note, shown green / yellow / red.
  - **Weak spots** — concepts with the most lapses or lowest retrievability; the screen that says *what to re-study*.
  - **Mechanism vs. anchor breakdown per concept** — recall split by card type, to catch the "knows the name, not the mechanism" gap early. (Only possible thanks to the card-type attribute — a genuine edge.)
- **FR-29** — The **"times seen" count** appears as a **detail inside a concept**, paired with retrievability (e.g. *seen 47× / retrievability 60%* → cards likely too fat, split them). It is **not** a headline metric.
- **FR-30** — **No streak counters, no engagement-maximizing metrics.** Long-range trend charts are deferred (insufficient history early on).

---

## 6. Non-Functional Requirements & Guiding Principles

Non-negotiable rules that keep the app aligned with its purpose:

1. **Behavioral, not organizational.** Never drift into "look how nicely my notes are stored." The app exists to change whether the user retains knowledge.
2. **The trust gate.** A permanent-memory machine must never be pointed at unverified content. Nothing enters the Retention deck unvetted; a hallucinated card drilled for weeks becomes a confidently-remembered wrong fact.
3. **Dislike ≠ hard.** Difficulty is never a reason to remove a card.
4. **Bounded engagement.** The win is remembering the concept in three weeks, not opening the app 40 times. No infinite scroll, no dopamine loop.
5. **The generation prompt is the product.** Card quality is a prompt-design outcome, not a model-capability one; it deserves the most iteration.
6. **Start conservative on new cards.** No controlled study fixes a single "optimal" session size; it is a cognitive-load and sustainability tradeoff. The defensible default is **10 new cards/day**. The classic 20/day default reliably produces a compounding review backlog that burns people out within ~2 weeks, and mechanism cards are denser than the vocabulary cards those numbers assume. Cap **new** cards (the throttle); never cap due reviews. Raise the intake once the daily load feels light.

---

## 7. Technical Architecture

| Layer | Choice | Role |
|-------|--------|------|
| Client | **Flutter** | Cross-platform mobile app: session, vetting, review, analytics UI |
| Scheduling | **`fsrs` Dart package** | In-app library computing next due dates from review grades |
| AI generation | **LLM API** (OpenAI / Anthropic) | Authors cards from notes (text-only in v1) |
| Adjacency | **Embeddings** over the vault | Finds semantic neighbours for the Explore tab |
| New-concept sourcing | **Web search API** | Explore tab's web-sourced cards (always cited) |
| Note source | **Dropbox API** (OAuth, Full Dropbox scope) | Read-only access to the Obsidian vault |
| Storage & auth | **Supabase** (Postgres + Auth) | Stores cards, FSRS state, review history; single-user via RLS |

**Data flow:** Dropbox (notes) → background generation → Supabase (`pending` cards) → daily session in the Flutter app (vet → review, calling FSRS) → Supabase (persist state + logs).

Supabase was chosen over local-first for **backup of review progress, queryable history, and optional multi-device** access.

---

## 8. Data Model (Supabase)

**`cards`** — one row per flashcard
- `id`, `user_id`
- `front`, `back`
- `card_type` — `anchor` | `mechanism` | `application`
- `source` — `notes` | `explore`
- `source_path` — Dropbox path of the origin note
- `source_excerpt` — the note text the card was derived from (the trust layer)
- `reference_url` — citation for Explore / web-sourced cards
- `status` — `pending` | `approved` | `discarded` | `remake_pending` (only `approved` cards enter review)
- `quality` — `liked` | `disliked` | null
- `fsrs` — jsonb, the full serialized FSRS card (source of truth)
- `due`, `reps` (**times seen**), `lapses`, `card_state` — promoted columns for indexing & display
- `created_at`, `updated_at`

**`review_logs`** — one row per review event (feeds analytics + future FSRS optimization)
- `id`, `user_id`, `card_id`
- `rating` (1 again, 2 hard, 3 good, 4 easy)
- `reviewed_at`, `elapsed_days`, `scheduled_days`

**`note_coverage`** — tracks background-generation rotation
- `id`, `user_id`, `source_path`
- `last_generated_at`, `cards_generated`
- used to pick under-carded notes next (FR-7 coverage-awareness)

**Security:** Row-Level Security scoped to a single authenticated user (`auth.uid()`).

> Each review write-back is one transaction: rebuild the FSRS card from `fsrs`, apply the rating, persist the new `fsrs`/`due`/`reps`/`lapses`/`card_state`, and insert a `review_logs` row — so a card's state and its log never drift apart.

---

## 9. User Journey (Happy Path)

1. **One-time:** connect Dropbox (Full Dropbox scope) and sign in to Supabase.
2. **Background (no user action):** the app rotates through `#flashcard` notes in `6 - Main Notes`, generates cards coverage-aware, and stores them as `pending`.
3. **Daily:** open the app → a short session starts automatically → swipe-vet a few new cards + review due cards (grading recall with FSRS, flagging any badly-made card) → close. No note-picking.
4. **Explore (when curious):** browse adjacent concepts and cited web-sourced cards; promote worthwhile ones with a single verify, or (preferred) write a note and let it flow into Retention.
5. **Periodically:** clear the Remake pile in a batch, and check analytics → see which concepts are slipping and where mechanism recall lags naming → re-study or re-explain those.

---

## 10. Success Criteria

- **Primary (behavioral):** weeks after studying, the user can **explain the mechanism** of a concept, not just name it.
- **Retention:** per-concept retrievability trends upward; mechanism-card recall closes the gap with anchor-card recall.
- **Engagement (healthy, not maximized):** consistent daily return to clear the session — then stop.
- **Anti-metric:** cards generated, streak length, and hours studied are explicitly **not** success measures.

---

## 11. Phasing: v1 / v2

### v1 — the full experience on real notes
**Phase 1a (core loop):** Dropbox connect → background generation with coverage rotation → friction-free daily session (10 new/day default) → unified swipe-vetting → FSRS review → like/dislike quality flag + Remake pile → concept-level analytics → Supabase storage.
**Phase 1b (Explore):** adjacency via embeddings over the vault + web-sourced cited cards, gated by the trust rule (FR-20).

### v2 — refinements
Automatic generator self-tuning beyond mix adjustment · long-range trend charts · interactive turn-by-turn decomposition · image / vision-based generation (only if image-only notes prove worth it).

---

## 12. Resolved Decisions (previously open)

1. **Dislike on an in-deck card** → moved to a **Remake pile**, cleared in a batch; the session is never interrupted (FR-26).
2. **Session size** → **adjustable**, default **10 new cards/day**, due reviews uncapped (FR-17, §6).
3. **Explore → Retention** → a **single verify** promotes a card; the **preferred** path for new concepts is to write a note first (FR-20).
4. **Name** → **Grasp**.

*No open questions remain. Next step: draft and test the generation prompt (FR-10 → FR-13) against a real note.*
