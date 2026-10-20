# MyDr

**Personal and family health management for Android, built with Flutter.**

MyDr helps one household keep its health information in one place: family member profiles, doctor appointments, questions for the doctor, a symptom journal, photos and videos to show at a visit, medications with dose reminders, and an emergency center with a first-aid library. The interface is Hebrew-only and laid out right-to-left.

All data is stored on the device in an encrypted database. If the user chooses, they can make an encrypted backup to the cloud and restore it on another device, and share selected children's profiles with the other parent through encrypted, user-initiated two-way sync.

> [!WARNING]
> MyDr has **not** had an external security audit or an external medical review. It does not diagnose, give medical advice or recommend treatment. It must not be used to store real medical information until those reviews are done. Cloud backup and household sync have **only been verified against the local Firebase Emulator Suite and automated tests** with fictional data. Household sync has never run between two real devices. Nothing is configured for a production Firebase project.

---

## Contents

- [Feature status](#feature-status)
- [Features](#features)
- [Technology stack](#technology-stack)
- [Architecture](#architecture)
- [Project structure](#project-structure)
- [Security and privacy](#security-and-privacy)
- [Getting started](#getting-started)
- [Testing](#testing)
- [Limitations and known issues](#limitations-and-known-issues)
- [Further documentation](#further-documentation)

---

## Feature status

| Area | Status | Notes |
|---|---|---|
| Family member profiles | ✅ Implemented | Stored in the encrypted local database |
| Appointments | ✅ Implemented | |
| Questions for the doctor | ✅ Implemented | Can be linked to an appointment |
| Symptom journal | ✅ Implemented | Records are shown as entered and never interpreted |
| Doctor visit preparation (photos and videos) | ✅ Implemented | Metadata is encrypted; **the media files themselves are not** |
| Medications and dose tracking | ✅ Implemented | |
| Medication reminders (local notifications) | ⚠️ Implemented, with platform limits | Verified on Android only. The OS may delay or suppress reminders |
| Emergency center (dialing 101 / 100 / 102) | ✅ Implemented | Opens the dialer and never places the call |
| First-aid library (7 topics) | ⚠️ Content not professionally approved | Shown as *"based on medical sources, not yet professionally approved"*. No topic is verified |
| First-aid draft review preview | 🧪 Developer tool | Debug builds only, behind a build flag |
| Account sign-in (email and password) | 🧪 Emulator only | Firebase Authentication, tested against the local emulator |
| Encrypted cloud backup and restore | 🧪 Emulator only | Not connected to a real Firebase project |
| Household sharing and two-way sync between parents | 🧪 Emulator and tests only | Children's profiles only; sync runs only when the user taps "Sync now". Never run on two real devices |
| Demo mode | 🛠️ Development only | Fictional data in memory, nothing saved |
| iOS | ❓ Not verified | The code is intended to support iOS, but it has never been built or tested |
| Automatic, scheduled or background backup and sync | ❌ Not implemented | Not allowed by the project rules (no automatic upload) |
| Account deletion from the app | ❌ Not implemented | Required by app stores before release |
| App lock / screenshot protection (`FLAG_SECURE`) | ❌ Not implemented | Deferred |
| Encryption of visit photo and video files at rest | ❌ Not implemented | Deferred |

---

## Features

### Home dashboard

The first tab is the home screen. It shows:

- An emergency card with a one-tap button that opens the dialer with 101.
- A summary of family members and an entry to the account and backup screen.
- Quick actions: new appointment, log a symptom, questions for the doctor.
- The next appointment and recent symptoms.

The home screen never connects to the network.

Bottom navigation: **Home · Family · Appointments · Symptoms · Medications**.

### Family profiles

- Add, edit, view and delete family members.
- Each profile has a name, relation (self, spouse, child, parent, sibling, grandparent, other), optional birth date (age is calculated from it), allergies, chronic conditions and notes.
- Only one profile can be marked as "me". The database enforces this.
- A member's profile page shows that member's appointments, questions, symptoms and medications.
- Deleting a member needs explicit confirmation. The dialog shows how many related records will be removed. The member and all their records are deleted in **one atomic transaction**.

### Appointments

- Add, edit and delete appointments for a family member: doctor name, date and time, and optionally specialty, location and notes.
- Upcoming and past lists, with a filter by family member.
- An appointment cannot be moved to a different family member while it has photos or videos, so documentation never moves to another profile.

### Questions for the doctor

- Write questions per family member and optionally link them to an appointment.
- Mark a question as handled and record the doctor's answer.
- Filter by family member and by status (not yet handled / handled).
- The database guarantees that a question can only be linked to an appointment of the same family member.

### Symptom journal

- Log a symptom for a family member: name, start time, a subjective severity rating from 1 to 5, status (ongoing / resolved), optional duration and notes.
- Journal view, newest first and grouped by day, with a filter by family member.
- A per-symptom track lists all records with the same symptom name for one member, oldest first.
- The app shows exactly what was entered: no trends, charts or interpretation.

### Doctor visit preparation

This section is on the appointment detail screen. It brings together what to take to the visit:

- **Questions for the doctor**, from the existing questions feature (not a copy).
- **Photos and videos** of symptoms that may change or go away before the visit:
  - Take a photo or a short video (up to 60 seconds) with the camera, or pick existing files from the gallery.
  - Add and edit a description for each item. View photos with zoom and play videos in the app.
  - Files are validated before saving: an allowed extension (JPG/PNG/WEBP/HEIC, MP4/MOV/M4V/3GP), a file signature that matches the type, and a size limit (25 MB per photo, 150 MB per video).
  - Files are copied into the app's private storage under random names. Camera captures are not saved to the gallery, and the user's original gallery files are never deleted.
  - Deleting an item needs confirmation. Files left without a record are cleaned up at the next start.

### Medications and reminders

- Add, edit, view and delete a family member's medications: name, dose (free text), optional instructions, 1–8 daily reminder times, a start date and an optional end date. The end date is inclusive.
- Medications are grouped as active, not yet started or ended. The app shows today's doses and up to 5 upcoming doses in the next week.
- Mark a scheduled dose as **taken** or **skipped**, change the mark or clear it. This works for today's doses and the past week, not for future days. Each scheduled dose has at most one record.
- A per-medication history shows all dose records.
- **Local reminders** on Android (and, untested, on iOS):
  - Planned from the saved medications. Up to 48 notifications, at most 14 days ahead.
  - Rescheduled after every change, at every start and whenever the app returns to the foreground.
  - Doses already marked get no reminder.
  - **Every notification has the same generic text.** No medication name, dose or family member name, and no payload.
  - Notification permission is requested only after the first medication is added. If the user refuses, everything except the notifications keeps working.
- MyDr records medications exactly as the user enters them. It does not recommend medications, doses or treatment changes, and it draws no conclusions from the records. The medication screens show this notice.

### Emergency center and first aid

- **Emergency dialing:** a large button for Magen David Adom (**101**), plus police (**100**) and fire and rescue (**102**). The numbers are kept in code and were checked against gov.il on 2026-10-15. The buttons open the phone dialer with the number filled in. They never place the call, so the app needs no phone permission.
- The dial buttons are built from constants with nothing to load. They stay available even when the first-aid content or the database fails to load.
- **First-aid library:** seven topics: CPR and AED use, choking, bleeding, burns, unconsciousness, seizures, and severe allergic reaction.
  - Each topic can include an overview, signs to recognize, when to call 101 right away, numbered steps, what not to do, warnings, aftercare and its cited sources with dates.
  - When guidance differs by age or situation (for example adult, child or infant), no steps are shown until the user picks one. The prompt *"If you are not sure which applies, call 101"* is always shown next to the choice.
  - Every topic screen has a fixed 101 button.
- **Content status:** all seven topics are marked `sourced`. The guidance was written from medical sources that were checked and cited, but **no medical professional has approved it for MyDr**, and the app says so prominently. No topic is `verified`, and the list of approvals in code (`FirstAidApprovals.trusted`) is empty.
  - A topic counts as verified only if a code-reviewed approval includes a SHA-256 fingerprint of its exact content. Any change cancels the approval.
  - The content parser rejects malformed, incomplete or unsourced content. In that case no guidance is shown and the dial buttons still work.
- **Review preview (developer tool):** in a debug build run with `MYDR_FIRST_AID_REVIEW=true`, the emergency center links to the draft content with reviewer notes, under a persistent "draft, not approved" banner. Release builds never show it.

### Account and encrypted cloud backup (experimental)

> [!IMPORTANT]
> This feature has only been tested against the **Firebase Local Emulator Suite** (`demo-mydr` project, fictional data). It is **not configured for production**: no real Firebase project, App Check, quotas or account deletion. No real medical data has been uploaded anywhere. See [docs/cloud_backup.md](docs/cloud_backup.md), section 8, for what is missing.

When the build includes a cloud configuration, the home screen shows a "Backup and account" card. The screen lets the user:

- Create an account, sign in with email and password, reset the password and sign out.
- Generate a **recovery key** (128 random bits, shown as 28 characters with check characters). The key is shown once and confirmed by typing its last 4 characters. It is stored per account in the OS secure storage and can be shown again.
- **Back up now**, with a progress bar. The backup includes every record and every visit photo and video. The screen shows the last backup time and the list of cloud backups (date and encrypted size).
- **Restore** on another device: sign in, enter the recovery key, pick a backup, review a summary of what will be replaced and confirm explicitly.

How it works:

- **End-to-end encryption on the device.** HKDF-SHA256 derives a separate key for each object, which is then encrypted with AES-256-GCM in 1 MiB chunks. The server only stores ciphertext.
- **Safe restore.** Everything is downloaded, decrypted and validated into a private temporary folder first, and nothing on the device changes before the user confirms. All records are then replaced in one transaction. If anything fails, the device stays exactly as it was.
- **Safe backups.** A manifest is uploaded last, so an interrupted backup never appears in the list. The two latest complete backups are kept. An older one is deleted only after a newer one has finished.
- **Storage rules** (`firebase/storage.rules`): each account can reach only `users/{uid}/backups/`. Objects can't be overwritten, are limited to 200 MB, and every other path is denied.
- **No network without configuration.** A build without cloud defines has no cloud backup and does not connect to the network. With a configuration, the app connects only when the backup screen is opened.
- **Losing the recovery key means losing the backup.** This is by design: there is no server-side recovery.

### Household sharing and sync (experimental)

> [!IMPORTANT]
> Verified only with automated tests (two real encrypted databases against an in-memory cloud) and the Firebase emulators (`demo-mydr`, fictional data). It has **not** been run between two real devices or against a real Firebase project, and has had no external security review. See [docs/household_sync.md](docs/household_sync.md).

In a build with a cloud configuration, the home screen shows a "Family sharing" card. With the same account as backup, a parent can:

- **Create a household** and **invite the other parent** with a one-time 28-character code, passed in person or by phone. No credentials are shared. The invitee **accepts or rejects**; the inviter then **completes** the addition after comparing key fingerprints.
- **Manage members:** admins change roles and remove members; any member can leave.
- **Choose which children to share.** Only `child` profiles can be shared (the database enforces it). Each parent's own profile, the spouse's and other relatives' stay on the device and are never uploaded.
- **Sync now.** All records of shared children sync both ways: profile, appointments, questions, symptoms, medications, dose records, and visit photos and videos. **There is no background or automatic sync**; offline changes are kept and sent at the next sync the user starts.
- **Resolve conflicts** on a dedicated screen that shows both versions as entered.

How it works:

- **Change tracking** by database triggers, in the same transaction as each change. Each shared record has a **version vector**, the time and device of its last change, and a **tombstone** once deleted, so deleted records never come back.
- **Per-device append-only change logs** in Cloud Firestore; each sync pulls and merges the other devices' batches in **one transaction**, then pushes local changes.
- **Merging:** changes to different fields combine; the same field changed differently becomes a **conflict for the user**, never a silent overwrite. **Deletions from another device are applied only after the user confirms** them, through the app's normal deletion.
- **No duplicate doses:** a scheduled dose has a deterministic id from its medication and time; the same status recorded on both phones merges (keeping the later recording time); different statuses are a conflict.
- **Encryption on the device:** every batch and photo is encrypted with a household key (AES-256-GCM, per-object HKDF) before upload. Each member has an **X25519 identity key** kept in secure storage; the household key is wrapped for each member and authenticated by a member the recipient already verified. Invitations authenticate both public keys with MACs derived from the code, so the server cannot swap keys. **Removing a member rotates the household key.**
- **Security rules** (`firebase/firestore.rules`, `firebase/storage.rules`) let only members read or write a household, only admins manage it, and never overwrite a log batch or photo. 38 emulator checks pass (`tool/household_rules_check.dart`).
- **Reminders** are rescheduled from the synced data after every sync that changed something; notification ids come from the dose time, so there are no duplicates.
- **Restoring a backup** resets the device's sync history in the same transaction, so a restore never pushes mass deletions; the next sync compares with the household and turns differences into conflicts.
- **What the server can see:** member account ids, emails (shown to other members), roles and public keys; when and from which (random) device id each encrypted batch or photo was written, and its size; invitation times. Never names, record contents or record ids.

### Demo mode (development only)

`--dart-define=MYDR_DEMO=true` starts the app on in-memory repositories filled with fictional data. A banner says that changes are not saved. In demo mode nothing is persisted, no reminders are scheduled and cloud backup is not available.

---

## Technology stack

| Concern | Technology |
|---|---|
| UI framework | Flutter (Material 3), Dart SDK `^3.10.4` |
| Localization | Hebrew only (`flutter_localizations`), right-to-left, strings in `lib/core/l10n/strings.dart` |
| Local database | [Drift](https://pub.dev/packages/drift) on SQLite, built as **SQLCipher** through the `sqlite3` package build hooks |
| Key storage | `flutter_secure_storage` (Android Keystore / iOS Keychain) |
| Media | `image_picker`, `video_player`, `path_provider` |
| Reminders | `flutter_local_notifications`, `timezone` |
| Emergency dialing | `url_launcher` (`tel:` links) |
| Cloud (experimental) | `firebase_core`, `firebase_auth`, `firebase_storage`, `cloud_firestore` (household sharing) |
| Backup and sync cryptography | `cryptography` (pure Dart AES-GCM, HKDF, HMAC, X25519), `crypto` (SHA-256) |
| Code generation | `drift_dev`, `build_runner` |
| Linting | `flutter_lints` |

There is no AI or machine learning in the app.

---

## Architecture

MyDr is organized in layers: **features** (screens, widgets and controllers) depend only on **repository interfaces**, and those interfaces have interchangeable **implementations**.

```
┌──────────────────────────────────────────────────────────────┐
│ UI: lib/features/*  (screens and widgets)                    │
│        │  reads and listens via AppScope                     │
│ Controllers: ChangeNotifier per feature                      │
│   (FamilyController, AppointmentController,                  │
│    MedicationController, BackupController, ...)              │
├──────────────────────────────────────────────────────────────┤
│ Repository interfaces: lib/data/repositories/*               │
│ TransactionRunner, ReminderScheduler, CloudBackend,          │
│ EmergencyDialer, MediaPicker, FirstAidRepository             │
├───────────────────────────────┬──────────────────────────────┤
│ Local (regular mode)          │ In-memory (demo and tests)   │
│ Drift + SQLCipher             │ lib/data/repositories/       │
│ lib/data/local/repositories/  │   in_memory/                 │
└───────────────────────────────┴──────────────────────────────┘
```

Key points:

- **Dependency injection.** `AppDependencies` (`lib/core/app_dependencies.dart`) holds the single shared instance of every repository and service. It has three factories: `local(database)` for the encrypted database, `withMockData` for demo mode and `empty` for tests. `AppScope` exposes the dependencies and controllers to the widget tree.
- **Startup.** `MyDrBootstrap` (`lib/app_bootstrap.dart`) opens the encrypted database while a startup screen is shown. If opening fails (missing key, wrong key or damaged file, newer schema, unavailable secure storage or encryption), the screen explains the problem and offers a retry. **It never deletes or resets data**, and emergency dialing and the first-aid library stay available.
- **Atomic multi-step operations.** Deleting a family member with all their records, deleting a medication with its dose records, deleting an appointment and moving an appointment to another member all run in one `TransactionRunner` transaction. Partial changes are never saved.
- **Data integrity in the database.** The tables are `STRICT` (schema version 4, `lib/data/local/schema.drift`), with foreign keys, composite keys that keep linked records on the same family member, `CHECK` constraints and unique indexes. Schema migrations only add data and are tested against encrypted files from the previous version.
- **Reminders are not stored.** The pure `ReminderPlanner` rebuilds them from the saved medications, and `ReminderScheduler` replaces all pending notifications.
- **Cloud is behind an interface.** `CloudBackend`, `AccountService` and `BackupStorage` contain no Firebase types. `FirebaseCloudBackend` is the only Firebase adapter, and tests use fakes.
- **First-aid content is data.** It lives in JSON assets (`assets/first_aid/`), separate from the code that shows it, and `FirstAidContentParser` validates it in a published mode and a review mode.

---

## Project structure

```
lib/
  main.dart                 Entry point: regular mode or demo mode
  app.dart                  MyDrApp: controllers, Hebrew RTL locale, lifecycle (reminder resync)
  app_bootstrap.dart        Opens the encrypted database; loading and error screens
  core/
    app_dependencies.dart   Dependency container (local / demo / test)
    app_scope.dart          Exposes dependencies and controllers to widgets
    l10n/strings.dart       All user-facing Hebrew strings
    theme/                  Colors and theme
    widgets/                Shared widgets (cards, empty states, error views, ...)
  data/
    models/                 FamilyMember, Appointment, DoctorQuestion, SymptomEntry,
                            VisitMedia, Medication, DoseRecord, FirstAidContent
    repositories/           Repository interfaces + in-memory implementations
    local/                  Drift schema, SQLCipher opener, key store, local repositories
    media/                  Media validation, private file store, picker
    reminders/              Reminder planner and local-notification scheduler
    emergency/              Emergency numbers and dialer
    first_aid/              Content parser, approvals, review document generator
    backup/                 Recovery key, backup cipher, snapshot format, record JSON, backup service
    cloud/                  Cloud interfaces (backup, household), Firebase adapter, key stores
    sync/                   Household crypto, household service, sync engine, merge
    mock/                   Fictional demo data
  features/
    shell/                  Bottom navigation
    dashboard/              Home screen and cards
    family/                 Profiles
    appointments/           Appointments
    questions/              Questions for the doctor
    symptoms/               Symptom journal and per-symptom track
    visit_preparation/      Photos and videos for a visit
    medications/            Medications, doses, reminder status
    emergency/              Emergency center, first-aid library, review preview
    backup/                 Account, backup and restore screen
    sharing/                Family sharing, invitations, sync status, conflicts
assets/first_aid/           he.json (published content), review/he.draft.json (drafts)
config/                     firebase.emulator.json, firebase.example.json (template)
firebase/                   firestore.rules, storage.rules, firebase.json (emulators), .firebaserc (demo-mydr)
docs/                       Technical documentation (Hebrew) and development prompts
integration_test/           On-device tests: encryption, persistence, cloud backup
test/                       Unit, widget and flow tests; helpers/ contains fakes
tool/                       first_aid_review.dart, storage_rules_check.dart, household_rules_check.dart
scripts/check.ps1           Runs flutter analyze, then flutter test
```

---

## Security and privacy

**Local storage**

- The whole database file (`mydr.sqlite`, in the app's private folder) is encrypted with SQLCipher. Before the key is applied, the opener checks that SQLCipher is present, so an unencrypted database is never created.
- A 32-byte random key is generated on first launch and kept in the OS secure storage. On iOS it uses the Keychain with `first_unlock_this_device`, which is not synced. The key never appears in code, logs or files.
- Android OS backup and device-to-device transfer are disabled (`allowBackup="false"`, data extraction rules). Moving to a new phone is possible only through MyDr's own encrypted backup.
- Error messages and the `toString()` of every model contain only error types and ids, never medical content.

**Media files**

- Visit photo and video *records* (descriptions, links, sizes) are in the encrypted database. **The files themselves are not encrypted.** They are protected only by the app's private storage.

**Notifications**

- Reminder notifications have a generic title and text, with no medical details and no payload. On Android they are marked `VISIBILITY_PRIVATE`.

**Network**

- A build without cloud configuration has no cloud backup and does not connect to the network. The first build downloads the SQLCipher library from GitHub and checks its SHA-256.
- Connecting to the Firebase emulator is allowed only in non-release builds with a `demo-` project. Plain HTTP is allowed only in debug builds, and only to `10.0.2.2`, `localhost` and `127.0.0.1`.
- The cloud only receives data encrypted on the device. For backups the server can see the account id, backup times, encrypted sizes and object counts. For household sharing, see the metadata list above.
- Firestore's local cache is disabled, and its network access is switched on only while a sharing action the user started runs.

**Known security gaps** (see also [Limitations](#limitations-and-known-issues))

- No app lock and no screenshot protection.
- No protection on a rooted or jailbroken device, or against malware while the device is unlocked.
- No external security audit has been done.

---

## Getting started

### Prerequisites

- Flutter SDK (stable channel) with Dart `^3.10.4`.
- An Android device or emulator. Android is the only platform that has been verified.
- Network access for the **first** build, which downloads SQLCipher.
- *Optional, for cloud backup:* the [Firebase CLI](https://firebase.google.com/docs/cli) to run the local emulators.

### Run

```sh
flutter pub get

# Regular mode: encrypted local database, starts empty
flutter run

# Demo mode: fictional data in memory, nothing saved
flutter run --dart-define=MYDR_DEMO=true

# Debug only: adds the first-aid draft review preview to the emergency center
flutter run --dart-define=MYDR_FIRST_AID_REVIEW=true
```

### Build-time options

| Define | Effect |
|---|---|
| `MYDR_DEMO=true` | Demo mode (in-memory fictional data) |
| `MYDR_FIRST_AID_REVIEW=true` | First-aid review preview; ignored in release builds |
| `MYDR_FIREBASE_PROJECT_ID`, `MYDR_FIREBASE_EMULATOR_HOST` | Cloud backup against the local emulators (`demo-` project, non-release builds) |
| `MYDR_FIREBASE_API_KEY`, `MYDR_FIREBASE_APP_ID`, `MYDR_FIREBASE_SENDER_ID`, `MYDR_FIREBASE_STORAGE_BUCKET` | A real Firebase project. **Not set up or tested.** See `config/firebase.example.json` |
| `MYDR_FIREBASE_AUTH_PORT`, `MYDR_FIREBASE_STORAGE_PORT`, `MYDR_FIREBASE_FIRESTORE_PORT` | Emulator ports (default 9099 / 9199 / 8080) |

Without any `MYDR_FIREBASE_*` defines, the build has no cloud backup.

### Cloud backup against the local emulators

```sh
# Terminal 1: no Firebase account or secrets needed
cd firebase
firebase emulators:start --project demo-mydr --only auth,firestore,storage

# Terminal 2, from the project root
flutter run --dart-define-from-file=config/firebase.emulator.json   # Android emulator reaches the host at 10.0.2.2
```

`config/firebase.json`, for a real project's settings, is git-ignored and does not exist in the repository.

### Regenerate code and content

```sh
# After changing lib/data/local/schema.drift (the build hooks need JIT mode)
dart run build_runner build --force-jit

# After changing first-aid content: regenerates docs/first_aid_medical_review.md
dart run tool/first_aid_review.dart
```

---

## Testing

```sh
# Static analysis, then all unit, widget and flow tests (stops at the first failure)
powershell -File scripts/check.ps1

# Or separately
flutter analyze
flutter test        # runs against real SQLCipher on the host
```

On 2026-10-19, `scripts/check.ps1` passed: `flutter analyze` found no issues, and all 1,127 tests passed. The same day, against the local emulators, all 38 household rule checks and all 12 storage rule checks passed.

The test suite covers:

- **Repository contract:** the in-memory and database implementations behave identically.
- **Database:** encryption, key handling, constraints, codecs, migrations from previous schema versions, and transaction atomicity.
- **Features:** controllers, screens and end-to-end flows in `MyDrApp`, including narrow screens with large text.
- **Reminders:** planner rules and the notification scheduler against the plugin's platform channel.
- **First-aid content:** parser validation, bundled content, and that the published content matches the drafts and the review document.
- **Backup:** cipher, recovery key, snapshot format and the full backup/restore service across two real encrypted databases with a fake cloud.
- **Household sync:** crypto (wrapping, rotation, invite MACs, swapped keys), merge rules, version vectors, dose dedup, and a two-device, two-account simulation over real encrypted databases and a fake cloud that enforces the security rules: invitation, offline edits and reconnect, concurrent edits, delete propagation and tombstones, revocation, and restore. Also the v3 to v4 migration from an encrypted file, the sync state repository contract, the controller and the screens.

**On-device integration tests**

> [!CAUTION]
> `flutter test integration_test` installs a test build **and uninstalls the app at the end, deleting its data**. Never run it on a device that has real data.

```sh
flutter test integration_test -d <device-id>

# Cloud backup end to end, with the Firebase emulators running
flutter test integration_test/cloud_backup_test.dart -d <test-emulator> \
  --dart-define-from-file=config/firebase.emulator.json

# Security rules, with the Firebase emulators running
dart run tool/storage_rules_check.dart
dart run tool/household_rules_check.dart
```

According to [docs/exercise_4_final_report.md](docs/exercise_4_final_report.md), the cloud backup integration test passed on an Android 16 emulator against the Firebase emulators: back up on phone A, block access from another account, and restore on phone B, including a photo that matched byte for byte. All 12 storage rule checks passed.

---

## Limitations and known issues

**Cloud backup**
- Verified **only** against the local Firebase Emulator Suite. It has not been connected to a real Firebase project.
- Before production it still needs: a real project and storage region, App Check, quotas and billing alerts, in-app account deletion, a privacy policy, and an external security and privacy review.
- The `contentType` condition in the storage rules could not be tested, because the emulator ignores the content type that is sent.
- No real network interruption during upload or download has been tested on a device; it has only been tested with a fake storage. Backing up a large (~150 MB) video has not been measured.
- Backup is manual only (no scheduled backup), and a restore replaces all data on the device (no merging). Signing out does not delete local data.

**Household sync**
- **User-initiated only:** no background, scheduled or on-reconnect sync, because the project rules forbid automatic upload. Changing that is a product decision.
- Never run between two real devices or against a real Firebase project; no external security or cryptography review.
- Data already shared stays with a removed member; it cannot be deleted remotely. The cloud log is never compacted, and logs and photos of unshared children or abandoned households stay in the cloud (encrypted). There is no in-app account or household deletion.
- Losing a device's identity key (reinstall) means being removed and invited again. Duplicate profiles created separately by both parents are not merged.
- See [docs/household_sync.md](docs/household_sync.md), section 10.

**Platforms**
- Only Android has been tested. iOS has not been built or tested; development was done on Windows. The other platform folders (Windows, Linux, macOS, Web) are Flutter scaffolding and have not been tested.
- Reminders are not supported on Windows, Web or in tests, and the app says so on screen.

**Reminders**
- They may be delayed or suppressed by battery optimization, Do Not Disturb, vendor background restrictions or disabled notifications.
- From Android 14 the exact-alarm permission is off by default, so reminders may arrive a few minutes late.
- Only the next 48 reminders within 14 days are scheduled, with no background refresh. A user who does not open the app for longer stops getting reminders.

**Data and security**
- Visit photo and video files are not encrypted at rest.
- If the database key is lost, local data cannot be recovered, and there is no in-app "start over". The only option is clearing the app data in the device settings.
- No app lock and no screenshot protection.
- Before distribution, the SQLCipher and OpenSSL licenses have to be included.

**Medical content**
- No first-aid topic has been approved by a medical professional.
- MyDr provides no diagnosis or medical advice, and it never interprets symptoms or medication records.

---

## Further documentation

The detailed technical documents are in Hebrew:

| Document | Topic |
|---|---|
| [docs/local_storage.md](docs/local_storage.md) | Encrypted local storage: schema, keys, migrations, opening errors, media files |
| [docs/cloud_backup.md](docs/cloud_backup.md) | Account and cloud backup: cryptography, restore safety, storage rules, production checklist |
| [docs/household_sync.md](docs/household_sync.md) | Household sharing and two-way sync: invitations, keys, merge rules, conflicts, security rules, metadata, limitations |
| [docs/medication_reminders.md](docs/medication_reminders.md) | Medications and reminders: architecture, notification privacy, platform limits, Android manual test plan |
| [docs/first_aid_content_policy.md](docs/first_aid_content_policy.md) | First-aid content policy: sources, schema, content states, approval process |
| [docs/first_aid_medical_review.md](docs/first_aid_medical_review.md) | Generated medical review document for every topic (do not edit by hand) |
| [docs/exercise_4_final_report.md](docs/exercise_4_final_report.md) | Final report for the cloud backup feature, with test results |
| [docs/prompts/](docs/prompts/) | The prompts used to develop the visit preparation and medication features |

---

> **Disclaimer:** MyDr is a personal organization tool. It is not a medical device and does not replace professional medical care. In an emergency in Israel, call **101** (Magen David Adom).
