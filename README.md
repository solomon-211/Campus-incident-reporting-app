# Campus Incident Reporter

**Individual Assignment 2: Campus Incident Reporting App**

A Flutter app where students report campus issues (broken facilities, water, electricity, safety, sanitation, furniture) and staff review them and update their status. It uses BLoC/Cubit for state management and Firebase (Auth and Firestore) for the backend. Everything runs on Firebase's **free Spark plan**, with no card needed.

---

## 1. Connect the app to Firebase

The code is complete, but it needs **your own Firebase project**. Until you connect one, the app opens on a "Firebase is not configured" screen. Follow these steps in order. They take about 10 minutes.

### Step 1: Install the tools (once per computer)

You need [Node.js](https://nodejs.org) for the Firebase CLI. In a terminal:

```bash
# Firebase CLI (deploys the security rules)
npm install -g firebase-tools
firebase login

# FlutterFire CLI (connects the Flutter app to Firebase)
dart pub global activate flutterfire_cli
```

> **Windows:** if `flutterfire` is "not recognized", its folder isn't on your PATH. Either run it through Dart, which always works:
>
> ```powershell
> dart pub global run flutterfire_cli:flutterfire configure --project=YOUR_PROJECT_ID
> ```
>
> or add it to PATH once, then **close and reopen** the terminal:
>
> ```powershell
> [Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path','User') + ";$env:LOCALAPPDATA\Pub\Cache\bin", 'User')
> ```

### Step 2: Create the Firebase project

1. Go to <https://console.firebase.google.com> and click **Create a project**.
2. Name it, for example `campus-incident-reporter`. Note the **project ID** it gives you (e.g. `campus-incident-reporter-1a2b3`).
3. Google Analytics is optional. You can turn it off.

### Step 3: Turn on Authentication

1. In the console, open **Build → Authentication → Get started**.
2. Under **Sign-in method**, enable **Email/Password**, then save.

### Step 4: Create the Firestore database

1. Open **Build → Firestore Database → Create database**.
2. Pick a location close to your users (e.g. `europe-west1` or `africa-south1`). **You can't change it later.**
3. Choose **Start in production mode**. The real rules get deployed in Step 7.

### Step 5: Skip Cloud Storage

You **don't** need Firebase Storage. New projects can only use it on the paid Blaze plan, so this app stores photos in Firestore instead (see [How photos are stored](#how-photos-are-stored)). If the console offers to upgrade for Storage, you can ignore it.

### Step 6: Connect the Flutter app

From the project folder (`campus_incident_reporter/`):

```bash
flutterfire configure --project=YOUR_PROJECT_ID
```

- Select the platforms you'll run on (Android, iOS, web). To run in Chrome you must tick **web**.
- This **replaces** `lib/firebase_options.dart` (a placeholder until then) and adds `android/app/google-services.json`.
- If it asks whether to overwrite `firebase.json`, answer **yes** for the Flutter config. The rules entry stays.
- You only need to run this again if you add a platform later.

### Step 7: Deploy the security rules

The rules enforce roles on the server: students can't change status, and only staff can. Without them, saving a report fails with `permission-denied`. Deploy them:

```bash
firebase login                       # once; opens your browser
firebase use campus-incident-reporter  # your project ID
firebase deploy --only firestore:rules
```

> **No CLI?** You can also paste the rules in by hand: copy the contents of `firestore.rules` into *Firestore Database → Rules*, then click **Publish**.

### Step 8: Run it

```bash
flutter pub get
flutter run
```

Register an account. You'll land on the student Home screen.

### Step 9: Create a staff account

Everyone registers as a student; staff are promoted by hand so nobody can promote themselves.

1. Register a second account in the app (e.g. `staff@yourcampus.edu`).
2. In the console, open **Firestore → `users`** and find the document for that account (its ID is the user's UID, shown under *Authentication → Users*).
3. Change the field `role` from `student` to `staff`.

The app switches that user to the **Staff Dashboard** straight away, with no re-login needed.

### Troubleshooting

| Symptom | Fix |
|---|---|
| "Firebase is not configured" screen | Step 6 wasn't run, or ran in another folder. Re-run `flutterfire configure` in the project root. |
| "Could not load reports. Is this account staff?" | The `role` field isn't exactly `staff`, or the rules from Step 7 aren't deployed. |
| `permission-denied` when submitting a report | The rules from Step 7 aren't deployed. |
| `flutterfire` is "not recognized" | See the Windows note in Step 1. |
| "One of the photos is too large" | The photo couldn't be compressed under 700 KB. Pick a different photo. |
| Chrome shows "Firebase is not configured" | Web wasn't selected in Step 6. Run `flutterfire configure` again and tick **web**. |

---

## 2. Features

**Students**
- Register and log in (email, password, name, program, campus), with password reset.
- Home: greeting, "Report an Issue" banner, summary cards (My Reports, In Progress, Resolved, Submitted), recent reports.
- Notification bell: a badge counts staff updates since you last looked; the list shows each new status with the staff note.
- Report an incident: category grid, title, description, location dropdown, up to 3 photos (camera or gallery, compressed before saving).
- My Reports: profile header, stats, status tabs, search by title, location or description, and a category filter.
- Incident details: status chip, status timeline, full history with staff notes, description, and photos (tap for a zoomable full-screen view).

**Staff**
- Dashboard with counts per status, search, status, category and sort filters.
- "Update status" sheet: new status, priority, and a **required note**. It's saved as a single batch write (the incident plus a timeline entry).

**Extra features**
1. **"Me too" upvote.** Other students can confirm an issue. This cuts duplicate reports, and staff can sort by it.
2. **Anonymous reporting.** `reporterId` is still stored for the security rules, but the name is shown as "Anonymous" to everyone except the reporter.
3. **Offline support.** Reports created offline show a **"Pending sync"** badge until they reach the server.
4. **Polish:** pull-to-refresh, empty states, and shimmer loading.

---

## 3. Architecture

Feature-first structure. **Screens talk only to cubits, cubits talk only to repositories, and only repositories touch Firebase.**

```
lib/
├── main.dart                 Firebase init (shows a setup screen if not configured)
├── firebase_options.dart     generated by `flutterfire configure`
├── app/                      app.dart, router.dart (role-based redirects), theme.dart
├── core/                     constants, validators, extensions, load_status
│   └── widgets/              status_chip, category_tile, report_card, stat_card,
│                             primary_button, empty_state, loading_list, incident_filters, ...
├── data/
│   ├── models/               app_user, incident, status_update
│   └── repositories/         auth_repository, incident_repository, photo_repository
└── features/
    ├── auth/                 AuthCubit + splash, login, register
    ├── home/                 student home + bottom-nav shell
    ├── report/               ReportFormCubit + report form
    ├── reports/              IncidentsCubit + My Reports
    ├── detail/               IncidentDetailCubit + details, timeline, photo viewer
    ├── staff/                StaffCubit + dashboard, update status sheet
    └── profile/              profile + logout
```

| Cubit | Responsibility |
|---|---|
| `AuthCubit` | Login, register, logout. Listens to `authStateChanges` **and** the user's profile doc, so role changes apply live. |
| `ReportFormCubit` | Validates and compresses photos, then saves the incident, its photos and its first `updates` entry in one batch. |
| `IncidentsCubit` | Streams the student's reports. Search and filters run on the loaded list. |
| `IncidentDetailCubit` | Streams one incident and its `updates` timeline, loads its photos, and handles "Me too". |
| `StaffCubit` | Streams all reports with counts per status; `updateStatus` uses a batch write. |

### Firestore data model

| Collection | Fields |
|---|---|
| `users/{uid}` | name, email, role (`student`/`staff`), program, campus, photoUrl, createdAt |
| `incidents/{id}` | title, description, category, location, photoCount, thumbnail (bytes), status, priority, reporterId, reporterName, isAnonymous, upvoters[], createdAt, updatedAt |
| `incidents/{id}/updates/{id}` | status, note, updatedBy, updatedByName, timestamp |
| `incidents/{id}/photos/{0,1,2}` | index, data (bytes) |

**No composite indexes are needed.** A student's reports are queried by `reporterId` only and sorted on the client. Firestore has no full-text search, so search also runs on the client.

### How photos are stored

The plan called for Firebase Storage, but new Firebase projects can only use Storage on the paid Blaze plan. To keep the project free, photos are stored **in Firestore as bytes**:

- Each photo is compressed to JPEG, stepping down in size and quality until it's under 700 KB (Firestore's limit is 1 MB per document).
- Each photo is its own document in `incidents/{id}/photos/`, written **in the same batch** as the incident. A report and its photos save together or not at all.
- A ~15 KB thumbnail is stored on the incident document, so report lists stay fast. Full photos load only when a report is opened.

Firestore's free tier (1 GB stored, 50,000 reads per day) is far more than a class project needs.

### Security rules (`firestore.rules`)
- New users can only create their profile as `student`, and can never change their own role.
- Students can only create their own reports, with status `submitted`. Title, description and photo limits are checked on the server too.
- Only staff can update an incident or add timeline entries. The one exception: the reporter writes the first "submitted" entry in the same batch that creates the incident.
- Students may only add or remove **their own** uid in `upvoters`.
- Photos can only be added by the reporter, in the batch that creates the incident, as bytes under 900 KB. They can't be changed afterwards.

### Validation
Title 5–80 characters · description at least 15 · category and location required · at most 3 photos · valid email · password at least 6 characters.

---

## 4. Tests

```bash
flutter test
```

41 tests cover the validators, models, role-based routing, all cubits (with mocked repositories), and widget smoke tests that render every main screen at phone size.
