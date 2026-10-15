/// All user-facing Hebrew strings, kept in one place so they can later be
/// moved to ARB files if more languages are added.
abstract final class AppStrings {
  static const String appTitle = 'MyDr';

  // Navigation tabs
  static const String tabHome = 'בית';
  static const String tabFamily = 'משפחה';
  static const String tabAppointments = 'תורים';
  static const String tabSymptoms = 'תסמינים';

  // Screen titles
  static const String familyTitle = 'בני המשפחה';
  static const String appointmentsTitle = 'התורים שלי';
  static const String symptomsTitle = 'יומן תסמינים';

  // Greetings by time of day
  static const String greetingMorning = 'בוקר טוב';
  static const String greetingNoon = 'צהריים טובים';
  static const String greetingEvening = 'ערב טוב';
  static const String greetingNight = 'לילה טוב';

  // Dashboard
  static const String dashboardSubtitle =
      'כל המידע הבריאותי של המשפחה, במקום אחד.';

  static const String familyCardTitle = 'המשפחה שלי';
  static const String familyCardEmpty = 'עדיין לא נוספו בני משפחה';
  static const String familyCardEmptyHint =
      'אפשר להוסיף בני משפחה בלשונית "משפחה".';
  static const String familyCardManageHint =
      'לצפייה ועריכה של הפרופילים עברו ללשונית "משפחה".';
  static String familyCardCount(int count) =>
      count == 1 ? 'בן משפחה אחד' : '$count בני משפחה';

  static const String quickActionsTitle = 'פעולות מהירות';
  static const String actionNewAppointment = 'תור חדש';
  static const String actionLogSymptom = 'תיעוד תסמין';
  static const String actionDoctorQuestions = 'שאלות לרופא';

  static const String nextAppointmentTitle = 'התורים הקרובים';
  static const String nextAppointmentEmptyTitle = 'אין תורים מתוכננים';
  static const String nextAppointmentEmptyMessage =
      'תורים עתידיים שתוסיפו יופיעו כאן.';
  static String moreUpcomingAppointments(int count) => count == 1
      ? 'ועוד תור אחד בלשונית "תורים".'
      : 'ועוד $count תורים בלשונית "תורים".';

  // Emergency card
  static const String emergencyTitle = 'עזרה ראשונה וחירום';
  static const String emergencyCallLine = 'במצב חירום חייגו 101 (מד״א)';
  static const String emergencyNoInstructions =
      'האפליקציה אינה כוללת עדיין הנחיות רפואיות. מידע לעזרה ראשונה יתווסף '
      'בהמשך ממקורות מאומתים בלבד.';

  // Demo data
  static const String demoDataBanner =
      'נתוני הדגמה בדויים. שינויים אינם נשמרים לאחר סגירת האפליקציה.';

  // Family relations
  static const String relationSelf = 'אני';
  static const String relationSpouse = 'בן/בת זוג';
  static const String relationChild = 'ילד/ה';
  static const String relationParent = 'הורה';
  static const String relationSibling = 'אח/אחות';
  static const String relationGrandparent = 'סבא/סבתא';
  static const String relationOther = 'אחר';

  // Family screen
  static const String addFamilyMember = 'הוספת בן משפחה';
  static const String familyEmptyTitle = 'עדיין לא נוספו בני משפחה';
  static const String familyEmptyMessage = 'בני המשפחה שתוסיפו יופיעו כאן.';
  static const String familyLoadErrorTitle = 'לא הצלחנו לטעון את בני המשפחה';
  static const String familyLoadErrorMessage = 'בדקו שוב בעוד רגע.';
  static const String familyRefreshError =
      'לא הצלחנו לרענן את הרשימה. ייתכן שהיא אינה מעודכנת.';
  static const String retry = 'נסו שוב';
  static const String ageUnderOneYear = 'פחות משנה';
  static String ageInYears(int years) => 'גיל $years';

  // Member profile
  static const String notSpecified = 'לא צוין';
  static const String personalDetailsSection = 'פרטים אישיים';
  static const String birthDateLabel = 'תאריך לידה';
  static const String allergiesSection = 'אלרגיות';
  static const String chronicConditionsSection = 'מחלות רקע';
  static const String notesSection = 'הערות';
  static const String memberNotFoundTitle = 'הפרופיל לא נמצא';
  static const String memberNotFoundMessage =
      'ייתכן שהפרופיל נמחק או שאינו קיים עוד.';
  static const String backToFamily = 'חזרה לרשימת המשפחה';
  static const String edit = 'עריכה';

  // Member form
  static const String editMemberTitle = 'עריכת פרופיל';
  static const String nameLabel = 'שם';
  static const String nameRequired = 'נא להזין שם';
  static const String relationLabel = 'קשר משפחתי';
  static const String relationRequired = 'נא לבחור קשר משפחתי';
  static const String selfAlreadyExists =
      'כבר קיים פרופיל מסוג "אני". אפשר להגדיר פרופיל אחד בלבד מסוג זה.';
  static const String birthDateOptionalLabel = 'תאריך לידה (אופציונלי)';
  static const String birthDatePickerHelp = 'בחירת תאריך לידה';
  static const String clearBirthDate = 'ניקוי תאריך הלידה';
  static const String allergyInputLabel = 'הוספת אלרגיה';
  static const String chronicConditionInputLabel = 'הוספת מחלת רקע';
  static const String addItem = 'הוספה';
  static String removeItem(String item) => 'הסרת $item';
  static const String listItemEmpty = 'נא להזין ערך';
  static const String listItemDuplicate = 'הפריט כבר קיים ברשימה';
  static const String listItemPending =
      'הטקסט לא נוסף לרשימה. לחצו על "הוספה" או מחקו אותו.';
  static const String notesOptionalLabel = 'הערות (אופציונלי)';
  static const String save = 'שמירה';
  static const String saveSucceeded = 'הפרטים נשמרו';
  static const String saveFailed =
      'השמירה נכשלה. הפרטים שהזנתם לא נמחקו, נסו שוב.';
  static const String discardChangesTitle = 'לצאת בלי לשמור?';
  static const String discardChangesMessage = 'השינויים שביצעתם לא יישמרו.';
  static const String keepEditing = 'המשך עריכה';
  static const String discardChanges = 'יציאה בלי שמירה';

  // Member deletion
  static const String deleteProfile = 'מחיקת פרופיל';
  static String deleteDialogTitle(String name) => 'למחוק את הפרופיל של $name?';
  static const String deleteDialogIntro = 'הפעולה תמחק לצמיתות:';
  static const String deleteItemProfile = 'פרופיל בן המשפחה';
  static const String deleteItemAppointments = 'תורים';
  static const String deleteItemQuestions = 'שאלות לרופא';
  static const String deleteItemSymptoms = 'רישומי תסמינים';
  static const String deleteIrreversible = 'לא ניתן לבטל פעולה זו.';
  static const String deleteSummaryLoading =
      'בודקים אילו נתונים משויכים לפרופיל…';
  static const String deleteSummaryFailed =
      'לא הצלחנו לבדוק אילו נתונים משויכים לפרופיל, ולכן אי אפשר למחוק כרגע.';
  static const String deleteIncomplete =
      'המחיקה לא הושלמה. ייתכן שחלק מהנתונים המשויכים כבר נמחקו, אבל '
      'הפרופיל עדיין קיים. אפשר לנסות שוב.';
  static const String deletionIncompleteBanner =
      'מחיקת הפרופיל הקודמת לא הושלמה. ייתכן שחלק מהנתונים המשויכים כבר '
      'נמחקו. אפשר לנסות למחוק שוב.';
  static String deleteSucceeded(String name) => 'הפרופיל של $name נמחק';
  static const String cancel = 'ביטול';
  static const String delete = 'מחיקה';
  static const String retryDelete = 'ניסיון חוזר';

  // Appointments list
  static const String filterAllFamily = 'כל המשפחה';
  static const String upcomingAppointmentsSection = 'תורים קרובים';
  static const String pastAppointmentsSection = 'תורים שעברו';
  static const String noUpcomingAppointments = 'אין תורים קרובים.';
  static const String noPastAppointments = 'אין תורים שעברו.';
  static const String appointmentsEmptyTitle = 'אין תורים עדיין';
  static const String appointmentsEmptyMessage =
      'התורים שתוסיפו יופיעו כאן, מסודרים לפי תאריך.';
  static String appointmentsEmptyForMember(String name) =>
      'אין תורים עבור $name';
  static const String appointmentsEmptyForMemberMessage =
      'אפשר לבחור בן משפחה אחר או להציג את התורים של כל המשפחה.';
  static const String showAllFamily = 'הצגת כל המשפחה';
  static const String appointmentsLoadErrorTitle = 'לא הצלחנו לטעון את התורים';
  static const String appointmentsLoadErrorMessage = 'בדקו שוב בעוד רגע.';
  static const String appointmentsRefreshError =
      'לא הצלחנו לרענן את רשימת התורים. ייתכן שהיא אינה מעודכנת.';
  static const String newAppointment = 'תור חדש';
  static const String unknownMember = 'בן משפחה לא ידוע';
  static const String today = 'היום';
  static const String tomorrow = 'מחר';
  static const String yesterday = 'אתמול';

  // Appointment details
  static const String appointmentStatusUpcoming = 'תור קרוב';
  static const String appointmentStatusPast = 'התור עבר';
  static const String appointmentTimeSection = 'מועד התור';
  static const String appointmentInfoSection = 'פרטי התור';
  static const String dateLabel = 'תאריך';
  static const String timeLabel = 'שעה';
  static const String doctorLabel = 'רופא/ה';
  static const String specialtyLabel = 'תחום התמחות';
  static const String familyMemberLabel = 'בן משפחה';
  static const String locationLabel = 'מיקום';
  static const String appointmentNotFoundTitle = 'התור לא נמצא';
  static const String appointmentNotFoundMessage =
      'ייתכן שהתור נמחק או שאינו קיים עוד.';
  static const String backToAppointments = 'חזרה לרשימת התורים';

  // Appointment form
  static const String editAppointmentTitle = 'עריכת תור';
  static const String editAppointment = 'עריכת תור';
  static const String memberRequired = 'נא לבחור בן משפחה';
  static const String doctorNameLabel = 'שם הרופא/ה';
  static const String doctorNameRequired = 'נא להזין את שם הרופא/ה';
  static const String specialtyOptionalLabel = 'תחום התמחות (אופציונלי)';
  static const String locationOptionalLabel = 'מיקום (אופציונלי)';
  static const String dateRequired = 'נא לבחור תאריך';
  static const String timeRequired = 'נא לבחור שעה';
  static const String appointmentDatePickerHelp = 'בחירת תאריך התור';
  static const String appointmentTimePickerHelp = 'בחירת שעת התור';
  static const String noFamilyForAppointmentTitle =
      'כדי לקבוע תור צריך קודם בן משפחה';
  static const String noFamilyForAppointmentMessage =
      'כל תור שייך לבן משפחה. הוסיפו בן משפחה, ואז תוכלו לחזור ולקבוע תור.';
  static String moveAppointmentTitle(String newMemberName) =>
      'להעביר את התור ל$newMemberName?';
  static String moveAppointmentMessage(int count, String originalName) =>
      'לתור משויכות $count שאלות לרופא של $originalName. הן יוסרו מהתור '
      'ויישארו אצל $originalName כשאלות כלליות.';
  static const String moveAndSave = 'העברה ושמירה';
  static const String linkedQuestionsCheckFailed =
      'לא הצלחנו לבדוק אם יש שאלות שמשויכות לתור, ולכן התור לא נשמר. '
      'נסו שוב.';
  static const String selectedMemberMissing =
      'בן המשפחה שנבחר כבר לא קיים. בחרו בן משפחה אחר.';
  static const String appointmentMissingOnSave =
      'התור כבר לא קיים, ייתכן שנמחק. השינויים לא נשמרו.';
  static String saveFailedAfterDetaching(String originalName) =>
      'השמירה נכשלה. השאלות שהיו משויכות לתור כבר הוסרו ממנו ונשארו אצל '
      '$originalName כשאלות כלליות. נסו לשמור שוב.';

  // Appointment deletion
  static const String deleteAppointment = 'מחיקת תור';
  static const String deleteAppointmentTitle = 'למחוק את התור?';
  static const String deleteAppointmentQuestionsLoading =
      'בודקים אם יש שאלות לרופא שמשויכות לתור…';
  static const String deleteAppointmentQuestionsFailed =
      'לא הצלחנו לבדוק אם יש שאלות שמשויכות לתור, ולכן אי אפשר למחוק כרגע.';
  static const String deleteAppointmentNoQuestions =
      'אין שאלות לרופא שמשויכות לתור.';
  static String deleteAppointmentQuestions(int count, String memberName) =>
      count == 1
      ? 'לתור משויכת שאלה אחת לרופא. היא לא תימחק: היא תוסר מהתור '
            'ותישאר אצל $memberName כשאלה כללית.'
      : 'לתור משויכות $count שאלות לרופא. הן לא יימחקו: הן יוסרו מהתור '
            'ויישארו אצל $memberName כשאלות כלליות.';
  static const String deleteAppointmentFailed =
      'מחיקת התור נכשלה ושום דבר לא השתנה. אפשר לנסות שוב.';
  static String deleteAppointmentPartiallyFailed(String memberName) =>
      'מחיקת התור לא הושלמה, והתור עדיין קיים. השאלות שהיו משויכות אליו '
      'כבר הוסרו ממנו ונשארו אצל $memberName כשאלות כלליות. הן לא נמחקו. '
      'אפשר לנסות שוב.';
  static const String appointmentDeleted = 'התור נמחק';

  // Questions to the doctor
  static const String doctorQuestionsTitle = 'שאלות לרופא';
  static const String questionsFilterAll = 'הכל';
  static const String unresolvedQuestionsSection = 'טרם טופלו';
  static const String resolvedQuestionsSection = 'טופלו';
  static const String questionStatusUnresolved = 'טרם טופלה';
  static const String questionStatusResolved = 'טופלה';
  static const String markQuestionResolved = 'סימון השאלה כטופלה';
  static const String markQuestionUnresolved = 'סימון השאלה כטרם טופלה';
  static const String generalQuestion = 'שאלה כללית';
  static const String linkedAppointmentMissing = 'משויכת לתור שאינו זמין';
  static const String recordedAnswerLabel = 'התשובה שרשמתם';
  static const String noUnresolvedQuestions = 'אין שאלות שטרם טופלו.';
  static const String noResolvedQuestions = 'אין שאלות שטופלו.';
  static const String questionsEmptyTitle = 'אין שאלות לרופא עדיין';
  static const String questionsEmptyMessage =
      'כאן תוכלו לרשום שאלות ונושאים שתרצו להעלות בפני הרופא.';
  static String questionsEmptyForMember(String name) => 'אין שאלות עבור $name';
  static const String questionsEmptyForMemberMessage =
      'אפשר לבחור בן משפחה אחר או להציג את השאלות של כל המשפחה.';
  static const String questionsLoadErrorTitle = 'לא הצלחנו לטעון את השאלות';
  static const String questionsLoadErrorMessage = 'בדקו שוב בעוד רגע.';
  static const String questionsRefreshError =
      'לא הצלחנו לרענן את רשימת השאלות. ייתכן שהיא אינה מעודכנת.';
  static const String newQuestion = 'שאלה חדשה';
  static const String questionUpdateFailed =
      'לא הצלחנו לעדכן את השאלה. נסו שוב.';
  static const String questionNoLongerExists = 'השאלה כבר לא קיימת.';

  // Question form
  static const String editQuestionTitle = 'עריכת שאלה';
  static const String questionNotFoundTitle = 'השאלה לא נמצאה';
  static const String questionNotFoundMessage =
      'ייתכן שהשאלה נמחקה או שאינה קיימת עוד.';
  static const String backToQuestions = 'חזרה לשאלות';
  static const String questionTextLabel = 'השאלה או הנושא';
  static const String questionTextRequired = 'נא לכתוב את השאלה';
  static const String linkedAppointmentLabel = 'שיוך לתור (אופציונלי)';
  static const String noAppointmentOption = 'שאלה כללית, ללא תור';
  static const String pastAppointmentSuffix = 'תור שעבר';
  static const String selectMemberFirst = 'בחרו קודם בן משפחה';
  static const String noAppointmentsForMember =
      'לבן המשפחה הזה אין תורים, ולכן השאלה תישמר כשאלה כללית.';
  static const String appointmentLinkClearedOnMemberChange =
      'השיוך לתור הוסר, כי כל תור שייך לבן משפחה אחד.';
  static const String linkedAppointmentDeletedWhileEditing =
      'התור שהשאלה הייתה משויכת אליו נמחק. אם לא תבחרו תור אחר, השאלה '
      'תישמר כשאלה כללית.';
  static const String questionResolvedLabel = 'השאלה טופלה';
  static const String doctorAnswerLabel =
      'תשובת הרופא / הערות מהביקור (אופציונלי)';
  static String moveQuestionTitle(String newMemberName) =>
      'להעביר את השאלה ל$newMemberName?';
  static String moveQuestionMessage(String doctorName, String originalName) =>
      'השאלה משויכת כרגע לתור אצל $doctorName של $originalName. '
      'השיוך לתור יוסר.';
  static const String questionMissingOnSave =
      'השאלה כבר לא קיימת, ייתכן שנמחקה. השינויים לא נשמרו.';
  static const String questionDeletedWhileEditing =
      'השאלה נמחקה בזמן שהטופס היה פתוח, ולכן אי אפשר לשמור אותה.';
  static const String selectedAppointmentMissing =
      'התור שנבחר כבר לא קיים. בחרו תור אחר או השאירו את השאלה כללית.';
  static const String appointmentOfAnotherMemberError =
      'התור שנבחר שייך לבן משפחה אחר.';
  static const String noFamilyForQuestionTitle =
      'כדי לרשום שאלה צריך קודם בן משפחה';
  static const String noFamilyForQuestionMessage =
      'כל שאלה שייכת לבן משפחה. הוסיפו בן משפחה, ואז תוכלו לחזור ולרשום שאלה.';

  // Questions in other screens
  static String unresolvedQuestionsCount(int count) => switch (count) {
    0 => 'אין שאלות שטרם טופלו',
    1 => 'שאלה אחת שטרם טופלה',
    _ => '$count שאלות שטרם טופלו',
  };
  static const String allQuestions = 'לכל השאלות';
  static const String addQuestionToAppointment = 'הוספת שאלה לתור';
  static const String noQuestionsForAppointment = 'אין שאלות שמשויכות לתור.';

  // Question deletion
  static const String deleteQuestion = 'מחיקת שאלה';
  static const String deleteQuestionTitle = 'למחוק את השאלה?';
  static const String deleteQuestionKeepsOthers =
      'התור ובן המשפחה שהשאלה משויכת אליהם לא יושפעו.';
  static const String deleteQuestionFailed =
      'מחיקת השאלה נכשלה, והשאלה לא נמחקה. אפשר לנסות שוב.';
  static const String questionDeleted = 'השאלה נמחקה';

  // Symptom journal
  static const String symptomsDisclaimer =
      'המידע מיועד לתיעוד בלבד ואינו מחליף ייעוץ רפואי';
  static const String symptomsEmptyTitle = 'אין תיעודי תסמינים עדיין';
  static const String symptomsEmptyMessage =
      'תסמינים שיתועדו יופיעו כאן לפי תאריך, מהחדש לישן.';
  static String symptomsEmptyForMember(String name) =>
      'אין תיעודי תסמינים עבור $name';
  static const String symptomsEmptyForMemberMessage =
      'אפשר לבחור בן משפחה אחר או להציג את התיעודים של כל המשפחה.';
  static const String symptomsLoadErrorTitle =
      'לא הצלחנו לטעון את יומן התסמינים';
  static const String symptomsLoadErrorMessage = 'בדקו שוב בעוד רגע.';
  static const String symptomsRefreshError =
      'לא הצלחנו לרענן את יומן התסמינים. ייתכן שהוא אינו מעודכן.';

  /// The user's own rating, worded so it never reads as a medical scale.
  static String symptomSeverity(int severity, int max) =>
      'עוצמה לפי הדיווח: $severity מתוך $max';

  // Symptom form
  static const String editSymptomTitle = 'עריכת תיעוד תסמין';
  static const String symptomNameLabel = 'שם התסמין';
  static const String symptomNameRequired = 'נא להזין את שם התסמין';
  static const String symptomNameSuggestions = 'הצעות';
  static const List<String> commonSymptomNames = [
    'שיעול',
    'חום',
    'כאב ראש',
    'כאב בטן',
    'כאב גרון',
    'נזלת',
    'בחילה',
    'עייפות',
  ];
  static const String symptomDatePickerHelp = 'בחירת תאריך התיעוד';
  static const String symptomTimePickerHelp = 'בחירת שעת התיעוד';
  static const String symptomDateInFuture = 'לא ניתן לתעד מועד עתידי';
  static String symptomDateTooOld(int years) =>
      'ניתן לתעד עד $years שנים אחורה';
  static const String severityLabel = 'עוצמה לפי התחושה';
  static const String severityHint =
      '1 – קלה מאוד, 5 – חזקה מאוד. דירוג אישי לתיעוד בלבד, ולא הערכה רפואית.';
  static const String severityRequired = 'נא לבחור עוצמה';
  static String severityOption(int level, int max) => 'עוצמה $level מתוך $max';
  static const String symptomNotesLabel = 'תיאור והערות (לא חובה)';
  static const String symptomNotFoundTitle = 'התיעוד לא נמצא';
  static const String symptomNotFoundMessage =
      'ייתכן שהתיעוד נמחק. אפשר לחזור ליומן התסמינים.';
  static const String backToSymptoms = 'חזרה ליומן התסמינים';
  static const String symptomDeletedWhileEditing =
      'התיעוד נמחק בזמן העריכה, ולכן אי אפשר לשמור אותו.';
  static const String symptomMemberDeletedWhileEditing =
      'בן המשפחה שנבחר נמחק. נא לבחור בן משפחה.';
  static const String symptomMissingOnSave =
      'התיעוד כבר לא קיים, ולכן השינויים לא נשמרו.';
  static const String noFamilyForSymptomTitle = 'כדי לתעד תסמין צריך בן משפחה';
  static const String noFamilyForSymptomMessage =
      'הוסיפו בן משפחה, ואחר כך תוכלו לתעד עבורו תסמינים.';
  static String moveSymptomTitle(String newMemberName) =>
      'להעביר את התיעוד ל$newMemberName?';
  static String moveSymptomMessage(String symptomName, String originalName) =>
      'התיעוד "$symptomName" ישויך לבן משפחה אחר ולא יופיע עוד אצל '
      '$originalName.';

  // Symptom summaries (home screen, profile)
  static const String recentSymptomsTitle = 'תסמינים אחרונים';
  static const String recentSymptomsEmptyTitle = 'אין תיעודי תסמינים';
  static const String recentSymptomsEmptyMessage = 'תסמינים שתתעדו יופיעו כאן.';
  static const String showAllSymptoms = 'הצגת כל התסמינים';
  static const String memberSymptomsEmpty =
      'עדיין לא תועדו תסמינים עבור בן משפחה זה.';
  static const String allMemberSymptoms = 'כל התיעודים';

  // Symptom track
  static const String symptomTrackTitle = 'מעקב אחר תסמין';
  static String symptomRecordCount(int count) =>
      count == 1 ? 'תיעוד אחד' : '$count תיעודים';
  static String openSymptomTrack(int count) =>
      'מעקב · ${symptomRecordCount(count)}';
  static String lastRecordedAt(String when) => 'תיעוד אחרון: $when';
  static const String symptomTrackDisclaimer =
      'כאן מוצגים יחד כל התיעודים של תסמין בשם זה, כפי שהוזנו. ייתכן שהם '
      'שייכים לתקופות או לאירועים שונים, והאפליקציה אינה מפרשת אותם.';
  static const String symptomTrackOrder = 'כל התיעודים, מהישן לחדש';
  static const String addFollowUpRecord = 'הוספת תיעוד המשך';
  static String symptomTrackEmptyTitle(String name) =>
      'אין עוד תיעודים של "$name"';
  static const String symptomTrackEmptyMessage =
      'ייתכן שהתיעודים נמחקו, או ששם התסמין או בן המשפחה שלהם שונו.';
  static const String symptomTrackMemberMissingTitle = 'בן המשפחה לא נמצא';
  static const String symptomTrackMemberMissingMessage =
      'ייתכן שהפרופיל נמחק יחד עם התיעודים שלו.';

  // Symptom deletion
  static const String deleteSymptom = 'מחיקת תיעוד';
  static const String deleteSymptomTitle = 'למחוק את התיעוד?';
  static const String deleteSymptomKeepsOthers =
      'תיעודים אחרים של אותו תסמין לא יימחקו.';
  static const String deleteSymptomFailed =
      'מחיקת התיעוד נכשלה, והתיעוד לא נמחק. אפשר לנסות שוב.';
  static const String symptomDeleted = 'התיעוד נמחק';

  // Placeholders
  static const String comingSoonBadge = 'בקרוב';
}
