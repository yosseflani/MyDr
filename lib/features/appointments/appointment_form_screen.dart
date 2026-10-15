import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/discard_changes_dialog.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/appointments/widgets/date_time_fields.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/widgets/no_family_members_view.dart';

/// Form for adding an appointment, or editing one when [appointmentId] is
/// set.
///
/// Saves through the shared [AppointmentController]; the list, details and
/// home screen update automatically because they listen to it.
class AppointmentFormScreen extends StatefulWidget {
  const AppointmentFormScreen({
    super.key,
    this.appointmentId,
    this.initialMemberId,
    this.clock = DateTime.now,
  });

  /// The appointment to edit, or null to add a new one.
  final String? appointmentId;

  /// Family member to preselect when adding.
  final String? initialMemberId;

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  static const int maxDoctorNameLength = 60;
  static const int maxSpecialtyLength = 50;
  static const int maxLocationLength = 100;
  static const int maxNotesLength = 500;

  /// Dates can be picked this many years back (to record past visits) and
  /// forward.
  static const int dateRangeYears = 5;

  static Route<void> addRoute({
    String? initialMemberId,
    DateTime Function() clock = DateTime.now,
  }) => MaterialPageRoute<void>(
    builder: (_) =>
        AppointmentFormScreen(initialMemberId: initialMemberId, clock: clock),
  );

  static Route<void> editRoute(
    String appointmentId, {
    DateTime Function() clock = DateTime.now,
  }) => MaterialPageRoute<void>(
    builder: (_) =>
        AppointmentFormScreen(appointmentId: appointmentId, clock: clock),
  );

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  static const double _maxContentWidth = 600;

  final _formKey = GlobalKey<FormState>();
  final _doctorController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  late final AppointmentController _appointments;
  late final FamilyController _family;
  bool _isInitialized = false;

  /// The appointment being edited, or null when adding or when not found.
  Appointment? _original;

  /// Id for a new appointment, created once so a retry reuses it.
  String? _newAppointmentId;

  String? _memberId;
  DateTime? _date;
  TimeOfDay? _time;

  // Values the form started with, to detect unsaved changes.
  String? _initialMemberId;
  DateTime? _initialDate;
  TimeOfDay? _initialTime;

  bool _isSaving = false;
  String? _saveError;

  /// Set once the user saved or chose to discard, so leaving is allowed.
  bool _canLeave = false;

  bool get _isEditing => widget.appointmentId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;

    final scope = AppScope.of(context);
    _appointments = scope.appointmentController;
    _family = scope.familyController;

    final appointmentId = widget.appointmentId;
    final original = appointmentId == null
        ? null
        : _appointments.appointmentById(appointmentId);
    _original = original;

    if (original != null) {
      _doctorController.text = original.doctorName;
      _specialtyController.text = original.specialty ?? '';
      _locationController.text = original.location ?? '';
      _notesController.text = original.notes ?? '';
      _memberId = original.memberId;
      _date = DateUtils.dateOnly(original.dateTime);
      _time = TimeOfDay.fromDateTime(original.dateTime);
    } else if (!_isEditing) {
      final members = _family.members;
      final requested = widget.initialMemberId;
      if (requested != null && _family.memberById(requested) != null) {
        _memberId = requested;
      } else if (members.length == 1) {
        _memberId = members.single.id;
      }
    }
    _initialMemberId = _memberId;
    _initialDate = _date;
    _initialTime = _time;

    for (final controller in _textControllers) {
      controller.addListener(_onTextChanged);
    }

    // A message left over from the previous screen would cover the save
    // button, so clear it once this screen is shown.
    final messenger = ScaffoldMessenger.maybeOf(context);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => messenger?.removeCurrentSnackBar(),
    );
  }

  List<TextEditingController> get _textControllers => [
    _doctorController,
    _specialtyController,
    _locationController,
    _notesController,
  ];

  @override
  void dispose() {
    for (final controller in _textControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _hasUnsavedChanges {
    final original = _original;
    bool changed(TextEditingController controller, String? initial) =>
        controller.text.trim() != (initial ?? '').trim();

    return changed(_doctorController, original?.doctorName) ||
        changed(_specialtyController, original?.specialty) ||
        changed(_locationController, original?.location) ||
        changed(_notesController, original?.notes) ||
        _memberId != _initialMemberId ||
        _date != _initialDate ||
        _time != _initialTime;
  }

  /// Whether the form was showing the "no family members" state, so the
  /// first member added from there can be selected automatically.
  bool _wasWithoutMembers = false;

  /// Keeps the member selection valid as the family list changes.
  ///
  /// A selected member that was deleted is cleared, never replaced by
  /// another member, so an appointment cannot silently move to the wrong
  /// person.
  void _syncMemberSelection() {
    final memberId = _memberId;
    if (memberId != null && _family.memberById(memberId) == null) {
      _memberId = null;
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
      }
    }
  }

  String _memberName(String memberId) =>
      _family.memberById(memberId)?.name ?? AppStrings.unknownMember;

  static String? _optional(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Appointment _buildAppointment() {
    final date = _date!;
    final time = _time!;
    return Appointment(
      id:
          widget.appointmentId ??
          (_newAppointmentId ??= _appointments.createId()),
      memberId: _memberId!,
      doctorName: _doctorController.text.trim(),
      dateTime: DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
      specialty: _optional(_specialtyController),
      location: _optional(_locationController),
      notes: _optional(_notesController),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final original = _original;
    if (original != null && original.memberId != _memberId) {
      final proceed = await _confirmMemberChange(original);
      if (!proceed || !mounted) return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    final appointment = _buildAppointment();
    final result = _isEditing
        ? await _appointments.update(appointment)
        : await _appointments.add(appointment);
    if (!mounted) return;

    if (result == AppointmentSaveResult.success) {
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
        AppointmentSaveResult.memberNotFound =>
          AppStrings.selectedMemberMissing,
        AppointmentSaveResult.appointmentNotFound =>
          AppStrings.appointmentMissingOnSave,
        AppointmentSaveResult.failedAfterDetachingQuestions =>
          AppStrings.saveFailedAfterDetaching(_memberName(original!.memberId)),
        AppointmentSaveResult.failed ||
        AppointmentSaveResult.success => AppStrings.saveFailed,
      };
    });
  }

  /// Before moving an appointment to another family member, checks for
  /// linked questions and, if there are any, asks the user to confirm that
  /// they will be unlinked (and stay with the original member).
  ///
  /// Returns whether saving should go ahead.
  Future<bool> _confirmMemberChange(Appointment original) async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    final count = await _appointments.linkedQuestionCount(original.id);
    if (!mounted) return false;
    setState(() => _isSaving = false);

    if (count == null) {
      setState(() => _saveError = AppStrings.linkedQuestionsCheckFailed);
      return false;
    }
    if (count == 0) return true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.swap_horiz),
        title: Text(AppStrings.moveAppointmentTitle(_memberName(_memberId!))),
        content: Text(
          AppStrings.moveAppointmentMessage(
            count,
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
    );
    return confirmed ?? false;
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
      listenable: _family,
      builder: (context, _) {
        _syncMemberSelection();
        final isMissing = _isEditing && _original == null;
        final hasNoMembers = _family.members.isEmpty;
        final canPop =
            _canLeave || isMissing || hasNoMembers || !_hasUnsavedChanges;

        final Widget body;
        if (isMissing) {
          body = const NotFoundView(
            icon: Icons.event_busy,
            title: AppStrings.appointmentNotFoundTitle,
            message: AppStrings.appointmentNotFoundMessage,
            backLabel: AppStrings.backToAppointments,
          );
        } else if (hasNoMembers && _family.isLoading) {
          body = const Center(child: CircularProgressIndicator());
        } else if (hasNoMembers) {
          body = const NoFamilyMembersView(
            title: AppStrings.noFamilyForAppointmentTitle,
            message: AppStrings.noFamilyForAppointmentMessage,
          );
        } else {
          body = _buildForm();
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
                    ? AppStrings.editAppointmentTitle
                    : AppStrings.newAppointment,
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

  Widget _buildForm() {
    final enabled = !_isSaving;
    final members = _family.members;
    final today = DateUtils.dateOnly(widget.clock());
    const years = AppointmentFormScreen.dateRangeYears;

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
                const SizedBox(height: 16),
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
                      ? (memberId) => setState(() => _memberId = memberId)
                      : null,
                  validator: (memberId) =>
                      memberId == null ? AppStrings.memberRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _doctorController,
                  enabled: enabled,
                  maxLength: AppointmentFormScreen.maxDoctorNameLength,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: AppStrings.doctorNameLabel,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medical_services_outlined),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? AppStrings.doctorNameRequired
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _specialtyController,
                  enabled: enabled,
                  maxLength: AppointmentFormScreen.maxSpecialtyLength,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: AppStrings.specialtyOptionalLabel,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_hospital_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                AppointmentDateField(
                  initialValue: _date,
                  enabled: enabled,
                  today: today,
                  firstDate: DateTime(
                    today.year - years,
                    today.month,
                    today.day,
                  ),
                  lastDate: DateTime(
                    today.year + years,
                    today.month,
                    today.day,
                  ),
                  onChanged: (date) => setState(() => _date = date),
                ),
                const SizedBox(height: 16),
                AppointmentTimeField(
                  initialValue: _time,
                  enabled: enabled,
                  onChanged: (time) => setState(() => _time = time),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  enabled: enabled,
                  maxLength: AppointmentFormScreen.maxLocationLength,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: AppStrings.locationOptionalLabel,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  enabled: enabled,
                  maxLength: AppointmentFormScreen.maxNotesLength,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: AppStrings.notesOptionalLabel,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
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
                    onPressed: _isSaving ? null : _save,
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
