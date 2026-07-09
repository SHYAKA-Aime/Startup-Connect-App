# ALU Ventures

A Flutter + Firebase mobile app that connects **ALU students** with **verified
student-led startups**. Startups are verified by an ALU admin, post
opportunities, and review applicants; students discover, filter, bookmark, apply,
and track their applications — all updating in real time.

Built for the Mobile Application Development final project.

---

## Features

- Email/password **authentication** with **student** and **startup** roles
- **Startup verification** trust gate — only admin-approved startups can post
  (enforced in the UI *and* in Firestore security rules)
- Opportunity **posting and full CRUD** (create, edit, open/close, delete)
- **Discovery** — search, category / role / location filters, and bookmarks
- **Skill-matched recommendations** on the student home feed
- **Apply** with a cover note; applicant counts updated atomically
- Real-time **application tracker** (student) and **applicant pipeline** (startup)
- Dedicated **admin verification console**

## Tech stack

- **Flutter** (Dart) — Material 3, ALU brand design system
- **Riverpod 2** — state management (`Notifier` / `AsyncNotifier`, no codegen)
- **Firebase** — Authentication (email/password) + Cloud Firestore (real-time)
- **go_router** — declarative routing with an auth/role redirect guard

## Architecture

Feature-first and layered. Dependencies point only downward, and repositories are
the only layer that touches Firebase:

```
Widgets ──watch──▶ Riverpod providers ──▶ Repositories ──▶ Firebase
                   (controllers for actions)   (only layer touching Firebase)
```

```
lib/
  app/        app, router, theme, global providers
  core/       shared widgets
  features/   auth, startups, opportunities, applications, profile, shell
              (each feature: domain / data / presentation)
firestore.rules          server-side security (verification, ownership, privacy)
firestore.indexes.json   composite indexes for the app's queries
```

## Getting started

**Prerequisites:** Flutter SDK, an Android emulator or device, Node.js (for the
Firebase CLI), and a Google account.

The generated Firebase config (`lib/firebase_options.dart`,
`android/app/google-services.json`) is intentionally **not** committed, so connect
your own Firebase project:

```bash
# 1. Install dependencies
flutter pub get

# 2. Install the CLIs and sign in (one-time)
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login

# 3. Generate the Firebase config for your project (creates the gitignored files)
flutterfire configure
```

In the [Firebase console](https://console.firebase.google.com):

1. Enable **Authentication → Email/Password**.
2. Create a **Cloud Firestore** database (production mode).
3. Deploy the security rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Then run the app:

```bash
flutter run
```

To act as an admin (to verify startups), set `isAdmin: true` on your user document
in **Firestore → `users`**.

## Verify

```bash
flutter analyze   # static analysis
flutter test      # domain unit tests
```
