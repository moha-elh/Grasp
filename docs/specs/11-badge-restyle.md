# 11 · Badge restyle

**Branch:** `feat/badge-restyle`
**Status:** done

## What changed

All the little labels on cards (Anchor / Mechanism / Application / Pending /
Remake, Explore's Adjacent / Web, and the Retention gap chip) are redesigned
into one consistent **tinted tag**: a soft color wash behind colored mono text,
pill-shaped, uppercased with letter-spacing. They read as quiet metadata rather
than the old thin outline boxes.

Type colors now match the rest of the app: Anchor = blue, Mechanism = amber,
Application = green (the same scheme as the concept ring and type bars).

## Key files

- `lib/design/widgets/tag.dart` - new shared `Tag(label, color)` widget.
- `lib/design/widgets/type_badge.dart` - factories now delegate to `Tag`.
- `lib/features/explore/explore_screen.dart` - kind badge uses `Tag`.
- `lib/features/retention/retention_screen.dart` - gap chip uses `Tag`.

## Verified

- `flutter analyze` clean (2 pre-existing info lints in `cards_repository.dart`).
- `flutter test` - 8 pass.

## Next

Persistence: turn the mock providers into Supabase-backed data now that sign-in
exists (unblocked by feat/ui-polish-2's auth).
