# Firebase Setup — ALU Ventures

Follow these once. Total time ~15 minutes. Commands run in **PowerShell** from the
project root: `c:\Users\shyak\Documents\Flutter ALU\Formative_assignment2`.

---

## 1. Install the CLIs (one-time on your machine)

You need Node.js (for the Firebase CLI). If `node -v` fails, install it from
<https://nodejs.org> first, then:

```powershell
npm install -g firebase-tools      # Firebase CLI
dart pub global activate flutterfire_cli   # FlutterFire CLI
firebase login                     # opens a browser — log in with your Google account
```

If `flutterfire` is "not recognized" afterwards, add Dart's pub-cache bin to PATH:
`C:\Users\shyak\AppData\Local\Pub\Cache\bin` (then reopen PowerShell).

---

## 2. Create the Firebase project

1. Go to <https://console.firebase.google.com> → **Add project** → name it
   `alu-ventures` → continue (Google Analytics optional, you can disable it).
2. Wait for it to provision, then open the project.

---

## 3. Connect the app (generates `firebase_options.dart`)

From the project root:

```powershell
flutterfire configure
```

- Select the `alu-ventures` project.
- When asked for platforms, select **android** (space to toggle, enter to confirm).
- This **overwrites** `lib/firebase_options.dart` with your real keys and creates
  `android/app/google-services.json`. That's expected.

---

## 4. Enable Authentication

Console → **Build → Authentication → Get started** →
**Sign-in method** tab → enable **Email/Password** → Save.

---

## 5. Create the Firestore database

Console → **Build → Firestore Database → Create database** →
Start in **production mode** → pick a location (e.g. `eur3` / closest region) → Enable.

---

## 6. Deploy the security rules + indexes

This project ships `firestore.rules` and `firestore.indexes.json`. Deploy them:

```powershell
firebase init firestore     # if prompted: use existing project alu-ventures,
                            # accept the default file names (firestore.rules,
                            # firestore.indexes.json) — do NOT overwrite them
firebase deploy --only firestore:rules,firestore:indexes
```

> Prefer the console? Paste the contents of `firestore.rules` into
> **Firestore → Rules → Publish**. For indexes, just run the app — when a query
> needs an index, Firestore prints a **clickable link in the debug console** that
> creates it in one click. Building indexes takes a minute or two.

---

## 7. Run the app on the emulator

```powershell
flutter emulators --launch Resizable_Experimental
flutter run
```

Create two accounts to see both sides:
1. Register as a **Startup** → set up the startup profile (it starts *pending*).
2. Register as a **Student** → browse (nothing shows until a startup is verified
   and posts).

---

## 8. Make yourself an admin (to verify startups)

Verification is gated by an `isAdmin` flag on your user document (in production
this would be a Firebase custom claim — see the report).

1. Register/log in once with the account you want as admin.
2. Console → **Firestore → `users` collection →** open your user document.
3. Add a field: `isAdmin` (boolean) = `true`.
4. Back in the app, open **Profile → Startup verification (Admin)**, and approve
   the pending startup. It can now post opportunities, which then appear to
   students in real time.

---

## Demo flow (what to record for the video)

1. **Auth** — register a student live; show the new user appear in
   Authentication + the `users` doc in Firestore (real-time console).
2. **Startup + verification** — register a startup, submit the profile (pending),
   switch to admin, verify it → show `status` flip to `verified` in the console.
3. **CRUD** — startup posts an opportunity → show the `opportunities` doc created;
   edit it → show the field change; all reflected instantly in the student app.
4. **Discovery + apply** — student searches/filters, opens the role, applies →
   show the `applications` doc created and `applicantCount` increment atomically.
5. **Real-time state** — as admin/startup, move the application to *Shortlisted* →
   show the student's tracker badge update **live** without a refresh.

That sequence hits every rubric line: Auth, CRUD, real-time, state management.
