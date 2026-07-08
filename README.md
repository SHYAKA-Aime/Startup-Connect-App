# ALU Ventures

A Flutter + Firebase mobile app connecting **ALU students** with **verified
student-led startups**. Startups get verified by an ALU admin, post
opportunities, and review applicants; students discover, filter, bookmark, apply,
and track their applications — all updating in real time.

Built for the Mobile Application Development final project.

---

## Tech stack

- **Flutter 3.44** (Dart 3.12)
- **Riverpod 2** — state management
- **Firebase** — Auth (email/password) + Cloud Firestore (real-time backend)
- **go_router** — declarative routing with an auth/role redirect guard

## Architecture (feature-first, layered)

```
Widgets ──watch──▶ Riverpod providers ──▶ Repositories ──▶ Firebase
                     (controllers for actions)  (only layer touching Firebase)
```

See **[REPORT.md](REPORT.md)** for the full write-up (architecture diagrams,
schema, workflows, scalability, testing, challenges) and
**[STUDY_GUIDE.md](STUDY_GUIDE.md)** for a rubric→code map and demo script.

## Features

- Auth + onboarding with **student / startup** roles
- **Startup verification** trust gate (admin-approved; enforced in security rules)
- Opportunity **posting + full CRUD** (create, edit, open/close, delete)
- **Discovery**: search, category/type/location filters, bookmarking
- **Skill-matched recommendations** on the home feed
- **Apply** with a cover note; atomic applicant counting
- **Application tracker** (student) + **applicant pipeline** (startup), real-time
- Admin **verification console**

## Run it

Firebase must be connected first — follow **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)**
(≈15 min), then:

```powershell
flutter pub get
flutter emulators --launch Resizable_Experimental
flutter run
```

## Verify

```powershell
flutter analyze   # → No issues found
flutter test      # → domain unit tests pass
```

## Project layout

```
lib/
  app/        app, router, theme, global providers
  core/       shared widgets
  features/   auth, startups, opportunities, applications, profile, shell
              (each: domain / data / presentation)
firestore.rules          # server-side security (verification, ownership, privacy)
firestore.indexes.json   # composite indexes for the queries
```
