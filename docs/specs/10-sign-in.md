# 10 · Sign-in

**Branch:** `feat/ui-polish-2` (fixes) + sign-in
**Status:** auth flow done; data persistence wiring is the next feature

## How to run the app yourself

```powershell
flutter run -d chrome
#   or: flutter run -d web-server --web-port 5610  → open the printed URL
```

Stop with `q`. New files were added, so press `R` (hot restart) or rerun.

**Testing on web:** the app now opens on the **Sign-in** screen. Either create
an account / sign in with a Supabase user, or tap **"Skip for now (debug)"** to
reach the Dropbox gate and shell as before.

> Supabase email confirmation: if the project has "Confirm email" on, sign-up
> won't create a session until the emailed link is clicked. For frictionless
> personal use, turn confirmation off in the Supabase dashboard (Auth settings)
> or create the user there directly.

## What this delivers

The deferred "last bit" (§8), first half - authentication:

- **Sign-in / create-account screen** - email + password against Supabase, a
  toggle between the two, inline errors, and a sign-up notice when email
  confirmation is pending. Debug skip for web.
- **Auth gate** - the app gates on a session first, then the Dropbox gate, then
  the shell. supabase_flutter persists the session across launches, so a
  returning user lands straight in.
- **Real sign-out** - the Settings account row now calls
  `AuthController.signOut()` (was a placeholder snackbar), which flips the gate
  back to Sign-in.

## Key files

- `lib/features/auth/auth_controller.dart` - `authStateChangesProvider`,
  `currentSessionProvider`, `AuthController` (signIn / signUp / signOut).
- `lib/features/auth/sign_in_screen.dart` - the screen.
- `lib/app.dart` - two-stage gate (auth, then Dropbox), each with a debug bypass.
- `lib/features/settings/settings_screen.dart` - wired sign-out.

## Also in this branch (UI polish, separate commit)

- Landing page recolored to accent `oklch(.55 .14 245)` and simplified.
- Session-complete screen centered, colored, no "Back to tabs".
- Retention concept rows: bigger tap target, accent hover instead of gray.

## Verified

- `flutter analyze` clean (2 pre-existing info lints in `cards_repository.dart`).
- `flutter test` - 8 pass.

## What's next (the other half: persistence)

Turn every mock provider into Supabase-backed data, scoped to `auth.uid()`:

- Session queue - real due + new cards (respecting the throttle) from `CardsRepository`.
- Vetting - `status = pending`; accept/discard/edit persist status + wording.
- Review - `FsrsService.review` → `ReviewsRepository.record` on each grade.
- Deck / analytics - `status = approved`; flag → remake persists.
- Remake pile / Explore verify - real writes.
- The 90-day curve, once review logs accumulate.
