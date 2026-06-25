import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum AiClassification { gasto, tarea, habito, nota }

class AiExtractionResult {
  final AiClassification type;
  final double confidence;
  final String title;
  final double amount;
  final String category;
  final bool isIncome;
  final DateTime? dueDate;
  final List<String> tags;

  AiExtractionResult({
    required this.type,
    required this.confidence,
    this.title = '',
    this.amount = 0.0,
    this.category = 'Varios',
    this.isIncome = false,
    this.dueDate,
    this.tags = const [],
  });
}

class AiService {
  static final String _systemPrompt = '''
Eres un asistente experto en productividad que extrae información estructurada de lenguaje natural.
Clasifica el texto en exactamente una de estas 4 categorías:
- GASTO: transacciones financieras, gastos, ingresos, pagos.
- TAREA: tareas, misiones, pendientes, recordatorios.
- HABITO: rutinas, comportamientos repetitivos.
- NOTA: pensamientos, ideas, descripciones largas, cualquier otra cosa.

DEBES responder SOLO con un JSON válido usando estrictamente esta estructura:
{
  "type": "GASTO|TAREA|HABITO|NOTA",
  "confidence": 0.95,
  "title": "Un título corto y descriptivo de la nota o tarea (máximo 6 palabras)",
  "amount": 15.50, // Si es GASTO, pon la cantidad numérica
  "category": "Comida", // Si es GASTO, pon una categoría corta
  "isIncome": false, // true si es un ingreso, false si es gasto
  "dueDate": "2026-06-25T00:00:00Z", // Si es TAREA y hay fecha, en ISO8601. Si no hay, null
  "tags": ["ocio", "ideas"] // Array de etiquetas inferidas
}

NO escribas código markdown, NO escribas explicaciones. SOLO EL JSON.
''';

  Future<AiExtractionResult> classify(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('ai_api_key');
    final endpoint = prefs.getString('ai_endpoint');
    final aiModel = prefs.getString('ai_model');

    if (apiKey == null || apiKey.isEmpty) {
      return _fallback(text);
    }

    try {
      final body = jsonEncode({
        'model': (aiModel != null && aiModel.trim().isNotEmpty) ? aiModel.trim() : 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': text},
        ],
        'temperature': 0.0,
      });

      String uriStr = (endpoint != null && endpoint.trim().isNotEmpty)
          ? endpoint.trim()
          : 'https://api.openai.com/v1/chat/completions';
          
      // Auto-fix common mistakes where the user puts the base URL but forgets the path
      if (!uriStr.endsWith('/chat/completions') && !uriStr.contains('generativelanguage')) {
        if (uriStr.endsWith('/')) {
          uriStr += 'chat/completions';
        } else {
          uriStr += '/chat/completions';
        }
      }
      final uri = Uri.parse(uriStr);

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('AiService Error: Status ${response.statusCode}, Body: ${response.body}');
        return _fallback(text);
      }

      final jsonResp = jsonDecode(response.body) as Map<String, dynamic>;
      final content = jsonResp['choices']?[0]?['message']?['content'] as String? ?? '';
      print('AiService Response: $content');
      return _parseResponse(content, text);
    } catch (e) {
      print('AiService Exception: $e');
      return _fallback(text);
    }
  }

  AiExtractionResult _fallback(String text) {
    return AiExtractionResult(
      type: AiClassification.nota,
      confidence: 0.0,
      title: text.split('\n').first,
    );
  }

  Future<List<String>> fetchAvailableModels({
    required String endpoint,
    required String apiKey,
    http.Client? client,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('La clave de API no puede estar vacía');
    }

    String uriStr = endpoint.trim();
    if (uriStr.isEmpty) {
      uriStr = 'https://api.openai.com/v1/chat/completions';
    }

    // Derivar URL de modelos
    if (uriStr.endsWith('/chat/completions')) {
      uriStr = uriStr.replaceAll('/chat/completions', '/models');
    } else if (uriStr.endsWith('/chat/completions/')) {
      uriStr = uriStr.replaceAll('/chat/completions/', '/models');
    } else {
      uriStr = uriStr.endsWith('/') ? '${uriStr}models' : '$uriStr/models';
    }

    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.get(
        Uri.parse(uriStr),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Error del servidor (${response.statusCode}): ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = data['data'] as List<dynamic>?;
      if (dataList == null) {
        throw Exception('Formato incorrecto: falta el campo "data"');
      }

      return dataList
          .map((item) => (item as Map<String, dynamic>)['id'] as String)
          .toList();
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  AiExtractionResult _parseResponse(String content, String originalText) {
    try {
      final jsonStrMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
      final jsonStr = jsonStrMatch?.group(0) ?? content;
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      final typeStr = (json['type'] as String? ?? 'NOTA').toUpperCase();
      final type = switch (typeStr) {
        'GASTO' => AiClassification.gasto,
        'TAREA' => AiClassification.tarea,
        'HABITO' => AiClassification.habito,
        _ => AiClassification.nota,
      };

      final confidence = (json['confidence'] as num?)?.toDouble() ?? 1.0;
      final title = json['title'] as String? ?? originalText.split('\n').first;
      final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;
      final category = json['category'] as String? ?? 'Varios';
      final isIncome = json['isIncome'] as bool? ?? false;
      
      DateTime? dueDate;
      if (json['dueDate'] != null) {
        dueDate = DateTime.tryParse(json['dueDate'].toString());
      }
      
      final tags = (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

      return AiExtractionResult(
        type: type,
        confidence: confidence.clamp(0.0, 1.0),
        title: title,
        amount: amount,
        category: category,
        isIncome: isIncome,
        dueDate: dueDate,
        tags: tags,
      );
    } catch (_) {
      return _fallback(originalText);
    }
  }
}
