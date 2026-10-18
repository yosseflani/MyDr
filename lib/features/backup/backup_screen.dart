import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/detail_section.dart';
import 'package:mydr/core/widgets/empty_state.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/data/backup/backup_service.dart';
import 'package:mydr/data/backup/recovery_key.dart';
import 'package:mydr/data/cloud/account_service.dart';
import 'package:mydr/features/backup/backup_controller.dart';
import 'package:mydr/features/backup/backup_messages.dart';
import 'package:mydr/features/backup/widgets/recovery_key_dialogs.dart';
import 'package:mydr/features/backup/widgets/restore_confirm_dialog.dart';

/// Account sign-in, encrypted cloud backup and restore.
///
/// Opening it is what connects to the cloud; the rest of the app never
/// does. Every step that replaces data on the device asks first.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const BackupScreen());

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  static const double _maxContentWidth = 600;

  late final BackupController _controller;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;
    _controller = AppScope.of(context).backupController;
    _controller.start();
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _backUp() async {
    final failure = await _controller.backUpNow();
    if (!mounted) return;
    _show(
      failure == null
          ? AppStrings.backupSucceeded
          : backupFailureMessage(failure),
    );
  }

  Future<void> _createKey() async {
    final key = _controller.createRecoveryKey();
    final confirmed = await showNewRecoveryKeyDialog(
      context,
      key,
      hasOlderBackups: _controller.backups?.isNotEmpty ?? false,
    );
    if (!confirmed || !mounted) return;
    final saved = await _controller.saveNewRecoveryKey(key);
    if (mounted) {
      _show(
        saved ? AppStrings.recoveryKeyStored : AppStrings.backupFailedUnknown,
      );
    }
  }

  Future<void> _enterKey() async {
    String? error;
    while (mounted) {
      final text = await showEnterRecoveryKeyDialog(context, error: error);
      if (text == null || !mounted) return;
      final result = await _controller.enterRecoveryKey(text);
      if (!mounted) return;
      switch (result) {
        case RecoveryKeyEntryResult.saved:
          _show(AppStrings.recoveryKeyStored);
          return;
        case RecoveryKeyEntryResult.invalid:
          error = AppStrings.recoveryKeyInvalid;
        case RecoveryKeyEntryResult.doesNotMatch:
          error = AppStrings.recoveryKeyDoesNotMatch;
        case RecoveryKeyEntryResult.failed:
          _show(
            backupFailureMessage(
              _controller.lastFailure ?? BackupFailure.unknown,
            ),
          );
          return;
      }
    }
  }

  Future<void> _revealKey() async {
    final key = await _controller.revealRecoveryKey();
    if (!mounted) return;
    if (key == null) {
      _show(AppStrings.recoveryKeyUnavailable);
      return;
    }
    await showRecoveryKeyDialog(context, key);
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.signOutConfirmTitle),
        content: const Text(AppStrings.signOutConfirmMessage),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.signOut),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await _controller.signOut();
  }

  /// Download and check first, then confirm, then replace.
  Future<void> _restore(RemoteBackup backup) async {
    RecoveryKey? typedKey;
    String? error;
    while (true) {
      if (!_controller.hasRecoveryKey || typedKey != null || error != null) {
        final text = await showEnterRecoveryKeyDialog(context, error: error);
        if (text == null || !mounted) return;
        typedKey = RecoveryKey.parse(text);
      }
      final prepared = await _controller.prepareRestore(backup, key: typedKey);
      if (!mounted) {
        if (prepared != null) await _controller.cancelRestore(prepared);
        return;
      }
      if (prepared != null) {
        final local = await _controller.localCounts();
        if (!mounted) {
          await _controller.cancelRestore(prepared);
          return;
        }
        final confirmed = await showRestoreConfirmDialog(
          context,
          restore: prepared,
          local: local,
        );
        if (!confirmed || !mounted) {
          await _controller.cancelRestore(prepared);
          return;
        }
        final failure = await _controller.applyRestore(
          prepared,
          userConfirmed: true,
          key: typedKey,
        );
        if (mounted) {
          _show(
            failure == null
                ? AppStrings.restoreSucceeded
                : backupFailureMessage(failure),
          );
        }
        return;
      }
      final failure = _controller.lastFailure ?? BackupFailure.unknown;
      if (failure != BackupFailure.wrongKey) {
        _show(backupFailureMessage(failure));
        return;
      }
      // Ask for the key (again).
      error = AppStrings.backupFailedWrongKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.backupTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                const _PrivacyNote(),
                const SizedBox(height: 16),
                ..._buildBody(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody() {
    final c = _controller;
    switch (c.status) {
      case CloudStatus.notConfigured:
        return const [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: AppStrings.backupNotConfiguredTitle,
            message: AppStrings.backupNotConfiguredMessage,
          ),
        ];
      case CloudStatus.idle:
      case CloudStatus.connecting:
        return const [
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 12),
          Center(child: Text(AppStrings.cloudConnecting)),
        ];
      case CloudStatus.failed:
        return [
          const InlineErrorMessage(message: AppStrings.cloudConnectFailed),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              onPressed: c.start,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ),
        ];
      case CloudStatus.connected:
        break;
    }

    final account = c.account;
    if (account == null) {
      return [_SignInForm(controller: c)];
    }

    final backups = c.backups;
    return [
      _AccountRow(
        email: account.email ?? '',
        enabled: !c.isBusy,
        onSignOut: _signOut,
      ),
      const SizedBox(height: 12),
      if (!c.canBackUp) ...[
        const InlineErrorMessage(message: AppStrings.backupDemoMode),
        const SizedBox(height: 12),
      ],
      if (!c.hasRecoveryKey) ...[
        _RecoveryKeySetup(
          hasBackups: backups?.isNotEmpty ?? false,
          enabled: !c.isBusy,
          onCreate: _createKey,
          onEnter: _enterKey,
        ),
        const SizedBox(height: 12),
      ],
      _StatusSection(controller: c, onBackUp: _backUp),
      const SizedBox(height: 12),
      _BackupsSection(controller: c, onRestore: _restore),
      if (c.hasRecoveryKey) ...[
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: c.isBusy ? null : _revealKey,
            icon: const Icon(Icons.key),
            label: const Text(AppStrings.showRecoveryKey),
          ),
        ),
      ],
    ];
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.bodySmall?.copyWith(color: color);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(AppStrings.backupPrivacy, style: style)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.wifi_off, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(AppStrings.backupOfflineNote, style: style)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignInForm extends StatefulWidget {
  const _SignInForm({required this.controller});

  final BackupController controller;

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  String? _info;

  static const int minPasswordLength = 8;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<AccountError?> Function() action, {
    String? success,
  }) async {
    setState(() {
      _error = null;
      _info = null;
    });
    final error = await action();
    if (!mounted) return;
    setState(() {
      _error = error == null ? null : accountErrorMessage(error);
      _info = error == null ? success : null;
    });
  }

  void _signIn() {
    if (!_formKey.currentState!.validate()) return;
    _run(() => widget.controller.signIn(_email.text, _password.text));
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    if (_password.text.length < minPasswordLength) {
      setState(() => _error = AppStrings.passwordTooShort);
      return;
    }
    _run(() => widget.controller.register(_email.text, _password.text));
  }

  void _reset() {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = AppStrings.emailRequired);
      return;
    }
    _run(
      () => widget.controller.sendPasswordReset(_email.text),
      success: AppStrings.passwordResetSent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.controller.isBusy;
    return DetailSection(
      title: AppStrings.signInTitle,
      icon: Icons.account_circle_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error case final error?) ...[
              InlineErrorMessage(message: error),
              const SizedBox(height: 12),
            ],
            if (_info case final info?) ...[
              Text(info),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: AppStrings.emailLabel,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? AppStrings.emailRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              enabled: !busy,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(
                labelText: AppStrings.passwordLabel,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.password),
              ),
              validator: (value) =>
                  (value ?? '').isEmpty ? AppStrings.passwordTooShort : null,
              onFieldSubmitted: (_) => _signIn(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : _signIn,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppStrings.signIn),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: busy ? null : _register,
                  child: const Text(AppStrings.createAccount),
                ),
                TextButton(
                  onPressed: busy ? null : _reset,
                  child: const Text(AppStrings.forgotPassword),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.email,
    required this.enabled,
    required this.onSignOut,
  });

  final String email;
  final bool enabled;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.account_circle_outlined),
        const SizedBox(width: 8),
        Expanded(child: Text(AppStrings.signedInAs(email))),
        TextButton(
          onPressed: enabled ? onSignOut : null,
          child: const Text(AppStrings.signOut),
        ),
      ],
    );
  }
}

class _RecoveryKeySetup extends StatelessWidget {
  const _RecoveryKeySetup({
    required this.hasBackups,
    required this.enabled,
    required this.onCreate,
    required this.onEnter,
  });

  final bool hasBackups;
  final bool enabled;
  final VoidCallback onCreate;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return DetailSection(
      title: AppStrings.recoveryKeyTitle,
      icon: Icons.key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hasBackups
                ? AppStrings.recoveryKeyNeededWithBackups
                : AppStrings.recoveryKeyNeeded,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasBackups) ...[
                FilledButton(
                  onPressed: enabled ? onEnter : null,
                  child: const Text(AppStrings.enterRecoveryKey),
                ),
                TextButton(
                  onPressed: enabled ? onCreate : null,
                  child: const Text(AppStrings.createRecoveryKey),
                ),
              ] else ...[
                FilledButton(
                  onPressed: enabled ? onCreate : null,
                  child: const Text(AppStrings.createRecoveryKey),
                ),
                TextButton(
                  onPressed: enabled ? onEnter : null,
                  child: const Text(AppStrings.enterRecoveryKey),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.controller, required this.onBackUp});

  final BackupController controller;
  final VoidCallback onBackUp;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final localizations = MaterialLocalizations.of(context);
    final latest = c.backups?.firstOrNull;
    final busy = c.activity == BackupActivity.backingUp;
    final progressLabel = switch (c.activity) {
      BackupActivity.backingUp => AppStrings.backingUp,
      BackupActivity.preparingRestore => AppStrings.preparingRestore,
      BackupActivity.restoring => AppStrings.restoring,
      _ => null,
    };

    return DetailSection(
      title: AppStrings.backupStatusTitle,
      icon: Icons.cloud_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            latest == null
                ? AppStrings.noBackupsYet
                : AppStrings.lastBackup(
                    formatBackupTime(latest.createdAt, localizations),
                  ),
          ),
          if (c.lastFailure case final failure?
              when c.activity == BackupActivity.none) ...[
            const SizedBox(height: 8),
            InlineErrorMessage(message: backupFailureMessage(failure)),
          ],
          if (progressLabel != null) ...[
            const SizedBox(height: 12),
            Semantics(liveRegion: true, child: Text(progressLabel)),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: c.progress),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: c.isBusy || !c.hasRecoveryKey || !c.canBackUp
                ? null
                : onBackUp,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: const Text(AppStrings.backUpNow),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.backupKeepsTwo,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BackupsSection extends StatelessWidget {
  const _BackupsSection({required this.controller, required this.onRestore});

  final BackupController controller;
  final void Function(RemoteBackup) onRestore;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final backups = c.backups;
    final localizations = MaterialLocalizations.of(context);

    final Widget content;
    if (backups == null && c.backupsFailure != null) {
      content = Row(
        children: [
          const Expanded(child: Text(AppStrings.backupsLoadFailed)),
          TextButton(
            onPressed: c.refreshBackups,
            child: const Text(AppStrings.retry),
          ),
        ],
      );
    } else if (backups == null) {
      content = const Center(child: CircularProgressIndicator());
    } else if (backups.isEmpty) {
      content = const Text(AppStrings.noBackupsYet);
    } else {
      content = Column(
        children: [
          for (final backup in backups)
            ListTile(
              key: ValueKey(backup.id),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(formatBackupTime(backup.createdAt, localizations)),
              subtitle: Text(
                AppStrings.backupSize(formatBytes(backup.totalBytes)),
              ),
              trailing: TextButton(
                onPressed: c.isBusy || !c.canBackUp
                    ? null
                    : () => onRestore(backup),
                child: const Text(AppStrings.restore),
              ),
            ),
        ],
      );
    }

    return DetailSection(
      title: AppStrings.backupsListTitle,
      icon: Icons.history,
      child: content,
    );
  }
}
