# MyDr

Flutter app for one household's health records: Hebrew-only, right-to-left, verified on Android only.
It has had no external security or medical review. Overview: `README.md`; technical docs (Hebrew): `docs/`.
Detailed rules live in `.claude/rules/` (privacy and logging; first-aid content) and are not repeated here.

## Forbidden

- Logging or showing medical data, keys, tokens or recovery keys; details in `.claude/rules/privacy-and-logging.md`. Reason: it is family health data.
- Creating an unencrypted database, exposing the database key, or removing the `sqlcipher` hook in `pubspec.yaml`. Reason: the whole local database must stay encrypted at rest.
- Deleting, resetting or overwriting user data without the user's explicit confirmation (`userConfirmed: true`), or a migration step that removes data. Reason: lost medical records cannot be recovered.
- Letting a record show up under, or link to, another family member, or loosening the composite member keys in `schema.drift`. Reason: each member's data must stay isolated.
- Multi-step deletes or moves outside a single `TransactionRunner` transaction. Reason: a failure must never leave partial changes.
- Diagnosing, giving medical advice, recommending medications, doses or treatment, or interpreting symptoms or medication records. Reason: MyDr only organizes; it is not a medical device.
- Hand-editing `docs/first_aid_medical_review.md`. Reason: it is generated, and tests fail when it differs from the content.
- Medication names, family member names or a payload in notifications. Reason: they show on the lock screen, and the plugin stores them unencrypted.
- Network access in a build without cloud configuration, or automatic upload or background sync. Reason: data leaves the device only when the user starts a backup or a household sync, encrypted on the device first.
- Sharing any profile other than a child's with the household. Reason: other relations differ per phone and are private; triggers in `schema.drift` enforce it.
- Sending real medical data to any cloud project. Reason: backup and household sync are verified only against the local emulators, with fictional data.
- Describing visit photo or video files as encrypted. Reason: only their records are encrypted; the files are not.
- Reading `.env`, or committing `config/firebase.json` or recovery keys. Reason: they hold secrets.
- Running `flutter test integration_test` on a device with real data. Reason: it uninstalls the app and deletes its data.
- Committing or pushing without the user's approval. Reason: changes are reviewed first (`/mydr-pre-commit-review`).
- Adding a parallel model, repository, controller or widget for something that already exists. Reason: copies drift apart. Reuse or extend; for example, visit preparation shows the existing questions rather than a copy.

## Conventions

- Layers: `lib/features/` → interfaces in `lib/data/repositories/` → a Drift implementation (`lib/data/local/repositories/`) plus an in-memory one (demo and tests). A new repository needs both, plus coverage in `test/data/repositories/repository_contract_test.dart`.
- Wiring goes through `AppDependencies` (`local`, `withMockData`, `empty`) and `AppScope`.
- Controllers are `ChangeNotifier`s. They reload from the repository after every change and return result enums, never raw errors.
- Models are immutable, with `copyWith` (clear a nullable field with `() => null`), `==`/`hashCode` and an id-only `toString()`.
- Tables are `STRICT`, with `CHECK` constraints and `ON DELETE RESTRICT`. A record linked to an appointment or medication uses a composite `(id, member_id)` key.
- Schema changes:
  - Raise `LocalDatabase.currentSchemaVersion` and add an add-only `onUpgrade` step.
  - Test the upgrade against an encrypted file from the previous version.
  - Regenerate the Drift code and update `docs/local_storage.md`.
  - Include the new records in `BackupSnapshot`, which has its own `formatVersion`.
- All user-facing text lives in `lib/core/l10n/strings.dart` (Hebrew, right-to-left).
- Code that depends on the current time takes an injected `DateTime Function() clock` so tests can control it.
- `lib/` imports use `package:mydr/...`. Docs in `docs/` are written in Hebrew; `README.md` is in English. Lints are the `flutter_lints` defaults.

## Stack

- Flutter (Material 3); the Dart SDK constraint is in `pubspec.yaml`.
- Local storage: Drift on SQLCipher, built through the `sqlite3` package hooks. The key is kept in `flutter_secure_storage`.
- Media: `image_picker`, `video_player`, `path_provider`.
- Reminders: `flutter_local_notifications`, `timezone`.
- Emergency dialing: `url_launcher`. It opens the dialer and never places the call.
- Cloud backup (emulator only): Firebase Auth and Storage behind `CloudBackend`. Encryption uses `cryptography` (AES-256-GCM, HKDF) and `crypto` (SHA-256).
- Household sharing and sync (emulator only): Cloud Firestore (`cloud_firestore`) and Storage behind `HouseholdCloud`; code in `lib/data/sync/` and `lib/features/sharing/`, X25519 key wrapping, details in `docs/household_sync.md`. Sync runs only when the user taps it.
- Code generation: `drift_dev` and `build_runner`.
- Platforms: development is on Windows. Android is verified; iOS has never been built.

## Commands

Verified (ran successfully on 2026-10-19):
- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check.ps1`: runs `flutter analyze`, then `flutter test`, and stops at the first failure.

Verified (ran successfully on 2026-10-20), cloud against the local emulators (ports in `firebase/firebase.json`: Auth 9099, Firestore 8080, Storage 9199):
- `firebase emulators:start --project demo-mydr --only auth,firestore,storage` (run in `firebase/`). It keeps running; stop it when done.
- Security rules, with the emulators running:
  - `dart run tool/household_rules_check.dart`: `firestore.rules` and the household part of `storage.rules` (38 checks).
  - `dart run tool/storage_rules_check.dart`: the backup part of `storage.rules` (12 checks).

Documented in the repository but not yet run:
- `flutter pub get`
- `flutter run` for the encrypted database. Add `--dart-define=MYDR_DEMO=true` for in-memory demo data, or `--dart-define=MYDR_FIRST_AID_REVIEW=true` for the debug-only first-aid review preview.
- `dart run build_runner build --force-jit` after changing `lib/data/local/schema.drift`.
- `dart run tool/first_aid_review.dart` after changing first-aid content.
- `flutter test integration_test -d <device-id>`. Test devices only; see Forbidden.
- `flutter run --dart-define-from-file=config/firebase.emulator.json`, with the emulators running.

## Open questions

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
