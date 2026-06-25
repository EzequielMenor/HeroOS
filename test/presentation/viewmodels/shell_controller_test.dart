import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heroos/presentation/viewmodels/shell_controller.dart';

void main() {
  test('ShellController default state and mutations', () {
    final controller = ShellController();
    expect(controller.currentIndex, 0);
    expect(controller.isWriting, false);
    expect(controller.isSidebarCollapsed, false);

    int notificationsCount = 0;
    controller.addListener(() => notificationsCount++);

    controller.setTab(2);
    expect(controller.currentIndex, 2);
    expect(notificationsCount, 1);

    controller.setWriting(true);
    expect(controller.isWriting, true);
    expect(notificationsCount, 2);

    controller.toggleSidebar();
    expect(controller.isSidebarCollapsed, true);
    expect(notificationsCount, 3);
  });

  testWidgets('ShellController provider resolution', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ShellController()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer<ShellController>(
              builder: (context, controller, child) {
                return Text('Index: ${controller.currentIndex}');
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('Index: 0'), findsOneWidget);
  });
}
