import 'package:flutter/material.dart';
import '../../core/utils/syntax_patterns.dart';
import '../../core/theme/app_colors.dart';

class UniversalSyntaxController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<InlineSpan> children = [];
    final textStr = text;

    if (textStr.isEmpty) {
      return TextSpan(style: style, text: '');
    }

    // We use a simple tokenization or regex splitting approach for highlighting
    // To ensure perfect O(n) rendering, we could iterate through matches,
    // but a combined RegExp is easiest to find all highlighted tokens.

    // Combine all highlighting patterns
    final combinedPattern = RegExp(
      '(${SyntaxPatterns.taskPrefix.pattern})|'
      '(${SyntaxPatterns.financePrefix.pattern})|'
      '(${SyntaxPatterns.tags.pattern})|'
      '(${SyntaxPatterns.mentions.pattern})|'
      '(${SyntaxPatterns.dateCommands.pattern})',
    );

    int lastMatchEnd = 0;
    for (final match in combinedPattern.allMatches(textStr)) {
      // Add plain text before the match
      if (match.start > lastMatchEnd) {
        children.add(
          TextSpan(
            text: textStr.substring(lastMatchEnd, match.start),
            style: style,
          ),
        );
      }

      final matchedStr = match.group(0)!;
      TextStyle highlightStyle = style ?? const TextStyle();

      if (SyntaxPatterns.financePrefix.hasMatch(matchedStr) &&
          match.start == 0) {
        highlightStyle = highlightStyle.copyWith(
          color: AppColors.finance,
          fontWeight: FontWeight.bold,
        );
      } else if (SyntaxPatterns.taskPrefix.hasMatch(matchedStr) &&
          match.start == 0) {
        highlightStyle = highlightStyle.copyWith(
          color: AppColors.tasks,
          fontWeight: FontWeight.bold,
        );
      } else if (SyntaxPatterns.tags.hasMatch(matchedStr)) {
        highlightStyle = highlightStyle.copyWith(
          color: AppColors.habits,
          fontWeight: FontWeight.w600,
        );
      } else if (SyntaxPatterns.mentions.hasMatch(matchedStr)) {
        highlightStyle = highlightStyle.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        );
      } else if (SyntaxPatterns.dateCommands.hasMatch(matchedStr)) {
        highlightStyle = highlightStyle.copyWith(
          color: AppColors.sleep,
          fontWeight: FontWeight.w600,
        );
      }

      children.add(TextSpan(text: matchedStr, style: highlightStyle));
      lastMatchEnd = match.end;
    }

    // Add remaining plain text
    if (lastMatchEnd < textStr.length) {
      children.add(
        TextSpan(text: textStr.substring(lastMatchEnd), style: style),
      );
    }

    return TextSpan(style: style, children: children);
  }
}
