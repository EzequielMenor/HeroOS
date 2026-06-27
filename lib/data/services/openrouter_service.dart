import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/secrets.dart';
import '../../domain/entities/sleep_log_entity.dart';
import '../../domain/services/sleep_diagnosis_service.dart';

/// Llama a la IA configurada (o Groq como fallback) para analizar un registro de sueño.
class OpenRouterService {
  static final String _defaultApiKey = Secrets.groqApiKey;
  static const String _defaultModel = 'llama-3.1-8b-instant';
  static const String _defaultEndpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Devuelve un [SleepDiagnosis] generado por la IA configurada con análisis estructurado.
  /// Si la IA falla o no hay API key, usa el diagnóstico local por reglas como fallback.
  static Future<SleepDiagnosis> analyzeSleep(SleepLogEntity log) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('ai_api_key') ?? _defaultApiKey;
    final endpoint = prefs.getString('ai_endpoint') ?? _defaultEndpoint;
    final aiModel = prefs.getString('ai_model') ?? _defaultModel;

    // Fallback local (siempre disponible para cuando la IA falla)
    final localFallback = SleepDiagnosisService.diagnose(log);
    if (localFallback == null) {
      throw Exception('No se pudo generar el diagnóstico de sueño');
    }

    // Si no hay API key, usamos el diagnóstico local directamente
    if (apiKey.isEmpty) {
      return localFallback;
    }

    http.Response? response;
    try {
      final prompt = _buildPrompt(log);
      response = await http
          .post(
            Uri.parse(
              endpoint.trim().isNotEmpty ? endpoint.trim() : _defaultEndpoint,
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': aiModel.trim().isNotEmpty
                  ? aiModel.trim()
                  : _defaultModel,
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
              'max_tokens': 600,
              'temperature': 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      // Error de red → fallback local
      return localFallback;
    }

    if (response.statusCode != 200) {
      return localFallback;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawContent =
        data['choices']?[0]?['message']?['content'] as String? ?? '';
    if (rawContent.isEmpty) {
      return localFallback;
    }

    // Intentar parsear directo; si falla, buscar bloque JSON con regex
    Map<String, dynamic>? json;
    try {
      json = jsonDecode(rawContent) as Map<String, dynamic>;
    } catch (_) {
      final match = RegExp(
        r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}',
        dotAll: true,
      ).firstMatch(rawContent);
      if (match == null) return localFallback;
      try {
        json = jsonDecode(match.group(0)!) as Map<String, dynamic>;
      } catch (_) {
        return localFallback;
      }
    }

    return SleepDiagnosis(
      title: (json!['title'] as String?) ?? 'Análisis de tu noche',
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
