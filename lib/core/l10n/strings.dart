/// All user-facing Hebrew strings, kept in one place so they can later be
/// moved to ARB files if more languages are added.
abstract final class AppStrings {
  static const String appTitle = 'MyDr';

  // Navigation tabs
  static const String tabHome = 'בית';
  static const String tabFamily = 'משפחה';
  static const String tabAppointments = 'תורים';
  static const String tabSymptoms = 'תסמינים';
  static const String tabMedications = 'תרופות';

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
  static const String emergencyGuidanceNotice =
      'הנחיות העזרה הראשונה מבוססות על מקורות רפואיים, וטרם אושרו מקצועית '
      'עבור MyDr. הן אינן תחליף לחיוג 101.';
  static const String callMedicalEmergency = 'חיוג ל־101';
  static const String openEmergencyCenter = 'מרכז החירום';

  // Emergency center
  static const String emergencyCenterTitle = 'מרכז חירום';
  static const String callMedicalEmergencyTitle = 'חיוג למד״א';
  static const String dialerHint =
      'ייפתח החייגן עם המספר. השיחה מתבצעת רק לאחר לחיצה על "חיוג" בטלפון.';
  static const String otherEmergencyNumbers = 'מספרי חירום נוספים';
  static const String serviceMedical = 'מגן דוד אדום';
  static const String servicePolice = 'משטרת ישראל';
  static const String serviceFire = 'כבאות והצלה';
  static String callServiceLabel(String service, String number) =>
      'חיוג אל $service, $number';
  static const String dialerUnavailableTitle = 'לא ניתן לפתוח את החייגן';
  static String dialerUnavailableMessage(String number) =>
      'השיחה לא בוצעה. חייגו בעצמכם מהטלפון למספר $number.';
  static const String close = 'סגירה';
  static const String firstAidSectionTitle = 'הנחיות עזרה ראשונה';
  static const String firstAidLoadErrorTitle =
      'לא הצלחנו לטעון את נושאי העזרה הראשונה';
  static const String firstAidLoadErrorMessage =
      'כפתורי החיוג ממשיכים לעבוד כרגיל. אפשר לנסות שוב.';
  static const String firstAidLoading = 'טוען את נושאי העזרה הראשונה…';
  static const String firstAidEmpty = 'אין כרגע נושאי עזרה ראשונה זמינים.';
  static const String topicKindEmergency = 'מצב חירום';
  static const String topicKindGeneralInfo = 'מידע כללי';
  static const String contentStatusPending = 'בהכנה';
  static const String contentStatusVerified = 'מאומת';
  static const String contentStatusDraft = 'טיוטה, לא מאושרת';
  static const String contentStatusSourced = 'מבוסס מקורות, לא אושר מקצועית';
  static const String firstAidSourcedNoticeTitle =
      'מבוסס על מקורות רפואיים, טרם אושר מקצועית';
  static const String firstAidSourcedNoticeMessage =
      'ההנחיות מבוססות על מקורות רפואיים מוסמכים, המפורטים בסוף העמוד, '
      'אך טרם עברו אישור מקצועי פרטני עבור MyDr. '
      'במצב חירום חייגו 101 מיד ופעלו לפי ההנחיות של המוקד.';
  static String firstAidTopicLabel(String title, String kind, String status) =>
      '$title, $kind, $status';
  static const String firstAidPendingTitle = 'ההנחיות בהכנה';
  static const String firstAidPendingMessage =
      'ההנחיות לנושא זה יוצגו רק לאחר אימות ממקור רפואי מוסמך. '
      'במצב חירום חייגו 101 מיד.';
  static const String firstAidCallNowTitle = 'מתי לחייג 101 מיד';
  static const String firstAidRecognizeTitle = 'איך מזהים';
  static const String firstAidChooseVariantTitle = 'בחרו את המצב המתאים';
  static const String firstAidChooseVariantHint =
      'אם אינכם בטוחים מה מתאים, חייגו 101 ופעלו לפי ההנחיות של המוקד.';
  static String firstAidVariantLabel(String label, String? appliesTo) =>
      appliesTo == null ? label : '$label, $appliesTo';
  static const String firstAidStepsTitle = 'שלבים';
  static String firstAidStepLabel(int order, int total, String text) =>
      'שלב $order מתוך $total: $text';
  static const String firstAidDoNotTitle = 'מה לא לעשות';
  static String firstAidDoNotLabel(String text) => 'לא לעשות: $text';
  static const String firstAidWarningsTitle = 'אזהרות';
  static const String firstAidAfterCareTitle = 'גם אחרי שיפור';
  static const String firstAidSourcesTitle = 'מקורות ואימות';
  static String firstAidSourcePublished(String date) => 'פורסם או עודכן: $date';
  static String firstAidSourceAccessed(String date) => 'נבדק: $date';
  static const String firstAidLastCheckedLabel = 'נבדק לאחרונה מול המקורות';
  static const String firstAidVerifiedOnLabel = 'תאריך אימות';
  static const String firstAidVerifiedByLabel = 'אומת על ידי';
  static const String firstAidNotVerifiedLabel =
      'טרם אושר על ידי איש מקצוע רפואי עבור MyDr';

  // First-aid review preview (developer builds only)
  static const String firstAidReviewEntryTitle = 'תצוגה מקדימה לסקירה מקצועית';
  static const String firstAidReviewEntrySubtitle =
      'למפתחים ולסוקרים בלבד. טיוטות שלא אושרו.';
  static const String firstAidReviewTitle = 'טיוטות לסקירה';
  static const String firstAidDraftBanner = 'טיוטה לסקירה בלבד, לא מאושרת';
  static const String firstAidDraftNotice =
      'התוכן כאן לא נבדק ולא אושר על ידי איש מקצוע רפואי, ואין להסתמך עליו. '
      'במצב חירום חייגו 101.';
  static const String firstAidReviewNotesTitle = 'הערות לסוקר';
  static const String firstAidReviewFingerprintLabel =
      'טביעת התוכן לאישור (SHA-256)';
  static const String firstAidReviewLoadErrorTitle =
      'לא הצלחנו לטעון את קובץ הטיוטות';
  static const String firstAidTopicNotFoundTitle = 'הנושא לא נמצא';
  static const String firstAidTopicNotFoundMessage =
      'ייתכן שהתוכן עודכן. אפשר לחזור למרכז החירום.';
  static const String backToEmergencyCenter = 'חזרה למרכז החירום';
  static const String emergencyDisclaimer =
      'המידע באפליקציה אינו תחליף לפנייה למוקד חירום או לאיש מקצוע רפואי. '
      'במצב חירום חייגו 101 מיד.';

  // Local storage startup
  static const String storageOpening = 'טוען את המידע השמור…';
  static const String storageUnavailableTitle = 'לא ניתן לפתוח את המידע השמור';
  static const String storageNothingDeleted = 'שום מידע לא נמחק.';
  static const String storageKeyMissing =
      'מפתח ההצפנה של המידע השמור לא נמצא במכשיר, ולכן אי אפשר לפתוח אותו.';
  static const String storageKeyInvalid =
      'מפתח ההצפנה השמור במכשיר אינו תקין, ולכן אי אפשר לפתוח את המידע.';
  static const String storageUnreadable =
      'המידע השמור לא נפתח עם מפתח ההצפנה של המכשיר, או שהקובץ פגום.';
  static const String storageNewerVersion =
      'המידע נשמר בגרסה חדשה יותר של האפליקציה. עדכנו את האפליקציה כדי '
      'לפתוח אותו.';
  static const String storageKeyStoreUnavailable =
      'האחסון המאובטח של המכשיר אינו זמין כרגע. נסו שוב בעוד רגע.';
  static const String storageEncryptionUnavailable =
      'רכיב ההצפנה אינו זמין, ולכן המידע לא נפתח. שום מידע לא נשמר בלי '
      'הצפנה.';
  static const String storageOpenFailed =
      'אירעה שגיאה בפתיחת המידע השמור. נסו שוב.';
  static const String storageEmergencyStillAvailable =
      'גם עכשיו אפשר לחייג למוקד חירום ולהיכנס למרכז החירום.';

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
  static const String deleteItemVisitMedia = 'תמונות וסרטונים לביקורים';
  static const String deleteItemMedications = 'תרופות ותזכורות';
  static const String deleteItemDoseRecords = 'רישומי מנות';
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
  static String moveAppointmentHasMedia(String originalName) =>
      'לתור מצורפים תמונות או סרטונים של $originalName, ולכן אי אפשר להעביר '
      'אותו לבן משפחה אחר. כדי להעביר אותו, מחקו קודם את התיעודים.';
  static const String linkedMediaCheckFailed =
      'לא הצלחנו לבדוק אם מצורפים לתור תמונות או סרטונים, ולכן התור לא נשמר. '
      'נסו שוב.';
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
  static String deleteAppointmentMedia(int count) => count == 1
      ? 'גם תיעוד אחד (תמונה או סרטון) שצורף לתור יימחק מהמכשיר.'
      : 'גם $count תיעודים (תמונות וסרטונים) שצורפו לתור יימחקו מהמכשיר.';

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

  // Doctor visit preparation
  static const String visitPreparationTitle = 'הכנה לביקור אצל הרופא';
  static const String visitPreparationIntro =
      'השאלות, התמונות והסרטונים שתרצו להראות לרופא, במקום אחד.';
  static const String visitMediaTitle = 'תמונות וסרטונים';
  static const String visitMediaPrivacyNote =
      'נשמרים רק במכשיר, באחסון הפרטי של האפליקציה, ולא בגלריה. '
      'לא מועלים לשום שרת.';
  static const String visitMediaEmpty =
      'עדיין לא צורפו תמונות או סרטונים לתור. אפשר לתעד תסמין שעלול להשתנות '
      'או להיעלם עד הביקור.';
  static const String visitMediaLoadError =
      'לא הצלחנו לטעון את התמונות והסרטונים של התור.';
  static const String takePhoto = 'צילום תמונה';
  static const String recordVideo = 'צילום סרטון';
  static const String chooseFromGallery = 'בחירה מהגלריה';
  static const String visitMediaAdding = 'שומרים במכשיר…';
  static const String visitMediaPhoto = 'תמונה';
  static const String visitMediaVideo = 'סרטון';
  static const String visitMediaNoDescription = 'ללא תיאור';
  static String visitMediaAddedAt(String when) => 'נוסף: $when';
  static String visitMediaAdded(int count) =>
      count == 1 ? 'התיעוד נשמר' : 'נשמרו $count תיעודים';
  static const String visitMediaMoreActions = 'פעולות נוספות';

  static const String cameraPermissionDenied =
      'אין הרשאה לגשת למצלמה או לגלריה. אפשר לאשר גישה בהגדרות המכשיר, '
      'ובינתיים להמשיך להשתמש בשאר האפשרויות.';
  static const String cameraUnavailable = 'לא נמצאה מצלמה זמינה במכשיר.';
  static const String mediaPickFailed =
      'לא הצלחנו לפתוח את המצלמה או את הגלריה. נסו שוב.';
  static const String mediaAppointmentMissing =
      'התור כבר לא קיים, ולכן התיעוד לא נשמר.';
  static String mediaRejectedUnsupported(int count) =>
      '${count == 1 ? 'קובץ אחד לא נשמר' : '$count קבצים לא נשמרו'}: '
      'סוג הקובץ אינו נתמך. אפשר לצרף תמונות (JPG, PNG, WEBP, HEIC) '
      'וסרטונים (MP4, MOV, 3GP).';
  static String mediaRejectedTooLarge(int count) =>
      '${count == 1 ? 'קובץ אחד לא נשמר' : '$count קבצים לא נשמרו'}: '
      'הקובץ גדול מדי (עד 25MB לתמונה ועד 150MB לסרטון).';
  static String mediaSaveFailed(int count) =>
      '${count == 1 ? 'קובץ אחד לא נשמר' : '$count קבצים לא נשמרו'}: '
      'לא הצלחנו לקרוא או לשמור את הקובץ. נסו שוב.';

  static const String visitMediaDescriptionTitle = 'תיאור התיעוד';
  static const String visitMediaDescriptionLabel = 'תיאור (אופציונלי)';
  static const String visitMediaDescriptionHint =
      'למשל: הפריחה הופיעה אתמול בערב';
  static const String editVisitMediaDescription = 'עריכת תיאור';
  static const String descriptionSaveFailed = 'התיאור לא נשמר. נסו שוב.';
  static const String visitMediaMissingDuringEdit =
      'התיעוד כבר לא קיים, ייתכן שנמחק.';

  static const String deleteVisitMedia = 'מחיקת תיעוד';
  static const String deleteVisitMediaTitle = 'למחוק את התיעוד?';
  static const String deleteVisitMediaMessage =
      'הקובץ והתיאור שלו יימחקו מהמכשיר. העותק המקורי בגלריה, אם יש כזה, '
      'לא יימחק.';
  static const String deleteVisitMediaFailed =
      'מחיקת התיעוד נכשלה, והוא לא נמחק. אפשר לנסות שוב.';
  static const String visitMediaDeleted = 'התיעוד נמחק';

  static const String visitMediaNotFoundTitle = 'התיעוד לא נמצא';
  static const String visitMediaNotFoundMessage =
      'ייתכן שהתיעוד נמחק, יחד עם התור או עם בן המשפחה.';
  static const String backToAppointment = 'חזרה לתור';
  static const String mediaFileMissing =
      'הקובץ לא נמצא במכשיר או שאינו תקין, ולכן אי אפשר להציג אותו. '
      'אפשר למחוק את התיעוד.';
  static const String playVideo = 'הפעלה';
  static const String pauseVideo = 'השהיה';

  // Medications and reminders
  static const String medicationsTitle = 'תרופות ותזכורות';
  static const String actionAddMedication = 'הוספת תרופה';
  static const String editMedicationTitle = 'עריכת תרופה';
  static const String medicationsNoAdvice =
      'MyDr שומרת את התרופות כפי שהזנתם, ואינה ממליצה על תרופות, מינונים או '
      'שינויים בטיפול. בכל שאלה פנו לרופא או לרוקח.';
  static const String remindersAreAnAid =
      'התזכורות הן כלי עזר בלבד: מערכת ההפעלה עלולה לעכב אותן או לא להציג '
      'אותן כלל. אל תסתמכו עליהן כעל המקור היחיד.';
  static const String noFamilyForMedicationsTitle = 'עדיין אין בני משפחה';
  static const String noFamilyForMedicationsMessage =
      'כדי להוסיף תרופה, הוסיפו קודם את בן המשפחה שנוטל אותה.';
  static const String medicationsLoadErrorTitle = 'לא הצלחנו לטעון את התרופות';
  static const String medicationsLoadErrorMessage = 'שום דבר לא נמחק. נסו שוב.';
  static const String medicationsRefreshError =
      'לא הצלחנו לרענן את התרופות, וייתכן שהמידע המוצג אינו עדכני.';
  static String medicationsEmptyForMember(String name) =>
      'עדיין אין תרופות עבור $name';
  static const String medicationsEmptyMessage =
      'אפשר להוסיף תרופה עם שעות תזכורת יומיות ותאריכי טיפול.';
  static const String todayDosesTitle = 'המנות של היום';
  static const String todayDosesEmpty = 'אין מנות מתוכננות להיום.';
  static const String upcomingDosesTitle = 'המנות הבאות';
  static const String upcomingDosesEmpty = 'אין מנות מתוכננות בשבוע הקרוב.';
  static const String activeMedicationsTitle = 'תרופות פעילות';
  static const String futureMedicationsTitle = 'טיפולים שעוד לא התחילו';
  static const String endedMedicationsTitle = 'טיפולים שהסתיימו';

  // Dose records
  static const String doseTaken = 'נלקחה';
  static const String doseSkipped = 'דולגה';
  static const String markDoseTaken = 'נלקחה';
  static const String markDoseSkipped = 'דילוג';
  static const String doseNotRecorded = 'לא תועד';
  static const String doseScheduled = 'מתוכננת';
  static const String doseActions = 'שינוי הרישום';
  static const String changeToTaken = 'שינוי ל"נלקחה"';
  static const String changeToSkipped = 'שינוי ל"דולגה"';
  static const String clearDoseRecord = 'ביטול הסימון';
  static const String doseRecordedTaken = 'נרשם שהמנה נלקחה';
  static const String doseRecordedSkipped = 'נרשם שהמנה דולגה';
  static const String doseRecordCleared = 'הסימון בוטל';
  static const String doseRecordFailed = 'הרישום לא נשמר. נסו שוב.';
  static const String doseNotScheduled =
      'המנה הזו כבר לא מתוכננת. ייתכן שפרטי התרופה השתנו.';
  static const String doseInFuture = 'אפשר לתעד מנה רק ביום שלה או אחריו.';
  static const String doseMedicationMissing =
      'התרופה כבר לא קיימת. ייתכן שנמחקה.';
  static String doseRecordedAt(String when) => 'תועד ב־$when';
  static String doseSemantics(String time, String status) => '$time, $status';

  // Medication form
  static const String medicationNameLabel = 'שם התרופה';
  static const String medicationNameRequired = 'נא להזין את שם התרופה';
  static const String doseLabel = 'מינון';
  static const String doseHint = 'כפי שנקבע לכם, למשל: טבליה אחת';
  static const String doseRequired = 'נא להזין מינון';
  static const String instructionsLabel = 'הוראות (אופציונלי)';
  static const String instructionsHint = 'למשל: אחרי האוכל';
  static const String reminderTimesLabel = 'שעות תזכורת יומיות';
  static const String addReminderTime = 'הוספת שעה';
  static String removeReminderTime(String time) => 'הסרת השעה $time';
  static const String reminderTimeRequired = 'נא להוסיף לפחות שעת תזכורת אחת';
  static const String reminderTimeDuplicate = 'השעה הזו כבר ברשימה';
  static String tooManyReminderTimes(int max) =>
      'אפשר להוסיף עד $max שעות ביום';
  static const String reminderTimePickerHelp = 'בחירת שעת תזכורת';
  static const String startDateLabel = 'תאריך התחלה';
  static const String endDateLabel = 'תאריך סיום (אופציונלי)';
  static const String startDatePickerHelp = 'בחירת תאריך התחלת הטיפול';
  static const String endDatePickerHelp = 'בחירת תאריך סיום הטיפול';
  static const String clearEndDate = 'הסרת תאריך הסיום';
  static const String noEndDate = 'ללא תאריך סיום';
  static const String endBeforeStart =
      'תאריך הסיום לא יכול להיות לפני תאריך ההתחלה';
  static const String medicationFormNotice =
      'הזינו את הפרטים כפי שקיבלתם מהרופא או מהרוקח. MyDr לא בודקת אותם '
      'ולא משנה אותם.';
  static const String medicationMemberFixed =
      'תרופה שייכת לבן משפחה אחד ואי אפשר להעביר אותה לאחר.';
  static const String medicationMemberDeletedWhileEditing =
      'בן המשפחה שנבחר נמחק. נא לבחור בן משפחה אחר.';
  static const String medicationDeletedWhileEditing =
      'התרופה נמחקה בזמן העריכה, ולכן אי אפשר לשמור את השינויים.';
  static const String medicationMissingOnSave =
      'התרופה כבר לא קיימת, ולכן השינויים לא נשמרו.';
  static const String medicationNotFoundTitle = 'התרופה לא נמצאה';
  static const String medicationNotFoundMessage =
      'ייתכן שהתרופה נמחקה, או שבן המשפחה נמחק יחד עם התרופות שלו.';
  static const String backToMedications = 'חזרה לתרופות';
  static const String remindersPermissionAfterSave =
      'כדי לקבל תזכורות, אפשרו ל־MyDr להציג התראות.';

  // Medication details
  static const String medicationDetailsSection = 'פרטי התרופה';
  static const String reminderTimesSection = 'שעות תזכורת';
  static const String treatmentDatesSection = 'תאריכי הטיפול';
  static String treatmentFrom(String date) => 'מ־$date, ללא תאריך סיום';
  static String treatmentRange(String start, String end) =>
      'מ־$start עד $end (כולל)';
  static const String medicationActive = 'פעילה';
  static const String medicationEnded = 'הסתיימה';
  static String medicationStartsOn(String date) => 'תתחיל ב־$date';
  static const String recentDosesTitle = 'המנות בשבוע האחרון';
  static const String recentDosesEmpty = 'לא היו מנות מתוכננות בשבוע האחרון.';
  static const String doseHistoryTitle = 'היסטוריית רישומים';
  static const String doseHistoryEmpty = 'עדיין לא תועדו מנות.';
  static String doseCountSummary(int taken, int skipped) =>
      'נלקחו: $taken · דולגו: $skipped';

  // Deleting a medication
  static const String deleteMedication = 'מחיקת התרופה';
  static const String deleteMedicationTitle = 'למחוק את התרופה?';
  static String deleteMedicationRecords(int count) => switch (count) {
    0 => 'אין לתרופה רישומי מנות.',
    1 => 'יימחק גם רישום מנה אחד.',
    _ => 'יימחקו גם $count רישומי מנות.',
  };
  static const String deleteMedicationRemovesReminders =
      'התזכורות של התרופה יבוטלו. התרופות והרישומים של שאר בני המשפחה לא '
      'ישתנו.';
  static const String deleteMedicationFailed =
      'המחיקה נכשלה, והתרופה לא נמחקה. אפשר לנסות שוב.';
  static const String medicationDeleted = 'התרופה נמחקה';

  // Reminder status
  static const String remindersDisabled =
      'ההתראות של MyDr כבויות, ולכן התזכורות לא יוצגו. כל השאר ממשיך '
      'לעבוד: אפשר להוסיף תרופות ולתעד מנות.';
  static const String enableReminders = 'הפעלת התראות';
  static const String openNotificationSettingsHint =
      'אם לא הופיעה בקשה, אפשר להפעיל התראות בהגדרות המכשיר, בהגדרות של '
      'MyDr.';
  static const String remindersUnsupported =
      'במכשיר הזה לא מוצגות תזכורות. התרופות והרישומים נשמרים כרגיל.';
  static const String remindersFailed =
      'לא הצלחנו לתזמן את התזכורות. התרופות והרישומים נשמרו.';
  static String remindersScheduledUntil(String when) =>
      'התזכורות מתוזמנות עד $when. הן מתחדשות בכל פתיחה של האפליקציה.';
  static const String remindersTruncated =
      'יש יותר מנות ממה שאפשר לתזמן מראש. פתחו את MyDr מדי פעם כדי '
      'שהתזכורות יתחדשו.';
  static const String remindersNoneScheduled = 'אין כרגע תזכורות מתוזמנות.';
  static const String remindersPrivacy =
      'בהתראה מופיע רק "תזכורת מ־MyDr", בלי שם התרופה או בן המשפחה.';

  // Reminder notification: generic on purpose, shown on the lock screen.
  static const String reminderNotificationTitle = 'תזכורת מ־MyDr';
  static const String reminderNotificationBody =
      'יש תזכורת שקבעתם. לפרטים, פתחו את האפליקציה.';
  static const String reminderChannelName = 'תזכורות';
  static const String reminderChannelDescription =
      'תזכורות ששמרתם ב־MyDr, ללא פרטים אישיים.';

  // Medications on a member's profile
  static const String memberMedicationsTitle = 'תרופות';
  static const String memberMedicationsEmpty = 'לא נוספו תרופות פעילות.';
  static String activeMedicationCount(int count) =>
      count == 1 ? 'תרופה פעילה אחת' : '$count תרופות פעילות';
  static const String allMemberMedications = 'כל התרופות והמנות';

  // Account and cloud backup
  static const String backupTitle = 'גיבוי וחשבון';
  static const String backupCardSubtitle = 'גיבוי מוצפן בענן ושחזור במכשיר אחר';
  static const String backupPrivacy =
      'הגיבוי מוצפן במכשיר לפני שהוא נשלח, במפתח שחזור שנמצא רק אצלכם. '
      'השרת שומר רק מידע מוצפן ולא יכול לקרוא אותו. בלי מפתח השחזור אי '
      'אפשר לשחזר את הגיבוי, גם לא בעזרתנו.';
  static const String backupOfflineNote =
      'האפליקציה ממשיכה לעבוד כרגיל גם בלי חיבור לאינטרנט. החיבור לענן נדרש '
      'רק לגיבוי ולשחזור.';
  static const String backupNotConfiguredTitle = 'גיבוי בענן לא זמין';
  static const String backupNotConfiguredMessage =
      'הגרסה הזו של האפליקציה לא הוגדרה לגיבוי בענן. כל המידע נשמר במכשיר '
      'בלבד.';
  static const String backupDemoMode =
      'במצב הדגמה אין גיבוי ואין שחזור, כי שום מידע לא נשמר.';
  static const String cloudConnecting = 'מתחברים לשירות הגיבוי…';
  static const String cloudConnectFailed =
      'לא הצלחנו להתחבר לשירות הגיבוי. בדקו את החיבור לאינטרנט ונסו שוב.';

  // Signing in
  static const String signInTitle = 'התחברות לחשבון';
  static const String emailLabel = 'אימייל';
  static const String passwordLabel = 'סיסמה';
  static const String signIn = 'התחברות';
  static const String createAccount = 'יצירת חשבון';
  static const String forgotPassword = 'שכחתי סיסמה';
  static const String signOut = 'התנתקות';
  static String signedInAs(String email) => 'מחוברים בתור $email';
  static const String emailRequired = 'נא להזין אימייל';
  static const String passwordTooShort = 'הסיסמה צריכה לכלול לפחות 8 תווים';
  static const String passwordResetSent =
      'אם קיים חשבון עם האימייל הזה, נשלח אליו קישור לאיפוס הסיסמה.';
  static const String accountInvalidEmail = 'כתובת האימייל אינה תקינה.';
  static const String accountWrongCredentials = 'האימייל או הסיסמה שגויים.';
  static const String accountEmailInUse = 'כבר קיים חשבון עם האימייל הזה.';
  static const String accountWeakPassword =
      'הסיסמה חלשה מדי. בחרו סיסמה ארוכה יותר.';
  static const String accountNetwork =
      'אין חיבור לאינטרנט. נסו שוב כשהחיבור יחזור.';
  static const String accountTooManyAttempts =
      'היו יותר מדי ניסיונות. נסו שוב מאוחר יותר.';
  static const String accountUnknownError = 'הפעולה נכשלה. נסו שוב.';
  static const String signOutConfirmTitle = 'להתנתק מהחשבון?';
  static const String signOutConfirmMessage =
      'הגיבויים נשארים בענן. מפתח השחזור יימחק מהמכשיר, ותצטרכו להזין אותו '
      'שוב כדי לגבות או לשחזר.';

  // Recovery key
  static const String recoveryKeyTitle = 'מפתח שחזור';
  static const String recoveryKeyNeeded =
      'כדי לגבות, צריך מפתח שחזור. המפתח מצפין את הגיבוי ונשמר רק במכשיר '
      'ואצלכם.';
  static const String recoveryKeyNeededWithBackups =
      'בחשבון כבר יש גיבויים. כדי לגבות או לשחזר, הזינו את מפתח השחזור '
      'שקיבלתם כשיצרתם אותם.';
  static const String createRecoveryKey = 'יצירת מפתח שחזור';
  static const String enterRecoveryKey = 'יש לי מפתח שחזור';
  static const String showRecoveryKey = 'הצגת מפתח השחזור';
  static const String newRecoveryKeyTitle = 'מפתח השחזור שלכם';
  static const String newRecoveryKeyMessage =
      'רשמו את המפתח ושמרו אותו במקום בטוח, מחוץ לטלפון. הוא יידרש כדי לשחזר '
      'את הגיבוי במכשיר אחר. אם הוא יאבד, אי אפשר יהיה לשחזר את הגיבוי.';
  static const String newRecoveryKeyOldBackups =
      'גיבויים קודמים בחשבון נשארים מוצפנים במפתח הקודם, ורק הוא יפתח אותם.';
  static const String confirmLastGroupLabel =
      'לאישור, הקלידו את 4 התווים האחרונים של המפתח';
  static const String confirmLastGroupMismatch = 'התווים לא תואמים לסוף המפתח';
  static const String recoveryKeySaved = 'שמרתי את המפתח';
  static const String recoveryKeyFieldLabel = 'מפתח השחזור';
  static const String recoveryKeyHint = 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX';
  static const String recoveryKeyInvalid =
      'זה לא מפתח שחזור תקין. בדקו שהקלדתם את כל 28 התווים.';
  static const String recoveryKeyDoesNotMatch =
      'המפתח תקין, אבל הגיבויים בחשבון הזה לא הוצפנו בו.';
  static const String recoveryKeyStored = 'מפתח השחזור נשמר במכשיר';
  static const String recoveryKeyUnavailable =
      'לא הצלחנו לקרוא את מפתח השחזור מהמכשיר.';
  static const String recoveryKeyRevealWarning =
      'כל מי שמחזיק במפתח ובסיסמה לחשבון יכול לשחזר את המידע. אל תשתפו אותו.';
  static const String continueLabel = 'המשך';

  // Backing up
  static const String backUpNow = 'גיבוי עכשיו';
  static const String backingUp = 'מצפינים ומעלים…';
  static const String backupSucceeded = 'הגיבוי הושלם';
  static const String backupStatusTitle = 'מצב הגיבוי';
  static const String noBackupsYet = 'עדיין אין גיבויים בחשבון.';
  static String lastBackup(String when) => 'הגיבוי האחרון: $when';
  static const String backupsListTitle = 'גיבויים בענן';
  static String backupSize(String size) => 'גודל מוצפן: $size';
  static const String backupsLoadFailed = 'לא הצלחנו לטעון את רשימת הגיבויים.';
  static const String backupKeepsTwo =
      'נשמרים שני הגיבויים האחרונים. גיבוי קודם נמחק רק אחרי שגיבוי חדש הושלם.';

  // Restoring
  static const String restore = 'שחזור';
  static const String preparingRestore = 'מורידים ובודקים את הגיבוי…';
  static const String restoring = 'משחזרים…';
  static const String restoreConfirmTitle = 'לשחזר את הגיבוי?';
  static String restoreFrom(String when) => 'גיבוי מ־$when';
  static const String restoreBackupContains = 'הגיבוי כולל:';
  static const String restoreDeviceHas = 'במכשיר כרגע:';
  static const String restoreReplacesWarning =
      'כל המידע שבמכשיר יוחלף במידע מהגיבוי. מידע שנוסף במכשיר אחרי הגיבוי '
      'יימחק.';
  static const String restoreDeviceEmpty = 'אין כרגע מידע במכשיר.';
  static const String restoreUnderstand =
      'הבנתי שהמידע במכשיר יוחלף ושאי אפשר לבטל את זה';
  static const String restoreConfirm = 'החלפה ושחזור';
  static const String restoreSucceeded = 'השחזור הושלם';
  static String restoreMissingFiles(int count) => count == 1
      ? 'קובץ אחד כבר היה חסר בזמן הגיבוי, והרשומה שלו שוחזרה בלעדיו.'
      : '$count קבצים כבר היו חסרים בזמן הגיבוי, והרשומות שלהם שוחזרו בלעדיהם.';
  static String countFamilyMembers(int n) => 'בני משפחה: $n';
  static String countAppointments(int n) => 'תורים: $n';
  static String countQuestions(int n) => 'שאלות לרופא: $n';
  static String countSymptoms(int n) => 'רישומי תסמינים: $n';
  static String countVisitMedia(int n) => 'תמונות וסרטונים: $n';
  static String countMedications(int n) => 'תרופות: $n';
  static String countDoseRecords(int n) => 'רישומי מנות: $n';

  // Backup failures
  static const String backupFailedNetwork =
      'אין חיבור לשירות הגיבוי. שום מידע במכשיר לא השתנה. נסו שוב.';
  static const String backupFailedUnauthorized =
      'אין הרשאה לגשת לגיבוי. התחברו מחדש ונסו שוב.';
  static const String backupFailedQuota = 'נגמר המקום בחשבון הגיבוי.';
  static const String backupFailedWrongKey = 'מפתח השחזור לא מתאים לגיבוי הזה.';
  static const String backupFailedDamaged =
      'הגיבוי פגום או ששונה, ולכן לא שוחזר. המידע במכשיר לא השתנה.';
  static const String backupFailedUnsupported =
      'הגיבוי נוצר בגרסה חדשה יותר של האפליקציה. עדכנו את האפליקציה ונסו שוב.';
  static const String backupFailedNotFound = 'הגיבוי לא נמצא. ייתכן שנמחק.';
  static const String backupFailedLocalRead =
      'לא הצלחנו לקרוא את המידע במכשיר, ולכן לא נוצר גיבוי.';
  static const String backupFailedLocalWrite =
      'לא הצלחנו לשמור את המידע מהגיבוי. המידע במכשיר לא השתנה.';
  static const String backupFailedUnknown =
      'הפעולה נכשלה. המידע במכשיר לא השתנה. נסו שוב.';

  // Placeholders
  static const String comingSoonBadge = 'בקרוב';
}
