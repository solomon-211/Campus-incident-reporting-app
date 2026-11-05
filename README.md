# Campus Incident Reporter

A Flutter application for reporting and tracking campus maintenance and safety issues at ALU. Students submit reports with photos and location details, staff manage and resolve them through a dedicated dashboard, and everyone stays informed through real-time status updates.

## Overview

Campus issues currently travel through WhatsApp groups and word of mouth — messages get buried, the same problem gets reported multiple times, and reporters rarely hear back. This application gives students a single place to report issues and track their progress, and gives staff a structured queue to work through.

## Features

### Students
- Register with an `@alustudent.com` email address and verify it before gaining access
- Submit reports with a category, title, description, location and up to three photos
- Report anonymously for sensitive or safety-related concerns
- Track each report through **Submitted → In Progress → Resolved / Rejected**, with staff notes at every step
- Tap **Me too** on an existing report instead of filing a duplicate
- Withdraw a report while it has not yet been picked up by staff
- Receive in-app alerts when staff update a report, accessible via the notification bell
- Upload and manage a profile photo

### Staff
- Dashboard showing all reports grouped by status, with urgent items highlighted
- Search, filter and sort by priority or number of affected students
- Update a report's status and priority with a mandatory note so the reporter understands the outcome
- Delete spam or duplicate reports
- Receive an alert as soon as a new report is submitted

### General
- Offline support — reports submitted without a connection show **Pending sync** until they reach the server
- Role-based navigation enforced at the router level; students and staff never see each other's screens

## Roles and Access

There are two account types: **student** and **staff**.

The email domain decides the role. An `@alustudent.com` address becomes a **student** and must verify its email before accessing the app. An `@alueducation.com` address becomes **staff** and goes straight to the dashboard without verification.

Staff skip verification because this is a demo and there is no real staff inbox to receive the link. In a real deployment staff should verify too. The security rules check the domain on the server, so a student account cannot make itself staff.

## Getting Started

**Requirements:** Flutter 3.47+, Android device or emulator, Node.js, a Google account.

```bash
git clone https://github.com/solomon-211/Campus-incident-reporting-app.git
cd Campus-incident-reporting-app
flutter pub get
```

### Firebase Setup

1. Create a project in the [Firebase Console](https://console.firebase.google.com).
2. Under **Authentication**, enable the **Email/Password** sign-in method.
3. Under **Firestore Database**, create a database in production mode.
4. Run the following to connect the app and deploy security rules:

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_PROJECT_ID
firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
```

> On Windows, if `flutterfire` is not recognised, use `dart pub global run flutterfire_cli:flutterfire configure --project=YOUR_PROJECT_ID` instead.

> Do not skip the rules deployment. Without it, every Firestore read and write fails with `permission-denied`.

```bash
flutter run
```

To test both roles, register a verified `@alustudent.com` account and any `@alueducation.com` address (it does not need to exist). Submit a report as the student, then manage it as staff.

## Project Structure

```
lib/
  main.dart              Firebase initialisation and app entry point
  app/                   Router, theme, page transitions, student shell
  core/
    incidents/           Shared incident list, filters and alert widgets
    widgets/             Reusable UI components
    constants.dart
    validators.dart
    extensions.dart
    load_status.dart
  data/
    models/              AppUser, Incident, StatusUpdate
    repositories/        All Firebase communication
    services/            Photo compression
  features/
    auth/                Splash, login, register, email verification
    home/                Student home screen and notifications
    report/              Report submission form
    reports/             My Reports list
    detail/              Incident detail, status timeline, photo viewer
    profile/             Profile management
    staff/               Staff dashboard and status update sheets
```

Each feature follows a consistent structure: `cubit/`, `screens/` and optionally `widgets/`. Screens never communicate with Firebase directly — they interact with a cubit, which delegates to a repository. This separation makes every cubit independently testable with mocked repositories.

Navigation is handled by `go_router`. A single redirect function evaluates auth state on every route change: unauthenticated users go to login, unverified users go to the verification screen, students go to the home screen and staff go to the dashboard.

## Data Model

Firestore has two top-level collections:

- `users/{uid}` — name, email, role, program, campus, optional profile photo URL, and last notification view timestamp
- `incidents/{id}` — title, description, category, location, status, priority, reporter UID, anonymous flag, Me Too list and a compressed thumbnail

Each incident document has two subcollections:

- `updates` — the full status history rendered on the timeline
- `photos` — full-size compressed photos

A new report, its initial timeline entry and its photos are written in a single batch operation, ensuring no partial data is ever stored.

Access control is defined entirely in [`firestore.rules`](firestore.rules). Students may only create reports as themselves, add or remove their own Me Too, and delete their own report while it is still in Submitted status. Only staff may change a report's status or priority.

## Running Tests

```bash
flutter test      # 54 tests
flutter analyze
```

Test coverage includes validators, model serialisation and Firestore mapping, router redirects for each user type, all cubits with mocked repositories, and main screens rendered at phone dimensions to catch layout overflows.

## Known Limitations

- **Photo storage** — Photos are stored as compressed bytes in Firestore rather than Firebase Storage. Storage now requires the Blaze billing plan. This works at the current scale but Storage is the appropriate long-term solution.
- **Push notifications** — In-app alerts only fire while the app is open. Background push notifications require Cloud Functions and Cloud Messaging, both of which require Blaze.
- **Staff verification** — Staff accounts skip email verification for the demo, so anyone can register an `@alueducation.com` address. A real deployment should require verification or an admin approval step.
- **Search** — Report search runs on the client. This is acceptable for a single campus but would not scale to a large dataset.

## Troubleshooting

| Symptom | Fix |
|---|---|
| "Firebase is not configured" | Run `flutterfire configure` in the project root |
| `permission-denied` on any Firestore operation | Deploy the security rules and confirm the student's email is verified |
| Staff account opens as student | Sign out and back in; the account is upgraded to staff automatically. Make sure the rules are deployed |
| Stuck on "Check your inbox" | Check spam, or tap Resend on the verification screen |

## License

The font used in this project is [Plus Jakarta Sans](https://github.com/tokotype/PlusJakartaSans), licensed under the SIL Open Font License. See [`assets/fonts/OFL.txt`](assets/fonts/OFL.txt) for details.
