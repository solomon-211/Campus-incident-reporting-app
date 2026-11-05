# Campus Incident Reporter

A Flutter app for reporting problems around the ALU campus, like a broken tap in the residence, a projector that won't turn on, or a light that's out on the walkway, and following them until they're fixed.

I built it for Individual Assignment 2 in Mobile Application Development. It uses Flutter with BLoC (Cubit) for state management and Firebase for sign-in and data.

## Why I built it

Right now most campus issues get reported by word of mouth or in a WhatsApp group. Messages get buried, the same problem gets reported five times, and the person who reported it rarely hears back. This app gives students one place to report an issue and see what's happening with it, and gives staff one list to work through.

## What it does

Students can:

- sign up with their ALU email and verify it before getting in
- report an issue with a category, title, description, location and up to three photos
- report anonymously, which is useful for safety concerns
- follow each report through Submitted, In Progress, Resolved or Rejected, with the note staff left at every step
- tap "Me too" on someone else's report instead of filing a duplicate
- withdraw their own report while staff haven't picked it up yet
- get an alert when staff update one of their reports, and see past updates behind the bell icon
- set a profile photo

Staff get a dashboard showing everything that's waiting, in progress, resolved or urgent. They can search and filter reports, sort them by priority or by how many students are affected, change a report's status and priority (a note is required so the student knows why), and delete spam or duplicates. They're alerted as soon as a new report comes in.

The app also works offline. A report submitted without a connection shows "Pending sync" until it reaches the server.

## Accounts and roles

There are two kinds of account: student and staff.

Anyone with an `@alustudent.com` or `@alueducation.com` address can register, and every account has to verify its email before it can do anything. Every new account starts as a student, whichever of the two domains it uses.

Staff accounts are set up by hand. Once someone has registered and verified, an admin opens the Firebase Console, goes to Firestore, opens `users/<their uid>` and changes `role` from `student` to `staff`. The app picks up the change straight away and moves them to the staff dashboard. Nobody can promote themselves, because the security rules reject any update that changes your own role.

I kept it this way because the email domain alone isn't a reliable signal. Plenty of `@alueducation.com` accounts belong to people who shouldn't be handling reports, and it's simpler to have one clear rule: staff are the people an admin has chosen.

## Running it yourself

You'll need Flutter 3.47 or newer, an Android phone or emulator, Node.js (for the Firebase CLI) and a Google account.

```bash
git clone https://github.com/solomon-211/Campus-incident-reporting-app.git
cd Campus-incident-reporting-app
flutter pub get
```

Then set up Firebase:

1. Create a project in the [Firebase Console](https://console.firebase.google.com).
2. Under Authentication, enable the Email/Password sign-in method.
3. Under Firestore Database, create a database in production mode. Pick a location close to you, because you can't change it later.
4. Connect the app and deploy the security rules:

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_PROJECT_ID
firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
```

On Windows, if `flutterfire` isn't recognised, run `dart pub global run flutterfire_cli:flutterfire configure --project=YOUR_PROJECT_ID` instead.

Don't skip the rules step. Without it, every read and write fails with `permission-denied`.

Now run `flutter run`.

To try both sides, register two accounts and verify both. Promote one of them to staff in the Console as described above. Submit a report as the student and it will show up on the staff dashboard. Move it to In Progress as staff, and the student sees the update right away.

## How the code is organised

```
lib/
  main.dart            starts Firebase
  app/                 router, theme, page transitions, student bottom nav
  core/                constants, validators, shared widgets
    incidents/         list, filter and alert code shared by students and staff
  data/
    models/            AppUser, Incident, StatusUpdate
    repositories/      the only classes that talk to Firebase
    services/          photo compression
  features/
    auth/              splash, login, register, verify email
    home/              student home and notifications
    report/            the report form
    reports/           "My Reports"
    detail/            incident details, timeline, photo viewer
    profile/           profile and photo
    staff/             staff dashboard and status updates
```

Each feature has its own `cubit/`, `screens/` and sometimes `widgets/` folder. Screens never touch Firebase directly. They talk to a cubit, and the cubit talks to a repository. That's what makes the cubits easy to test with mocked repositories.

Navigation uses go_router. A single redirect decides where you go based on your auth state: signed out goes to login, unverified goes to the verify-email screen, students go to their home and staff go to the dashboard. That keeps the two roles out of each other's screens.

## Data

Firestore has two top-level collections:

- `users/{uid}` holds name, email, role, program, campus, an optional profile photo, and when you last opened your notifications.
- `incidents/{id}` holds the report itself: title, description, category, location, status, priority, who reported it, whether it's anonymous, who tapped "Me too", and a small thumbnail.

Each incident has two subcollections. `updates` is the status history shown on the timeline, and `photos` holds the full-size photos. A new report, its first timeline entry and its photos are written in one batch, so you never end up with half a report.

All access control lives in [firestore.rules](firestore.rules). Students can only create reports as themselves, only add or remove their own "Me too", and only delete their own report while it's still submitted. Only staff can change a report's status.

## Tests

```bash
flutter test      # 53 tests
flutter analyze
```

The tests cover the validators, the models and their Firestore mapping, the router's redirects for each kind of user, every cubit (using mocktail for the repositories), and the main screens rendered at phone size so any layout overflow fails the test.

## Things I'd change with more time

- Photos are stored as compressed bytes in Firestore instead of Firebase Storage, because Storage now needs the paid Blaze plan. It works fine at this size, but Storage is the proper home for files.
- Alerts only fire while the app is open. Real push notifications would need Cloud Functions and Cloud Messaging, which also need Blaze.
- Making someone staff means editing Firestore by hand. A small admin screen would be nicer.
- Search runs on the device. That's fine for one campus, but it wouldn't scale to thousands of reports.

## Troubleshooting

If you see "Firebase is not configured", you haven't run `flutterfire configure` in the project folder yet.

If you get `permission-denied`, deploy the rules and check that the account's email is verified.

If a staff account still opens as a student, check that `role` is exactly `staff` (lowercase) on that user's document.

If you're stuck on "Check your inbox", look in your spam folder or tap Resend.

## Credits

Built by Solomon Thiong Garang Leek ([@solomon-211](https://github.com/solomon-211)).

The font is [Plus Jakarta Sans](https://github.com/tokotype/PlusJakartaSans), used under the SIL Open Font License (see `assets/fonts/OFL.txt`).
