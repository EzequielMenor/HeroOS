class SyntaxPatterns {
  // Categorization (starts at the beginning of the string)
  static final RegExp taskPrefix = RegExp(r'^(\[\]|\*)\s');
  // Matches: -15, 15€, $15, -15.50, +20
  static final RegExp financePrefix = RegExp(r'^([+-]?\s?[$€]?\s?\d+(\.\d+)?\s?[$€]?)\s');

  // Highlights anywhere in the string
  static final RegExp tags = RegExp(r'#\w+');
  static final RegExp mentions = RegExp(r'@\w+');
  static final RegExp dateCommands = RegExp(r'/(hoy|mañana|lunes|martes|miercoles|jueves|viernes|sabado|domingo|tarde|noche)');
}
