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
5. Check whether generated files or documentation need updating.
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
