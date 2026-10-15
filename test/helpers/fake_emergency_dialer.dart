import 'dart:async';

import 'package:mydr/data/emergency/emergency_dialer.dart';

/// Records the numbers it was asked to dial instead of opening a dialer.
class FakeEmergencyDialer implements EmergencyDialer {
  final List<String> dialed = [];

  /// What [openDialer] reports: whether the dialer opened.
  bool opens = true;

  /// When true, [openDialer] throws, like a broken platform would.
  bool throws = false;

  /// When set, [openDialer] waits for it to complete.
  Completer<void>? gate;

  @override
  Future<bool> openDialer(String number) async {
    dialed.add(number);
    await gate?.future;
    if (throws) throw StateError('dialer failed');
    return opens;
  }
}
