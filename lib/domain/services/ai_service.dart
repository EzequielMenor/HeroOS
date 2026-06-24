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
  static final String _systemPrompt = '''
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
    final endpoint = prefs.getString('ai_endpoint');
    final aiModel = prefs.getString('ai_model');

    if (apiKey == null || apiKey.isEmpty) {
      return (AiClassification.nota, 0.0);
    }

    try {
      final body = jsonEncode({
        'model': (aiModel != null && aiModel.trim().isNotEmpty) ? aiModel.trim() : 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': text},
        ],
        'max_tokens': 50,
        'temperature': 0.0,
      });

      final uriStr = (endpoint != null && endpoint.trim().isNotEmpty)
          ? endpoint.trim()
          : 'https://api.openai.com/v1/chat/completions';
      final uri = Uri.parse(uriStr);

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      ).timeout(Duration(seconds: 15));

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
