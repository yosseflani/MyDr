---
name: mydr-pre-commit-review
description: Review MyDr project changes before a Git commit. Use when asked to check changes, review code before committing, or verify that the project is ready for a commit.
---

# MyDr Pre-Commit Review

Review the current changes in the MyDr Flutter project before committing.

## Workflow

1. Run `git status` and inspect staged and unstaged changes.
2. Run `git diff --check` and `git diff --cached --check`.
3. Check that no secrets, passwords, API tokens, recovery keys, `.env` files, or `config/firebase.json` are staged.
4. Review changes for privacy, security, and unintended data loss.
5. Check the MyDr rules that apply to what the diff touches:
   - `lib/data/local/schema.drift`: `LocalDatabase.currentSchemaVersion` raised, an add-only `onUpgrade` step, `local_database.g.dart` regenerated, `docs/local_storage.md` updated, and the new records included in `BackupSnapshot`.
   - First-aid content (`assets/first_aid/`, `lib/data/first_aid/`): `dart run tool/first_aid_review.dart` was run, and `docs/first_aid_medical_review.md` was not edited by hand.
   - New or changed models: `toString()` shows the id only.
   - Deletes or moves: they require `userConfirmed: true` and run in a single `TransactionRunner` transaction.
   - A new repository: both a Drift and an in-memory implementation, plus coverage in `test/data/repositories/repository_contract_test.dart`.
   - Notifications: no medication or member names and no payload.
   - User-facing text: in `lib/core/l10n/strings.dart`.
6. Run `scripts/check.ps1` from PowerShell when the environment supports it.
7. Report the results clearly:
   - Changed files
   - Tests passed or failed
   - Security or privacy risks
   - Recommended fixes
   - Whether the changes appear ready for commit

## Safety

- Never commit or push automatically.
- Never discard or overwrite user changes.
- Do not modify files unless explicitly requested.
- Do not print secret values in the report.
- If a check cannot run, report it as not verified rather than passed.
