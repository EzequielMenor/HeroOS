import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heroos/data/repositories/auth_repository.dart';
import 'package:heroos/domain/entities/note_entity.dart';
import 'package:heroos/presentation/screens/zen_canvas_screen.dart';
import 'package:provider/provider.dart';
import 'package:heroos/presentation/viewmodels/notes_viewmodel.dart';

void main() {
  setUpAll(() {
    AuthRepository.devQuickAccess = true;
  });

  testWidgets('ZenCanvasScreen renders with correct background color',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => NotesViewModel(),
          child: const ZenCanvasScreen(),
        ),
      ),
    );

    // Verify scaffold has #1C1C1E background
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFF1C1C1E));
  });

  testWidgets('ZenCanvasScreen shows LIENZO ZEN header',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => NotesViewModel(),
          child: const ZenCanvasScreen(),
        ),
      ),
    );

    expect(find.text('LIENZO ZEN'), findsOneWidget);
  });

  testWidgets('ZenCanvasScreen has back button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => NotesViewModel(),
          child: const ZenCanvasScreen(),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('ZenCanvasScreen has TextField for editing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => NotesViewModel(),
          child: const ZenCanvasScreen(),
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('ZenCanvasScreen accepts text input', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => NotesViewModel(),
          child: const ZenCanvasScreen(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Test note content');
    await tester.pump(const Duration(milliseconds: 2000)); // Let debounce timer fire

    expect(find.text('Test note content'), findsOneWidget);
  });

  testWidgets('ZenCanvasScreen with note shows existing content',
      (WidgetTester tester) async {
    final note = NoteEntity(
      id: 'test-1',
      userId: 'dev-user',
      title: 'Existing Note',
      content: 'Existing content here',
      date: DateTime.now(),
      tags: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => NotesViewModel(),
          child: ZenCanvasScreen(note: note),
        ),
      ),
    );

    expect(find.text('Existing content here'), findsOneWidget);
  });

  testWidgets('ZenCanvasScreen shows "Nota guardada" when save succeeds',
      (WidgetTester tester) async {
    final mockVm = FakeNotesViewModel()..flushAutosaveResult = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<NotesViewModel>.value(
            value: mockVm,
            child: const ZenCanvasScreen(),
          ),
        ),
      ),
    );

    // Tap checkmark button
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 500)); // Advance animation

    expect(find.text('Nota guardada'), findsOneWidget);
  });

  testWidgets('ZenCanvasScreen shows dynamic error from ViewModel when save fails',
      (WidgetTester tester) async {
    final mockVm = FakeNotesViewModel()
      ..flushAutosaveResult = false
      ..mockError = 'Custom failure message';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<NotesViewModel>.value(
            value: mockVm,
            child: const ZenCanvasScreen(),
          ),
        ),
      ),
    );

    // Tap checkmark button
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Custom failure message'), findsOneWidget);
  });

  testWidgets('ZenCanvasScreen does not show Snackbar when saved is null',
      (WidgetTester tester) async {
    final mockVm = FakeNotesViewModel()..flushAutosaveResult = null;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<NotesViewModel>.value(
            value: mockVm,
            child: const ZenCanvasScreen(),
          ),
        ),
      ),
    );

    // Tap checkmark button
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SnackBar), findsNothing);
  });
}

class FakeNotesViewModel extends NotesViewModel {
  bool? flushAutosaveResult;
  String? mockError;

  @override
  Future<bool?> flushAutosave() async {
    return flushAutosaveResult;
  }

  @override
  String? get error => mockError;

  @override
  void queueAutosave(dynamic note) {
    // No-op to avoid triggering real timers/saves in test
  }
}
