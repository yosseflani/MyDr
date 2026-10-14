import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/data/mock/mock_data.dart';
import 'package:mydr/features/shell/home_shell.dart';

void main() {
  testWidgets('MyDrApp exposes its dependencies to the home screen', (
    tester,
  ) async {
    final dependencies = AppDependencies.empty();
    await tester.pumpWidget(MyDrApp(dependencies: dependencies));

    final context = tester.element(find.byType(HomeShell));
    expect(AppScope.of(context).dependencies, same(dependencies));
  });

  testWidgets('pushed routes receive the same dependencies and controller', (
    tester,
  ) async {
    await tester.pumpWidget(MyDrApp(dependencies: AppDependencies.empty()));
    final homeScope = AppScope.of(tester.element(find.byType(HomeShell)));

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const _PushedPage()),
    );
    await tester.pumpAndSettle();

    final pushedScope = AppScope.of(tester.element(find.byType(_PushedPage)));
    expect(pushedScope.dependencies, same(homeScope.dependencies));
    expect(pushedScope.familyController, same(homeScope.familyController));
  });

  testWidgets('MyDrApp loads the family members on start', (tester) async {
    await tester.pumpWidget(
      MyDrApp(dependencies: AppDependencies.withMockData(DateTime.now())),
    );
    await tester.pumpAndSettle();

    final controller = AppScope.of(
      tester.element(find.byType(HomeShell)),
    ).familyController;
    expect(controller.isLoading, isFalse);
    expect(controller.members, hasLength(MockData.members().length));
  });
}

class _PushedPage extends StatelessWidget {
  const _PushedPage();

  @override
  Widget build(BuildContext context) => const Placeholder();
}
