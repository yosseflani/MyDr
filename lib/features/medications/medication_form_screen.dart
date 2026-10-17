import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/date_time_fields.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/discard_changes_dialog.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/widgets/no_family_members_view.dart';
import 'package:mydr/features/medications/medication_controller.dart';
import 'package:mydr/features/medications/widgets/medication_notice.dart';
import 'package:mydr/features/medications/widgets/reminder_times_field.dart';

/// Form for adding a medication, or editing one when [medicationId] is set.
///
/// The family member is chosen when adding and fixed afterwards. Saves
/// through the shared [MedicationController], which also reschedules the
/// reminders.
class MedicationFormScreen extends StatefulWidget {
  const MedicationFormScreen({
    super.key,
    this.medicationId,
    this.initialMemberId,
  });

  /// The medication to edit, or null to add one.
  final String? medicationId;

  /// Family member to preselect when adding.
  final String? initialMemberId;

  static const int maxNameLength = 80;
  static const int maxDoseLength = 80;
  static const int maxInstructionsLength = 300;

  /// How far back a treatment may start, and how far ahead it may end.
  static const int maxYearsBack = 10;
  static const int maxYearsAhead = 5;

  static Route<void> addRoute({String? initialMemberId}) =>
      MaterialPageRoute<void>(
        builder: (_) => MedicationFormScreen(initialMemberId: initialMemberId),
      );

  static Route<void> editRoute(String medicationId) => MaterialPageRoute<void>(
    builder: (_) => MedicationFormScreen(medicationId: medicationId),
  );

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  static const double _maxContentWidth = 600;

  final _formKey = GlobalKey<FormState>();
  final _endDateKey = GlobalKey<FormFieldState<DateTime>>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _instructionsController = TextEditingController();

  late final MedicationController _medications;
  late final FamilyController _family;
  bool _isInitialized = false;

  /// The medication being edited, or null when adding or when not found.
  Medication? _original;

  /// Id for a new medication, created once so a retry reuses it.
  String? _newId;

  String? _memberId;
  List<DoseTime> _times = const [];
  DateTime? _startDate;
  DateTime? _endDate;

  // Values the form started with, to detect unsaved changes.
  String? _initialMemberId;
  List<DoseTime> _initialTimes = const [];
  DateTime? _initialStartDate;
  DateTime? _initialEndDate;

  /// Explains why the member selection was cleared, if it was.
  String? _memberNotice;

  bool _isSaving = false;
  String? _saveError;

  /// Set once the user saved or chose to discard, so leaving is allowed.
  bool _canLeave = false;

  bool get _isEditing => widget.medicationId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;

    final scope = AppScope.of(context);
    _medications = scope.medicationController;
    _family = scope.familyController;

    final id = widget.medicationId;
    final original = id == null ? null : _medications.medicationById(id);
    _original = original;

    if (original != null) {
      _nameController.text = original.name;
      _doseController.text = original.dose;
      _instructionsController.text = original.instructions ?? '';
      _memberId = original.memberId;
      _times = original.reminderTimes;
      _startDate = original.startDate;
      _endDate = original.endDate;
    } else if (!_isEditing) {
      final requested = widget.initialMemberId;
      if (requested != null) {
        // A member that was deleted meanwhile is not replaced by another.
        if (_family.memberById(requested) != null) _memberId = requested;
      } else if (_family.members.length == 1) {
        _memberId = _family.members.single.id;
      }
      _startDate = DateUtils.dateOnly(_medications.now);
    }
    _initialMemberId = _memberId;
    _initialTimes = _times;
    _initialStartDate = _startDate;
    _initialEndDate = _endDate;

    _nameController.addListener(_onTextChanged);
    _doseController.addListener(_onTextChanged);
    _instructionsController.addListener(_onTextChanged);

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
    _doseController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _hasUnsavedChanges {
    final original = _original;
    return _nameController.text.trim() != (original?.name ?? '') ||
        _doseController.text.trim() != (original?.dose ?? '') ||
        _instructionsController.text.trim() != (original?.instructions ?? '') ||
        _memberId != _initialMemberId ||
        !_sameTimes(_times, _initialTimes) ||
        _startDate != _initialStartDate ||
        _endDate != _initialEndDate;
  }

  static bool _sameTimes(List<DoseTime> a, List<DoseTime> b) =>
      a.length == b.length &&
      Iterable.generate(a.length).every((i) => a[i] == b[i]);

  /// Keeps the member selection valid as the family changes while the form
  /// is open. A deleted member is cleared, never replaced by another one,
  /// so nothing is ever saved for the wrong person.
  void _syncSelection() {
    final memberId = _memberId;
    if (memberId != null &&
        !_isEditing &&
        !_family.isLoading &&
        _family.memberById(memberId) == null) {
      _memberId = null;
      _memberNotice = AppStrings.medicationMemberDeletedWhileEditing;
    }
  }

  String? _validateEndDate(DateTime? end) {
    final start = _startDate;
    if (end == null || start == null) return null;
    return end.isBefore(start) ? AppStrings.endBeforeStart : null;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    final instructions = _instructionsController.text.trim();
    final result = _isEditing
        ? await _medications.update(
            widget.medicationId!,
            name: _nameController.text,
            dose: _doseController.text,
            instructions: instructions.isEmpty ? null : instructions,
            reminderTimes: _times,
            startDate: _startDate!,
            endDate: _endDate,
          )
        : await _medications.add(
            Medication(
              id: _newId ??= _medications.createId(),
              memberId: _memberId!,
              name: _nameController.text,
              dose: _doseController.text,
              instructions: instructions,
              reminderTimes: _times,
              startDate: _startDate!,
              endDate: _endDate,
            ),
          );
    if (!mounted) return;

    if (result == MedicationSaveResult.success) {
      setState(() {
        _isSaving = false;
        _canLeave = true;
      });
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      // Shown on the screen we return to.
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text(AppStrings.saveSucceeded)));
      // In context, right after the first reason to: never at start-up.
      if (!_isEditing) await _medications.askForPermissionOnce();
      return;
    }

    setState(() {
      _isSaving = false;
      _saveError = switch (result) {
        MedicationSaveResult.nameRequired => AppStrings.medicationNameRequired,
        MedicationSaveResult.doseRequired => AppStrings.doseRequired,
        MedicationSaveResult.reminderTimeRequired =>
          AppStrings.reminderTimeRequired,
        MedicationSaveResult.tooManyReminderTimes =>
          AppStrings.tooManyReminderTimes(Medication.maxReminderTimes),
        MedicationSaveResult.endBeforeStart => AppStrings.endBeforeStart,
        MedicationSaveResult.memberNotFound => AppStrings.selectedMemberMissing,
        MedicationSaveResult.medicationNotFound =>
          AppStrings.medicationMissingOnSave,
        MedicationSaveResult.failed ||
        MedicationSaveResult.success => AppStrings.saveFailed,
      };
    });
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
      listenable: Listenable.merge([_medications, _family]),
      builder: (context, _) {
        _syncSelection();
        final id = widget.medicationId;
        final isMissing = _isEditing && _original == null;
        final wasDeleted =
            !isMissing &&
            id != null &&
            !_medications.isLoading &&
            _medications.medicationById(id) == null;
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
            title: AppStrings.medicationNotFoundTitle,
            message: AppStrings.medicationNotFoundMessage,
            backLabel: AppStrings.backToMedications,
          );
        } else if (hasNoMembers && _family.isLoading) {
          body = const Center(child: CircularProgressIndicator());
        } else if (hasNoMembers && !wasDeleted) {
          body = const NoFamilyMembersView(
            title: AppStrings.noFamilyForMedicationsTitle,
            message: AppStrings.noFamilyForMedicationsMessage,
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
                    ? AppStrings.editMedicationTitle
                    : AppStrings.actionAddMedication,
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
    final today = DateUtils.dateOnly(_medications.now);
    final firstDate = DateTime(
      today.year - MedicationFormScreen.maxYearsBack,
      today.month,
      today.day,
    );
    final lastDate = DateTime(
      today.year + MedicationFormScreen.maxYearsAhead,
      today.month,
      today.day,
    );

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
                    message: AppStrings.medicationDeletedWhileEditing,
                  ),
                ],
                const SizedBox(height: 8),
                const MedicationNotice(showReminderNote: false),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 28),
                  child: Text(
                    AppStrings.medicationFormNotice,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_isEditing)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: AppStrings.familyMemberLabel,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                      helperText: AppStrings.medicationMemberFixed,
                      helperMaxLines: 2,
                    ),
                    child: Text(
                      _family.memberById(_memberId ?? '')?.name ??
                          AppStrings.unknownMember,
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    // Rebuilt when the family changes, so it never holds a
                    // member that no longer exists.
                    key: ValueKey(members.map((m) => m.id).join(',')),
                    initialValue: _memberId,
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
                  InlineErrorMessage(message: notice),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  enabled: enabled,
                  maxLength: MedicationFormScreen.maxNameLength,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: AppStrings.medicationNameLabel,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? AppStrings.medicationNameRequired
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _doseController,
                  enabled: enabled,
                  maxLength: MedicationFormScreen.maxDoseLength,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: AppStrings.doseLabel,
                    hintText: AppStrings.doseHint,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? AppStrings.doseRequired
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _instructionsController,
                  enabled: enabled,
                  maxLength: MedicationFormScreen.maxInstructionsLength,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: AppStrings.instructionsLabel,
                    hintText: AppStrings.instructionsHint,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ReminderTimesField(
                  initialValue: _times,
                  enabled: enabled,
                  onChanged: (times) => setState(() => _times = times),
                ),
                const SizedBox(height: 16),
                DatePickerField(
                  initialValue: _startDate,
                  enabled: enabled,
                  today: today,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  label: AppStrings.startDateLabel,
                  helpText: AppStrings.startDatePickerHelp,
                  onChanged: (date) {
                    setState(() => _startDate = date);
                    // The end date's check depends on the start date.
                    if (_endDate != null) _endDateKey.currentState?.validate();
                  },
                ),
                const SizedBox(height: 16),
                OptionalDatePickerField(
                  key: _endDateKey,
                  initialValue: _endDate,
                  enabled: enabled,
                  today: _startDate ?? today,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  label: AppStrings.endDateLabel,
                  helpText: AppStrings.endDatePickerHelp,
                  clearTooltip: AppStrings.clearEndDate,
                  validator: _validateEndDate,
                  onChanged: (date) => setState(() => _endDate = date),
                ),
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
