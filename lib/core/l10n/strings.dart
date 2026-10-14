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
  static const String familyCardDescription =
      'בקרוב תוכלו להוסיף פרופילים ולנהל את המידע הבריאותי של כל בני המשפחה.';

  static const String quickActionsTitle = 'פעולות מהירות';
  static const String actionNewAppointment = 'תור חדש';
  static const String actionLogSymptom = 'תיעוד תסמין';
  static const String actionDoctorQuestions = 'שאלות לרופא';

  static const String nextAppointmentTitle = 'התור הקרוב';
  static const String nextAppointmentEmptyTitle = 'אין תורים מתוכננים';
  static const String nextAppointmentEmptyMessage =
      'לאחר הוספת תורים, התור הקרוב יוצג כאן.';

  // Emergency card
  static const String emergencyTitle = 'עזרה ראשונה וחירום';
  static const String emergencyCallLine = 'במצב חירום חייגו 101 (מד״א)';
  static const String emergencyNoInstructions =
      'האפליקציה אינה כוללת עדיין הנחיות רפואיות. מידע לעזרה ראשונה יתווסף '
      'בהמשך ממקורות מאומתים בלבד.';

  // Placeholders
  static const String comingSoonBadge = 'בקרוב';
  static const String comingSoon = 'המסך יהיה זמין בקרוב';
  static const String familyPlaceholder =
      'כאן תוכלו לנהל את פרופילי בני המשפחה.';
  static const String appointmentsPlaceholder =
      'כאן תוכלו לנהל תורים ושאלות לרופא.';
  static const String symptomsPlaceholder =
      'כאן תוכלו לתעד תסמינים ולצפות בהיסטוריה.';
}
