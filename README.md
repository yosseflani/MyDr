# MyDr

אפליקציית Flutter לניהול בריאות אישי ומשפחתי, בעברית ומימין לשמאל: בני משפחה, תורים, שאלות לרופא, יומן תסמינים, ומרכז חירום עם ספריית עזרה ראשונה.

המידע נשמר במכשיר בלבד, במסד נתונים מוצפן (SQLCipher). אין ענן, אין שליחה לרשת ואין AI. האפליקציה אינה מספקת אבחון או ייעוץ רפואי.

## הרצה

```sh
flutter pub get
flutter run                                  # regular mode: encrypted local database, starts empty
flutter run --dart-define=MYDR_DEMO=true     # demo mode: fictional data in memory, nothing saved
flutter run --dart-define=MYDR_FIRST_AID_REVIEW=true   # debug only: adds the first-aid draft review preview
```

### ספריית העזרה הראשונה

שבעת נושאי העזרה הראשונה מציגים הנחיות מלאות, במצב הרגיל וב־Release: התאמות לפי גיל או מצב, שלבים, אזהרות ומקורות עם תאריכים. ההנחיות **מבוססות על מקורות רפואיים, אבל טרם אושרו מקצועית** עבור MyDr, וכך הן מסומנות באפליקציה. אף נושא אינו מסומן כמאומת. ההבדל בין שני הסוגים מוסבר ב[מדיניות התוכן](docs/first_aid_content_policy.md). התצוגה המקדימה לסקירה (Debug build עם הדגל שלמעלה) מוסיפה את הטיוטות עם הערות הסוקר.

```sh
dart run tool/first_aid_review.dart   # regenerates docs/first_aid_medical_review.md from the content files
```

## בדיקות

```sh
flutter analyze
flutter test
flutter test integration_test -d <device-id>   # Warning: uninstalls the app from the device at the end
```

## תיעוד

- [שמירת נתונים מקומית ומוצפנת](docs/local_storage.md): מבנה המסד, הצפנה, מפתחות, Migrations ומגבלות אבטחה.
- [מדיניות תוכן העזרה הראשונה](docs/first_aid_content_policy.md): מקורות, מבנה התוכן, טיוטות ותהליך האישור.
- [מסמך הסקירה הרפואית](docs/first_aid_medical_review.md): כל ההנחיות בטיוטה, המקורות, הסתירות ומצב האישור. המסמך נוצר אוטומטית.

> האפליקציה לא עברה ביקורת אבטחה או ביקורת רפואית חיצונית, ואין להשתמש בה למידע רפואי אמיתי לפני ביקורת כזו.
