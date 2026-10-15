import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/emergency/emergency_numbers.dart';

/// The full name of [service], as read out and shown in lists.
String emergencyServiceName(EmergencyService service) => switch (service) {
  EmergencyService.medical => AppStrings.serviceMedical,
  EmergencyService.police => AppStrings.servicePolice,
  EmergencyService.fire => AppStrings.serviceFire,
};

/// Opens the dialer with [number] when the user taps what [builder] builds.
///
/// Dialing only ever starts from that tap, with no confirmation in between:
/// the dialer itself is where the call is placed. If the dialer cannot be
/// opened, a dialog shows the number to dial by hand, never suggesting that
/// a call was made. Repeated taps while opening are ignored.
class EmergencyDialAction extends StatefulWidget {
  const EmergencyDialAction({
    super.key,
    required this.number,
    required this.builder,
  });

  final EmergencyNumber number;

  /// Builds the tappable widget; [onPressed] opens the dialer.
  final Widget Function(BuildContext context, VoidCallback onPressed) builder;

  @override
  State<EmergencyDialAction> createState() => _EmergencyDialActionState();
}

class _EmergencyDialActionState extends State<EmergencyDialAction> {
  bool _isOpening = false;

  Future<void> _dial() async {
    if (_isOpening) return;
    _isOpening = true;
    final number = widget.number.number;
    final dialer = AppScope.of(context).dependencies.emergencyDialer;

    bool opened;
    try {
      opened = await dialer.openDialer(number);
    } catch (_) {
      opened = false;
    }
    _isOpening = false;
    if (opened || !mounted) return;
    await showDialerUnavailableDialog(context, number);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _dial);
}

/// Explains that the dialer could not be opened and shows [number] large,
/// selectable, so the user can dial it by hand.
Future<void> showDialerUnavailableDialog(BuildContext context, String number) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        icon: Icon(Icons.phone_disabled, color: theme.colorScheme.error),
        title: const Text(AppStrings.dialerUnavailableTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.dialerUnavailableMessage(number),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SelectableText(
              number,
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.close),
          ),
        ],
      );
    },
  );
}
