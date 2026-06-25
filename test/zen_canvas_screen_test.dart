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
    await tester.pump();

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
}
