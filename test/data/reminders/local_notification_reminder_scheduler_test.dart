import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/reminders/local_notification_reminder_scheduler.dart';
import 'package:mydr/data/reminders/reminder_planner.dart';
import 'package:mydr/data/reminders/reminder_scheduler.dart';

/// What the app actually hands to the Android notification plugin, through
/// a mocked platform channel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const texts = ReminderTexts(
    title: 'כותרת כללית',
    body: 'טקסט כללי',
    channelName: 'ערוץ',
    channelDescription: 'תיאור',
  );

  late List<MethodCall> calls;
  late bool notificationsEnabled;
  late bool exactAllowed;
  late bool exactGrantedOnRequest;

  setUp(() {
    calls = [];
    notificationsEnabled = true;
    exactAllowed = false;
    exactGrantedOnRequest = false;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'initialize' => true,
            'areNotificationsEnabled' => notificationsEnabled,
            'requestNotificationsPermission' => notificationsEnabled,
            'canScheduleExactNotifications' => exactAllowed,
            // The plugin returns once the user is back from the setting.
            'requestExactAlarmsPermission' => exactAllowed =
                exactAllowed || exactGrantedOnRequest,
            _ => null,
          };
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  // The plugin itself refuses times in the past, by the real clock.
  final base = DateTime.now().add(const Duration(days: 2));
  final day = DateTime(base.year, base.month, base.day);

  PlannedReminder reminder(DateTime at) =>
      PlannedReminder(id: ReminderPlanner.reminderIdFor(at), at: at);

  List<MethodCall> scheduled() =>
      calls.where((c) => c.method == 'zonedSchedule').toList();

  test('replaces pending reminders with generic, payload-free ones', () async {
    final scheduler = LocalNotificationReminderScheduler(texts: texts);
    final at = DateTime(day.year, day.month, day.day, 8);

    await scheduler.replaceAll([reminder(at)]);

    final methods = calls.map((c) => c.method).toList();
    expect(
      methods.indexOf('cancelAllPendingNotifications'),
      lessThan(methods.indexOf('zonedSchedule')),
    );
    expect(methods, isNot(contains('cancelAll')));

    final args = scheduled().single.arguments as Map;
    expect(args['id'], ReminderPlanner.reminderIdFor(at));
    expect(args['title'], texts.title);
    expect(args['body'], texts.body);
    expect(args['payload'], '');
    // The instant is handed over in UTC, converted with the device's own
    // time zone rules.
    expect(args['timeZoneName'], 'UTC');
    expect(DateTime.parse('${args['scheduledDateTime']}Z'), at.toUtc());
    final platform = args['platformSpecifics'] as Map;
    expect(platform['channelId'], LocalNotificationReminderScheduler.channelId);
    expect(platform['scheduleMode'], 'inexactAllowWhileIdle');
    expect(platform['visibility'], NotificationVisibility.private.index);
  });

  test('uses exact alarms only where the user allows them', () async {
    exactAllowed = true;
    final scheduler = LocalNotificationReminderScheduler(texts: texts);

    await scheduler.replaceAll([
      reminder(DateTime(day.year, day.month, day.day, 8)),
    ]);

    final platform =
        (scheduled().single.arguments as Map)['platformSpecifics'] as Map;
    expect(platform['scheduleMode'], 'exactAllowWhileIdle');
  });

  test('skips reminders that are already due instead of failing', () async {
    final now = DateTime.now();
    final scheduler = LocalNotificationReminderScheduler(
      texts: texts,
      clock: () => now,
    );

    await scheduler.replaceAll([
      reminder(now.subtract(const Duration(minutes: 1))),
      reminder(now.add(const Duration(seconds: 1))),
      reminder(DateTime(day.year, day.month, day.day, 9)),
    ]);

    expect(scheduled(), hasLength(1));
  });

  test('an empty plan only cancels', () async {
    final scheduler = LocalNotificationReminderScheduler(texts: texts);
    await scheduler.replaceAll(const []);
    expect(calls.map((c) => c.method), [
      'initialize',
      'cancelAllPendingNotifications',
    ]);
  });

  test('reports the permission state, and asks only when told to', () async {
    final scheduler = LocalNotificationReminderScheduler(texts: texts);

    expect(await scheduler.availability(), ReminderAvailability.enabled);
    notificationsEnabled = false;
    expect(await scheduler.availability(), ReminderAvailability.disabled);
    expect(
      calls.map((c) => c.method),
      isNot(contains('requestNotificationsPermission')),
    );

    expect(await scheduler.requestPermission(), ReminderAvailability.disabled);
    expect(
      calls.map((c) => c.method),
      contains('requestNotificationsPermission'),
    );
  });

  test('reports exact timing, and opens its setting only when told to', () async {
    final scheduler = LocalNotificationReminderScheduler(texts: texts);

    expect(await scheduler.hasExactTiming(), isFalse);
    expect(
      calls.map((c) => c.method),
      isNot(contains('requestExactAlarmsPermission')),
    );

    // Back from the setting without allowing it.
    expect(await scheduler.requestExactTiming(), isFalse);
    expect(
      calls.where((c) => c.method == 'requestExactAlarmsPermission'),
      hasLength(1),
    );

    exactGrantedOnRequest = true;
    expect(await scheduler.requestExactTiming(), isTrue);
    expect(await scheduler.hasExactTiming(), isTrue);
  });

  test('platform errors reach the caller, which handles them', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'initialize') return true;
          throw PlatformException(code: 'error');
        });
    final scheduler = LocalNotificationReminderScheduler(texts: texts);

    await expectLater(
      scheduler.replaceAll([
        reminder(DateTime(day.year, day.month, day.day, 8)),
      ]),
      throwsA(isA<PlatformException>()),
    );
    // E.g. another permission request still in progress.
    await expectLater(
      scheduler.requestExactTiming(),
      throwsA(isA<PlatformException>()),
    );
  });

  test('platforms without local notifications do nothing', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final scheduler = LocalNotificationReminderScheduler(texts: texts);

    expect(await scheduler.availability(), ReminderAvailability.unsupported);
    // Nothing to warn about or ask for.
    expect(await scheduler.hasExactTiming(), isTrue);
    expect(await scheduler.requestExactTiming(), isTrue);
    await scheduler.replaceAll([
      reminder(DateTime(day.year, day.month, day.day, 8)),
    ]);
    expect(calls, isEmpty);
  });
}
