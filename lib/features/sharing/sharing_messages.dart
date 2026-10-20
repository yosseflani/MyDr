import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/features/sharing/sync_controller.dart';

/// The message shown for a sharing failure. Carries no data.
String sharingFailureMessage(SharingFailure failure) => switch (failure) {
  SharingFailure.network => AppStrings.sharingFailedNetwork,
  SharingFailure.permissionDenied => AppStrings.sharingFailedPermission,
  SharingFailure.invalidCode => AppStrings.sharingFailedInvalidCode,
  SharingFailure.expired => AppStrings.sharingFailedExpired,
  SharingFailure.alreadyUsed => AppStrings.sharingFailedAlreadyUsed,
  SharingFailure.verificationFailed => AppStrings.sharingFailedVerification,
  SharingFailure.notAdmin => AppStrings.sharingFailedNotAdmin,
  SharingFailure.lastAdmin => AppStrings.sharingFailedLastAdmin,
  SharingFailure.keyUnavailable => AppStrings.sharingFailedKey,
  SharingFailure.alreadyInHousehold =>
    AppStrings.sharingFailedAlreadyInHousehold,
  SharingFailure.notInHousehold => AppStrings.sharingFailedNotInHousehold,
  SharingFailure.removed => AppStrings.sharingFailedRemoved,
  SharingFailure.damaged => AppStrings.sharingFailedDamaged,
  SharingFailure.localWriteFailed => AppStrings.sharingFailedLocalWrite,
  SharingFailure.notSignedIn => AppStrings.sharingFailedNotSignedIn,
  SharingFailure.deleteFailed => AppStrings.sharingFailedDelete,
  SharingFailure.unknown => AppStrings.sharingFailedUnknown,
};

String roleLabel(HouseholdRole role) => switch (role) {
  HouseholdRole.admin => AppStrings.roleAdmin,
  HouseholdRole.member => AppStrings.roleMember,
};

String syncKindLabel(SyncKind kind) => switch (kind) {
  SyncKind.share || SyncKind.member => AppStrings.kindMember,
  SyncKind.appointment => AppStrings.kindAppointment,
  SyncKind.medication => AppStrings.kindMedication,
  SyncKind.question => AppStrings.kindQuestion,
  SyncKind.symptom => AppStrings.kindSymptom,
  SyncKind.media => AppStrings.kindMedia,
  SyncKind.dose => AppStrings.kindDose,
};

String conflictReasonLabel(ConflictReason reason) => switch (reason) {
  ConflictReason.edited => AppStrings.conflictEdited,
  ConflictReason.deleted => AppStrings.conflictDeleted,
  ConflictReason.deletedHere => AppStrings.conflictDeletedHere,
};

String syncFieldLabel(String field) =>
    AppStrings.syncFieldLabels[field] ?? field;

/// A stored value shown exactly as entered, never interpreted: text as is,
/// lists joined, dates and times in the device's format.
String syncFieldValue(
  String field,
  Object? value,
  MaterialLocalizations localizations,
) {
  if (value == null) return AppStrings.emptyValue;
  if (value is bool) return value ? AppStrings.yes : AppStrings.no;
  if (value is List) {
    return value.isEmpty ? AppStrings.emptyValue : value.join(', ');
  }
  if (field == 'durationMicros' && value is int) {
    final minutes = Duration(microseconds: value).inMinutes;
    return '$minutes ${localizations.timePickerMinuteLabel}';
  }
  if (value is String) {
    try {
      final at = StorageCodecs.decodeLocalDateTime(value);
      return '${localizations.formatShortDate(at)} '
          '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(at), alwaysUse24HourFormat: true)}';
    } on FormatException {
      // Not a date and time.
    }
    try {
      return localizations.formatShortDate(StorageCodecs.decodeDate(value));
    } on FormatException {
      return value;
    }
  }
  return '$value';
}

/// Asks to confirm an action; returns whether it was confirmed.
Future<bool> confirmSharingAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
