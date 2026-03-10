import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/secrets.dart';
import '../../domain/entities/sleep_log_entity.dart';
import '../../domain/services/sleep_diagnosis_service.dart';

/// Llama a Groq (100% gratis) para analizar un registro de sueño.
/// Crea tu API key gratis en: https://console.groq.com/keys
class OpenRouterService {
  static const String _apiKey = Secrets.groqApiKey;
  static const String _model = 'llama-3.1-8b-instant';
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Devuelve un [SleepDiagnosis] generado por IA con análisis estructurado.
  static Future<SleepDiagnosis> analyzeSleep(SleepLogEntity log) async {
    final prompt = _buildPrompt(log);

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {
                'role': 'system',
                'content':
                    'Eres un experto en medicina del sueño. '
                    'Responde ÚNICAMENTE con un objeto JSON válido, sin texto adicional, '
                    'con estas claves exactas en español:\n'
                    '- "title": titular breve y descriptivo (máx 8 palabras)\n'
                    '- "physicalAnalysis": análisis de recuperación física (2-3 frases)\n'
                    '- "mentalAnalysis": análisis de recuperación mental y cognitiva (2-3 frases)\n'
                    '- "reason": explicación científica breve de por qué el sueño fue así (1-2 frases)\n'
                    '- "advice": consejo concreto y motivador para hoy (1 frase)\n'
                    'Sé directo, claro y motivador. No uses markdown dentro de los valores.',
              },
              {'role': 'user', 'content': prompt},
            ],
            'response_format': {'type': 'json_object'},
            'max_tokens': 600,
            'temperature': 0.7,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        data['choices']?[0]?['message']?['content'] as String? ?? '';
    if (content.isEmpty) throw Exception('Respuesta vacía de la IA');

    final json = jsonDecode(content) as Map<String, dynamic>;
    return SleepDiagnosis(
      title: (json['title'] as String?) ?? 'Análisis de tu noche',
      physicalAnalysis: (json['physicalAnalysis'] as String?) ?? '',
      mentalAnalysis: (json['mentalAnalysis'] as String?) ?? '',
      reason: (json['reason'] as String?) ?? '',
      advice: (json['advice'] as String?) ?? '',
    );
  }

  static String _buildPrompt(SleepLogEntity log) {
    final buffer = StringBuffer();
    buffer.writeln('Datos de mi noche:');
    buffer.writeln('- Horas totales: ${log.totalHours.toStringAsFixed(1)}h');
    if (log.deepSleepPct != null) {
      buffer.writeln('- Sueño profundo: ${log.deepSleepPct}%');
    }
    if (log.remSleepPct != null) {
      buffer.writeln('- Sueño REM: ${log.remSleepPct}%');
    }
    if (log.lightSleepPct != null) {
      buffer.writeln('- Sueño ligero: ${log.lightSleepPct}%');
    }
    if (log.avgHeartRate != null) {
      buffer.writeln('- Frecuencia cardíaca media: ${log.avgHeartRate} lpm');
    }
    if (log.qualityRating != null) {
      buffer.writeln('- Calidad subjetiva: ${log.qualityRating}/5');
    }
    if (log.notes != null && log.notes!.isNotEmpty) {
      buffer.writeln('- Notas: ${log.notes}');
    }
    buffer.writeln('\nAnaliza estos datos en detalle.');
    return buffer.toString();
  }
}
