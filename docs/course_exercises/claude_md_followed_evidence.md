# ראיות: Claude Code פעל לפי CLAUDE.md

**תאריך:** 19 באוקטובר 2026
**מטרה:** תיעוד לתרגיל בקורס DDOS. המסמך מראה, לכל בקשה בשיחה אחת, את הבקשה המדויקת, מה Claude Code עשה, ואיזה כלל ב־`CLAUDE.md` (או ב־`.claude/rules/`) הפעולה מקיימת.
**מצב:** המסמך, `CLAUDE.md` ו־`lib/data/CLAUDE.md` נכללים ב־Commit מקומי אחד, שנוצר באישור המשתמש (בקשה 7). לא בוצע Push. במהלך בקשות 1–6 הקבצים לא היו במעקב, ושום דבר לא נוסף ל־staging ולא נשמר ב־Commit.

> **מגבלה:** את המסמך כתב Claude Code עצמו, והוא מתאר את הפעולות שלו. אפשר לאמת אותו מול תמליל השיחה, מול `git status` ומול הרצה חוזרת של `scripts/check.ps1`.

---

## 1. בקשה ראשונה: הכנת `CLAUDE.md` ל־Commit

### הבקשה המדויקת

```text
Please review the current Git working tree and prepare the new project instruction file for a commit. Show me the proposed commit message and the files that would be included. Do not explicitly commit or push anything yet.
```

### מה נעשה, ולפי איזה כלל

| פעולה | הכלל ב־`CLAUDE.md` |
|---|---|
| הופעל ה־skill `mydr-pre-commit-review` לפני כל דבר אחר. | "Committing or pushing without the user's approval. Reason: changes are reviewed first (`/mydr-pre-commit-review`)." |
| לא בוצע Commit, לא בוצע Push, ולא נוסף שום קובץ ל־staging. הוצגו רק הודעת Commit מוצעת ורשימת קבצים. | אותו כלל (Forbidden). |
| נבדק שאין סודות בקובץ, ושהוא לא מתעלם ממנו ב־`.gitignore`. `.env` לא נקרא. | "Reading `.env`, or committing `config/firebase.json` or recovery keys." |
| כל נתיב שמוזכר ב־`CLAUDE.md` נבדק מול הקבצים בפועל, כולל `LocalDatabase.currentSchemaVersion` וה־hook של `sqlcipher` ב־`pubspec.yaml`. | Conventions ו־Stack: לוודא שההוראות מתארות את הקוד. |
| הורצה הבדיקה המאומתת היחידה: `scripts/check.ps1`. התוצאה: `flutter analyze` בלי בעיות, 1038 בדיקות עברו, קוד יציאה 0. | Commands: "Verified (ran successfully on 2026-10-19)". |
| השאלה הפתוחה על `backup_service.dart` הוצגה למשתמש, ולא הוכרעה. | Open questions: "Unresolved. Ask the user; don't decide these yourself." |

### הודעת ה־Commit שהוצעה

```text
Add CLAUDE.md project instructions for Claude Code

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

---

## 2. בקשה שנייה: הצעה לשיפור הדיבאג בכשלים

### הבקשה המדויקת

```text
I want to improve debugging for failed medical record operations in MyDr. Please inspect the relevant code and propose what diagnostic information should be logged when an operation fails. Explain your reasoning. Do not modify any files.
```

### מה נעשה, ולפי איזה כלל

| פעולה | הכלל |
|---|---|
| נקראו רק קבצים, ולא שונה שום קובץ. | הבקשה עצמה ("Do not modify any files"). |
| ההצעה מתירה רישום של שדות מרשימה סגורה בלבד: שם הפעולה, השלב, סוג השגיאה (`LocalDataError`, `MediaFileError`), קוד התוצאה המספרי של SQLite ומצב הטרנזקציה. | "Logging or showing medical data … error messages (error type only)." ו־`privacy-and-logging.md`: "Use safe error types and generic messages". |
| ההצעה אוסרת במפורש לרשום: טקסט של חריגות, SQL ופרמטרים, מזהי רשומות ובני משפחה, ערכי שדות, שמות קבצים ונתיבים, מפתחות וטוקנים. | אותו כלל, ו־`privacy-and-logging.md`: "Never log personal, medical, or sensitive user information." |
| ההצעה דוחה קובץ לוג במכשיר (לא מוצפן) ודיווח קריסות לרשת. | "Creating an unencrypted database…" ו־"Network access in a build without cloud configuration…" |
| ההצעה משתמשת בסוגי השגיאות הקיימים, ולא מוסיפה סיווג מקביל. | "Adding a parallel model, repository, controller or widget for something that already exists." |
| תוצאות הממשק (`SymptomSaveResult` וכו') נשארות כמו שהן, ו־Controllers ממשיכים להחזיר enums. | Conventions: "They reload from the repository after every change and return result enums, never raw errors." |
| שלוש החלטות נשארו למשתמש: רישום ב־release, stack traces, והשאלה על `backup_service.dart`. Claude Code נתן המלצה, אבל לא הכריע. | Open questions: "Ask the user; don't decide these yourself." |

---

## 3. בקשה שלישית: יצירת המסמך הזה

### הבקשה המדויקת

הבקשה הגיעה קטועה, כפי שהודבקה מהטרמינל (כולל שבירות השורות):

```text
Create docs/course_exercises/claude_md_followe
  d_evidence.md as evidence for the DDOS course
  exercise. Include the exact use
```

הבקשה הובנה כ"כלול את הבקשות המדויקות של המשתמש" (exact user prompts), ושם הקובץ הובן כ־`claude_md_followed_evidence.md`.

### מה נעשה, ולפי איזה כלל

| פעולה | הכלל |
|---|---|
| המסמך נכתב בעברית, והבקשות מצוטטות כלשונן באנגלית. | Conventions: "Docs in `docs/` are written in Hebrew". |
| במסמך אין מידע רפואי, שמות בני משפחה, מפתחות או פרטי חשבון. | "Logging or showing medical data, keys, tokens or recovery keys". |
| בשלב הזה המסמך לא נוסף ל־staging ולא נכלל ב־Commit. | "Committing or pushing without the user's approval." |

---

## 4. בקשה רביעית: בדיקת `lib/data/` לקראת `CLAUDE.md` מקומי

### הבקשה המדויקת

```text
Inspect the lib/data/ directory in MyDr to prepare a nested CLAUDE.md for the DDOS course exercise.

Identify conventions that apply specifically to this directory, including repository interfaces and implementations, data models, Drift schema and migrations, encryption, and backup handling.

Check the existing root CLAUDE.md and .claude/rules/ to avoid duplicating global instructions. Recommend 4-6 concise, verifiable rules that belong specifically in lib/data/CLAUDE.md, and explain why each is local rather than global.

Do not create or modify any files yet. Do not commit or push. Report your findings first.
```

### מה נעשה, ולפי איזה כלל

| פעולה | הכלל |
|---|---|
| נקראו רק קבצים, ולא נוצר ולא שונה שום קובץ. | הבקשה עצמה. |
| הכללים שכבר מופיעים ב־`CLAUDE.md` הראשי וב־`.claude/rules/` הוצאו מההמלצה, ונכתב במפורש מה הוצא. | "Detailed rules live in `.claude/rules/` … and are not repeated here." |
| כל אחד משישת הכללים נבדק מול הקוד (למשל, ב־grep על גבולות הייבוא) לפני שהומלץ. | "Use accurate existing file names" (הבקשה), ו־Conventions. |
| נמצא שהכלל על `repository_contract_test.dart` ב־`CLAUDE.md` הראשי לא תואם את הבדיקות בפועל. זה דווח, והקובץ הראשי לא שונה. | Open questions: "Ask the user; don't decide these yourself." |
| נמצא שהודעות `StateError` כוללות מזהה רשומה. זה דווח כשאלה, ולא תוקן. | "error messages (error type only)", ו־Open questions. |

---

## 5. בקשה חמישית: יצירת `lib/data/CLAUDE.md`

### הבקשה המדויקת

```text
Create lib/data/CLAUDE.md using the six verified, directory-specific conventions from your inspection.

Requirements:
- Keep it concise, ideally 20-35 lines.
- Include only rules that specifically apply to lib/data/.
- Do not duplicate root CLAUDE.md or .claude/rules/.
- Use accurate existing file names, APIs, and test paths.
- Do not present the root repository_contract_test.dart rule as universally accurate; leave the existing root file unchanged for now.
- Do not change application source code, tests, or any other files.
- Do not commit or push yet.

After creating the file, show its complete contents, line count, and git status.
```

### מה נעשה, ולפי איזה כלל

| פעולה | הכלל |
|---|---|
| לפני הכתיבה נבדק שכל API ונתיב בדיקה שמוזכרים בקובץ קיימים (`prepareRestore`, `applyRestore`, הקבוצה `local database guarantees` ועוד). | הבקשה עצמה. |
| הטיוטה הראשונה הייתה 36 שורות, וקוצרה ל־35. | הבקשה עצמה ("ideally 20-35 lines"). |
| הקובץ כתוב באנגלית, כמו `CLAUDE.md` הראשי. הכלל על עברית חל על `docs/`. | Conventions: "Docs in `docs/` are written in Hebrew". |
| `CLAUDE.md` הראשי, הקוד והבדיקות לא שונו, ולא בוצע Commit. | הבקשה עצמה, ו־"Committing or pushing without the user's approval." |

---

## 6. בקשה שישית: סקירה לפני Commit

### הבקשה המדויקת

```text
Review the three new files: CLAUDE.md, lib/data/CLAUDE.md, and docs/course_exercises/claude_md_followed_evidence.md. Check for formatting problems, secrets, inaccurate claims, and unintended changes. If all checks pass, stage only these three files and create one local commit with the message: "Add project and data-layer Claude instructions". Do not push. Show the commit hash and final git status. If you find any issue, stop and explain it before committing.
```

### מה נעשה, ולפי איזה כלל

| פעולה | הכלל |
|---|---|
| הופעל `mydr-pre-commit-review`, ו־`scripts/check.ps1` עבר (1038 בדיקות). | "Reason: changes are reviewed first (`/mydr-pre-commit-review`)." |
| נמצאו טענות לא מדויקות: שלוש ב־`lib/data/CLAUDE.md`, ושורת מצב במסמך הזה שהייתה הופכת לשגויה אחרי Commit. | הבקשה עצמה ("inaccurate claims"). |
| העבודה נעצרה לפני staging ו־Commit, והבעיות הוסברו. | הבקשה עצמה ("stop and explain it before committing"). |

---

## 7. בקשה שביעית: תיקונים ו־Commit מקומי

### הבקשה המדויקת

```text
Yes. Apply the proposed accuracy fixes to lib/data/CLAUDE.md and the evidence document. Keep the changes minimal and preserve the existing rules and transcript excerpts. Re-run the pre-commit review. If all checks pass, stage only CLAUDE.md, lib/data/CLAUDE.md, and docs/course_exercises/claude_md_followed_evidence.md, then create the local commit with the agreed message: "Add project and data-layer Claude instructions". Do not push. Report the commit hash and final git status. If any issue remains, stop before committing.
```

### מה נעשה, ולפי איזה כלל

| פעולה | הכלל |
|---|---|
| ב־`lib/data/CLAUDE.md` תוקן רק הניסוח של שלוש הטענות. הכללים עצמם לא השתנו. | הבקשה עצמה ("Keep the changes minimal"). |
| במסמך הזה תוקנה שורת המצב, ונוספו סעיפים 4–7. הציטוטים הקיימים לא שונו. | הבקשה עצמה ("preserve the existing … transcript excerpts"). |
| הסקירה רצה שוב לפני ה־Commit. | "Reason: changes are reviewed first (`/mydr-pre-commit-review`)." |
| נוספו ל־staging רק שלושת הקבצים, ונוצר Commit מקומי אחד בלי Push, אחרי אישור מפורש. מזהה ה־Commit לא מופיע כאן, כי המסמך הוא חלק מה־Commit. | "Committing or pushing without the user's approval." |

---

## 8. סיכום (בקשות 1–3)

| כלל ב־`CLAUDE.md` | בקשה 1 | בקשה 2 | בקשה 3 |
|---|---|---|---|
| בלי Commit או Push בלי אישור | נשמר | נשמר | נשמר |
| בדיקה לפני Commit דרך `/mydr-pre-commit-review` | בוצעה | לא רלוונטי | לא רלוונטי |
| בלי רישום או הצגה של מידע רפואי, מפתחות או טוקנים | נשמר | נשמר, וגם בהצעה | נשמר |
| בלי קריאת `.env` ובלי סודות ב־Commit | נשמר | לא רלוונטי | נשמר |
| בלי מודל, Repository או Controller מקבילים | לא רלוונטי | נשמר | לא רלוונטי |
| שאלות פתוחות נשארות למשתמש | נשמר | נשמר | לא רלוונטי |
| מסמכים ב־`docs/` בעברית | לא רלוונטי | לא רלוונטי | נשמר |
| שימוש בפקודה המאומתת `scripts/check.ps1` | הורצה ועברה | לא הורצה (לא שונה קוד) | לא הורצה (מסמך בלבד) |
