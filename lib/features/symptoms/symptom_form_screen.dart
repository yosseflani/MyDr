import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/date_time_fields.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/discard_changes_dialog.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/widgets/no_family_members_view.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/symptoms/widgets/delete_symptom_dialog.dart';
import 'package:mydr/features/symptoms/widgets/severity_field.dart';

/// Form for recording a symptom, or editing a record when [entryId] is set.
///
/// Saves through the shared [SymptomController]; the journal updates
/// automatically because it listens to it. Only the fields shown here are
/// changed when editing: the record's status and duration are kept by
/// [SymptomController.update].
class SymptomFormScreen extends StatefulWidget {
  const SymptomFormScreen({
    super.key,
    this.entryId,
    this.initialMemberId,
    this.initialName,
    this.clock = DateTime.now,
  });

  /// The record to edit, or null to add a new one.
  final String? entryId;

  /// Family member to preselect when adding.
  final String? initialMemberId;

  /// Symptom name to fill in when adding, e.g. for a follow-up record. The
  /// user can change it.
  final String? initialName;

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  static const int maxNameLength = 60;
  static const int maxNotesLength = 500;

  /// How many name suggestions to offer.
  static const int maxSuggestions = 10;

  static Route<void> addRoute({
    String? initialMemberId,
    String? initialName,
    DateTime Function() clock = DateTime.now,
  }) => MaterialPageRoute<void>(
    builder: (_) => SymptomFormScreen(
      initialMemberId: initialMemberId,
      initialName: initialName,
      clock: clock,
    ),
  );

  static Route<void> editRoute(
    String entryId, {
    DateTime Function() clock = DateTime.now,
  }) => MaterialPageRoute<void>(
    builder: (_) => SymptomFormScreen(entryId: entryId, clock: clock),
  );

  @override
  State<SymptomFormScreen> createState() => _SymptomFormScreenState();
}

class _SymptomFormScreenState extends State<SymptomFormScreen> {
  static const double _maxContentWidth = 600;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  late final SymptomController _symptoms;
  late final FamilyController _family;
  bool _isInitialized = false;

  /// The record being edited, or null when adding or when not found.
  SymptomEntry? _original;

  /// Id for a new record, created once so a retry reuses it.
  String? _newEntryId;

  String? _memberId;
  DateTime? _date;
  TimeOfDay? _time;
  int? _severity;

  // Values the form started with, to detect unsaved changes.
  String _initialName = '';
  String? _initialMemberId;
  DateTime? _initialDate;
  TimeOfDay? _initialTime;

  /// Explains why the member selection was cleared, if it was.
  String? _memberNotice;

  /// Whether the form was showing the "no family members" state, so the
  /// first member added from there can be selected automatically.
  bool _wasWithoutMembers = false;

  bool _isSaving = false;
  String? _saveError;

  /// Set once the user saved or chose to discard, so leaving is allowed.
  bool _canLeave = false;

  bool get _isEditing => widget.entryId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;

    final scope = AppScope.of(context);
    _symptoms = scope.symptomController;
    _family = scope.familyController;

    final entryId = widget.entryId;
    final original = entryId == null ? null : _symptoms.entryById(entryId);
    _original = original;

    if (original != null) {
      _nameController.text = original.name;
      _notesController.text = original.notes ?? '';
      _memberId = original.memberId;
      _date = DateUtils.dateOnly(original.startedAt);
      _time = TimeOfDay.fromDateTime(original.startedAt);
      _severity = original.severity;
    } else if (!_isEditing) {
      final requested = widget.initialMemberId;
      if (requested != null) {
        // A member that was deleted meanwhile is not replaced by another.
        if (_family.memberById(requested) != null) _memberId = requested;
      } else if (_family.members.length == 1) {
        _memberId = _family.members.single.id;
      }
      _nameController.text = SymptomController.tidyName(
        widget.initialName ?? '',
      );
      final now = widget.clock();
      _date = DateUtils.dateOnly(now);
      _time = TimeOfDay.fromDateTime(now);
    }
    _initialName = _nameController.text;
    _initialMemberId = _memberId;
    _initialDate = _date;
    _initialTime = _time;

    _nameController.addListener(_onTextChanged);
    _notesController.addListener(_onTextChanged);

    // A message left over from the previous screen would cover the save
    // button, so clear it once this screen is shown.
    final messenger = ScaffoldMessenger.maybeOf(context);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => messenger?.removeCurrentSnackBar(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _hasUnsavedChanges {
    final original = _original;
    return SymptomController.tidyName(_nameController.text) !=
            SymptomController.tidyName(_initialName) ||
        _notesController.text.trim() != (original?.notes ?? '').trim() ||
        _memberId != _initialMemberId ||
        _date != _initialDate ||
        _time != _initialTime ||
        _severity != original?.severity;
  }

  /// Keeps the member selection valid as the family changes while the form
  /// is open. A deleted member is cleared, never replaced by another one,
  /// so nothing is ever saved for the wrong person.
  void _syncSelection() {
    final memberId = _memberId;
    if (memberId != null &&
        !_family.isLoading &&
        _family.memberById(memberId) == null) {
      _memberId = null;
      _memberNotice = AppStrings.symptomMemberDeletedWhileEditing;
    }

    final members = _family.members;
    if (members.isEmpty) {
      _wasWithoutMembers = true;
    } else if (_wasWithoutMembers) {
      _wasWithoutMembers = false;
      // Back from adding the first family member: select them.
      if (!_isEditing && _memberId == null && members.length == 1) {
        _memberId = members.single.id;
        _initialMemberId ??= _memberId;
        _memberNotice = null;
      }
    }
  }

  String _memberName(String memberId) =>
      _family.memberById(memberId)?.name ?? AppStrings.unknownMember;

  /// The member's own symptom names (most recent first), then common ones,
  /// each once.
  List<String> _nameSuggestions(String? memberId) {
    final seen = <String>{};
    final names = <String>[];
    for (final name in [
      if (memberId != null)
        for (final group in _symptoms.groups(memberId: memberId)) group.name,
      ...AppStrings.commonSymptomNames,
    ]) {
      if (seen.add(SymptomController.normalizeName(name))) names.add(name);
      if (names.length == SymptomFormScreen.maxSuggestions) break;
    }
    return names;
  }

  void _useSuggestion(String name) {
    _nameController.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
  }

  DateTime get _startedAt {
    final date = _date!;
    final time = _time!;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String? _validateDate(DateTime? date) {
    if (date == null) return null;
    final original = _original;
    final unchanged =
        original != null && date == DateUtils.dateOnly(original.startedAt);
    if (date.isBefore(_symptoms.earliestAllowedDate) && !unchanged) {
      return AppStrings.symptomDateTooOld(SymptomController.maxHistoryYears);
    }
    return null;
  }

  String? _validateTime(TimeOfDay? time) {
    if (time == null || _date == null) return null;
    return _startedAt.isAfter(widget.clock())
        ? AppStrings.symptomDateInFuture
        : null;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final original = _original;
    if (original != null && original.memberId != _memberId) {
      final confirmed = await _confirmMove(original);
      if (!confirmed || !mounted) return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    final notes = _notesController.text.trim();
    final result = _isEditing
        ? await _symptoms.update(
            widget.entryId!,
            memberId: _memberId!,
            name: _nameController.text,
            startedAt: _startedAt,
            severity: _severity!,
            notes: notes.isEmpty ? null : notes,
          )
        : await _symptoms.add(
            SymptomEntry(
              id: _newEntryId ??= _symptoms.createId(),
              memberId: _memberId!,
              name: _nameController.text,
              startedAt: _startedAt,
              severity: _severity!,
              notes: notes,
            ),
          );
    if (!mounted) return;

    if (result == SymptomSaveResult.success) {
      setState(() {
        _isSaving = false;
        _canLeave = true;
      });
      // Shown on the screen we return to.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.saveSucceeded)));
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = false;
      _saveError = switch (result) {
        SymptomSaveResult.memberNotFound => AppStrings.selectedMemberMissing,
        SymptomSaveResult.nameRequired => AppStrings.symptomNameRequired,
        SymptomSaveResult.dateInFuture => AppStrings.symptomDateInFuture,
        SymptomSaveResult.dateTooOld => AppStrings.symptomDateTooOld(
          SymptomController.maxHistoryYears,
        ),
        SymptomSaveResult.entryNotFound => AppStrings.symptomMissingOnSave,
        SymptomSaveResult.failed ||
        SymptomSaveResult.success => AppStrings.saveFailed,
      };
    });
  }

  /// Asks before moving a record to another family member.
  Future<bool> _confirmMove(SymptomEntry original) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.swap_horiz),
        title: Text(AppStrings.moveSymptomTitle(_memberName(_memberId!))),
        content: Text(
          AppStrings.moveSymptomMessage(
            SymptomController.tidyName(_nameController.text),
            _memberName(original.memberId),
          ),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.moveAndSave),
          ),
        ],
      ),
    ).then((confirmed) => confirmed ?? false);
  }

  /// Deletes only after the user confirms in [DeleteSymptomDialog]; on
  /// success leaves the form (any unsaved edits go with the record).
  Future<void> _confirmAndDelete() async {
    final entryId = widget.entryId;
    if (_isSaving || entryId == null) return;
    final entry = _symptoms.entryById(entryId) ?? _original;
    if (entry == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final deleted = await DeleteSymptomDialog.show(
      context,
      entry,
      memberName: _memberName(entry.memberId),
    );
    if (!deleted || !mounted) return;

    setState(() => _canLeave = true);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.symptomDeleted)));
    navigator.pop();
  }

  Future<void> _confirmLeave() async {
    if (_isSaving) return;
    final leave = await showDiscardChangesDialog(context);
    if (leave && mounted) {
      setState(() => _canLeave = true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_symptoms, _family]),
      builder: (context, _) {
        _syncSelection();
        final entryId = widget.entryId;
        final isMissing = _isEditing && _original == null;
        final wasDeleted =
            !isMissing &&
            entryId != null &&
            !_symptoms.isLoading &&
            _symptoms.entryById(entryId) == null;
        final hasNoMembers = _family.members.isEmpty;
        final canPop =
            _canLeave ||
            isMissing ||
            wasDeleted ||
            hasNoMembers ||
            !_hasUnsavedChanges;

        final Widget body;
        if (isMissing) {
          body = const NotFoundView(
            icon: Icons.help_outline,
            title: AppStrings.symptomNotFoundTitle,
            message: AppStrings.symptomNotFoundMessage,
            backLabel: AppStrings.backToSymptoms,
          );
        } else if (hasNoMembers && _family.isLoading) {
          body = const Center(child: CircularProgressIndicator());
        } else if (hasNoMembers && !wasDeleted) {
          body = const NoFamilyMembersView(
            title: AppStrings.noFamilyForSymptomTitle,
            message: AppStrings.noFamilyForSymptomMessage,
          );
        } else {
          body = _buildForm(wasDeleted: wasDeleted);
        }

        return PopScope<void>(
          canPop: canPop && !_isSaving,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmLeave();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                _isEditing
                    ? AppStrings.editSymptomTitle
                    : AppStrings.actionLogSymptom,
              ),
            ),
            body: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: body,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildForm({required bool wasDeleted}) {
    final enabled = !_isSaving && !wasDeleted;
    final members = _family.members;
    final memberId = _memberId;
    final today = DateUtils.dateOnly(widget.clock());
    final theme = Theme.of(context);
    final typedName = SymptomController.normalizeName(_nameController.text);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const DemoDataBanner(),
                if (wasDeleted) ...[
                  const SizedBox(height: 12),
                  const InlineErrorMessage(
                    message: AppStrings.symptomDeletedWhileEditing,
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  // Rebuilt when the family changes, so it never holds a
                  // member that no longer exists.
                  key: ValueKey(members.map((m) => m.id).join(',')),
                  initialValue: memberId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.familyMemberLabel,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: [
                    for (final member in members)
                      DropdownMenuItem(
                        value: member.id,
                        child: Text(member.name),
                      ),
                  ],
                  onChanged: enabled
                      ? (id) => setState(() {
                          _memberId = id;
                          _memberNotice = null;
                        })
                      : null,
                  validator: (id) =>
                      id == null ? AppStrings.memberRequired : null,
                ),
                if (_memberNotice case final notice? when !wasDeleted) ...[
                  const SizedBox(height: 8),
                  _Notice(text: notice),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  enabled: enabled,
                  maxLength: SymptomFormScreen.maxNameLength,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: AppStrings.symptomNameLabel,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? AppStrings.symptomNameRequired
                      : null,
                ),
                Text(
                  AppStrings.symptomNameSuggestions,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final name in _nameSuggestions(memberId))
                      ChoiceChip(
                        label: Text(name),
                        selected:
                            SymptomController.normalizeName(name) == typedName,
                        onSelected: enabled
                            ? (_) => _useSuggestion(name)
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                DatePickerField(
                  initialValue: _date,
                  enabled: enabled,
                  today: today,
                  firstDate: _symptoms.earliestAllowedDate,
                  lastDate: today,
                  helpText: AppStrings.symptomDatePickerHelp,
                  validator: _validateDate,
                  onChanged: (date) => setState(() => _date = date),
                ),
                const SizedBox(height: 16),
                TimePickerField(
                  initialValue: _time,
                  enabled: enabled,
                  helpText: AppStrings.symptomTimePickerHelp,
                  validator: _validateTime,
                  onChanged: (time) => setState(() => _time = time),
                ),
                const SizedBox(height: 24),
                SeverityField(
                  initialValue: _severity,
                  enabled: enabled,
                  onChanged: (level) => setState(() => _severity = level),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _notesController,
                  enabled: enabled,
                  maxLength: SymptomFormScreen.maxNotesLength,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: AppStrings.symptomNotesLabel,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_isEditing && !wasDeleted) ...[
                  // Destructive action, kept apart from the regular fields.
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: enabled ? _confirmAndDelete : null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(AppStrings.deleteSymptom),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Kept outside the scroll view so it stays above the keyboard.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_saveError case final error?) ...[
                    InlineErrorMessage(message: error),
                    const SizedBox(height: 8),
                  ],
                  FilledButton(
                    onPressed: _isSaving || wasDeleted ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.save),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
