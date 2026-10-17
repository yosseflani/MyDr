import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/models/symptom_entry.dart';

/// Fictional sample data for development and demos.
///
/// All people, doctors, clinics and medical details here are invented and
/// generic. Never add real personal or medical information to this file.
///
/// Dates are relative to [now] so there are always both upcoming and past
/// appointments.
abstract final class MockData {
  static const String selfId = 'member-1';
  static const String spouseId = 'member-2';
  static const String daughterId = 'member-3';
  static const String sonId = 'member-4';
  static const String grandmotherId = 'member-5';

  static const String upcomingFamilyDoctorId = 'appointment-1';
  static const String upcomingPediatricianId = 'appointment-2';
  static const String pastEyeCheckId = 'appointment-3';

  static List<FamilyMember> members() => [
    FamilyMember(
      id: selfId,
      name: 'דנה',
      relation: FamilyRelation.self,
      birthDate: DateTime(1988, 4, 12),
    ),
    FamilyMember(
      id: spouseId,
      name: 'אבי',
      relation: FamilyRelation.spouse,
      birthDate: DateTime(1986, 9, 3),
      allergies: const ['אבקני פרחים'],
    ),
    FamilyMember(
      id: daughterId,
      name: 'נועה',
      relation: FamilyRelation.child,
      birthDate: DateTime(2016, 1, 20),
    ),
    FamilyMember(
      id: sonId,
      name: 'איתי',
      relation: FamilyRelation.child,
      birthDate: DateTime(2020, 6, 8),
      notes: 'מעדיף שיחה קצרה לפני בדיקה',
    ),
    FamilyMember(
      id: grandmotherId,
      name: 'סבתא רחל',
      relation: FamilyRelation.grandparent,
      birthDate: DateTime(1950, 11, 30),
      chronicConditions: const ['לחץ דם גבוה'],
    ),
  ];

  static List<Appointment> appointments(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      Appointment(
        id: upcomingFamilyDoctorId,
        memberId: grandmotherId,
        doctorName: 'ד״ר לוי',
        specialty: 'רפואת משפחה',
        dateTime: today.add(const Duration(days: 3, hours: 10)),
        location: 'מרפאה שכונתית',
      ),
      Appointment(
        id: upcomingPediatricianId,
        memberId: sonId,
        doctorName: 'ד״ר מזרחי',
        specialty: 'רפואת ילדים',
        dateTime: today.add(const Duration(days: 10, hours: 16, minutes: 30)),
        location: 'מרפאת ילדים',
        notes: 'ביקורת שגרתית',
      ),
      Appointment(
        id: pastEyeCheckId,
        memberId: daughterId,
        doctorName: 'ד״ר אברהם',
        specialty: 'עיניים',
        dateTime: today
            .subtract(const Duration(days: 20))
            .add(const Duration(hours: 9)),
        location: 'מרפאה שכונתית',
      ),
    ];
  }

  static List<DoctorQuestion> questions(DateTime now) => [
    DoctorQuestion(
      id: 'question-1',
      memberId: grandmotherId,
      appointmentId: upcomingFamilyDoctorId,
      text: 'לשאול על תוצאות בדיקות הדם האחרונות',
      createdAt: now.subtract(const Duration(days: 2)),
    ),
    DoctorQuestion(
      id: 'question-2',
      memberId: grandmotherId,
      appointmentId: upcomingFamilyDoctorId,
      text: 'מתי לקבוע את הביקורת הבאה?',
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    DoctorQuestion(
      id: 'question-3',
      memberId: daughterId,
      appointmentId: pastEyeCheckId,
      text: 'האם צריך בדיקה נוספת?',
      createdAt: now.subtract(const Duration(days: 25)),
      isResolved: true,
      doctorAnswer: 'ביקורת חוזרת בעוד שנה',
    ),
    DoctorQuestion(
      id: 'question-4',
      memberId: selfId,
      text: 'לבקש הפניה לבדיקה תקופתית',
      createdAt: now.subtract(const Duration(days: 5)),
    ),
  ];

  static List<SymptomEntry> symptoms(DateTime now) => [
    SymptomEntry(
      id: 'symptom-1',
      memberId: sonId,
      name: 'שיעול',
      startedAt: now.subtract(const Duration(days: 2)),
      severity: 3,
      notes: 'בעיקר בלילה',
    ),
    SymptomEntry(
      id: 'symptom-4',
      memberId: sonId,
      name: 'שיעול',
      startedAt: now.subtract(const Duration(days: 1)),
      severity: 4,
      notes: 'התגבר במהלך הלילה',
    ),
    SymptomEntry(
      id: 'symptom-5',
      memberId: sonId,
      name: 'שיעול',
      startedAt: now.subtract(const Duration(hours: 3)),
      severity: 2,
      notes: 'פחות מאתמול',
    ),
    SymptomEntry(
      id: 'symptom-2',
      memberId: selfId,
      name: 'כאב ראש',
      startedAt: now.subtract(const Duration(days: 4, hours: 6)),
      severity: 4,
      status: SymptomStatus.resolved,
      duration: const Duration(hours: 3),
    ),
    SymptomEntry(
      id: 'symptom-3',
      memberId: daughterId,
      name: 'חום',
      startedAt: now.subtract(const Duration(days: 12)),
      severity: 5,
      status: SymptomStatus.resolved,
      duration: const Duration(days: 2),
    ),
  ];

  static const String vitaminId = 'medication-1';
  static const String syrupId = 'medication-2';
  static const String dailyTabletId = 'medication-3';

  /// Placeholder names and doses, not suggestions of any treatment.
  static List<Medication> medications(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return [
      Medication(
        id: vitaminId,
        memberId: selfId,
        name: 'ויטמין לדוגמה',
        dose: 'כמוסה אחת',
        reminderTimes: [DoseTime(8, 0)],
        startDate: today.subtract(const Duration(days: 30)),
      ),
      Medication(
        id: syrupId,
        memberId: sonId,
        name: 'סירופ לדוגמה',
        dose: '5 מ״ל',
        instructions: 'אחרי האוכל',
        reminderTimes: [DoseTime(8, 0), DoseTime(20, 0)],
        startDate: today.subtract(const Duration(days: 2)),
        endDate: today.add(const Duration(days: 4)),
      ),
      Medication(
        id: dailyTabletId,
        memberId: grandmotherId,
        name: 'טבליה לדוגמה',
        dose: 'טבליה אחת',
        reminderTimes: [DoseTime(9, 0), DoseTime(21, 0)],
        startDate: today.subtract(const Duration(days: 365)),
      ),
    ];
  }

  static List<DoseRecord> doseRecords(DateTime now) {
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return [
      DoseRecord(
        id: 'dose-1',
        memberId: sonId,
        medicationId: syrupId,
        scheduledAt: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          8,
        ),
        status: DoseStatus.taken,
        recordedAt: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          8,
          5,
        ),
      ),
      DoseRecord(
        id: 'dose-2',
        memberId: sonId,
        medicationId: syrupId,
        scheduledAt: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          20,
        ),
        status: DoseStatus.skipped,
        recordedAt: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          20,
          30,
        ),
      ),
    ];
  }
}
