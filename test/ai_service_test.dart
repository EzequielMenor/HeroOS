import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:heroos/domain/services/ai_service.dart';

void main() {
  group('AiService - fetchAvailableModels', () {
    test('devuelve lista de modelos correctamente con respuesta 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/models'));
        expect(request.headers['Authorization'], 'Bearer test-key');

        final responseMap = {
          'data': [
            {'id': 'gpt-4o'},
            {'id': 'gpt-3.5-turbo'},
          ]
        };
        return http.Response(jsonEncode(responseMap), 200);
      });

      final aiService = AiService();
      final models = await aiService.fetchAvailableModels(
        endpoint: 'https://api.openai.com/v1/chat/completions',
        apiKey: 'test-key',
        client: mockClient,
      );

      expect(models, containsAll(['gpt-4o', 'gpt-3.5-turbo']));
    });

    test('lanza excepcion cuando el status code no es 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Error de credenciales', 401);
      });

      final aiService = AiService();
      expect(
        () => aiService.fetchAvailableModels(
          endpoint: 'https://api.openai.com/v1/chat/completions',
          apiKey: 'invalid-key',
          client: mockClient,
        ),
        throwsException,
      );
    });
  });
}
