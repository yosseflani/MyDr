import 'package:flutter/material.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/emergency/emergency_dialer.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/local_database_exception.dart';
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/repositories/first_aid_repository.dart';
import 'package:mydr/features/emergency/emergency_screen.dart';
import 'package:mydr/features/emergency/widgets/medical_call_button.dart';

/// Starts the app on the encrypted local database.
///
/// While the database opens, and if it cannot be opened, a startup screen
/// is shown instead of the app. That screen never deletes or resets
/// anything; it explains the problem, offers to try again, and keeps
/// emergency calling and the emergency center available throughout.
class MyDrBootstrap extends StatefulWidget {
  const MyDrBootstrap({
    super.key,
    this.openDatabase = _openDefault,
    this.emergencyDialer = const UrlLauncherEmergencyDialer(),
    this.firstAidRepository = const AssetFirstAidRepository(),
  });

  /// Opens the database; replaceable in tests.
  final Future<LocalDatabase> Function() openDatabase;
  final EmergencyDialer emergencyDialer;
  final FirstAidRepository firstAidRepository;

  static Future<LocalDatabase> _openDefault() =>
      const LocalDatabaseOpener().open();

  @override
  State<MyDrBootstrap> createState() => _MyDrBootstrapState();
}

class _MyDrBootstrapState extends State<MyDrBootstrap> {
  LocalDatabase? _database;
  AppDependencies? _dependencies;
  LocalDatabaseError? _error;
  bool _isOpening = false;

  /// Serves the startup screen: emergency calling and the first-aid library
  /// work without the database; the in-memory repositories stay empty and
  /// are never shown.
  late final AppDependencies _startupDependencies = AppDependencies.empty(
    emergencyDialer: widget.emergencyDialer,
    firstAidRepository: widget.firstAidRepository,
  );

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }

  Future<void> _open() async {
    if (_isOpening) return;
    setState(() {
      _isOpening = true;
      _error = null;
    });

    LocalDatabaseError? error;
    LocalDatabase? database;
    try {
      database = await widget.openDatabase();
    } on LocalDatabaseException catch (e) {
      error = e.error;
    } catch (_) {
      error = LocalDatabaseError.openFailed;
    }

    if (!mounted) {
      await database?.close();
      return;
    }
    setState(() {
      _isOpening = false;
      _error = error;
      if (database != null) {
        _database = database;
        _dependencies = AppDependencies.local(
          database,
          emergencyDialer: widget.emergencyDialer,
          firstAidRepository: widget.firstAidRepository,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = _dependencies;
    if (dependencies != null) {
      return MyDrApp(key: const ValueKey('app'), dependencies: dependencies);
    }
    return MyDrApp(
      key: const ValueKey('startup'),
      dependencies: _startupDependencies,
      home: DatabaseStartupScreen(
        error: _isOpening ? null : _error,
        onRetry: _open,
      ),
    );
  }
}

/// Shown while the saved data opens, or when it cannot be opened.
class DatabaseStartupScreen extends StatelessWidget {
  const DatabaseStartupScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  /// Null while opening.
  final LocalDatabaseError? error;
  final VoidCallback onRetry;

  static const double _maxContentWidth = 600;

  static String messageFor(LocalDatabaseError error) => switch (error) {
    LocalDatabaseError.keyMissing => AppStrings.storageKeyMissing,
    LocalDatabaseError.keyInvalid => AppStrings.storageKeyInvalid,
    LocalDatabaseError.wrongKeyOrDamaged => AppStrings.storageUnreadable,
    LocalDatabaseError.unsupportedSchema => AppStrings.storageNewerVersion,
    LocalDatabaseError.keyStoreUnavailable =>
      AppStrings.storageKeyStoreUnavailable,
    LocalDatabaseError.encryptionUnavailable =>
      AppStrings.storageEncryptionUnavailable,
    LocalDatabaseError.openFailed => AppStrings.storageOpenFailed,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final error = this.error;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              if (error == null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    AppStrings.storageOpening,
                    style: theme.textTheme.titleMedium,
                  ),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        header: true,
                        liveRegion: true,
                        child: Text(
                          AppStrings.storageUnavailableTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(messageFor(error), style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text(
                  AppStrings.storageNothingDeleted,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.tonalIcon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text(AppStrings.retry),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Text(
                AppStrings.storageEmergencyStillAvailable,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              const MedicalCallButton(),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).push(EmergencyScreen.route()),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.emergency_outlined),
                label: const Text(AppStrings.openEmergencyCenter),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
