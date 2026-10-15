import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/detail_section.dart';
import 'package:mydr/features/questions/doctor_question_form_screen.dart';
import 'package:mydr/features/questions/doctor_questions_screen.dart';

/// Short summary of a family member's questions for their profile: how many
/// are not yet handled, a preview of up to [maxPreview] of them, and links to
/// all of their questions and to adding a new one.
class MemberQuestionsSection extends StatelessWidget {
  const MemberQuestionsSection({super.key, required this.memberId});

  final String memberId;

  static const int maxPreview = 3;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).doctorQuestionController;

    return DetailSection(
      title: AppStrings.doctorQuestionsTitle,
      icon: Icons.question_answer_outlined,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final theme = Theme.of(context);
          final unresolved = controller.unresolved(memberId: memberId);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.hasLoadError && controller.questions.isEmpty)
                Row(
                  children: [
                    const Expanded(
                      child: Text(AppStrings.questionsLoadErrorTitle),
                    ),
                    TextButton(
                      onPressed: controller.load,
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                )
              else
                Text(
                  AppStrings.unresolvedQuestionsCount(unresolved.length),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              for (final question in unresolved.take(maxPreview)) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.radio_button_unchecked,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).push(
                      DoctorQuestionFormScreen.addRoute(
                        initialMemberId: memberId,
                      ),
                    ),
                    icon: const Icon(Icons.add_comment_outlined),
                    label: const Text(AppStrings.newQuestion),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      DoctorQuestionsScreen.route(initialMemberId: memberId),
                    ),
                    icon: const Icon(Icons.list_alt),
                    label: const Text(AppStrings.allQuestions),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
