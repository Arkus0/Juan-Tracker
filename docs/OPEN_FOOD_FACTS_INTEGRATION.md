# Integración Open Food Facts

## Resumen

Se ha integrado la búsqueda de alimentos externos usando **Open Food Facts** (OFF), una base de datos libre con más de 3 millones de productos alimenticios de todo el mundo.

## Características

### Funcionalidades Implementadas

1. **Búsqueda por texto**
   - Búsqueda con debounce (500ms) para no spamear la API
   - Normalización de queries (case-insensitive)
   - Paginación de resultados

2. **Búsqueda por voz**
   - Integración con `speech_to_text`
   - Soporte para español (`es_ES`)
   - Timeout de 10 segundos

3. **Escaneo de código de barras**
   - Búsqueda por EAN-13
   - Fallback a cache si no hay conexión

4. **Modo Offline Completo**
   - Cache de términos de búsqueda (TTL: 7 días)
   - Cache de alimentos guardados (persistente)
   - Búsqueda local cuando no hay red

## Arquitectura

### Modelos

```
lib/diet/models/open_food_facts_model.dart
├── OpenFoodFactsResult        # Producto individual
│   ├── Normalización de campos nutricionales
│   ├── Fallback de kcal desde kJ
│   └── Serialización para cache
└── OpenFoodFactsSearchResponse # Respuesta de búsqueda
```

### Servicios

```
lib/diet/services/
├── open_food_facts_service.dart  # Cliente HTTP
│   ├── Timeout: 10s
│   ├── Rate limiting: 60 req/min
│   └── User-Agent personalizado
└── food_cache_service.dart       # Cache local
    ├── SharedPreferences (términos, alimentos)
    └── File system (imágenes)
```

### Providers

```
lib/diet/providers/external_food_search_provider.dart
├── ExternalFoodSearchNotifier (Riverpod 3)
│   ├── Estados: idle/loading/success/error/offline/empty
│   ├── Búsqueda online con fallback offline
│   └── Guardado a biblioteca local
└── Providers de servicios
```

### UI

```
lib/features/diary/presentation/
├── external_food_search_screen.dart  # Pantalla principal
│   ├── Barra de búsqueda con voz/barcode
│   ├── Estados: loading/error/offline/empty
│   ├── Lista de resultados con imágenes
│   └── Diálogo de confirmación para guardar
└── food_search_screen.dart           # Integración
    └── Botón "Buscar Online" añadido
```

## Flujo de Uso

### Online

1. Usuario va a Diario → Añadir Alimento → Buscar Online
2. Escribe/pide por voz/escanea código
3. Se muestran resultados de Open Food Facts
4. Al seleccionar, se guarda en biblioteca local
5. El alimento está disponible para uso inmediato y futuro offline

### Offline

1. Si no hay conexión, se muestra indicador visual
2. La búsqueda se realiza en cache local
3. Si no hay resultados, mensaje informativo
4. Los alimentos previamente guardados siguen funcionando

## API Open Food Facts

- **URL Base**: `https://world.openfoodfacts.org/api/v2`
- **Endpoints**:
  - `GET /search` - Búsqueda por texto
  - `GET /product/{barcode}` - Búsqueda por código
- **Campos solicitados**: code, product_name, brands, image_url, nutriments, serving_size
- **Rate Limit**: 60 peticiones/minuto (conservador)

## Criterios de Aceptación Verificados

✅ **Sin internet, la app funciona igual con biblioteca local**
- Cache persistente de alimentos guardados
- Búsqueda offline en resultados previos
- UI indica modo offline claramente

✅ **Con internet, puedo buscar y guardar 3 alimentos y luego usarlos offline**
- Al guardar, se persisten en SharedPreferences
- Disponibles inmediatamente en búsquedas offline
- Imágenes cacheadas localmente

## Permisos Android

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## Tests

```bash
# Tests específicos del feature
flutter test test/diet/services/open_food_facts_service_test.dart
flutter test test/diet/services/food_cache_service_test.dart

# Todos los tests
flutter test  # 171 tests pasando
```

## Dependencias Agregadas

```yaml
dependencies:
  http: ^1.3.0           # Cliente HTTP
  connectivity_plus: ^6.1.3  # Estado de red
```

## Notas de Implementación

1. **Normalización de datos**: La API de OFF tiene datos inconsistentes. Se implementaron múltiples estrategias de fallback para extraer kcal (energy-kcal_100g → energy_100g → energy-kj_100g).

2. **Rate Limiting**: Implementación propia con ventana deslizante para evitar bloqueos por parte de OFF.

3. **User-Agent**: Identificación personalizada requerida por OFF para uso de la API.

4. **Imágenes**: Las imágenes se descargan bajo demanda y se cachean en disco para uso offline.

## Futuras Mejoras

- [ ] Soporte para múltiples idiomas en búsqueda
- [ ] Filtros por país/idioma del producto
- [ ] Historial de alimentos consumidos frecuentemente
- [ ] Sincronización de cache entre dispositivos
