import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/questions/widgets/question_card.dart';

/// A [QuestionCard] wired to the shared controllers: looks up the member
/// name and linked appointment, toggles the handled status and copies the
/// question text.
///
/// While the status is being saved the toggle shows progress and ignores
/// taps. The card keeps showing the stored status until the save succeeds,
/// so a failure never leaves a wrong state on screen; it is explained in a
/// snack bar instead.
///
/// Used wherever questions are listed, so this behavior lives in one place.
class QuestionTile extends StatefulWidget {
  const QuestionTile({
    super.key,
    required this.question,
    required this.now,
    this.showAppointment = true,
    this.onTap,
  });

  final DoctorQuestion question;

  /// Used to show the appointment time relative to today.
  final DateTime now;

  /// See [QuestionCard.showAppointment].
  final bool showAppointment;
  final VoidCallback? onTap;

  @override
  State<QuestionTile> createState() => _QuestionTileState();
}

class _QuestionTileState extends State<QuestionTile> {
  bool _isUpdating = false;

  Future<void> _toggleResolved() async {
    if (_isUpdating) return;
    final controller = AppScope.of(context).doctorQuestionController;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isUpdating = true);

    final result = await controller.setResolved(
      widget.question.id,
      resolved: !widget.question.isResolved,
    );
    if (mounted) setState(() => _isUpdating = false);

    if (result == QuestionSaveResult.success) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result == QuestionSaveResult.questionNotFound
                ? AppStrings.questionNoLongerExists
                : AppStrings.questionUpdateFailed,
          ),
        ),
      );
  }

  /// Copies only the question text: no member name, appointment or answer.
  /// A failure is reported by type only, never its message.
  Future<void> _copy() async {
    final messenger = ScaffoldMessenger.of(context);
    var copied = true;
    try {
      await Clipboard.setData(ClipboardData(text: widget.question.text));
    } catch (_) {
      copied = false;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            copied ? AppStrings.questionCopied : AppStrings.questionCopyFailed,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final question = widget.question;

    return QuestionCard(
      question: question,
      memberName:
          scope.familyController.memberById(question.memberId)?.name ??
          AppStrings.unknownMember,
      linkedAppointment: switch (question.appointmentId) {
        final id? => scope.appointmentController.appointmentById(id),
        null => null,
      },
      now: widget.now,
      isUpdating: _isUpdating,
      onToggleResolved: _toggleResolved,
      onCopy: _copy,
      showAppointment: widget.showAppointment,
      onTap: widget.onTap,
    );
  }
}
