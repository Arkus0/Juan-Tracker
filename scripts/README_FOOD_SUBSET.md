# Open Food Facts - Spain/Europe Subset Creator

Script Python para crear un subset masivo de productos de Open Food Facts enfocado en España y países vecinos con productos comunes en supermercados españoles.

## 🎯 Objetivo: Offline-First

Este subset está diseñado para aplicaciones de nutrición que funcionan principalmente **sin conexión a internet**, minimizando las llamadas a APIs externas.

## 📊 Resultados Generados

| Archivo | Tamaño | Descripción |
|---------|--------|-------------|
| `spain_subset.jsonl` | ~206 MB | JSONL sin comprimir (600K productos) |
| `spain_subset.jsonl.gz` | **23.6 MB** | JSONL comprimido con gzip |

## 📈 Estadísticas del Subset (600,000 productos)

| Métrica | Valor | % |
|---------|-------|---|
| **Total productos** | 600,000 | 100% |
| Con Nutri-Score | 523,867 | **87.3%** |
| Con marca | 579,287 | **96.5%** |
| Con calorías (kcal) | 572,687 | **95.4%** |
| Con proteínas | 579,348 | **96.6%** |
| Con carbohidratos | 578,860 | **96.5%** |
| Con grasas | 578,656 | **96.4%** |

### Cobertura Geográfica
- **España** (productos con `countries_tags` = Spain/España)
- **Portugal** (productos que se venden en España)
- **Francia** (marcas comunes: Danone, Nestlé, etc.)
- **Italia** (pasta, pizza, productos mediterráneos)
- **Alemania** (marcas de supermercado tipo Lidl)
- **Bélgica/Holanda** (chocolates, cervezas)

## 💾 Uso de Espacio

- **Usado**: 23.6 MB de 50 MB posibles (47%)
- **Margen disponible**: 26.4 MB
- **Potencial de ampliación**: ~700K productos adicionales si fuera necesario

## 🚀 Instrucciones de Uso

### 1. Instalar dependencias

```bash
pip install duckdb requests tqdm pandas numpy
```

### 2. Ejecutar el script

```bash
cd scripts
python create_spain_food_subset.py
```

### 3. Seguir las instrucciones interactivas

El script:
1. Descarga automáticamente el dump de Open Food Facts (~1.1 GB)
2. Filtra productos relevantes para España y países vecinos
3. Prioriza por completitud de datos (Nutri-Score, valores nutricionales)
4. Exporta a JSONL con campos limpios
5. Comprime automáticamente con gzip

### 4. Archivos generados

Los archivos se guardan en el mismo directorio del script:
- `spain_subset.jsonl` - JSONL sin comprimir (~206 MB)
- `spain_subset.jsonl.gz` - JSONL comprimido (**23.6 MB**) ← Usar este

## 📋 Estructura del JSON

```json
{
  "code": "8410376040452",
  "name": "Leche entera Hacendado",
  "brands": "Hacendado",
  "generic_name": null,
  "nutriscore": "b",
  "nutriments": {
    "energy_kcal": 64.0,
    "proteins": 3.2,
    "carbohydrates": 4.8,
    "fat": 3.6,
    "fiber": null,
    "sugars": 4.8
  },
  "categories": ["dairies", "milks", "cow milks"]
}
```

## 🏪 Categorías Incluidas (Ampliado para Offline-First)

### Alimentación Básica
- **Lácteos**: leche, yogur, queso, mantequilla, nata
- **Carnes**: ternera, cerdo, pollo, jamón, embutidos
- **Pescados**: atún, salmón, sardina, bacalao, marisco
- **Frutas y verduras**: frescas, congeladas, en conserva
- **Cereales**: pan, pasta, arroz, harina, avena
- **Legumbres**: judías, lentejas, garbanzos, guisantes

### Bebidas
- **No alcohólicas**: agua, zumos, refrescos, café, té, isotónicas
- **Alcohólicas**: vino, cerveza, licores, whisky, vodka, anís

### Snacks y Dulces
- Galletas, crackers, cereales de desayuno
- Chocolates, caramelos, chicles
- Pastelería: pasteles, tartas, bizcochos, magdalenas
- Helados y postres congelados

### Otros
- Aceites (oliva, girasol), mantequilla, margarina
- Salsas: kétchup, mayonesa, mostaza
- Conservas: aceitunas, encurtidos
- Comida preparada y platos precocinados
- Suplementos deportivos y nutrición deportiva
- Alimentación infantil

## 🏷️ Marcas Cubiertas

### Marcas Españolas
- **Supermercados**: Hacendado, Mercadona, DIA, Lidl, Alcampo, Eroski, Consum, Carrefour, Aldi, Caprabo, Más y Más
- **Lácteos**: Danone, Activia, Pascual, Central Lechera Asturiana, Feiraco
- **Bebidas**: Mahou, Estrella Damm, San Miguel, Cruzcampo
- **Embutidos**: El Pozo, Campofrío, Navidul
- **Chocolates**: Valor, Chiquilín, ColaCao, Nesquik
- **Panadería**: Bimbo, Panrico, Artiach, Cuétara

### Marcas Europeas Comunes
- **Chocolates**: Milka, Nutella, Ferrero, Kinder, Lindt
- **Snacks**: Lay's, Pringles, Doritos, Cheetos
- **Bebidas**: Coca-Cola, Pepsi, Red Bull, Monster
- **Cereales**: Kellogg's, Special K
- **Café**: Nescafé, Nespresso, Dolce Gusto
- **Suplementos**: Prozis, MyProtein, Optimum Nutrition

## 🔍 Integración en Flutter (Juan Tracker)

### Flujo Offline-First Recomendado

```
1. Búsqueda local (Drift/Hive) → Prioridad #1
   └── Si encuentra → Mostrar inmediatamente
   └── Si NO encuentra → Opciones:
       ├── Añadir manual (offline)
       ├── Dictar con voz (offline)
       ├── Escanear etiqueta OCR (offline)
       └── Escanear barcode → Única llamada online
```

### Cobertura Esperada con 600K Productos

| Escenario | Cobertura |
|-----------|-----------|
| Productos de supermercado español común | ~95% |
| Marcas internacionales populares | ~90% |
| Productos de países vecinos | ~85% |
| Productos gourmet/especializados | ~60% |
| Productos locales artesanales | ~30% |

**Resultado**: La mayoría de usuarios rara vez necesitarán conexión a internet.

## 📦 Notas Técnicas

- El CSV original (~1.1 GB) puede eliminarse tras el procesamiento
- El script detecta si ya existe el CSV y pregunta si reutilizarlo
- Los valores `null` indican datos no disponibles (diferente de cero)
- El formato JSONL permite lectura lineal eficiente (streaming)
- La compresión gzip reduce el tamaño ~88% manteniendo compatibilidad

## 🔮 Futuras Ampliaciones

Si en el futuro se necesita más cobertura:
- Ampliar a productos de UK, Suiza, Austria
- Incluir más categorías: cosmética, higiene, productos para mascotas
- Target potencial: ~1,000,000 productos en ~40 MB
