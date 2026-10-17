import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mydr/data/reminders/reminder_scheduler.dart';
import 'package:timezone/timezone.dart' as tz;

/// The generic text every reminder shows. Supplied by the UI layer, which
/// owns all user-facing strings.
class ReminderTexts {
  const ReminderTexts({
    required this.title,
    required this.body,
    required this.channelName,
    required this.channelDescription,
  });

  final String title;
  final String body;

  /// Android's name for the notification category, shown in the system
  /// settings.
  final String channelName;
  final String channelDescription;
}

/// [ReminderScheduler] on Android and iOS, through
/// flutter_local_notifications.
///
/// Every notification has the same generic title and body and no payload,
/// so neither the lock screen nor the plugin's own record of scheduled
/// notifications (stored unencrypted by the operating system) ever holds a
/// medication name or any other health detail.
///
/// Times are handed over as instants: a wall-clock time is converted with
/// the device's current time zone rules (which include daylight saving)
/// at the moment of scheduling. After a time zone change the reminders are
/// planned again when the app next opens.
class LocalNotificationReminderScheduler implements ReminderScheduler {
  LocalNotificationReminderScheduler({
    required this.texts,
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function() clock = DateTime.now,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _clock = clock;

  static const String channelId = 'dose_reminders';

  /// A reminder closer than this is skipped rather than risk being in the
  /// past by the time the platform receives it.
  static const Duration minimumLeadTime = Duration(seconds: 5);

  final ReminderTexts texts;
  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _clock;
  Future<void>? _initialization;

  /// Whether this platform is one the plugin is set up for here.
  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _initialize() => _initialization ??= _plugin
      .initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Permission is asked for in context (see requestPermission), never
          // at start-up.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      )
      .then(
        (_) {},
        onError: (Object error) {
          // Allow a later call to try again.
          _initialization = null;
          throw error;
        },
      );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<ReminderAvailability> availability() async {
    if (!isSupportedPlatform) return ReminderAvailability.unsupported;
    await _initialize();
    final bool? enabled;
    if (_android case final android?) {
      enabled = await android.areNotificationsEnabled();
    } else if (_ios case final ios?) {
      enabled = (await ios.checkPermissions())?.isEnabled;
    } else {
      return ReminderAvailability.unsupported;
    }
    return enabled == true
        ? ReminderAvailability.enabled
        : ReminderAvailability.disabled;
  }

  @override
  Future<ReminderAvailability> requestPermission() async {
    if (!isSupportedPlatform) return ReminderAvailability.unsupported;
    await _initialize();
    if (_android case final android?) {
      // Shows the system dialog on Android 13+, unless the user already
      // refused it twice; then it returns at once.
      await android.requestNotificationsPermission();
    } else if (_ios case final ios?) {
      await ios.requestPermissions(alert: true, sound: true);
    }
    return availability();
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    if (!isSupportedPlatform) return;
    await _initialize();
    // Pending ones only: a reminder already showing stays until dismissed.
    await _plugin.cancelAllPendingNotifications();
    if (reminders.isEmpty) return;

    final android = _android;
    final exact = await android?.canScheduleExactNotifications() ?? false;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        texts.channelName,
        channelDescription: texts.channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        // The text is generic anyway; this also hides it on a secure lock
        // screen.
        visibility: NotificationVisibility.private,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );

    final earliest = _clock().add(minimumLeadTime);
    for (final reminder in reminders) {
      if (!reminder.at.isAfter(earliest)) continue;
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: texts.title,
        body: texts.body,
        scheduledDate: tz.TZDateTime.from(reminder.at.toUtc(), tz.UTC),
        notificationDetails: details,
        // Without the exact-alarm permission (off by default from Android
        // 14), Android may deliver the reminder late to save battery.
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
