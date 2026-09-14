# Testing Grasp on your phone (end to end)

This walks through running Grasp on a real Android device and exercising the
whole flow: sign in, connect Dropbox, generate cards, vet, review, and the
analytics. Dropbox OAuth uses a mobile custom-scheme redirect (`grasp://auth`),
so the connect + generate steps only work on a device, not in Chrome.

> iOS needs a Mac + Xcode to build. These steps are for Android on your Windows
> machine.

---

## 0. One-time backend setup (do this first)

1. **Supabase schema.** In the Supabase dashboard → SQL editor, paste and run
   the contents of `supabase/schema.sql`. This creates `cards`, `review_logs`,
   `note_coverage`, row-level security, and the `record_review` function.
2. **Turn off email confirmation** (personal use, so sign-up gives a session
   immediately): Supabase dashboard → Authentication → Providers → Email →
   turn **Confirm email** off. (Or leave it on and confirm via the email link.)
3. **Dropbox app console** (https://www.dropbox.com/developers/apps):
   - Your app must have **Full Dropbox** access (not App folder) - the vault
     lives inside Remotely Save's folder, which App-folder can't reach.
   - Under **OAuth 2 → Redirect URIs**, add exactly: `grasp://auth`
   - Permissions: `files.metadata.read` and `files.content.read`. Click
     **Submit** after changing scopes.
4. **`.env`** in the project root is filled:
   ```
   SUPABASE_URL=...        SUPABASE_KEY=sb_publishable_...
   DROPBOX_APP_KEY=...     GROQ_API_KEY=gsk_...
   ```
5. **Your vault**: at least one note under the scoped folder
   (`/Applications/remotely-save/Knowledge/6 - Main Notes`) that contains the
   text `#flashcard`.

---

## 1. Enable Developer mode + USB debugging on the phone

1. Settings → **About phone**.
2. Tap **Build number** 7 times until it says "You are now a developer".
3. Back → **System → Developer options** (on some phones it's under
   Additional settings).
4. Turn on **USB debugging**.
5. (Optional but handy) turn on **Stay awake** so the screen doesn't sleep while
   plugged in.

## 2. Plug in and authorize the computer

1. Connect the phone by USB. Set the USB mode to **File transfer / Android
   Auto** (not "charging only") if prompted.
2. A prompt **"Allow USB debugging?"** appears on the phone - check "Always
   allow from this computer" and tap **Allow**.

## 3. Confirm the tooling sees the device

From the project root (`C:\Users\mohsi\Desktop\Projects\flashMemo`):

```powershell
flutter doctor        # first time: fix any Android toolchain X marks
flutter devices       # your phone should be listed
```

If the phone isn't listed: unplug/replug, re-accept the debugging prompt, and
make sure `flutter doctor` shows "Android toolchain" with a check (accept
licenses with `flutter doctor --android-licenses` if asked).

## 4. Run the app on the phone

```powershell
flutter run           # if only the phone is connected
# or, if several devices:
flutter devices       # copy the phone's id
flutter run -d <device-id>
```

First build takes a few minutes. Leave it running: press `r` to hot reload,
`R` to hot restart, `q` to quit.

To install a standalone build instead (no cable needed after):
```powershell
flutter build apk --release
# APK lands in build/app/outputs/flutter-apk/app-release.apk - copy it to the phone and install.
```

---

## 5. End-to-end test checklist

Go through these in order and confirm each works:

**Sign in**
- [ ] App opens on the Sign-in screen.
- [ ] "Create an account" → enter email + password → you land past the gate
      (if it says check your email, confirmation is still on - see step 0.2).
- [ ] Kill and reopen the app: it should skip sign-in (session persists).

**Connect Dropbox**
- [ ] The Dropbox onboarding page shows (blue screen with the Dropbox logo).
- [ ] Tap **Connect Dropbox** → the system browser opens the Dropbox consent
      page → approve → it returns to the app.
- [ ] It scans and reports how many `#flashcard` notes it found.
- [ ] Reopen the app: it should skip the connect page (token persists).

**Generate cards**
- [ ] Go to **Settings** (gear, top-right of any tab) → **Content** →
      **Generate cards now**.
- [ ] It shows "Generating…", then "Added N cards last run".
- [ ] In the Supabase dashboard, `cards` has rows with `status = pending`.

> Note: at this stage the vetting/review/deck screens still show sample
> (mock) data - wiring the generated cards into those screens is the next
> feature (persistence). This checklist verifies generation writes to Supabase.

**Review loop (sample data)**
- [ ] Session tab: tap a card to reveal, see four interval labels, grade
      through to "Done for today". Tab bar hides mid-session, returns after.
- [ ] "Flag it" shows the badly-made rule and drops the card.

**Vetting (sample data)**
- [ ] The session opens with the vet batch first: swipe or use the
      Discard / Edit / Accept buttons; Edit opens the wording sheet.

**Retention**
- [ ] Retention tab: the ring shows Name / Explain / Apply arcs, concept rows
      by widest gap; tap a concept for its detail (triple ring + breakdown).
- [ ] Remake pile row → each card can be **Keep it**, **Delete**, or you can
      **Regenerate all**.

**Explore**
- [ ] Explore tab: cited cards, each with a source; **Verify** and **Dismiss**.

**Settings reachable everywhere**
- [ ] The gear opens Settings from **Session**, **Retention**, and **Explore**.
- [ ] **Sign out** returns you to the Sign-in screen.

---

## Troubleshooting

- **"Missing required env var"** on launch → `.env` isn't filled or wasn't
  bundled; check the root `.env` and rerun.
- **Dropbox returns to the app but errors** → the app isn't Full Dropbox scope,
  or `grasp://auth` isn't in the redirect URIs. Fix in the Dropbox console and
  Submit.
- **Browser doesn't return to the app** → confirm the `grasp` scheme
  intent-filter is in `android/app/src/main/AndroidManifest.xml` (it is, by
  default here).
- **Generation "failed"** → check the Groq key in `.env`, and that the note
  actually contains `#flashcard`. The error text in Settings names the cause.
- **Phone not detected** → re-accept the USB-debugging prompt; try a different
  cable/port; `adb kill-server` then replug.
