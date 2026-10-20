import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/detail_section.dart';
import 'package:mydr/core/widgets/empty_state.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/data/cloud/household_cloud.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/data/sync/household_crypto.dart';
import 'package:mydr/data/sync/household_service.dart';
import 'package:mydr/features/backup/backup_messages.dart';
import 'package:mydr/features/backup/backup_screen.dart';
import 'package:mydr/features/sharing/conflicts_screen.dart';
import 'package:mydr/features/sharing/sharing_messages.dart';
import 'package:mydr/features/sharing/sync_controller.dart';

/// Household sharing: create or join a household, invite the other parent,
/// choose the shared children, sync, and manage members.
///
/// Opening it is what connects to the cloud (through the backup account);
/// nothing syncs until the user taps "Sync now".
class FamilySharingScreen extends StatefulWidget {
  const FamilySharingScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const FamilySharingScreen());

  @override
  State<FamilySharingScreen> createState() => _FamilySharingScreenState();
}

class _FamilySharingScreenState extends State<FamilySharingScreen> {
  static const double _maxContentWidth = 600;

  late final SyncController _controller;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;
    _controller = AppScope.of(context).syncController;
    _controller.start();
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _report(SharingFailure? failure, {String? success}) {
    if (!mounted) return;
    if (failure != null) {
      _show(sharingFailureMessage(failure));
    } else if (success != null) {
      _show(success);
    }
  }

  Future<void> _create() async {
    _report(
      await _controller.createHousehold(),
      success: AppStrings.householdCreated,
    );
  }

  Future<void> _join() async {
    String? error;
    while (true) {
      if (!mounted) return;
      final code = await showDialog<String>(
        context: context,
        builder: (_) => _JoinCodeDialog(error: error),
      );
      if (code == null || !mounted) return;
      final (preview, failure) = await _controller.lookupInvite(code);
      if (!mounted) return;
      if (preview == null) {
        error = sharingFailureMessage(failure ?? SharingFailure.unknown);
        continue;
      }
      final accept = await showDialog<bool>(
        context: context,
        builder: (_) => _InvitePreviewDialog(preview: preview),
      );
      if (accept == null || !mounted) return;
      _report(
        await _controller.respondToInvite(preview, accept: accept),
        success: accept ? null : AppStrings.inviteRejected,
      );
      return;
    }
  }

  Future<void> _checkJoined() async {
    final failure = await _controller.checkJoined();
    if (!mounted) return;
    if (failure != null) {
      _report(failure);
    } else {
      _show(
        _controller.status == SharingStatus.active
            ? AppStrings.joiningDone
            : AppStrings.joiningNotYet,
      );
    }
  }

  Future<void> _invite() async {
    final code = await _controller.createInvite();
    if (!mounted) return;
    if (code == null) {
      _report(_controller.lastFailure ?? SharingFailure.unknown);
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _InviteCodeDialog(code: code, fingerprint: _controller.myFingerprint),
    );
  }

  Future<void> _complete(InviteView invite) async {
    final fingerprint = invite.inviteeFingerprint;
    if (fingerprint == null) return;
    final role = await showDialog<HouseholdRole>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.completeInviteTitle),
        content: Text(AppStrings.completeInviteMessage(fingerprint)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(HouseholdRole.admin),
            child: const Text(AppStrings.completeAsAdmin),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(HouseholdRole.member),
            child: const Text(AppStrings.completeAsMember),
          ),
        ],
      ),
    );
    if (role == null || !mounted) return;
    _report(
      await _controller.completeInvite(invite.id, role),
      success: AppStrings.memberAdded,
    );
  }

  Future<void> _revoke(HouseholdMemberView member) async {
    final confirmed = await confirmSharingAction(
      context,
      title: AppStrings.removeMemberConfirmTitle,
      message: AppStrings.removeMemberConfirmMessage,
      confirmLabel: AppStrings.removeMember,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    _report(
      await _controller.revokeMember(member.uid, userConfirmed: true),
      success: AppStrings.memberRemoved,
    );
  }

  Future<void> _leave() async {
    final confirmed = await confirmSharingAction(
      context,
      title: AppStrings.leaveConfirmTitle,
      message: AppStrings.leaveConfirmMessage,
      confirmLabel: AppStrings.leaveConfirm,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    _report(await _controller.leave(userConfirmed: true));
  }

  Future<void> _toggleShare(FamilyMember member, bool share) async {
    final confirmed = await confirmSharingAction(
      context,
      title: share
          ? AppStrings.shareConfirmTitle
          : AppStrings.unshareConfirmTitle,
      message: share
          ? AppStrings.shareConfirmMessage(member.name)
          : AppStrings.unshareConfirmMessage(member.name),
      confirmLabel: share ? AppStrings.shareConfirm : AppStrings.unshareConfirm,
    );
    if (!confirmed || !mounted) return;
    _report(
      share
          ? await _controller.share(member.id, userConfirmed: true)
          : await _controller.unshare(member.id),
    );
  }

  Future<void> _sync() async {
    final failure = await _controller.syncNow();
    if (!mounted) return;
    if (failure != null) {
      _report(failure);
      return;
    }
    final report = _controller.lastReport;
    _show(
      report == null
          ? AppStrings.syncSucceeded
          : '${AppStrings.syncSucceeded}. '
                '${AppStrings.syncSummary(report.received, report.sent)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sharingTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _controller,
              AppScope.of(context).familyController,
            ]),
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
                if (_controller.isBusy &&
                    _controller.activity != SharingActivity.syncing) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                ],
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
    final busy = c.isBusy;
    switch (c.status) {
      case SharingStatus.unavailable:
        return const [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: AppStrings.sharingTitle,
            message: AppStrings.sharingUnavailable,
          ),
        ];
      case SharingStatus.connecting:
        return const [
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 12),
          Center(child: Text(AppStrings.sharingConnecting)),
        ];
      case SharingStatus.connectFailed:
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
      case SharingStatus.signedOut:
        return [
          Text(
            c.settings?.accountUid == null
                ? AppStrings.sharingSignInFirst
                : AppStrings.sharingOtherAccount,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(BackupScreen.route());
                if (mounted) await _controller.refresh();
              },
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text(AppStrings.sharingOpenAccount),
            ),
          ),
        ];
      case SharingStatus.none:
        return [
          DetailSection(
            title: AppStrings.householdNoneTitle,
            icon: Icons.family_restroom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(AppStrings.householdNoneMessage),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: busy ? null : _create,
                  icon: const Icon(Icons.add_home_outlined),
                  label: const Text(AppStrings.householdCreate),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy ? null : _join,
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: const Text(AppStrings.householdJoin),
                ),
              ],
            ),
          ),
        ];
      case SharingStatus.joining:
        final name = c.waitingFor;
        return [
          DetailSection(
            title: AppStrings.joiningTitle,
            icon: Icons.hourglass_top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  name == null
                      ? AppStrings.joiningWaiting
                      : AppStrings.joiningWaitingFor(name),
                ),
                if (c.myFingerprint case final fingerprint?) ...[
                  const SizedBox(height: 8),
                  Text(AppStrings.fingerprintLabel(fingerprint)),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy ? null : _checkJoined,
                  child: const Text(AppStrings.joiningCheck),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () async => _report(await c.cancelJoining()),
                  child: const Text(AppStrings.joiningCancel),
                ),
              ],
            ),
          ),
        ];
      case SharingStatus.removed:
        return [
          DetailSection(
            title: AppStrings.removedTitle,
            icon: Icons.person_off_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(AppStrings.removedMessage),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy ? null : c.acknowledgeRemoval,
                  child: const Text(AppStrings.removedAcknowledge),
                ),
              ],
            ),
          ),
        ];
      case SharingStatus.active:
        break;
    }
    return [
      _SyncSection(controller: c, onSync: _sync),
      const SizedBox(height: 12),
      _SharedChildrenSection(controller: c, onToggle: _toggleShare),
      const SizedBox(height: 12),
      _MembersSection(
        controller: c,
        onRevoke: _revoke,
        onRole: (member, role) async =>
            _report(await c.setRole(member.uid, role)),
      ),
      if (c.isAdmin) ...[
        const SizedBox(height: 12),
        _InvitesSection(
          controller: c,
          onInvite: _invite,
          onComplete: _complete,
          onDelete: (invite) async => _report(await c.cancelInvite(invite.id)),
        ),
      ],
      const SizedBox(height: 12),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: busy ? null : _leave,
          icon: const Icon(Icons.logout),
          label: const Text(AppStrings.leaveHousehold),
        ),
      ),
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
    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(Icons.lock_outline, AppStrings.sharingPrivacy),
          line(Icons.touch_app_outlined, AppStrings.sharingManualOnly),
          line(Icons.photo_outlined, AppStrings.sharingMediaNote),
        ],
      ),
    );
  }
}

class _SyncSection extends StatelessWidget {
  const _SyncSection({required this.controller, required this.onSync});

  final SyncController controller;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final localizations = MaterialLocalizations.of(context);
    final last = c.lastSyncAt;
    final syncing = c.activity == SharingActivity.syncing;
    final waiting = c.lastReport?.waiting ?? 0;
    return DetailSection(
      title: AppStrings.syncSectionTitle,
      icon: Icons.sync,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            last == null
                ? AppStrings.syncNever
                : AppStrings.syncLast(formatBackupTime(last, localizations)),
          ),
          if (c.pendingCount > 0) Text(AppStrings.syncPending(c.pendingCount)),
          if (waiting > 0) Text(AppStrings.syncWaiting(waiting)),
          if (c.lastFailure case final failure? when !c.isBusy) ...[
            const SizedBox(height: 8),
            InlineErrorMessage(message: sharingFailureMessage(failure)),
          ],
          if (syncing) ...[
            const SizedBox(height: 12),
            Semantics(liveRegion: true, child: const Text(AppStrings.syncing)),
            const SizedBox(height: 6),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: c.isBusy ? null : onSync,
            icon: const Icon(Icons.sync),
            label: const Text(AppStrings.syncNow),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          if (c.conflicts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.rule, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(AppStrings.conflictsWaiting(c.conflicts.length)),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).push(ConflictsScreen.route()),
                child: const Text(AppStrings.reviewConflicts),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SharedChildrenSection extends StatelessWidget {
  const _SharedChildrenSection({
    required this.controller,
    required this.onToggle,
  });

  final SyncController controller;
  final void Function(FamilyMember member, bool share) onToggle;

  @override
  Widget build(BuildContext context) {
    final children = [
      for (final m in AppScope.of(context).familyController.members)
        if (m.relation == FamilyRelation.child) m,
    ];
    return DetailSection(
      title: AppStrings.sharedChildrenTitle,
      icon: Icons.child_care,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.sharedChildrenHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (children.isEmpty) const Text(AppStrings.noChildrenToShare),
          for (final child in children)
            SwitchListTile(
              key: ValueKey('share-${child.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(child.name),
              value: controller.sharedMemberIds.contains(child.id),
              onChanged: controller.isBusy
                  ? null
                  : (share) => onToggle(child, share),
            ),
        ],
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({
    required this.controller,
    required this.onRevoke,
    required this.onRole,
  });

  final SyncController controller;
  final void Function(HouseholdMemberView member) onRevoke;
  final void Function(HouseholdMemberView member, HouseholdRole role) onRole;

  @override
  Widget build(BuildContext context) {
    final members = controller.members;
    final theme = Theme.of(context);
    return DetailSection(
      title: AppStrings.membersTitle,
      icon: Icons.groups_outlined,
      child: members == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                for (final m in members)
                  ListTile(
                    key: ValueKey('member-${m.uid}'),
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      m.verified ? Icons.verified_user : Icons.gpp_maybe,
                      color: m.verified
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                    title: Text(
                      [
                        m.label ?? AppStrings.unknownMember,
                        if (m.isMe) AppStrings.memberYou,
                      ].join(' '),
                    ),
                    subtitle: Text(
                      [
                        roleLabel(m.role),
                        AppStrings.fingerprintLabel(m.fingerprint),
                        if (!m.verified) AppStrings.memberUnverified,
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                    trailing: controller.isAdmin && !m.isMe
                        ? PopupMenuButton<String>(
                            enabled: !controller.isBusy,
                            onSelected: (action) => switch (action) {
                              'admin' => onRole(m, HouseholdRole.admin),
                              'member' => onRole(m, HouseholdRole.member),
                              _ => onRevoke(m),
                            },
                            itemBuilder: (_) => [
                              if (m.role == HouseholdRole.member)
                                const PopupMenuItem(
                                  value: 'admin',
                                  child: Text(AppStrings.makeAdmin),
                                )
                              else
                                const PopupMenuItem(
                                  value: 'member',
                                  child: Text(AppStrings.makeMember),
                                ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Text(AppStrings.removeMember),
                              ),
                            ],
                          )
                        : null,
                  ),
              ],
            ),
    );
  }
}

class _InvitesSection extends StatelessWidget {
  const _InvitesSection({
    required this.controller,
    required this.onInvite,
    required this.onComplete,
    required this.onDelete,
  });

  final SyncController controller;
  final VoidCallback onInvite;
  final void Function(InviteView invite) onComplete;
  final void Function(InviteView invite) onDelete;

  @override
  Widget build(BuildContext context) {
    final invites = [
      for (final i in controller.invites ?? const <InviteView>[])
        if (i.status != InviteStatus.completed) i,
    ];
    final now = controller.now;
    final busy = controller.isBusy;
    return DetailSection(
      title: AppStrings.invitesTitle,
      icon: Icons.mail_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (invites.isEmpty) const Text(AppStrings.noInvites),
          for (final invite in invites)
            ListTile(
              key: ValueKey('invite-${invite.id}'),
              contentPadding: EdgeInsets.zero,
              title: Text(switch (invite.status) {
                InviteStatus.open when invite.expiresAt.isBefore(now) =>
                  AppStrings.inviteExpired,
                InviteStatus.open => AppStrings.inviteStatusOpen,
                InviteStatus.accepted => AppStrings.inviteStatusAccepted,
                InviteStatus.rejected => AppStrings.inviteStatusRejected,
                InviteStatus.completed => AppStrings.inviteStatusCompleted,
              }),
              subtitle: invite.status == InviteStatus.accepted
                  ? Text(
                      invite.verified
                          ? [
                              if (invite.inviteeLabel case final label?)
                                AppStrings.inviteFrom(label),
                              AppStrings.fingerprintLabel(
                                invite.inviteeFingerprint ?? '',
                              ),
                            ].join('\n')
                          : AppStrings.inviteNotVerified,
                    )
                  : null,
              trailing: Wrap(
                spacing: 4,
                children: [
                  if (invite.status == InviteStatus.accepted && invite.verified)
                    TextButton(
                      onPressed: busy ? null : () => onComplete(invite),
                      child: const Text(AppStrings.inviteComplete),
                    ),
                  IconButton(
                    tooltip: AppStrings.inviteDelete,
                    onPressed: busy ? null : () => onDelete(invite),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: busy ? null : onInvite,
            icon: const Icon(Icons.person_add_alt),
            label: const Text(AppStrings.inviteParent),
          ),
        ],
      ),
    );
  }
}

class _InviteCodeDialog extends StatelessWidget {
  const _InviteCodeDialog({required this.code, required this.fingerprint});

  final InviteCode code;
  final String? fingerprint;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.inviteCodeTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(AppStrings.inviteCodeMessage),
            const SizedBox(height: 16),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                code.format(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (fingerprint case final value?) ...[
              const SizedBox(height: 16),
              Text(AppStrings.inviteYourFingerprint(value)),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.continueLabel),
        ),
      ],
    );
  }
}

class _JoinCodeDialog extends StatefulWidget {
  const _JoinCodeDialog({this.error});

  final String? error;

  @override
  State<_JoinCodeDialog> createState() => _JoinCodeDialogState();
}

class _JoinCodeDialogState extends State<_JoinCodeDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.joinTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.error case final error?) ...[
              InlineErrorMessage(message: error),
              const SizedBox(height: 12),
            ],
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _code,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: AppStrings.joinCodeLabel,
                  hintText: AppStrings.joinCodeHint,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_code.text),
          child: const Text(AppStrings.joinCheck),
        ),
      ],
    );
  }
}

class _InvitePreviewDialog extends StatelessWidget {
  const _InvitePreviewDialog({required this.preview});

  final InvitePreview preview;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.invitePreviewTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (preview.inviterLabel case final label?)
              Text(AppStrings.invitePreviewFrom(label)),
            const SizedBox(height: 8),
            Text(
              AppStrings.invitePreviewFingerprint(preview.inviterFingerprint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.invitePreviewReject),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppStrings.invitePreviewAccept),
        ),
      ],
    );
  }
}
