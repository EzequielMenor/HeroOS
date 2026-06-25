import 'package:flutter/material.dart';

class LineCache {
  final String text;
  final TextSpan span;
  const LineCache({required this.text, required this.span});
}

class ZenMarkdownController extends TextEditingController {
  final Map<int, LineCache> _lineCache = {};

  ZenMarkdownController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final lines = text.split('\n');
    final List<TextSpan> spans = [];

    for (int i = 0; i < lines.length; i++) {
      final lineText = lines[i];

      if (_lineCache[i]?.text == lineText) {
        spans.add(_lineCache[i]!.span);
      } else {
        final parsedSpan = _parseLineMarkdown(lineText, style);
        _lineCache[i] = LineCache(text: lineText, span: parsedSpan);
        spans.add(parsedSpan);
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: spans, style: style);
  }

  TextSpan _parseLineMarkdown(String line, TextStyle? defaultStyle) {
    // Basic Markdown matching for headers, bold, list markers, and code
    final normalStyle = defaultStyle ?? const TextStyle(color: Colors.white, fontSize: 14);
    
    if (line.startsWith('#')) {
      final headerLevel = RegExp(r'^#+').firstMatch(line)?.group(0)?.length ?? 1;
      final size = headerLevel == 1 ? 20.0 : (headerLevel == 2 ? 18.0 : 16.0);
      return TextSpan(
        text: line,
        style: normalStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: size,
          color: const Color(0xFFFFFFFF),
        ),
      );
    }

    if (line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('* ')) {
      return TextSpan(
        text: line,
        style: normalStyle.copyWith(color: const Color(0xFFA0A0A2)),
      );
    }

    final children = <TextSpan>[];
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int currentPos = 0;

    for (final match in boldRegex.allMatches(line)) {
      if (match.start > currentPos) {
        children.add(TextSpan(text: line.substring(currentPos, match.start)));
      }
      children.add(TextSpan(
        text: line.substring(match.start, match.end),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ));
      currentPos = match.end;
    }

    if (currentPos < line.length) {
      children.add(TextSpan(text: line.substring(currentPos)));
    }

    return TextSpan(children: children, style: normalStyle);
  }
}
