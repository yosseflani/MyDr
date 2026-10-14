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

  // Placeholders
  static const String comingSoonBadge = 'בקרוב';
  static const String comingSoon = 'המסך יהיה זמין בקרוב';
  static const String symptomsPlaceholder =
      'כאן תוכלו לתעד תסמינים ולצפות בהיסטוריה.';
}
