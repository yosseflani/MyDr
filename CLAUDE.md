# MyDr

Flutter app for one household's health records: Hebrew-only, right-to-left. It has had no external security or medical review.
Overview: `README.md`; technical docs (Hebrew): `docs/`. Area rules: `.claude/rules/` (privacy and logging; first-aid content) and `lib/data/CLAUDE.md`. They are not repeated here.

## Forbidden

Most critical first

- Logging or showing medical data, keys, tokens or recovery keys; details in `.claude/rules/privacy-and-logging.md`. Reason: it is family health data.
- Creating an unencrypted database, exposing the database key, or removing the `sqlcipher` hook in `pubspec.yaml`. Reason: the whole local database must stay encrypted at rest.
- Deleting, resetting or overwriting user data without the user's explicit confirmation (`userConfirmed: true`), or a migration step that removes data. Reason: lost medical records cannot be recovered.
- Letting a record show up under, or link to, another family member, or loosening the composite member keys in `schema.drift`. Reason: each member's data must stay isolated.
- Multi-step deletes or moves outside a single `TransactionRunner` transaction. Reason: a failure must never leave partial changes.
- Diagnosing, giving medical advice, recommending medications, doses or treatment, or interpreting symptoms or medication records. Reason: MyDr only organizes; it is not a medical device.
- Network access in a build without cloud configuration, or automatic upload or background sync. Reason: data leaves the device only when the user starts a backup or a household sync, encrypted on the device first.
- Sending real medical data to any cloud project. Reason: backup and household sync are verified only against the local emulators, with fictional data.
- Sharing any profile other than a child's with the household. Reason: other relations differ per phone and are private; triggers in `schema.drift` enforce it.
- Medication names, family member names or a payload in notifications. Reason: they show on the lock screen, and the plugin stores them unencrypted.
- Describing visit photo or video files as encrypted on the device. Reason: only their records are encrypted; the files are not.
- Reading `.env`, or committing `config/firebase.json` or recovery keys. Reason: they hold secrets.
- Running `flutter test integration_test` on a device with real data. Reason: it uninstalls the app and deletes its data.
- Committing or pushing without the user's approval. Reason: changes are reviewed first (`/mydr-pre-commit-review`).

## Conventions

- Reuse or extend what exists; don't add a parallel model, repository, controller or widget. Reason: copies drift apart. For example, visit preparation shows the existing questions rather than a copy.
- Controllers are `ChangeNotifier`s. They reload from the repository after every change and return result enums, never raw errors.
- Models are immutable, with `copyWith` (clear a nullable field with `() => null`), `==`/`hashCode` and an id-only `toString()`.
- Tables are `STRICT`, with `CHECK` constraints and `ON DELETE RESTRICT`. A record linked to an appointment or medication uses a composite `(id, member_id)` key.
- Schema changes (a new record type also needs the steps in `lib/data/CLAUDE.md`):
  - Raise `LocalDatabase.currentSchemaVersion` and add an add-only `onUpgrade` step.
  - Test the upgrade against an encrypted file from the previous version.
  - Regenerate the Drift code and update `docs/local_storage.md`.
  - Include the new records in `BackupSnapshot`, which has its own `formatVersion`.
- All user-facing text lives in `lib/core/l10n/strings.dart` (Hebrew, right-to-left).
- Code that depends on the current time takes an injected `DateTime Function() clock` so tests can control it.
- Docs in `docs/` are written in Hebrew; `README.md` is in English.

## Stack & Architecture

- Flutter (Material 3). Development is on Windows; Android is verified, iOS has never been built.
- Flow: `lib/features/` (screens and controllers) → interfaces in `lib/data/repositories/` → a Drift implementation in `lib/data/local/repositories/` plus an in-memory one (demo and tests). A new repository needs both implementations, shared contract tests in `test/data/repositories/repository_contract_test.dart` where applicable (run against both), and dedicated tests for behavior that needs more specific coverage; see `lib/data/CLAUDE.md`.
- Wiring goes through `AppDependencies` (`local`, `withMockData`, `empty`) and `AppScope`.
- Local storage: Drift on SQLCipher, built through the `sqlite3` package hooks; the key is kept in `flutter_secure_storage`. Visit photos and videos are plain files in the app's private storage.
- Reminders: `flutter_local_notifications` and `timezone`; details in `docs/medication_reminders.md`.
- Emergency dialing: `url_launcher` opens the dialer and never places the call.
- Cloud (local emulators only), both encrypted on the device first:
  - Backup: Firebase Auth and Storage behind `CloudBackend`; AES-256-GCM with HKDF. Details: `docs/cloud_backup.md`.
  - Household sharing and sync: Cloud Firestore and Storage behind `HouseholdCloud`, with X25519 key wrapping; code in `lib/data/sync/` and `lib/features/sharing/`. Sync runs only when the user taps it. Details: `docs/household_sync.md`.

## Commands

Verified (ran successfully on 2026-10-20):
- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1`: runs `flutter analyze`, then `flutter test`, and stops at the first failure.
- `firebase emulators:start --project demo-mydr --only auth,firestore,storage` (run in `firebase/`; ports in `firebase/firebase.json`). It keeps running; stop it when done.
- Security rules, with the emulators running:
  - `dart run tool/household_rules_check.dart`: `firestore.rules` and the household part of `storage.rules`.
  - `dart run tool/storage_rules_check.dart`: the backup part of `storage.rules`.

Documented in the repository but not yet run:
- `flutter pub get`
- `flutter run` for the encrypted database. Add `--dart-define=MYDR_DEMO=true` for in-memory demo data, or `--dart-define=MYDR_FIRST_AID_REVIEW=true` for the debug-only first-aid review preview.
- `flutter run --dart-define-from-file=config/firebase.emulator.json`, with the emulators running.
- `dart run build_runner build --force-jit` after changing `lib/data/local/schema.drift`.
- `dart run tool/first_aid_review.dart` after changing first-aid content.
- `flutter test integration_test -d <device-id>`. Test devices only; see Forbidden.

## Open Questions

Unresolved. Ask the user; don't decide these yourself.
- Should `dart format` be a required check? The feature prompts ask for it, but `scripts/check.ps1` does not run it.
- `lib/data/backup/backup_service.dart` prints `PlatformException` messages in debug builds, although its own comment says messages can hold data. Is that acceptable?
- Test files mix relative and `package:` imports. Should they be standardized?
- Product decisions still open:
  - Encrypting visit photo and video files at rest.
  - An app lock and screenshot protection (`FLAG_SECURE`).
  - In-app account deletion.
  - A production Firebase project.
  - Background or on-reconnect household sync, and deleting a household from the app.
  - Separate notes versus extended questions for visit preparation.
