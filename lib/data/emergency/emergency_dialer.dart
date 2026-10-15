import 'package:url_launcher/url_launcher.dart';

/// Opens the phone's dialer with a number filled in.
///
/// Never places the call itself: the user still presses "call" in the
/// dialer, so the app needs no phone permissions. Replaceable in tests, so
/// no real dialer opens while testing.
abstract interface class EmergencyDialer {
  /// Returns whether the dialer was opened. False (never an error) when the
  /// device cannot dial, so the caller can show the number to dial by hand.
  Future<bool> openDialer(String number);
}

/// Opens the dialer through a `tel:` link.
class UrlLauncherEmergencyDialer implements EmergencyDialer {
  const UrlLauncherEmergencyDialer();

  @override
  Future<bool> openDialer(String number) async {
    try {
      return await launchUrl(Uri(scheme: 'tel', path: number));
    } catch (_) {
      return false;
    }
  }
}
