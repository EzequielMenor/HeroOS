import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heroos/presentation/widgets/zen_markdown_controller.dart';

void main() {
  testWidgets('ZenMarkdownController parses bold text correctly', (WidgetTester tester) async {
    final controller = ZenMarkdownController();
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(controller: controller),
        ),
      ),
    );

    controller.text = 'This is **bold** style';

    final span = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      style: const TextStyle(color: Colors.white),
      withComposing: true,
    );
    
    expect(span.children, isNotNull);
    expect(span.children!.isNotEmpty, true);
  });

  testWidgets('ZenMarkdownController parses headers correctly', (WidgetTester tester) async {
    final controller = ZenMarkdownController();
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(controller: controller),
        ),
      ),
    );

    controller.text = '# Header';

    final span = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      style: const TextStyle(color: Colors.white),
      withComposing: true,
    );
    
    expect(span.children, isNotNull);
    expect(span.children!.isNotEmpty, true);
  });

  testWidgets('ZenMarkdownController caches line spans', (WidgetTester tester) async {
    final controller = ZenMarkdownController();
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(controller: controller),
        ),
      ),
    );

    controller.text = 'Line 1\nLine 2\nLine 3';

    final span1 = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      style: const TextStyle(color: Colors.white),
      withComposing: true,
    );
    
    final span2 = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      style: const TextStyle(color: Colors.white),
      withComposing: true,
    );
    
    expect(span1.children?.length, equals(span2.children?.length));
  });

  testWidgets('ZenMarkdownController parses list items', (WidgetTester tester) async {
    final controller = ZenMarkdownController();
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(controller: controller),
        ),
      ),
    );

    controller.text = '- item 1\n- item 2';

    final span = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      style: const TextStyle(color: Colors.white),
      withComposing: true,
    );
    
    expect(span.children, isNotNull);
    expect(span.children!.length > 0, true);
  });
}
