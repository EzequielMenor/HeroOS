import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:heroos/core/utils/responsive.dart';
import 'package:heroos/presentation/viewmodels/shell_controller.dart';
import 'package:heroos/presentation/widgets/responsive_shell.dart';

void main() {
  setUp(() {
    debugOverrideIsWeb = true;
  });

  tearDown(() {
    debugOverrideIsWeb = false;
  });

  testWidgets('ResponsiveShell adaptive layout test (desktop shows sidebar)', (tester) async {
    final shell = ShellController();

    // Force Desktop size
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: shell,
        child: const MaterialApp(
          home: ResponsiveShell(
            child: Scaffold(body: Text('Content')),
          ),
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsOneWidget);

    // Reset layout sizes
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('ResponsiveShell mobile layout test (no sidebar)', (tester) async {
    debugOverrideIsWeb = false; // Turn off override to simulate mobile/native layout
    final shell = ShellController();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: shell,
        child: const MaterialApp(
          home: ResponsiveShell(
            child: Scaffold(body: Text('Content')),
          ),
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('ResponsiveShell Cmd+B toggles sidebar', (tester) async {
    final shell = ShellController();

    // Force Desktop size
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: shell,
        child: const MaterialApp(
          home: ResponsiveShell(
            child: Scaffold(body: Text('Content')),
          ),
        ),
      ),
    );

    expect(shell.isSidebarCollapsed, isFalse);

    // Simulate keyboard shortcut Cmd + B (Meta + B)
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();

    expect(shell.isSidebarCollapsed, isTrue);

    // Reset layout sizes
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('ResponsiveShell Cmd+K opens Omnibox dialog', (tester) async {
    final shell = ShellController();

    // Force Desktop size
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: shell,
        child: const MaterialApp(
          home: ResponsiveShell(
            child: Scaffold(body: Text('Content')),
          ),
        ),
      ),
    );

    expect(find.byType(Dialog), findsNothing);

    // Simulate keyboard shortcut Cmd + K (Meta + K)
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Captura rápida asistida por IA...'), findsOneWidget);

    // Close the dialog by submitting or popping
    await tester.tapAt(const Offset(10, 10)); // Tap outside barrier to close
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    // Reset layout sizes
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('ResponsiveShell collapses sidebar to width 0 when isWriting is true', (tester) async {
    final shell = ShellController();

    // Force Desktop size
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: shell,
        child: const MaterialApp(
          home: ResponsiveShell(
            child: Scaffold(body: Text('Content')),
          ),
        ),
      ),
    );

    // Find the AnimatedContainer wrapping ZenSidebar
    final animatedContainerFinder = find.descendant(
      of: find.byType(ResponsiveShell),
      matching: find.byType(AnimatedContainer),
    );

    AnimatedContainer container = tester.widget<AnimatedContainer>(animatedContainerFinder);
    expect(container.constraints?.maxWidth, 240.0);

    // Set writing mode to true
    shell.setWriting(true);
    await tester.pumpAndSettle();

    container = tester.widget<AnimatedContainer>(animatedContainerFinder);
    expect(container.constraints?.maxWidth, 0.0);

    // Reset layout sizes
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
