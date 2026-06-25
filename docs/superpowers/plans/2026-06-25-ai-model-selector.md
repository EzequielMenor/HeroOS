# Selector de Modelos e Integración IA Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar un botón de validación de credenciales de IA en el perfil que, al ser exitoso, reemplace el campo de texto manual de modelos por un selector desplegable con los modelos reales del proveedor.

**Architecture:** Añadiremos el método de red en el servicio `AiService` para validar credenciales y listar modelos, mientras que en la UI de `ProfileScreen` manejaremos el estado local para alternar entre el selector desplegable y la caja de texto manual de fallback.

**Tech Stack:** Flutter, Dart, SharedPreferences, http package

## Global Constraints

- Estética Zen OS: paleta de grises, minimalismo, sin bordes gruesos ni sombras.
- Resiliencia: si falla la llamada a `/models`, permitir al usuario usar el campo de texto manual.
- Convención de commits: Conventional Commits, sin autorías de IA.

---

### Task 1: Lógica de red para obtener modelos en `AiService`

**Files:**
- Modify: `lib/domain/services/ai_service.dart`
- Create: `test/ai_service_test.dart`

**Interfaces:**
- Produces: `Future<List<String>> fetchAvailableModels({required String endpoint, required String apiKey, http.Client? client})` en `AiService`.

- [ ] **Step 1: Crear archivo de pruebas para verificar la obtención de modelos**

Escribir la prueba unitaria mockeando la llamada HTTP utilizando `package:http/testing.dart`.

Crear `test/ai_service_test.dart`:
```dart
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
```

- [ ] **Step 2: Ejecutar la prueba para verificar que falla**

Ejecutar en la terminal:
Run: `flutter test test/ai_service_test.dart`
Expected: FALLA con un error indicando que `fetchAvailableModels` no está definido en `AiService`.

- [ ] **Step 3: Implementar `fetchAvailableModels` en `AiService`**

Modificar `lib/domain/services/ai_service.dart` añadiendo el método:
```dart
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

    // Transformar a endpoint de modelos
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
```

- [ ] **Step 4: Ejecutar la prueba para verificar que pasa**

Ejecutar en la terminal:
Run: `flutter test test/ai_service_test.dart`
Expected: PASA con éxito.

- [ ] **Step 5: Confirmar que todo el suite de pruebas pasa**

Ejecutar en la terminal:
Run: `flutter test`
Expected: PASA con éxito.

- [ ] **Step 6: Commitear los cambios**

Ejecutar en la terminal:
```bash
git add lib/domain/services/ai_service.dart test/ai_service_test.dart
git commit -m "feat: add fetchAvailableModels and tests to AiService"
```

---

### Task 2: Modificar la interfaz de usuario en `ProfileScreen`

**Files:**
- Modify: `lib/presentation/screens/profile_screen.dart`

**Interfaces:**
- Consumes: `fetchAvailableModels` de `AiService`.

- [ ] **Step 1: Añadir variables de estado e inicialización**

Modificar `lib/presentation/screens/profile_screen.dart` para declarar variables de estado en `_ProfileScreenState`:
```dart
  List<String> _availableModels = [];
  bool _isValidating = false;
  String? _errorMessage;
  String? _selectedModel;
```

Actualizar `_loadAiConfig` para cargar el modelo preseleccionado:
```dart
  Future<void> _loadAiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('ai_api_key') ?? '';
      _endpointController.text = prefs.getString('ai_endpoint') ?? '';
      _modelController.text = prefs.getString('ai_model') ?? '';
      _selectedModel = _modelController.text.isNotEmpty ? _modelController.text : null;
    });
  }
```

- [ ] **Step 2: Implementar la función de validación en la UI**

Añadir la función `_validateAndLoadModels` en `_ProfileScreenState`:
```dart
  Future<void> _validateAndLoadModels() async {
    if (_apiKeyController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, introduce una API Key';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final aiService = AiService();
      final models = await aiService.fetchAvailableModels(
        endpoint: _endpointController.text,
        apiKey: _apiKeyController.text,
      );

      setState(() {
        _availableModels = models;
        if (models.isNotEmpty) {
          // Si el modelo actual está en la lista obtenida, mantenerlo. Si no, preseleccionar el primero.
          if (!models.contains(_selectedModel)) {
            _selectedModel = models.first;
            _modelController.text = models.first;
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Credenciales válidas. Modelos cargados.'),
            backgroundColor: _kAccent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al validar: ${e.toString().replaceAll('Exception: ', '')}';
        _availableModels = [];
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }
```

- [ ] **Step 3: Modificar la UI de Configuración IA**

Actualizar el método `_buildAiConfigSection` para incluir el botón de verificación, mostrar errores y pintar el dropdown si hay modelos disponibles.

Reemplazar `_buildAiConfigSection` con:
```dart
  Widget _buildAiConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('ENDPOINT'),
        SizedBox(height: 8),
        _buildUnderlineInput(
          controller: _endpointController,
          hint: 'Ej: https://api.openai.com/v1/chat/completions',
        ),
        SizedBox(height: 16),
        _buildFieldLabel('API KEY'),
        SizedBox(height: 8),
        _buildUnderlineInput(
          controller: _apiKeyController,
          hint: 'sk-…',
          obscureText: true,
        ),
        SizedBox(height: 16),
        if (_isValidating)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'VALIDANDO CREDENCIALES...',
                  style: TextStyle(color: _kTextSecondary, fontSize: 9, letterSpacing: 1.0),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _kDivider),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: _validateAndLoadModels,
              child: Text(
                'VERIFICAR CREDENCIALES',
                style: TextStyle(color: _kTextPrimary, fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        if (_errorMessage != null) ...[
          SizedBox(height: 8),
          Text(
            _errorMessage!.toUpperCase(),
            style: TextStyle(color: _kDanger, fontSize: 9, letterSpacing: 0.5),
          ),
        ],
        SizedBox(height: 24),
        _buildFieldLabel('MODELO'),
        SizedBox(height: 8),
        if (_availableModels.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _availableModels.contains(_selectedModel) ? _selectedModel : _availableModels.first,
            dropdownColor: _kBg,
            style: TextStyle(color: _kTextPrimary, fontSize: 14),
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _kDivider),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _kAccent),
              ),
              contentPadding: EdgeInsets.only(bottom: 8),
            ),
            items: _availableModels.map((String model) {
              return DropdownMenuItem<String>(
                value: model,
                child: Text(model, style: TextStyle(color: _kTextPrimary, fontSize: 13)),
              );
            }).toList(),
            onChanged: (String? value) {
              setState(() {
                _selectedModel = value;
                if (value != null) {
                  _modelController.text = value;
                }
              });
            },
          )
        else
          _buildUnderlineInput(
            controller: _modelController,
            hint: 'Ej: gpt-3.5-turbo, llama-3',
          ),
        SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.textPrimary,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: _saveAiConfig,
            child: Text(
              'GUARDAR',
              style: TextStyle(fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 4: Ejecutar pruebas unitarias para verificar la UI**

Ejecutar en la terminal:
Run: `flutter test`
Expected: PASA con éxito (sin roturas).

- [ ] **Step 5: Commitear los cambios**

Ejecutar en la terminal:
```bash
git add lib/presentation/screens/profile_screen.dart
git commit -m "feat: integrate API validation and dynamic models dropdown in ProfileScreen"
```
