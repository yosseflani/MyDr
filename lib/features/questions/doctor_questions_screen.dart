import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/empty_state.dart';
import 'package:mydr/core/widgets/load_error_views.dart';
import 'package:mydr/core/widgets/member_filter_chips.dart';
import 'package:mydr/core/widgets/section_header.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/questions/doctor_question_form_screen.dart';
import 'package:mydr/features/questions/widgets/question_tile.dart';

/// Which questions to show, by whether they were handled.
enum QuestionStatusFilter { all, unresolved, resolved }

/// Questions to the doctor, from the shared [DoctorQuestionController],
/// grouped into "not yet handled" and "handled", with filters by family
/// member and by status.
class DoctorQuestionsScreen extends StatefulWidget {
  const DoctorQuestionsScreen({
    super.key,
    this.initialMemberId,
    this.clock = DateTime.now,
  });

  /// Family member to filter on when the screen opens.
  final String? initialMemberId;

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  static Route<void> route({
    String? initialMemberId,
    DateTime Function() clock = DateTime.now,
  }) => MaterialPageRoute<void>(
    builder: (_) =>
        DoctorQuestionsScreen(initialMemberId: initialMemberId, clock: clock),
  );

  @override
  State<DoctorQuestionsScreen> createState() => _DoctorQuestionsScreenState();
}

class _DoctorQuestionsScreenState extends State<DoctorQuestionsScreen> {
  static const double _maxContentWidth = 600;

  /// Leaves room so the last card is not hidden behind the add button.
  static const double _bottomPaddingForFab = 96;

  late String? _selectedMemberId = widget.initialMemberId;
  QuestionStatusFilter _statusFilter = QuestionStatusFilter.all;

  /// Opens the form, preselecting the member currently filtered on.
  void _openAddForm() {
    Navigator.of(context).push(
      DoctorQuestionFormScreen.addRoute(
        initialMemberId: _selectedMemberId,
        clock: widget.clock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final questions = scope.doctorQuestionController;
    final family = scope.familyController;
    final appointments = scope.appointmentController;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.doctorQuestionsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'questions-add-button',
        onPressed: _openAddForm,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text(AppStrings.newQuestion),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: ListenableBuilder(
            listenable: Listenable.merge([questions, family, appointments]),
            builder: (context, _) =>
                _buildList(questions, family, appointments),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    DoctorQuestionController questions,
    FamilyController family,
    AppointmentController appointments,
  ) {
    // A filtered member that was deleted falls back to the whole family.
    if (_selectedMemberId case final id? when family.memberById(id) == null) {
      if (!family.isLoading) _selectedMemberId = null;
    }
    final memberId = _selectedMemberId;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        _bottomPaddingForFab + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const DemoDataBanner(),
        if (questions.questions.isNotEmpty) ...[
          if (family.members.isNotEmpty) ...[
            const SizedBox(height: 12),
            MemberFilterChips(
              members: family.members,
              selectedMemberId: memberId,
              onSelected: (id) => setState(() => _selectedMemberId = id),
            ),
          ],
          const SizedBox(height: 12),
          SegmentedButton<QuestionStatusFilter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: QuestionStatusFilter.all,
                label: Text(AppStrings.questionsFilterAll),
              ),
              ButtonSegment(
                value: QuestionStatusFilter.unresolved,
                label: Text(AppStrings.unresolvedQuestionsSection),
              ),
              ButtonSegment(
                value: QuestionStatusFilter.resolved,
                label: Text(AppStrings.resolvedQuestionsSection),
              ),
            ],
            selected: {_statusFilter},
            onSelectionChanged: (selection) =>
                setState(() => _statusFilter = selection.single),
          ),
        ],
        ..._buildContent(questions, family, appointments, memberId),
      ],
    );
  }

  List<Widget> _buildContent(
    DoctorQuestionController questions,
    FamilyController family,
    AppointmentController appointments,
    String? memberId,
  ) {
    if (questions.questions.isEmpty) {
      if (questions.isLoading) {
        return const [
          Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      }
      if (questions.hasLoadError) {
        return [
          LoadErrorView(
            title: AppStrings.questionsLoadErrorTitle,
            message: AppStrings.questionsLoadErrorMessage,
            onRetry: questions.load,
          ),
        ];
      }
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.question_answer_outlined,
            title: AppStrings.questionsEmptyTitle,
            message: AppStrings.questionsEmptyMessage,
          ),
        ),
      ];
    }

    final unresolved = questions.unresolved(memberId: memberId);
    final resolved = questions.resolved(memberId: memberId);
    final showUnresolved = _statusFilter != QuestionStatusFilter.resolved;
    final showResolved = _statusFilter != QuestionStatusFilter.unresolved;

    return [
      if (questions.hasLoadError) ...[
        const SizedBox(height: 12),
        RefreshErrorCard(
          message: AppStrings.questionsRefreshError,
          onRetry: questions.load,
        ),
      ],
      if (memberId != null && unresolved.isEmpty && resolved.isEmpty)
        _EmptyForMember(
          memberName: family.memberById(memberId)?.name ?? '',
          onShowAll: () => setState(() => _selectedMemberId = null),
        )
      else ...[
        if (showUnresolved) ...[
          const SizedBox(height: 24),
          const SectionHeader(title: AppStrings.unresolvedQuestionsSection),
          ..._buildSection(unresolved, AppStrings.noUnresolvedQuestions),
        ],
        if (showResolved) ...[
          const SizedBox(height: 24),
          const SectionHeader(title: AppStrings.resolvedQuestionsSection),
          ..._buildSection(resolved, AppStrings.noResolvedQuestions),
        ],
      ],
    ];
  }

  List<Widget> _buildSection(List<DoctorQuestion> items, String emptyText) {
    if (items.isEmpty) {
      final theme = Theme.of(context);
      return [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Text(
            emptyText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }

    final now = widget.clock();
    return [
      for (final (index, question) in items.indexed) ...[
        if (index > 0) const SizedBox(height: 12),
        QuestionTile(
          key: ValueKey(question.id),
          question: question,
          now: now,
          onTap: () => Navigator.of(context).push(
            DoctorQuestionFormScreen.editRoute(
              question.id,
              clock: widget.clock,
            ),
          ),
        ),
      ],
    ];
  }
}

class _EmptyForMember extends StatelessWidget {
  const _EmptyForMember({required this.memberName, required this.onShowAll});

  final String memberName;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          EmptyState(
            icon: Icons.question_answer_outlined,
            title: AppStrings.questionsEmptyForMember(memberName),
            message: AppStrings.questionsEmptyForMemberMessage,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onShowAll,
            child: const Text(AppStrings.showAllFamily),
          ),
        ],
      ),
    );
  }
}
