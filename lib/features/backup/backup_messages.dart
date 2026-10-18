import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/backup/backup_service.dart';
import 'package:mydr/data/backup/backup_snapshot.dart';
import 'package:mydr/data/cloud/account_service.dart';

String accountErrorMessage(AccountError error) => switch (error) {
  AccountError.invalidEmail => AppStrings.accountInvalidEmail,
  AccountError.wrongCredentials => AppStrings.accountWrongCredentials,
  AccountError.emailInUse => AppStrings.accountEmailInUse,
  AccountError.weakPassword => AppStrings.accountWeakPassword,
  AccountError.network => AppStrings.accountNetwork,
  AccountError.tooManyAttempts => AppStrings.accountTooManyAttempts,
  AccountError.unknown => AppStrings.accountUnknownError,
};

String backupFailureMessage(BackupFailure failure) => switch (failure) {
  BackupFailure.network => AppStrings.backupFailedNetwork,
  BackupFailure.unauthorized => AppStrings.backupFailedUnauthorized,
  BackupFailure.quotaExceeded => AppStrings.backupFailedQuota,
  BackupFailure.wrongKey => AppStrings.backupFailedWrongKey,
  BackupFailure.damaged => AppStrings.backupFailedDamaged,
  BackupFailure.unsupported => AppStrings.backupFailedUnsupported,
  BackupFailure.notFound => AppStrings.backupFailedNotFound,
  BackupFailure.localReadFailed => AppStrings.backupFailedLocalRead,
  BackupFailure.localWriteFailed => AppStrings.backupFailedLocalWrite,
  BackupFailure.unknown => AppStrings.backupFailedUnknown,
};

/// "15 באוק׳ 2026 · 9:30".
String formatBackupTime(DateTime at, MaterialLocalizations localizations) {
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(at),
    alwaysUse24HourFormat: true,
  );
  return '${localizations.formatShortDate(at)} · $time';
}

/// "4.2 MB".
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// One line per kind of record.
List<String> describeCounts(BackupCounts counts) => [
  AppStrings.countFamilyMembers(counts.familyMembers),
  AppStrings.countAppointments(counts.appointments),
  AppStrings.countQuestions(counts.doctorQuestions),
  AppStrings.countSymptoms(counts.symptoms),
  AppStrings.countVisitMedia(counts.visitMedia),
  AppStrings.countMedications(counts.medications),
  AppStrings.countDoseRecords(counts.doseRecords),
];
