import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heroos/presentation/viewmodels/shell_controller.dart';
import 'package:heroos/presentation/widgets/zen_sidebar.dart';

void main() {
  testWidgets('ZenSidebar renders navigation destinations and responds to taps', (tester) async {
    final shell = ShellController();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: shell,
        child: const MaterialApp(
          home: Scaffold(
            body: ZenSidebar(),
          ),
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(shell.currentIndex, 0);

    // Tap on the second destination (Misiones / index 1)
    await tester.tap(find.byIcon(Icons.task_alt_outlined));
    await tester.pumpAndSettle();

    expect(shell.currentIndex, 1);
  });
}
