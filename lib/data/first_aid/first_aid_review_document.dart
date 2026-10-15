import 'package:mydr/data/first_aid/content_approvals.dart';
import 'package:mydr/data/first_aid/first_aid_content_parser.dart';
import 'package:mydr/data/models/first_aid_content.dart';

/// Builds the medical review document (docs/first_aid_medical_review.md,
/// in Hebrew) from the draft file, the app's content and the trusted
/// approvals, so the document always shows exactly what a reviewer would
/// approve. `tool/first_aid_review.dart` writes it; a test fails when the
/// committed document is out of date.
///
/// The approval status comes only from [approvals] and [published]; the
/// document never claims an approval that the app would not honor.
String buildFirstAidReviewDocument({
  required FirstAidContentPack drafts,
  required FirstAidContentPack published,
  List<ContentApproval> approvals = FirstAidApprovals.trusted,
}) {
  final out = StringBuffer();
  void line([String text = '']) => out.writeln(text);
  final date = FirstAidContentParser.formatDate;

  line('# סקירה רפואית: ספריית העזרה הראשונה');
  line();
  line(
    '> מסמך שנוצר אוטומטית מקובץ הטיוטות. אין לערוך אותו ידנית. '
    'לעדכון: `dart run tool/first_aid_review.dart`.',
  );
  line();
  line('- קובץ הטיוטות: `assets/first_aid/review/he.draft.json`');
  line('- גרסת הטיוטות: ${drafts.contentVersion}');
  line('- תאריך הטיוטות: ${date(drafts.publishedAt)}');
  line(
    '- התוכן שהאפליקציה מציגה: `assets/first_aid/he.json`, '
    'גרסה ${published.contentVersion}',
  );
  line('- אישורים מקצועיים רשומים: ${approvals.length}');
  line();
  line('## מצב האישור');
  line();
  line('| נושא | מצב בטיוטות | מצב באפליקציה | אישור מקצועי |');
  line('| --- | --- | --- | --- |');
  for (final draft in drafts.topics) {
    final live = published.topicById(draft.id);
    final approval = _approvalFor(draft.id, published, approvals);
    line(
      '| ${draft.title} | ${_status(draft.status)} | '
      '${live == null ? 'לא קיים' : _status(live.status)} | '
      '${approval == null ? 'אין' : '${approval.approvedBy}, ${approval.approvedOn}'} |',
    );
  }
  line();
  line(
    'כל ההנחיות נכתבו מחדש בעברית, על סמך המקורות שנבדקו בפועל ושמפורטים '
    'בכל נושא. הן לא נבדקו על ידי איש מקצוע רפואי.',
  );
  line();
  line(
    'נושא "מבוסס מקורות" מוצג באפליקציה במצב הרגיל עם ההנחיות המלאות, '
    'תחת הודעה בולטת שההנחיות מבוססות על מקורות רפואיים אך טרם עברו '
    'אישור מקצועי פרטני עבור MyDr. הוא אינו מסומן כמאומת. נושא "מאומת" '
    'מחייב אישור מקצועי אמיתי שנרשם בקוד, כמפורט בתהליך שלהלן. הערות '
    'הסוקר מופיעות רק במסמך הזה ובתצוגה המקדימה למפתחים, ולא באפליקציה.',
  );
  line();
  line('## תהליך האישור');
  line();
  line(
    '1. איש מקצוע רפואי מוסמך (למשל רופא או רופאה, פרמדיק או פרמדיקית, '
    'או מדריך או מדריכה מוסמכים של מד"א) קורא את הנושא במסמך הזה, '
    'ומשווה אותו למקורות ולנהלים העדכניים בישראל.',
  );
  line(
    '2. הסוקר או הסוקרת מכריעים בכל אחת מ"הערות לסוקר", ומבקשים תיקונים '
    'לפי הצורך. כל תיקון משנה את טביעת התוכן, והנושא חוזר לסקירה.',
  );
  line(
    '3. האישור נרשם בכתב, לגרסה מסוימת: מזהה הנושא, גרסת הטיוטות, טביעת '
    'התוכן לאישור (SHA-256) שמופיעה בנושא, שם הסוקר או הסוקרת, תפקיד '
    'ומספר רישיון, ותאריך.',
  );
  line(
    '4. רק אחרי אישור כזה: משנים את הנושא ב־`assets/first_aid/he.json` '
    'מ־`"sourced"` ל־`"status": "verified"` ומוסיפים `verification`. מחשבים '
    'את הטביעה המלאה (`publishedFingerprint`) ומוסיפים `ContentApproval` '
    'ל־`FirstAidApprovals.trusted`.',
  );
  line(
    '5. כל שינוי, אפילו מילה אחת, מקור או פרטי האימות, משנה את הטביעה. '
    'האפליקציה מבטלת אז את האישור אוטומטית ומציגה את הנושא כ"בהכנה", '
    'בלי הנחיות, עד אישור חדש.',
  );
  line();
  line('## מקורות שלא ניתן היה לאמת');
  line();
  line(
    'המקורות האלה נבדקו בניסיון גישה ישיר ולא היו נגישים, או שלא ניתן '
    'היה לקרוא את התוכן שלהם. לכן לא שימשו כמקור לאף הנחיה:',
  );
  line();
  for (final note in unverifiedSources) {
    line('- $note');
  }
  line();

  for (final topic in drafts.topics) {
    _writeTopic(out, topic, published, approvals);
  }
  // Exactly one newline at the end of the file.
  return '${out.toString().trimRight()}\n';
}

/// Sources the drafts could not be based on, with why.
const List<String> unverifiedSources = [
  'American Heart Association: 2025 Guidelines for CPR and ECC. '
      'האתרים cpr.heart.org ו־professional.heart.org החזירו שגיאת 403 בכל '
      'הניסיונות. נבדקו רק סיכומים משניים.',
  'American Heart Association ו־American Red Cross: 2024 Guidelines for '
      'First Aid. האתרים החזירו שגיאת 403.',
  'European Resuscitation Council: Guidelines 2025. נמצא רק תקציר '
      '(PubMed). הטקסט המלא לא נבדק.',
  'משרד הבריאות (gov.il). הגישה לאתר נחסמה.',
  'משרד החינוך ומד"א: דף מידע לעזרה ראשונה (2020–2021, '
      'meyda.education.gov.il). חילוץ הטקסט מה־PDF נכשל, ולכן התוכן לא אומת.',
];

ContentApproval? _approvalFor(
  String topicId,
  FirstAidContentPack published,
  List<ContentApproval> approvals,
) {
  final topic = published.topicById(topicId);
  if (topic == null || !topic.isVerified) return null;
  final hash = FirstAidContentParser.publishedFingerprint(topic);
  for (final approval in approvals) {
    if (approval.topicId == topicId &&
        approval.locale == published.locale &&
        approval.contentSha256 == hash) {
      return approval;
    }
  }
  return null;
}

String _status(ContentStatus status) => switch (status) {
  ContentStatus.pending => 'בהכנה',
  ContentStatus.draft => 'טיוטה, לא מאושרת',
  ContentStatus.sourced => 'מבוסס מקורות, לא אושר מקצועית',
  ContentStatus.verified => 'מאומת',
};

void _writeTopic(
  StringBuffer out,
  FirstAidTopic topic,
  FirstAidContentPack published,
  List<ContentApproval> approvals,
) {
  void line([String text = '']) => out.writeln(text);
  void list(String title, List<String> items) {
    if (items.isEmpty) return;
    line('**$title**');
    line();
    for (final item in items) {
      line('- $item');
    }
    line();
  }

  final date = FirstAidContentParser.formatDate;
  final approval = _approvalFor(topic.id, published, approvals);

  line('## ${topic.title} (`${topic.id}`)');
  line();
  final live = published.topicById(topic.id);
  line('- מצב בקובץ הסקירה: ${_status(topic.status)}');
  line(
    '- מצב באפליקציה: ${live == null ? 'לא קיים' : _status(live.status)}'
    '${live != null && live.isPublished && FirstAidContentParser.reviewFingerprint(live) != FirstAidContentParser.reviewFingerprint(topic) ? ' (הנוסח באפליקציה שונה מהנוסח כאן)' : ''}',
  );
  line(
    '- אישור מקצועי: '
    '${approval == null ? 'אין. הנושא אינו מוצג כהנחיות מאומתות.' : '${approval.approvedBy}, ${approval.approvedOn}'}',
  );
  line(
    '- טביעת התוכן לאישור (SHA-256): '
    '`${FirstAidContentParser.reviewFingerprint(topic)}`',
  );
  final lastChecked = topic.lastChecked;
  if (lastChecked != null) {
    line('- נבדק לאחרונה מול המקורות: ${date(lastChecked)}');
  }
  line();
  line(topic.summary);
  line();
  final overview = topic.overview;
  if (overview != null) {
    line(overview);
    line();
  }
  list('מתי לחייג 101 מיד', topic.callNow);
  list('איך מזהים', topic.recognize);
  for (final variant in topic.variants) {
    final appliesTo = variant.appliesTo;
    line(
      '### ${variant.label}'
      '${appliesTo == null ? '' : ' ($appliesTo)'}',
    );
    line();
    for (final step in variant.steps) {
      final note = step.note;
      line('${step.order}. ${step.text}${note == null ? '' : ' ($note)'}');
    }
    line();
    list('מה לא לעשות', variant.doNot);
  }
  list('אזהרות', topic.warnings);
  list('גם אחרי שיפור', topic.afterCare);
  line('**מקורות**');
  line();
  for (final source in topic.sources) {
    line(
      '- ${source.publisher}: ${source.title}. '
      'פורסם או עודכן: ${source.published}. '
      'נבדק: ${date(source.accessedOn)}. <${source.url}>',
    );
  }
  line();
  list('הערות לסוקר: סתירות ונקודות להכרעה', topic.reviewNotes);
}
