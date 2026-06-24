import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// AI classification types for quick capture routing.
enum AiClassification { gasto, tarea, habito, nota }

/// Service for AI text classification.
/// Uses OpenAI or Gemini API based on user profile setting.
/// System prompt embedded in code (NOT in Supabase config).
/// API key stored in shared_preferences (NOT Supabase).
class AiService {
  static const String _systemPrompt = '''
Eres un asistente que clasifica texto en exactamente una de estas 4 categorías:
- GASTO: gastos, compras, pagos, transacciones financieras
- TAREA: tareas, pendientes, quehaceres, obligaciones
- HABITO: hábitos, rutinas, comportamiento repetitivo
- NOTA: pensamientos, ideas, notas, información general

Responde SOLO con JSON válido: {"type":"CATEGORIA","confidence":0.0} donde confidence es un número entre 0.0 y 1.0.
No escribas nada más, solo el JSON.
''';

  /// Clasifica el texto usando la API de IA configurada.
  /// Retorna (type, confidence) tuple con confidence 0.0 si falla el parse.
  Future<(AiClassification, double)> classify(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('ai_api_key');
    final provider = prefs.getString('ai_provider') ?? 'openai';

    if (apiKey == null || apiKey.isEmpty) {
      return (AiClassification.nota, 0.0);
    }

    try {
      final body = jsonEncode({
        'model': provider == 'gemini' ? 'gemini-pro' : 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': text},
        ],
        'max_tokens': 50,
        'temperature': 0.0,
      });

      final uri = provider == 'gemini'
          ? Uri.parse('https://api.gemini.com/v1/chat/completions')
          : Uri.parse('https://api.openai.com/v1/chat/completions');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return (AiClassification.nota, 0.0);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final content = json['choices']?[0]?['message']?['content'] as String? ?? '';
      return _parseResponse(content);
    } catch (_) {
      return (AiClassification.nota, 0.0);
    }
  }

  (AiClassification, double) _parseResponse(String content) {
    try {
      // Extraer JSON del contenido (por si hay texto extra)
      final jsonStr = RegExp(r'\{.*\}').firstMatch(content)?.group(0) ?? content;
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final typeStr = (json['type'] as String? ?? 'NOTA').toUpperCase();
      final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;

      final type = switch (typeStr) {
        'GASTO' => AiClassification.gasto,
        'TAREA' => AiClassification.tarea,
        'HABITO' => AiClassification.habito,
        _ => AiClassification.nota,
      };

      return (type, confidence.clamp(0.0, 1.0));
    } catch (_) {
      return (AiClassification.nota, 0.0);
    }
  }
}
