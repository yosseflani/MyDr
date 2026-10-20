# Privacy and Logging Rules

Source: docs/local_storage.md

MyDr holds family health data, so anything that reaches a log, an error or a diagnostic screen has to be treated as leaving the app.

- Never log personal, medical, or sensitive user information.
- Do not expose patient records, encryption keys, database keys, recovery keys, passwords, or authentication tokens in error messages or diagnostics.
- Give models an id-only `toString()`, because objects end up in logs and test output through string interpolation.
- Report errors by their type only, never their message, because platform and plugin messages can contain data. Controllers return result enums rather than raw errors.
- Do not add new prints of exception messages, even debug-only. Whether the existing `PlatformException` print in `lib/data/backup/backup_service.dart` is acceptable is an open question in `CLAUDE.md`; leave it as is.
- Keep debugging information minimal and privacy-preserving.
- Do not weaken existing privacy or encryption protections when modifying the application.
