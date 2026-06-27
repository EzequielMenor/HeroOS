import '../utils/syntax_patterns.dart';

enum InputCategory { note, task, finance }

class ParsedInput {
  final InputCategory category;
  final String cleanText;
  final double? amount;
  final bool isIncome;
  final DateTime? date;
  final List<String> tags;
  final String? project;

  ParsedInput({
    required this.category,
    required this.cleanText,
    this.amount,
    this.isIncome = false,
    this.date,
    this.tags = const [],
    this.project,
  });
}

class InputParserService {
  static InputCategory determineCategory(String text) {
    if (text.isEmpty) return InputCategory.note;
    if (SyntaxPatterns.financePrefix.hasMatch(text))
      return InputCategory.finance;
    if (SyntaxPatterns.taskPrefix.hasMatch(text)) return InputCategory.task;
    return InputCategory.note;
  }

  static ParsedInput parse(String text) {
    if (text.isEmpty) {
      return ParsedInput(category: InputCategory.note, cleanText: '');
    }

    final category = determineCategory(text);
    String cleanText = text;
    double? amount;
    bool isIncome = false;
    DateTime? date;
    List<String> tags = [];
    String? project;

    // Extract tags
    final tagMatches = SyntaxPatterns.tags.allMatches(cleanText);
    for (final match in tagMatches) {
      tags.add(match.group(0)!.substring(1)); // remove #
    }
    cleanText = cleanText.replaceAll(SyntaxPatterns.tags, '');

    // Extract project/mentions
    final mentionMatches = SyntaxPatterns.mentions.allMatches(cleanText);
    if (mentionMatches.isNotEmpty) {
      project = mentionMatches.first.group(0)!.substring(1); // remove @
      cleanText = cleanText.replaceAll(SyntaxPatterns.mentions, '');
    }

    // Extract dates
    final dateMatches = SyntaxPatterns.dateCommands.allMatches(cleanText);
    if (dateMatches.isNotEmpty) {
      final cmd = dateMatches.first.group(0)!.substring(1).toLowerCase();
      cleanText = cleanText.replaceAll(SyntaxPatterns.dateCommands, '');
      final now = DateTime.now();
      if (cmd == 'hoy') {
        date = now;
      }
      if (cmd == 'mañana') {
        date = now.add(const Duration(days: 1));
      }
      // Basic implementation for others...
    }

    // Process specific categories
    if (category == InputCategory.finance) {
      final match = SyntaxPatterns.financePrefix.firstMatch(cleanText);
      if (match != null) {
        final rawAmountStr = match.group(1)!;
        cleanText = cleanText.replaceFirst(rawAmountStr, '');

        // Determine income/expense and parse number
        if (rawAmountStr.contains('+')) {
          isIncome = true;
        } else if (!rawAmountStr.contains('-')) {
          // If no sign, assume expense for simplicity or maybe check logic
          isIncome = false;
        }

        final numStr = rawAmountStr.replaceAll(RegExp(r'[^0-9.]'), '');
        if (numStr.isNotEmpty) {
          amount = double.tryParse(numStr);
        }
      }
    } else if (category == InputCategory.task) {
      final match = SyntaxPatterns.taskPrefix.firstMatch(cleanText);
      if (match != null) {
        cleanText = cleanText.replaceFirst(match.group(0)!, '');
      }
    }

    return ParsedInput(
      category: category,
      cleanText: cleanText.trim().replaceAll(
        RegExp(r'\\s+'),
        ' ',
      ), // cleanup extra spaces
      amount: amount,
      isIncome: isIncome,
      date: date,
      tags: tags,
      project: project,
    );
  }
}
