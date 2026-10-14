import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/mock/mock_data.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);

  test('withMockData seeds every repository with the demo data', () async {
    final dependencies = AppDependencies.withMockData(now);

    expect(
      await dependencies.familyRepository.getAll(),
      unorderedEquals(MockData.members()),
    );
    expect(
      await dependencies.appointmentRepository.getAll(),
      unorderedEquals(MockData.appointments(now)),
    );
    expect(
      await dependencies.doctorQuestionRepository.getAll(),
      unorderedEquals(MockData.questions(now)),
    );
    expect(
      await dependencies.symptomRepository.getAll(),
      unorderedEquals(MockData.symptoms(now)),
    );
  });

  test('empty starts with no data', () async {
    final dependencies = AppDependencies.empty();

    expect(await dependencies.familyRepository.getAll(), isEmpty);
    expect(await dependencies.appointmentRepository.getAll(), isEmpty);
    expect(await dependencies.doctorQuestionRepository.getAll(), isEmpty);
    expect(await dependencies.symptomRepository.getAll(), isEmpty);
  });

  test('each instance has its own independent repositories', () async {
    final first = AppDependencies.empty();
    final second = AppDependencies.empty();

    await first.familyRepository.add(MockData.members().first);

    expect(await first.familyRepository.getAll(), hasLength(1));
    expect(await second.familyRepository.getAll(), isEmpty);
  });
}
