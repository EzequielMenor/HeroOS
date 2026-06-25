# Especificación de Diseño: Selector de Modelos e Integración IA

Este documento detalla la implementación de la validación de credenciales de IA y la carga dinámica de modelos en el perfil de Zen OS.

## 1. Objetivos
- **Validación Rápida:** Permitir al usuario verificar si su Endpoint y API Key son correctos con un botón de validación.
- **Selector Inteligente:** Reemplazar el campo de texto manual de "MODELO" por un selector interactivo (`DropdownButtonFormField`) al validar con éxito.
- **Resiliencia (Fallback):** Si la validación falla o el proveedor no soporta la ruta estándar `/models`, permitir al usuario seguir usando la entrada de texto manual para no bloquear el uso de la app.

## 2. Cambios en el Backend/Servicio (`AiService`)

Añadiremos un método en `AiService` para realizar la verificación y obtener la lista de modelos.

### URL Derivada del Endpoint
El método transformará el endpoint de chat de completions actual:
- De: `https://api.openai.com/v1/chat/completions` o similar
- A: `https://api.openai.com/v1/models`

```dart
String _deriveModelsEndpoint(String chatEndpoint) {
  final trimmed = chatEndpoint.trim();
  if (trimmed.endsWith('/chat/completions')) {
    return trimmed.replaceAll('/chat/completions', '/models');
  }
  if (trimmed.endsWith('/chat/completions/')) {
    return trimmed.replaceAll('/chat/completions/', '/models');
  }
  return trimmed.endsWith('/') ? '${trimmed}models' : '$trimmed/models';
}
```

### Petición HTTP GET
El servicio realizará un `GET` a la URL derivada con cabeceras de autorización y parseará la respuesta:
```dart
Future<List<String>> fetchAvailableModels({
  required String endpoint,
  required String apiKey,
}) async {
  // 1. Derivar endpoint de modelos
  final modelsUrl = _deriveModelsEndpoint(endpoint);
  
  // 2. GET request
  final response = await http.get(
    Uri.parse(modelsUrl),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
  ).timeout(const Duration(seconds: 10));

  if (response.statusCode != 200) {
    throw Exception('Error del servidor (${response.statusCode}): ${response.body}');
  }

  // 3. Parsear JSON de OpenAI / Groq / OpenRouter
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final dataList = json['data'] as List<dynamic>?;
  if (dataList == null) {
    throw Exception('Formato de respuesta inválido (sin campo "data")');
  }

  return dataList
      .map((item) => (item as Map<String, dynamic>)['id'] as String)
      .toList();
}
```

## 3. Cambios en la UI (`ProfileScreen`)

### Estado Adicional en `_ProfileScreenState`
- `List<String> _availableModels = [];` - Lista de modelos recuperados.
- `bool _isValidating = false;` - Bandera para deshabilitar controles y mostrar el spinner.
- `String? _errorMessage;` - Mensaje si la validación falla.

### Flujo de Interacción
1. El usuario introduce el **Endpoint** y la **API Key**.
2. Presiona el botón **"VERIFICAR CREDENCIALES"** (debajo de API Key).
3. Se muestra un indicador de carga circular pequeño y discreto dentro del botón o al lado.
4. **Si tiene éxito:**
   - Oculta el campo de texto clásico "MODELO".
   - Muestra un `DropdownButtonFormField<String>` con la lista de modelos.
   - Si el modelo anteriormente configurado en SharedPreferences existe en la lista, se selecciona automáticamente; si no, se selecciona el primero de la lista o queda vacío.
   - Muestra un SnackBar o texto de confirmación *"Conexión exitosa. Modelos cargados."*
5. **Si falla:**
   - Muestra un mensaje de error estilizado en rojo tenue debajo del botón.
   - Mantiene el campo de texto manual de "MODELO" para permitir la configuración libre.

### Apariencia Visual (Zen OS)
Se mantendrá el diseño minimalista en escala de grises, usando `AppColors.divider`, `AppColors.textSecondary` y fuentes limpias sin bordes gruesos ni sombras.
