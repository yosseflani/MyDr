# פרומפט: ניהול תרופות ותזכורות (Medication Management and Reminders)

הפרומפט ששימש לפיתוח הפיצ'ר, לפי שבע הטכניקות של תרגיל 3.

**מה מקורי ומה נוסף:** הטקסט בתוך בלוקי הקוד (` ```xml `) הוא הפרומפט המקורי, מילה במילה. כל השאר (הכותרות, הטבלה וההערות המסומנות "הערת תיעוד") נכתב אחרי ההרצה, לצורך תיעוד בלבד.

## הערת תיעוד: מיפוי שבע הטכניקות

| # | טכניקה | איפה היא בפרומפט |
|---|---|---|
| 1 | Be specific | `<requirements technique="1 - Be specific">` |
| 2 | Multishot | `<examples technique="2 - Multishot">` |
| 3 | Give a role | `<role technique="3 - Give a role">` |
| 4 | XML structure | הפרומפט כולו: כל חלק עטוף בתגית XML משלו |
| 5 | Dial effort, not words | `<run_configuration technique="5 - Dial effort, not words">` |
| 6 | Brief once | `<execution technique="6 - Brief once">` |
| 7 | Data first | `<project_data technique="7 - Data first">` |

**טכניקה 4, XML structure:** בפרומפט המקורי אין תווית `technique="4 - ..."`, כי הטכניקה לא שייכת לחלק אחד. היא המבנה של הפרומפט כולו: תגיות XML מפרידות בין המידע על הפרויקט (`<project_data>`), התפקיד (`<role>`), הדרישות (`<requirements>`), הדוגמאות (`<examples>`), הוראות הביצוע (`<execution>`), תצורת ההרצה (`<run_configuration>`) והבדיקות (`<verification>`).

**`<verification>`:** החלק היחיד בפרומפט המקורי שאין לו תווית `technique`. הוא מוצג כאן בלי שיוך לטכניקה ממוספרת, והוא חלק מהמבנה של טכניקה 4.

החלקים מופיעים להלן לפי הסדר שלהם בפרומפט המקורי. הכותרות שמעליהם הן תוספת תיעוד.

## טכניקה 7: Data first

```xml
<project_data technique="7 - Data first">
Project: MyDr, an existing Flutter/Dart family medical application.

Known architecture from repository inspection:
- Drift + SQLCipher encrypted local database, currently schema version 2.
- Family members have unique IDs; medical records belong to a specific member.
- Repository interfaces with local and in-memory implementations.
- ChangeNotifier controllers and AppDependencies/AppScope dependency injection.
- Existing family-member deletion cleanup and relatedDataRevision.
- AppStrings-based Hebrew localization.
- Existing tests under test/, integration_test/, and check.ps1.
- No existing local-notification scheduling infrastructure was found.

Treat these as preliminary observations. Inspect the actual repository before editing. Reuse existing conventions and avoid inventing APIs or assumptions.
</project_data>
```

## טכניקה 3: Give a role

```xml
<role technique="3 - Give a role">
You are a senior Flutter engineer specializing in reliable offline-first mobile applications, secure local data storage, testable architecture, and mobile notification scheduling.
</role>
```

## טכניקה 1: Be specific

```xml
<requirements technique="1 - Be specific">
Implement a new Medication Management and Reminders feature in MyDr.

Required functionality:
1. Add, edit, view and delete medications for an individual family member.
2. Store medication name, user-entered dose, optional instructions, daily reminder times, treatment start date and optional end date.
3. Validate required fields, time entries, and end date >= start date.
4. Display active medications and upcoming scheduled doses for the selected member.
5. Record a scheduled dose as Taken or Skipped and show its history. Prevent duplicate records for the same scheduled dose.
6. Persist all records locally using the existing database architecture, with a safe additive migration preserving existing user data.
7. Implement local notifications for scheduled doses, only within the treatment date range. Handle permission denial, app restarts, editing/deletion, family-member deletion, time zones, and platform scheduling limitations without crashing.
8. Use generic privacy-preserving notification content by default; do not expose medication names or other health information on the lock screen.
9. Reuse existing UI, Hebrew localization, dependency injection, family isolation and testing conventions.
10. Do not recommend medications, doses or treatment changes. Clearly state that reminders are an aid and may be delayed or missed by the operating system.

Ensure reminder scheduling is bounded and refreshed appropriately rather than assuming unlimited pending notifications.
</requirements>
```

## טכניקה 2: Multishot

```xml
<examples technique="2 - Multishot">
Example A:
Given a medication for family member A, dose "1 tablet", reminder 08:00, start October 20, end October 27:
Show scheduled doses during that range only. Never schedule a reminder for October 28.

Example B:
Given family members A and B:
A's medications and dose history must never appear under B's profile. Deleting A must clean up A's medication data and reminders without changing B's records.

Example C:
Given a user who denies notification permission:
Medication CRUD and dose logging must still work. Show a clear non-blocking explanation that notifications are disabled.

Example D:
Given an 08:00 dose already marked Taken:
Reopening the app must preserve that record, and marking the same scheduled occurrence again must not create a duplicate.
</examples>
```

## טכניקה 6: Brief once

```xml
<execution technique="6 - Brief once">
This is the complete implementation brief. Inspect the repository, make reasonable decisions consistent with its patterns, implement the feature end-to-end, and test it. Do not wait for repeated prompts for routine implementation choices.

Before making a destructive change or introducing an unavoidable safety/privacy tradeoff, stop and explain the decision. Do not run git commit or git push.

Document the implemented architecture, known platform limitations and manual validation steps. Save this complete seven-technique prompt in docs/prompts/medication_management_seven_techniques.md, including labels for all seven techniques.
</execution>
```

## טכניקה 5: Dial effort, not words

```xml
<run_configuration technique="5 - Dial effort, not words">
Model: Opus 5.5
Effort configured externally in Claude Code: High.
This is a record of the run configuration, not an instruction to change reasoning effort.
</run_configuration>
```

## בדיקות והגדרת סיום (ללא תווית טכניקה בפרומפט המקורי)

```xml
<verification>
Run the project's relevant automated checks, including Flutter analysis, tests and a supported build when feasible. Report the exact commands and results.

Done when the feature is implemented, tests are green, and the app can be manually verified on Android. Leave the changes uncommitted for developer review.
</verification>
```

## הערת תיעוד: איפה כל דוגמה נבדקת

נכתב אחרי ההרצה. זה לא חלק מהפרומפט.

- **דוגמה A:** `test/data/models/medication_test.dart`, `test/data/reminders/reminder_planner_test.dart`, `test/features/medications/medication_controller_test.dart`, `test/features/medications/medications_screen_test.dart`.
- **דוגמה B:** `test/data/local/medication_storage_test.dart`, `medication_controller_test.dart`, `medications_screen_test.dart`, `test/medications_flow_test.dart`.
- **דוגמה C:** `medication_controller_test.dart`, `medications_screen_test.dart`, `medication_form_screen_test.dart`.
- **דוגמה D:** `medication_storage_test.dart` (כולל סגירה ופתיחה של המסד המוצפן), `medication_controller_test.dart`, `medications_flow_test.dart`, `integration_test/persistence_test.dart`.
