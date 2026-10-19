import 'package:mydr/data/reminders/reminder_scheduler.dart';

class SimulatedSchedulerFailure implements Exception {
  const SimulatedSchedulerFailure();
}

/// Records what the app asks of the notification system, with a permission
/// state and failures set by the test.
class FakeReminderScheduler implements ReminderScheduler {
  FakeReminderScheduler({
    this.permission = ReminderAvailability.enabled,
    this.grantOnRequest = false,
  });

  ReminderAvailability permission;

  /// Whether asking turns a disabled permission into enabled.
  bool grantOnRequest;

  /// Whether reminders are scheduled for their exact time.
  bool exactTiming = true;

  /// Whether asking for exact timing allows it.
  bool grantExactOnRequest = false;

  bool failAvailability = false;
  bool failReplace = false;
  bool failExactTiming = false;

  int permissionRequests = 0;
  int exactTimingRequests = 0;

  /// Every list passed to [replaceAll], in order.
  final List<List<PlannedReminder>> replacements = [];

  /// What is scheduled now: the last successful replacement.
  List<PlannedReminder> get scheduled =>
      replacements.isEmpty ? const [] : replacements.last;

  @override
  Future<ReminderAvailability> availability() async {
    if (failAvailability) throw const SimulatedSchedulerFailure();
    return permission;
  }

  @override
  Future<ReminderAvailability> requestPermission() async {
    permissionRequests++;
    if (grantOnRequest) permission = ReminderAvailability.enabled;
    return permission;
  }

  @override
  Future<bool> hasExactTiming() async {
    if (failExactTiming) throw const SimulatedSchedulerFailure();
    return exactTiming;
  }

  @override
  Future<bool> requestExactTiming() async {
    exactTimingRequests++;
    if (failExactTiming) throw const SimulatedSchedulerFailure();
    if (grantExactOnRequest) exactTiming = true;
    return exactTiming;
  }

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async {
    if (failReplace) throw const SimulatedSchedulerFailure();
    replacements.add(List.unmodifiable(reminders));
  }
}
