import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:heroos/presentation/screens/dashboard_screen.dart';
import 'package:heroos/presentation/viewmodels/habits_viewmodel.dart';
import 'package:heroos/presentation/viewmodels/tasks_viewmodel.dart';
import 'package:heroos/presentation/viewmodels/sleep_viewmodel.dart';
import 'package:heroos/presentation/viewmodels/profile_viewmodel.dart';
import 'package:heroos/presentation/viewmodels/finance_viewmodel.dart';
import 'package:heroos/presentation/viewmodels/goals_viewmodel.dart';
import 'package:heroos/presentation/viewmodels/notes_viewmodel.dart';
import 'package:heroos/presentation/viewmodels/shell_controller.dart';
import 'package:heroos/presentation/widgets/responsive_shell.dart';
import 'package:heroos/core/utils/responsive.dart';
import 'package:heroos/presentation/screens/notes_screen.dart';
import 'package:heroos/domain/entities/habit_entity.dart';
import 'package:heroos/domain/entities/task_entity.dart';
import 'package:heroos/domain/entities/sleep_log_entity.dart';
import 'package:heroos/domain/entities/note_entity.dart';
import 'package:heroos/domain/entities/account_entity.dart';
import 'package:heroos/domain/entities/transaction_entity.dart';
import 'package:heroos/domain/entities/category_entity.dart';

// Elegant Mocking using Dart's native noSuchMethod feature to avoid mock library dependencies
class MockHabitsViewModel extends ChangeNotifier implements HabitsViewModel {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #todayHabits) return <HabitEntity>[];
    if (name == #habits) return <HabitEntity>[];
    if (name == #completedTodayIds) return <String>{};
    if (name == #isLoading) return false;
    if (name == #isCompletedToday) return false;
    if (invocation.isMethod) return Future<void>.value();
    return null;
  }
}

class MockTasksViewModel extends ChangeNotifier implements TasksViewModel {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #pendingTasks) return <TaskEntity>[];
    if (name == #tasks) return <TaskEntity>[];
    if (name == #doneTasks) return <TaskEntity>[];
    if (name == #isLoading) return false;
    if (invocation.isMethod) return Future<void>.value();
    return null;
  }
}

class MockSleepViewModel extends ChangeNotifier implements SleepViewModel {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #logs) return <SleepLogEntity>[];
    if (name == #todayLog) return null;
    if (name == #isLoading) return false;
    if (invocation.isMethod) return Future<void>.value();
    return null;
  }
}

class MockProfileViewModel extends ChangeNotifier implements ProfileViewModel {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #profile) return null;
    if (name == #isLoading) return false;
    if (invocation.isMethod) return Future<void>.value();
    return null;
  }
}

class MockFinanceViewModel extends ChangeNotifier implements FinanceViewModel {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #accounts) return <AccountEntity>[];
    if (name == #transactions) return <TransactionEntity>[];
    if (name == #categories) return <CategoryEntity>[];
    if (name == #isLoading) return false;
    if (name == #error) return null;
    if (name == #totalBalance) return 0.0;
    if (invocation.isMethod) return Future<void>.value();
    return null;
  }
}

class MockGoalsViewModel extends ChangeNotifier implements GoalsViewModel {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #isLoading) return false;
    if (invocation.isMethod) return Future<void>.value();
    return null;
  }
}

class MockNotesViewModel extends ChangeNotifier implements NotesViewModel {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #notes) return <NoteEntity>[];
    if (name == #allTags) return <String>{};
    if (name == #selectedTag) return null;
    if (name == #searchQuery) return '';
    if (name == #isLoading) return false;
    if (invocation.isMethod) return Future<void>.value();
    return null;
  }
}

List<SingleChildWidget> _buildMockProviders({ShellController? shellController}) {
  return [
    ChangeNotifierProvider<HabitsViewModel>.value(value: MockHabitsViewModel()),
    ChangeNotifierProvider<TasksViewModel>.value(value: MockTasksViewModel()),
    ChangeNotifierProvider<SleepViewModel>.value(value: MockSleepViewModel()),
    ChangeNotifierProvider<ProfileViewModel>.value(value: MockProfileViewModel()),
    ChangeNotifierProvider<FinanceViewModel>.value(value: MockFinanceViewModel()),
    ChangeNotifierProvider<GoalsViewModel>.value(value: MockGoalsViewModel()),
    ChangeNotifierProvider<NotesViewModel>.value(value: MockNotesViewModel()),
    ChangeNotifierProvider<ShellController>.value(value: shellController ?? ShellController()),
  ];
}

void main() {
  setUpAll(() async {
    // Mock SharedPreferences native platform channel
    SharedPreferences.setMockInitialValues({});

    // Initialize date formatting for test environment
    await initializeDateFormatting('es', null);

    // Initialize Supabase with dummy credentials and EmptyLocalStorage to bypass storage channel errors
    await Supabase.initialize(
      url: 'https://dummy.supabase.co',
      anonKey: 'dummyAnonKey',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );
  });

  tearDown(() {
    debugOverrideIsWeb = false;
  });

  testWidgets('DashboardScreen PageView swipe transition test', (WidgetTester tester) async {
    // Pump DashboardScreen inside required providers
    await tester.pumpWidget(
      MultiProvider(
        providers: _buildMockProviders(),
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Verify PageView is present
    final pageViewFinder = find.byType(PageView);
    expect(pageViewFinder, findsOneWidget);

    // Swipe left from page 0 to page 1 (using fling with negative X offset to trigger next page transition)
    await tester.fling(pageViewFinder, const Offset(-500.0, 0.0), 1000.0);
    await tester.pumpAndSettle();

    // Verify we transitioned to the next page
    final pageView = tester.widget<PageView>(pageViewFinder);
    expect(pageView.controller?.page, 1.0);
  });

  testWidgets('DashboardScreen bottom navbar drag transition test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: _buildMockProviders(),
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    final pageViewFinder = find.byType(PageView);
    final pageView = tester.widget<PageView>(pageViewFinder);
    expect(pageView.controller?.page, 0.0);

    // Find the text 'Misiones' tab to tap it and verify animation
    final misTabFinder = find.text('MIS');
    expect(misTabFinder, findsOneWidget);

    await tester.tap(misTabFinder);
    await tester.pumpAndSettle();

    // Verify it transitioned to page 1
    expect(pageView.controller?.page, 1.0);
  });

  testWidgets('DashboardScreen bottom navbar drag gesture test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: _buildMockProviders(),
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    final pageViewFinder = find.byType(PageView);
    final pageView = tester.widget<PageView>(pageViewFinder);
    expect(pageView.controller?.page, 0.0);

    // Find the drag detector
    final dragGestureFinder = find.byWidgetPredicate((widget) =>
        widget is GestureDetector &&
        widget.onHorizontalDragUpdate != null &&
        widget.child is SizedBox);
    expect(dragGestureFinder, findsOneWidget);

    // Let's drag on the navbar.
    // We start from the left side of the drag detector (representing page 0)
    // and drag to the right to transition to page 2.
    final topLeft = tester.getTopLeft(dragGestureFinder);
    final size = tester.getSize(dragGestureFinder);

    // Let's calculate the tab width
    final double tabWidth = size.width / 7.0;

    // Start drag at the center of the first tab: page 0 is centered at (0.5 * tabWidth)
    final startPoint = Offset(topLeft.dx + (0.5 * tabWidth), topLeft.dy + (size.height / 2.0));

    // Drag to the center of the third tab: page 2 is centered at (2.5 * tabWidth)
    final endPoint = Offset(topLeft.dx + (2.5 * tabWidth), topLeft.dy + (size.height / 2.0));

    // Perform the drag
    final gesture = await tester.startGesture(startPoint);
    await tester.pump();
    await gesture.moveTo(endPoint);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify it transitioned to page 2
    expect(pageView.controller?.page, 2.0);
  });

  testWidgets('DashboardScreen renders ResponsiveShell on web layout', (WidgetTester tester) async {
    // Enable web layout simulation
    debugOverrideIsWeb = true;
    // Set viewport width to >= 900
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MultiProvider(
        providers: _buildMockProviders(),
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Verify ResponsiveShell is rendered instead of mobile PageView
    expect(find.byType(ResponsiveShell), findsOneWidget);
    expect(find.byType(PageView), findsNothing);

    // Reset physicalSize and devicePixelRatio
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('NoteEditorSheet triggers isWriting state in ShellController on focus', (WidgetTester tester) async {
    final shell = ShellController();

    await tester.pumpWidget(
      ChangeNotifierProvider<ShellController>.value(
        value: shell,
        child: MaterialApp(
          home: Scaffold(
            body: NoteEditorSheet(
              note: null,
              onSave: (title, content, tags) {},
            ),
          ),
        ),
      ),
    );

    // Since TextField has autofocus: true, it gets focus immediately upon being pumped
    expect(shell.isWriting, isTrue);

    // Unfocus the TextField
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // Verify isWriting returns to false when focus is lost
    expect(shell.isWriting, isFalse);
  });
}
