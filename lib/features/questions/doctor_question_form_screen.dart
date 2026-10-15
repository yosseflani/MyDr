import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/discard_changes_dialog.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/appointments/appointment_formatting.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/widgets/no_family_members_view.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/questions/widgets/delete_question_dialog.dart';

/// Form for adding a question to the doctor, or editing one when
/// [questionId] is set.
///
/// Saves through the shared [DoctorQuestionController]; the questions list
/// updates automatically because it listens to it.
class DoctorQuestionFormScreen extends StatefulWidget {
  const DoctorQuestionFormScreen({
    super.key,
    this.questionId,
    this.initialMemberId,
    this.initialAppointmentId,
    this.clock = DateTime.now,
  });

  /// The question to edit, or null to add a new one.
  final String? questionId;

  /// Family member to preselect when adding.
  final String? initialMemberId;

  /// Appointment to preselect when adding; only used if it belongs to the
  /// preselected member.
  final String? initialAppointmentId;

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  static const int maxTextLength = 300;
  static const int maxAnswerLength = 1000;

  static Route<void> addRoute({
    String? initialMemberId,
    String? initialAppointmentId,
    DateTime Function() clock = DateTime.now,
  }) => MaterialPageRoute<void>(
    builder: (_) => DoctorQuestionFormScreen(
      initialMemberId: initialMemberId,
      initialAppointmentId: initialAppointmentId,
      clock: clock,
    ),
  );

  static Route<void> editRoute(
    String questionId, {
    DateTime Function() clock = DateTime.now,
  }) => MaterialPageRoute<void>(
    builder: (_) =>
        DoctorQuestionFormScreen(questionId: questionId, clock: clock),
  );

  @override
  State<DoctorQuestionFormScreen> createState() =>
      _DoctorQuestionFormScreenState();
}

class _DoctorQuestionFormScreenState extends State<DoctorQuestionFormScreen> {
  static const double _maxContentWidth = 600;

  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _answerController = TextEditingController();

  late final DoctorQuestionController _questions;
  late final FamilyController _family;
  late final AppointmentController _appointments;
  bool _isInitialized = false;

  /// The question being edited, or null when adding or when not found.
  DoctorQuestion? _original;

  /// Id for a new question, created once so a retry reuses it.
  String? _newQuestionId;

  String? _memberId;
  String? _appointmentId;
  bool _resolved = false;

  // Values the form started with, to detect unsaved changes.
  String? _initialMemberId;
  String? _initialAppointmentId;

  /// Explains why the appointment link was removed, if it was.
  String? _appointmentNotice;

  /// Whether the form was showing the "no family members" state, so the
  /// first member added from there can be selected automatically.
  bool _wasWithoutMembers = false;

  bool _isSaving = false;
  String? _saveError;

  /// Set once the user saved or chose to discard, so leaving is allowed.
  bool _canLeave = false;

  bool get _isEditing => widget.questionId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;

    final scope = AppScope.of(context);
    _questions = scope.doctorQuestionController;
    _family = scope.familyController;
    _appointments = scope.appointmentController;

    final questionId = widget.questionId;
    final original = questionId == null
        ? null
        : _questions.questionById(questionId);
    _original = original;

    if (original != null) {
      _textController.text = original.text;
      _answerController.text = original.doctorAnswer ?? '';
      _memberId = original.memberId;
      _appointmentId = original.appointmentId;
      _resolved = original.isResolved;
    } else if (!_isEditing) {
      final requested = widget.initialMemberId;
      if (requested != null && _family.memberById(requested) != null) {
        _memberId = requested;
      } else if (_family.members.length == 1) {
        _memberId = _family.members.single.id;
      }
      final appointment = switch (widget.initialAppointmentId) {
        final id? => _appointments.appointmentById(id),
        null => null,
      };
      if (appointment != null && appointment.memberId == _memberId) {
        _appointmentId = appointment.id;
      }
    }
    _initialMemberId = _memberId;
    _initialAppointmentId = _appointmentId;

    _textController.addListener(_onTextChanged);
    _answerController.addListener(_onTextChanged);

    // A message left over from the previous screen would cover the save
    // button, so clear it once this screen is shown.
    final messenger = ScaffoldMessenger.maybeOf(context);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => messenger?.removeCurrentSnackBar(),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _hasUnsavedChanges {
    final original = _original;
    return _textController.text.trim() != (original?.text ?? '').trim() ||
        _answerController.text.trim() !=
            (original?.doctorAnswer ?? '').trim() ||
        _memberId != _initialMemberId ||
        _appointmentId != _initialAppointmentId ||
        _resolved != (original?.isResolved ?? false);
  }

  /// Keeps the selections valid as family members and appointments change
  /// while the form is open.
  ///
  /// A deleted member is cleared, never replaced by another one, and a
  /// deleted appointment is unlinked with an explanation, so nothing is
  /// ever saved for the wrong person or to a missing appointment.
  void _syncSelections() {
    final memberId = _memberId;
    if (memberId != null &&
        !_family.isLoading &&
        _family.memberById(memberId) == null) {
      _memberId = null;
      _appointmentId = null;
    }

    final appointmentId = _appointmentId;
    if (appointmentId != null &&
        !_appointments.isLoading &&
        _appointments.appointmentById(appointmentId) == null) {
      _appointmentId = null;
      _appointmentNotice = AppStrings.linkedAppointmentDeletedWhileEditing;
      // Removed elsewhere, not by the user, so it is not a change to save.
      if (_initialAppointmentId == appointmentId) _initialAppointmentId = null;
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

  void _onMemberChanged(String? memberId) {
    if (memberId == _memberId) return;
    setState(() {
      _memberId = memberId;
      if (_appointmentId != null) {
        _appointmentId = null;
        _appointmentNotice = AppStrings.appointmentLinkClearedOnMemberChange;
      }
    });
  }

  /// The member's appointments: upcoming nearest first, then past most
  /// recent first.
  List<Appointment> _appointmentsOf(String memberId, DateTime now) => [
    ..._appointments.upcoming(now, memberId: memberId),
    ..._appointments.past(now, memberId: memberId),
  ];

  String _memberName(String memberId) =>
      _family.memberById(memberId)?.name ?? AppStrings.unknownMember;

  DoctorQuestion _buildQuestion() {
    final answer = _answerController.text.trim();
    return DoctorQuestion(
      id: widget.questionId ?? (_newQuestionId ??= _questions.createId()),
      memberId: _memberId!,
      appointmentId: _appointmentId,
      text: _textController.text.trim(),
      createdAt: _original?.createdAt ?? widget.clock(),
      isResolved: _resolved,
      doctorAnswer: answer.isEmpty ? null : answer,
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final original = _original;
    final originalAppointmentId = original?.appointmentId;
    if (original != null &&
        original.memberId != _memberId &&
        originalAppointmentId != null) {
      final confirmed = await _confirmMove(original, originalAppointmentId);
      if (!confirmed || !mounted) return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    final question = _buildQuestion();
    final result = _isEditing
        ? await _questions.update(question)
        : await _questions.add(question);
    if (!mounted) return;

    if (result == QuestionSaveResult.success) {
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
        QuestionSaveResult.memberNotFound => AppStrings.selectedMemberMissing,
        QuestionSaveResult.appointmentNotFound =>
          AppStrings.selectedAppointmentMissing,
        QuestionSaveResult.appointmentOfAnotherMember =>
          AppStrings.appointmentOfAnotherMemberError,
        QuestionSaveResult.questionNotFound => AppStrings.questionMissingOnSave,
        QuestionSaveResult.textRequired => AppStrings.questionTextRequired,
        QuestionSaveResult.failed ||
        QuestionSaveResult.success => AppStrings.saveFailed,
      };
    });
  }

  /// Asks before moving a question that is linked to an appointment to
  /// another member, since the link will be removed.
  Future<bool> _confirmMove(DoctorQuestion original, String appointmentId) {
    final doctorName =
        _appointments.appointmentById(appointmentId)?.doctorName ?? '';
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.swap_horiz),
        title: Text(AppStrings.moveQuestionTitle(_memberName(_memberId!))),
        content: Text(
          AppStrings.moveQuestionMessage(
            doctorName,
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

  /// Deletes only after the user confirms in [DeleteQuestionDialog]; on
  /// success leaves the form (any unsaved edits go with the question).
  Future<void> _confirmAndDelete() async {
    final questionId = widget.questionId;
    if (_isSaving || questionId == null) return;
    final question = _questions.questionById(questionId) ?? _original;
    if (question == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final deleted = await DeleteQuestionDialog.show(context, question);
    if (!deleted || !mounted) return;

    setState(() => _canLeave = true);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.questionDeleted)));
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
      listenable: Listenable.merge([_questions, _family, _appointments]),
      builder: (context, _) {
        _syncSelections();
        final questionId = widget.questionId;
        final isMissing = _isEditing && _original == null;
        final wasDeleted =
            !isMissing &&
            questionId != null &&
            !_questions.isLoading &&
            _questions.questionById(questionId) == null;
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
            title: AppStrings.questionNotFoundTitle,
            message: AppStrings.questionNotFoundMessage,
            backLabel: AppStrings.backToQuestions,
          );
        } else if (hasNoMembers && _family.isLoading) {
          body = const Center(child: CircularProgressIndicator());
        } else if (hasNoMembers) {
          body = const NoFamilyMembersView(
            title: AppStrings.noFamilyForQuestionTitle,
            message: AppStrings.noFamilyForQuestionMessage,
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
                    ? AppStrings.editQuestionTitle
                    : AppStrings.newQuestion,
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
    final now = widget.clock();
    final memberAppointments = memberId == null
        ? const <Appointment>[]
        : _appointmentsOf(memberId, now);
    final localizations = MaterialLocalizations.of(context);
    final theme = Theme.of(context);

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
                    message: AppStrings.questionDeletedWhileEditing,
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  // Rebuilt when the family changes, so it never holds a
                  // member that no longer exists.
                  key: ValueKey('member:${members.map((m) => m.id).join(',')}'),
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
                  onChanged: enabled ? _onMemberChanged : null,
                  validator: (value) =>
                      value == null ? AppStrings.memberRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _textController,
                  enabled: enabled,
                  maxLength: DoctorQuestionFormScreen.maxTextLength,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: AppStrings.questionTextLabel,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? AppStrings.questionTextRequired
                      : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  // Rebuilt when the member or their appointments change.
                  key: ValueKey(
                    'appointment:$memberId:'
                    '${memberAppointments.map((a) => a.id).join(',')}',
                  ),
                  initialValue: _appointmentId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: AppStrings.linkedAppointmentLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.event_outlined),
                    helperText: memberId == null
                        ? AppStrings.selectMemberFirst
                        : memberAppointments.isEmpty
                        ? AppStrings.noAppointmentsForMember
                        : null,
                    helperMaxLines: 3,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(AppStrings.noAppointmentOption),
                    ),
                    for (final appointment in memberAppointments)
                      DropdownMenuItem<String?>(
                        value: appointment.id,
                        child: Text(
                          _appointmentLabel(appointment, now, localizations),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: enabled && memberId != null
                      ? (id) => setState(() {
                          _appointmentId = id;
                          _appointmentNotice = null;
                        })
                      : null,
                ),
                if (_appointmentNotice case final notice?) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notice,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _resolved,
                  onChanged: enabled
                      ? (value) => setState(() => _resolved = value)
                      : null,
                  title: const Text(AppStrings.questionResolvedLabel),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _answerController,
                  enabled: enabled,
                  maxLength: DoctorQuestionFormScreen.maxAnswerLength,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: AppStrings.doctorAnswerLabel,
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
                    label: const Text(AppStrings.deleteQuestion),
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

  static String _appointmentLabel(
    Appointment appointment,
    DateTime now,
    MaterialLocalizations localizations,
  ) {
    final when = formatAppointmentDateTime(
      appointment.dateTime,
      now,
      localizations,
    );
    final label = '${appointment.doctorName} · $when';
    return appointment.isUpcoming(now)
        ? label
        : '$label (${AppStrings.pastAppointmentSuffix})';
  }
}
