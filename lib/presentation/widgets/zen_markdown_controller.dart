import 'package:flutter/material.dart';

/// Regex for WikiLinks: [[Target]] or [[Target|Label]]
final wikiLinkRegex = RegExp(r'\[\[([^\]|]+)(?:\|([^\]]+))?\]\]');

/// Represents an inline match (bold, wiki link) within a line.
class _InlineMatch {
  final int start;
  final int end;
  final String displayText;
  final String? extra; // For WikiLinks: target vs label

  const _InlineMatch({
    required this.start,
    required this.end,
    required this.displayText,
    this.extra,
  });
}

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
    final normalStyle =
        defaultStyle ?? const TextStyle(color: Colors.white, fontSize: 14);

    // Full-line patterns: headers, list markers
    if (line.startsWith('#')) {
      final headerLevel =
          RegExp(r'^#+').firstMatch(line)?.group(0)?.length ?? 1;
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

    // Inline pattern matching: bold + WikiLinks
    final boldPattern = RegExp(r'\*\*(.*?)\*\*');
    final wikiPattern = wikiLinkRegex;

    // Collect all inline matches and sort by position
    final allMatches = <_InlineMatch>[];

    for (final match in boldPattern.allMatches(line)) {
      allMatches.add(
        _InlineMatch(
          start: match.start,
          end: match.end,
          displayText: match.group(0)!,
        ),
      );
    }

    for (final match in wikiPattern.allMatches(line)) {
      final target = match.group(1)!;
      final label = match.group(2);
      allMatches.add(
        _InlineMatch(
          start: match.start,
          end: match.end,
          displayText: label ?? target,
          extra: target,
        ),
      );
    }

    allMatches.sort((a, b) => a.start.compareTo(b.start));

    // Build TextSpans avoiding overlaps
    final children = <TextSpan>[];
    int currentPos = 0;

    for (final m in allMatches) {
      if (m.start < currentPos) continue; // skip overlapping

      // Plain text before this match
      if (m.start > currentPos) {
        children.add(TextSpan(text: line.substring(currentPos, m.start)));
      }

      // Bold match: **text**
      if (m.extra == null && m.displayText.startsWith('**')) {
        children.add(
          TextSpan(
            text: m.displayText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
      // WikiLink match: [[Target]] or [[Target|Label]]
      else if (m.extra != null) {
        final label = m.displayText;
        final bracketColor = const Color(0xFF7B61FF);
        children.add(
          TextSpan(
            children: [
              TextSpan(
                text: '[[',
                style: TextStyle(color: bracketColor),
              ),
              TextSpan(
                text: label,
                style: TextStyle(
                  color: const Color(0xFFA0A0A2),
                  decoration: TextDecoration.underline,
                  decorationColor: bracketColor,
                ),
              ),
              TextSpan(
                text: ']]',
                style: TextStyle(color: bracketColor),
              ),
            ],
          ),
        );
      }
      // Fallback plain text
      else {
        children.add(TextSpan(text: m.displayText));
      }

      currentPos = m.end;
    }

    if (currentPos < line.length) {
      children.add(TextSpan(text: line.substring(currentPos)));
    }

    return TextSpan(
      children: children.isEmpty ? [TextSpan(text: line)] : children,
      style: normalStyle,
    );
  }
}
