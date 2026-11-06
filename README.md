# Campus Incident Reporter

A Flutter application for reporting and tracking campus maintenance and safety issues at ALU. Students submit reports with photos, PDFs and location details, staff manage and resolve them through a dedicated dashboard, and everyone stays informed through real-time status updates.

## Overview

Campus issues currently travel through WhatsApp groups and word of mouth — messages get buried, the same problem gets reported multiple times, and reporters rarely hear back. This application gives students a single place to report issues and track their progress, and gives staff a structured queue to work through.

## Features

### Students
- Register with an `@alustudent.com` email address and verify it before gaining access
- Submit reports with a category, title, description, location and up to three attachments (photos or PDFs)
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
- Offline support — reports without attachments can be submitted without a connection and show **Pending sync** until they reach the server
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

Firebase handles sign-in and all report data.

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

### Supabase Setup

Photos and PDFs are stored in Supabase Storage, because Firebase Storage requires the paid Blaze plan.

1. Create a free project at [supabase.com](https://supabase.com).
2. Under **Storage**, create a **public** bucket named `incident-files`.
3. In the **SQL Editor**, run this policy so the app can upload images and PDFs to that bucket:

```sql
create policy "App can upload incident files"
on storage.objects for insert
to anon, authenticated
with check (
  bucket_id = 'incident-files'
  and lower(storage.extension(name)) in ('jpg', 'jpeg', 'png', 'pdf')
);
```

4. Under **Project Settings → API Keys**, copy the project URL and the **publishable** key into `supabaseUrl` and `supabaseKey` in [`lib/core/constants.dart`](lib/core/constants.dart).

> Never put the **secret** key in the app. It bypasses every storage policy.

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
    models/              AppUser, Incident, StatusUpdate, Attachment
    repositories/        All Firebase communication
    services/            Photo compression and Supabase file uploads
  features/
    auth/                Splash, login, register, email verification
    home/                Student home screen and notifications
    report/              Report submission form
    reports/             My Reports list
    detail/              Incident detail, status timeline, photo viewer, PDFs
    profile/             Profile management
    staff/               Staff dashboard and status update sheets
```

Each feature follows a consistent structure: `cubit/`, `screens/` and optionally `widgets/`. Screens never communicate with Firebase or Supabase directly — they interact with a cubit, which delegates to a repository. This separation makes every cubit independently testable with mocked repositories.

Navigation is handled by `go_router`. A single redirect function evaluates auth state on every route change: unauthenticated users go to login, unverified users go to the verification screen, students go to the home screen and staff go to the dashboard.

## Data Model

Firestore has two top-level collections:

- `users/{uid}` — name, email, role, program, campus, optional profile photo (a small compressed image stored on the document), and last notification view timestamp
- `incidents/{id}` — title, description, category, location, status, priority, reporter UID, anonymous flag, Me Too list, a compressed thumbnail and an `attachments` list
- `incidents/{id}/updates` — the full status history rendered on the timeline

The files themselves live in the Supabase `incident-files` bucket, one folder per report (for example `incident-files/<report-id>/1.jpg`). Each entry in `attachments` keeps only the file's public link, name and type. Photos are compressed on the device to under 700 KB before upload; PDFs must be under 10 MB.

Files are uploaded first, then the report and its initial timeline entry are written in a single batch, so no partial report is ever stored. Photos from reports made before the move to Supabase are still read from an older `photos` subcollection.

Access control is defined entirely in [`firestore.rules`](firestore.rules). Students may only create reports as themselves, add or remove their own Me Too, and delete their own report while it is still in Submitted status. Only staff may change a report's status or priority.

## Running Tests

```bash
flutter test      # 55 tests
flutter analyze
```

Test coverage includes validators, model serialisation and Firestore mapping, router redirects for each user type, all cubits with mocked repositories, and main screens rendered at phone dimensions to catch layout overflows.

## Known Limitations

- **File uploads use a public key** — The app signs in with Firebase, so Supabase cannot tell which user uploaded a file. The storage policy limits uploads to images and PDFs in one bucket; tying uploads to signed-in users would need a Cloud Function, which requires Blaze.
- **Files stay after a report is deleted** — The app's key can upload but not delete. Remove leftover files from the Supabase dashboard.
- **Attachments need a connection** — Reports without attachments can be saved offline, but files can only be uploaded online.
- **Supabase pauses idle projects** — A free project pauses after about a week without activity. Restore it from the dashboard before a demo.
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
| "Could not upload your files" | Make sure the `incident-files` bucket exists and the upload policy above has been run in the Supabase SQL Editor |
| A PDF won't open from a report | The phone needs a PDF viewer or browser installed |

## License

The font used in this project is [Plus Jakarta Sans](https://github.com/tokotype/PlusJakartaSans), licensed under the SIL Open Font License. See [`assets/fonts/OFL.txt`](assets/fonts/OFL.txt) for details.
