/// Whether the device will show the app's reminders.
enum ReminderAvailability {
  /// Notifications are allowed.
  enabled,

  /// The user has not allowed notifications (or turned them off). Reminders
  /// are still planned, so they work as soon as notifications are allowed.
  disabled,

  /// This platform has no local notifications (e.g. desktop, tests).
  unsupported,
}

/// One notification to show at [at], a local wall-clock time.
///
/// It carries no medical details: the notification text is the same
/// generic text for every reminder, so nothing about a medication or a
/// family member ever reaches the lock screen or the operating system's
/// notification store.
class PlannedReminder {
  const PlannedReminder({required this.id, required this.at});

  /// Stable for the same [at], so planning again gives the same ids.
  final int id;
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder && other.id == id && other.at == at;

  @override
  int get hashCode => Object.hash(id, at);

  @override
  String toString() => 'PlannedReminder($id)';
}

/// Schedules the app's local notifications.
///
/// The operating system decides when (and whether) they are shown: a
/// reminder can be delayed by battery saving, or not shown at all if
/// notifications are turned off. Every method may throw; callers treat a
/// failure as "reminders unavailable" and keep working without them.
abstract interface class ReminderScheduler {
  /// Current permission state, without asking the user.
  Future<ReminderAvailability> availability();

  /// Asks the user to allow notifications, where the platform still allows
  /// asking, and returns the resulting state.
  Future<ReminderAvailability> requestPermission();

  /// Whether reminders are scheduled for their exact time. False only where
  /// the user can allow it and has not (Android 12+, "Alarms & reminders");
  /// the operating system may then deliver them late to save battery.
  Future<bool> hasExactTiming();

  /// Opens the system setting that allows exact timing, where there is one,
  /// and returns [hasExactTiming] once the user is back.
  Future<bool> requestExactTiming();

  /// Replaces every pending reminder with [reminders].
  Future<void> replaceAll(List<PlannedReminder> reminders);
}

/// For platforms without local notifications: nothing is ever shown.
class UnsupportedReminderScheduler implements ReminderScheduler {
  const UnsupportedReminderScheduler();

  @override
  Future<ReminderAvailability> availability() async =>
      ReminderAvailability.unsupported;

  @override
  Future<ReminderAvailability> requestPermission() async =>
      ReminderAvailability.unsupported;

  @override
  Future<bool> hasExactTiming() async => true;

  @override
  Future<bool> requestExactTiming() async => true;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {}
}
