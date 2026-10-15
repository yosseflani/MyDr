# MyDr

אפליקציית Flutter לניהול בריאות אישי ומשפחתי, בעברית ומימין לשמאל: בני משפחה, תורים, שאלות לרופא, יומן תסמינים, ומרכז חירום עם ספריית עזרה ראשונה.

המידע נשמר במכשיר בלבד, במסד נתונים מוצפן (SQLCipher). אין ענן, אין שליחה לרשת ואין AI. האפליקציה אינה מספקת אבחון או ייעוץ רפואי.

## הרצה

```sh
flutter pub get
flutter run                                  # regular mode: encrypted local database, starts empty
flutter run --dart-define=MYDR_DEMO=true     # demo mode: fictional data in memory, nothing saved
```

## בדיקות

```sh
flutter analyze
flutter test
flutter test integration_test -d <device-id>   # Warning: uninstalls the app from the device at the end
```

## תיעוד

- [שמירת נתונים מקומית ומוצפנת](docs/local_storage.md): מבנה המסד, הצפנה, מפתחות, Migrations ומגבלות אבטחה.
- [מדיניות תוכן העזרה הראשונה](docs/first_aid_content_policy.md)

> האפליקציה לא עברה ביקורת אבטחה או ביקורת רפואית חיצונית, ואין להשתמש בה למידע רפואי אמיתי לפני ביקורת כזו.
