#!/usr/bin/env python3
"""
Script para crear un subset de productos de Open Food Facts enfocado en Espana.

INSTALACION DE DEPENDENCIAS:
    pip install duckdb requests tqdm pandas numpy

EJECUCION:
    python create_spain_food_subset.py

ARCHIVOS GENERADOS:
    - spain_subset.jsonl        (~100-150 MB, JSONL sin comprimir)
    - spain_subset.jsonl.gz     (~20-40 MB, JSONL comprimido con gzip)

REQUISITOS:
    - Python 3.10+
    - ~2 GB de espacio libre temporal (para el CSV de origen)
    - Conexion a Internet (para descargar el dump)

El script descarga automaticamente el dump desde:
https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz

Si el archivo ya existe localmente, preguntara si re-descargar o usar el existente.
"""

import os
import sys
import json
import gzip
import time
import math
import shutil
from pathlib import Path
from typing import Optional, List, Dict, Any
from urllib.parse import urlparse

# Dependencias externas (instalar con: pip install duckdb requests tqdm)
try:
    import duckdb
    import requests
    from tqdm import tqdm
except ImportError as e:
    print(f"Error: Falta dependencia {e.name}")
    print("Instala con: pip install duckdb requests tqdm")
    sys.exit(1)


# =============================================================================
# CONFIGURACION
# =============================================================================

# URL del dump de Open Food Facts
DUMP_URL = "https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz"

# Nombres de archivos
CSV_FILENAME = "openfoodfacts_products.csv.gz"
JSONL_FILENAME = "spain_subset.jsonl"
GZIPPED_FILENAME = "spain_subset.jsonl.gz"

# Directorio de trabajo (mismo directorio donde esta el script)
WORK_DIR = Path(__file__).parent.resolve()
CSV_PATH = WORK_DIR / CSV_FILENAME
JSONL_PATH = WORK_DIR / JSONL_FILENAME
GZIPPED_PATH = WORK_DIR / GZIPPED_FILENAME

# Marcas comunes en supermercados espanoles (espanolas + europeas)
SPANISH_BRANDS = [
    # Espanolas
    'hacendado', 'mercadona', 'dia', 'lidl', 'alcampo', 'eroski', 
    'consum', 'auchan', 'carrefour', 'aldi', 'caprabo', 'masymas',
    'el pozo', 'campofrio', 'navidul', 'gallina blanca', 'knorr',
    'mahou', 'estrella damm', 'san miguel', 'cruzcampo', 'amstel',
    'danone', 'activia', 'yogures', 'kaiku', 'pascual', 'central lechera asturiana',
    'asturiana', 'feiraco', 'ram', 'begano', 'eroski', 'bonpreu', 'bonarea',
    'condis', 'sorli', 'simply', 'froiz', 'plusfresc', 'veritas',
    'herbolario', 'guttara', 'puleva', 'nestle', 'milka', 'suchard',
    'valor', 'torras', 'chocolates', 'galletas', 'cuetara', 'fontaneda',
    'artiach', 'principe', 'oreo', 'digestive', 'maria', 'chiquilin',
    'colacao', 'nesquik', 'valor', 'elgorriaga', 'napolitana',
    'bimbo', 'panrico', 'bon preu', 'bon area', 'congelados', 'findus',
    'la sirena', 'pitusa', 'pagoda', 'elpozo', 'fripozo', 'casa tarradellas',
    'embutidos', 'revilla', 'serrano', 'sanchez alcaraz',
    # Europeas comunes en Espana
    'milka', 'nutella', 'ferrero', 'kinder', 'raffaello',
    'heinz', 'hellmanns', 'hellmann', 'kraft', 'philadelphia',
    'coca-cola', 'coca cola', 'pepsi', 'fanta', 'sprite', '7up', 'schweppes',
    'lays', 'pringles', 'doritos', 'cheetos', 'ritos', 'tostitos',
    'kelloggs', 'kellogg', 'special k', 'corn flakes', 'choco krispis',
    'nespresso', 'dolce gusto', 'tassimo', 'senseo',
    'philips', 'nescafe', 'nescafe gold',
    'haagen dazs', 'ben and jerry', 'mars', 'twix', 'snickers', 'kit kat', 'kitkat',
    'red bull', 'monster', 'burn', 'rockstar',
    'evian', 'vittel', 'perrier', 'san pellegrino',
    'johnson', 'johnson and johnson', 'nivea', 'dove', 'colgate', 'oral b',
    'prozis', 'myprotein', 'optimum nutrition', 'scitec', 'weider',
    'haribo', 'mms', 'm and m', 'skittles', 'starburst', 'jelly belly',
]

# Categorias relevantes (ampliado para maxima cobertura offline)
RELEVANT_CATEGORIES = [
    # Lacteos
    'dairies', 'milk', 'yogurt', 'cheese', 'butter', 'cream', 'dairy',
    'leche', 'yogur', 'queso', 'mantequilla', 'nata', 'lacteos',
    # Carnes
    'meat', 'beef', 'pork', 'chicken', 'poultry', 'ham', 'sausage',
    'carne', 'ternera', 'cerdo', 'pollo', 'ave', 'jamon', 'embutido',
    # Pescados
    'fish', 'seafood', 'tuna', 'salmon', 'sardine', 'cod',
    'pescado', 'marisco', 'atun', 'salmon', 'sardina', 'bacalao',
    # Frutas y verduras
    'fruit', 'vegetable', 'apple', 'orange', 'banana', 'tomato', 'potato',
    'fruta', 'verdura', 'manzana', 'naranja', 'platano', 'tomate', 'patata',
    # Cereales y pan
    'bread', 'cereal', 'pasta', 'rice', 'flour', 'wheat', 'oats',
    'pan', 'cereal', 'pasta', 'arroz', 'harina', 'trigo', 'avena',
    # Legumbres
    'legume', 'bean', 'lentil', 'chickpea', 'pea', 'soy',
    'legumbre', 'judia', 'lenteja', 'garbanzo', 'guisante', 'soja',
    # Bebidas no alcoholicas
    'beverage', 'water', 'juice', 'soft drink', 'tea', 'coffee',
    'bebida', 'agua', 'zumo', 'refresco', 'te', 'cafe', 'isotonic', 'sports drink',
    # Bebidas alcoholicas (comunes en Espana)
    'alcohol', 'wine', 'beer', 'spirit', 'liquor', 'cider',
    'vino', 'cerveza', 'licor', 'whisky', 'vodka', 'ron', 'ginebra', 'anis',
    # Conservas
    'canned', 'preserve', 'pickle', 'olive',
    'conserva', 'conservado', 'encurtido', 'aceituna',
    # Aceites y grasas
    'oil', 'olive oil', 'sunflower oil', 'margarine',
    'aceite', 'aceite de oliva', 'girasol', 'margarina',
    # Huevos
    'egg', 'huevo',
    # Otros basicos
    'sauce', 'vinegar', 'salt', 'sugar', 'honey', 'mustard', 'ketchup', 'mayonnaise',
    'salsa', 'vinagre', 'sal', 'azucar', 'miel', 'mostaza', 'ketchup', 'mayonesa',
    # Congelados
    'frozen', 'congelado', 'frozen food', 'frozen dessert', 'ice cream', 'helado',
    # Snacks y dulces (ampliado)
    'cracker', 'biscuit', 'cookie', 'galleta', 'snack', 'aperitivo', 'chocolate',
    'candy', 'sweet', 'caramel', 'golosina', 'chicle', 'chewing gum',
    'cake', 'pastry', 'tart', 'pie', 'pastel', 'tarta', 'bizcocho', 'magdalena',
    # Desayuno
    'breakfast', 'desayuno', 'cereal bar', 'energy bar', 'protein bar', 'granola', 'muesli',
    # Suplementos y deporte
    'supplement', 'protein', 'suplemento', 'proteina', 'sports nutrition', 'nutricion deportiva',
    # Comida preparada
    'ready meal', 'prepared meal', 'comida preparada', 'platos preparados', 'soup', 'sopa',
    # Infantil
    'baby food', 'infant', 'bebe', 'infantil', 'formula',
]

# Campos nutricionales que queremos extraer (con sus nombres de salida)
NUTRIMENT_FIELDS = {
    'energy-kcal_100g': 'energy_kcal',
    'proteins_100g': 'proteins',
    'carbohydrates_100g': 'carbohydrates',
    'fat_100g': 'fat',
    'fiber_100g': 'fiber',
    'sugars_100g': 'sugars',
}

# Target de productos (optimizado para offline-first)
# 189K productos = ~7.4MB, asi que 500-600K = ~20-25MB (bien bajo los 50MB limite)
TARGET_MIN_PRODUCTS = 200_000
TARGET_MAX_PRODUCTS = 600_000


# =============================================================================
# FUNCIONES DE UTILIDAD
# =============================================================================

def format_size(size_bytes: int) -> str:
    """Formatea bytes a unidades legibles."""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024
    return f"{size_bytes:.1f} TB"


def download_file(url: str, dest_path: Path, chunk_size: int = 8192) -> bool:
    """
    Descarga un archivo con barra de progreso.
    Retorna True si fue exitoso, False en caso contrario.
    """
    try:
        print(f"\n[DESCARGA] Descargando dump de Open Food Facts...")
        print(f"   URL: {url}")
        print(f"   Destino: {dest_path}")
        
        response = requests.get(url, stream=True, timeout=300)
        response.raise_for_status()
        
        total_size = int(response.headers.get('content-length', 0))
        
        with open(dest_path, 'wb') as f, tqdm(
            desc=dest_path.name,
            total=total_size,
            unit='B',
            unit_scale=True,
            unit_divisor=1024,
        ) as pbar:
            for chunk in response.iter_content(chunk_size=chunk_size):
                if chunk:
                    f.write(chunk)
                    pbar.update(len(chunk))
        
        print(f"   [OK] Descarga completada: {format_size(dest_path.stat().st_size)}")
        return True
        
    except requests.exceptions.RequestException as e:
        print(f"   [ERROR] Error de conexion: {e}")
        return False
    except Exception as e:
        print(f"   [ERROR] Error inesperado: {e}")
        return False


def check_existing_file(file_path: Path) -> bool:
    """Verifica si existe el archivo CSV y pregunta al usuario que hacer."""
    if not file_path.exists():
        return True  # No existe, necesitamos descargar
    
    size = file_path.stat().st_size
    print(f"\n[ARCHIVO] Archivo existente encontrado: {file_path.name}")
    print(f"   Tamano: {format_size(size)}")
    
    while True:
        response = input("   Usar archivo existente (u) o re-descargar (r)? [u/r]: ").strip().lower()
        if response in ['u', 'usar', '']:
            return False  # Usar existente
        elif response in ['r', 're-descargar', 'redescargar']:
            print(f"   Eliminando archivo existente...")
            file_path.unlink()
            return True  # Re-descargar
        else:
            print("   Opcion no valida. Usa 'u' para usar existente o 'r' para re-descargar.")


def create_duckdb_connection() -> duckdb.DuckDBPyConnection:
    """Crea una conexion DuckDB con configuracion optimizada."""
    conn = duckdb.connect(':memory:')
    
    # Configuracion para procesamiento eficiente
    conn.execute("SET memory_limit = '2GB'")
    conn.execute("SET threads TO 4")
    
    return conn


def build_filter_query() -> str:
    """Construye la query SQL para filtrar productos espanoles y europeos comunes en Espana."""
    
    # Condiciones para countries_tags (Espana + paises vecinos con productos comunes en Espana)
    country_conditions = [
        "countries_tags ILIKE '%spain%'",
        "countries_tags ILIKE '%espana%'",
        "countries_tags ILIKE '%es:es%'",
        "countries_tags ILIKE '%en:spain%'",
        "countries_tags ILIKE '%portugal%'",
        "countries_tags ILIKE '%france%'",
        "countries_tags ILIKE '%italy%'",
        "countries_tags ILIKE '%italia%'",
        "countries_tags ILIKE '%germany%'",
        "countries_tags ILIKE '%alemania%'",
        "countries_tags ILIKE '%belgium%'",
        "countries_tags ILIKE '%belgica%'",
        "countries_tags ILIKE '%netherlands%'",
        "countries_tags ILIKE '%holanda%'",
    ]
    
    # Condiciones para marcas espanyolas
    brand_conditions = []
    for brand in SPANISH_BRANDS:
        brand_clean = brand.replace("'", "''")  # Escapar comillas
        brand_conditions.append(f"brands_tags ILIKE '%{brand_clean}%'")
    
    # Condiciones para categorias relevantes
    category_conditions = []
    for cat in RELEVANT_CATEGORIES:
        cat_clean = cat.replace("'", "''")
        category_conditions.append(f"categories_tags ILIKE '%{cat_clean}%'")
    
    # Combinar condiciones
    country_filter = ' OR '.join(country_conditions)
    brand_filter = ' OR '.join(brand_conditions)
    category_filter = ' OR '.join(category_conditions)
    
    # Query principal: productos de Espana O marcas espanyolas (con categorias relevantes)
    query = f"""
    (
        ({country_filter})
        OR 
        ({brand_filter})
    )
    AND
    (
        categories IS NOT NULL 
        AND categories != ''
        AND ({category_filter})
    )
    AND product_name IS NOT NULL 
    AND product_name != ''
    """
    
    return query


def build_nutriments_dict(row: Dict[str, Any]) -> Dict[str, Optional[float]]:
    """Extrae los valores nutricionales del row."""
    result = {}
    
    for csv_field, output_field in NUTRIMENT_FIELDS.items():
        value = row.get(csv_field)
        if value is not None and value != '':
            try:
                float_val = float(value)
                # Verificar si es NaN (de pandas/numpy)
                if math.isnan(float_val):
                    result[output_field] = None
                else:
                    result[output_field] = float_val
            except (ValueError, TypeError):
                result[output_field] = None
        else:
            result[output_field] = None
    
    return result


def clean_categories(categories_tags: Optional[str]) -> List[str]:
    """Limpia y formatea las categorias."""
    if not categories_tags:
        return []
    
    # Las categorias vienen como: en:dairies, en:milks, es:lacteos
    categories = [cat.strip() for cat in categories_tags.split(',')]
    # Quitar el prefijo de idioma para mostrar
    cleaned = []
    for cat in categories:
        if ':' in cat:
            cleaned.append(cat.split(':', 1)[1].replace('-', ' '))
        else:
            cleaned.append(cat.replace('-', ' '))
    return cleaned[:5]  # Maximo 5 categorias


def is_valid_string(value: Any) -> bool:
    """Verifica si un valor es un string valido (no vacio, no nan)."""
    if value is None:
        return False
    s = str(value).strip()
    if not s or s.lower() == 'nan':
        return False
    return True

def get_product_name(row: Dict[str, Any]) -> str:
    """Obtiene el nombre del producto."""
    # Usar nombre principal
    name = row.get('product_name', '')
    if is_valid_string(name):
        return str(name).strip()
    
    # Fallback a generic_name
    generic = row.get('generic_name', '')
    if is_valid_string(generic):
        return str(generic).strip()
    
    return 'Producto sin nombre'


def process_and_export(conn: duckdb.DuckDBPyConnection, output_path: Path) -> int:
    """
    Procesa los datos filtrados y exporta a JSONL.
    Retorna el numero de productos exportados.
    """
    print("\n[FILTRO] Filtrando productos relevantes para Espana...")
    
    filter_query = build_filter_query()
    
    # Campos nutricionales para seleccionar
    nutriment_columns = ', '.join([f'"{col}"' for col in NUTRIMENT_FIELDS.keys()])
    
    # Query para seleccionar campos relevantes
    select_query = f"""
    SELECT 
        code,
        product_name,
        brands,
        generic_name,
        nutriscore_grade,
        categories_tags,
        countries_tags,
        brands_tags,
        {nutriment_columns}
    FROM read_csv_auto('{CSV_PATH}', 
        header=true, 
        delim='\t',
        quote='"',
        escape='"',
        nullstr='',
        ignore_errors=true
    )
    WHERE {filter_query}
    """
    
    # Ejecutar query y obtener resultados
    result = conn.execute(select_query).fetchdf()
    total_found = len(result)
    
    print(f"   Productos encontrados: {total_found:,}")
    
    # Si tenemos demasiados, aplicar priorizacion
    if total_found > TARGET_MAX_PRODUCTS:
        print(f"   Aplicando priorizacion para reducir a ~{TARGET_MAX_PRODUCTS:,} productos...")
        
        # Priorizar productos con mas datos completos
        result['completeness_score'] = (
            result['nutriscore_grade'].notna().astype(int) +
            result['energy-kcal_100g'].notna().astype(int) +
            result['categories_tags'].notna().astype(int) +
            result['brands'].notna().astype(int)
        )
        
        # Priorizar productos de Espana explicitamente
        result['spain_score'] = result['countries_tags'].str.contains('spain|espana', case=False, na=False).astype(int)
        
        # Ordenar por score y tomar los mejores
        result = result.sort_values(
            ['spain_score', 'completeness_score'], 
            ascending=[False, False]
        ).head(TARGET_MAX_PRODUCTS)
        
        result = result.drop(columns=['completeness_score', 'spain_score'])
    
    # Limitar a minimo si tenemos menos
    if total_found < TARGET_MIN_PRODUCTS:
        print(f"   [ADVERTENCIA] Solo se encontraron {total_found:,} productos (meta: {TARGET_MIN_PRODUCTS:,})")
    
    # Exportar a JSONL
    print(f"\n[EXPORT] Exportando a JSONL: {output_path.name}")
    
    count = 0
    with open(output_path, 'w', encoding='utf-8') as f:
        for _, row in tqdm(result.iterrows(), total=len(result), desc="Procesando"):
            # Construir objeto limpio
            nutriments = build_nutriments_dict(row)
            categories = clean_categories(row.get('categories_tags'))
            
            # Validar nutriscore
            nutriscore = row.get('nutriscore_grade')
            if nutriscore not in ['a', 'b', 'c', 'd', 'e']:
                nutriscore = None
            
            brands_val = row.get('brands')
            generic_val = row.get('generic_name')
            
            product = {
                'code': str(row.get('code', '')).strip(),
                'name': get_product_name(row),
                'brands': str(brands_val).strip() if is_valid_string(brands_val) else None,
                'generic_name': str(generic_val).strip() if is_valid_string(generic_val) else None,
                'nutriscore': nutriscore,
                'nutriments': nutriments,
                'categories': categories,
            }
            
            # Escribir linea JSON
            f.write(json.dumps(product, ensure_ascii=False) + '\n')
            count += 1
    
    return count


def compress_jsonl(input_path: Path, output_path: Path) -> int:
    """
    Comprime el archivo JSONL con gzip.
    Retorna el tamano del archivo comprimido en bytes.
    """
    print(f"\n[COMPRESION] Comprimiendo a gzip: {output_path.name}")
    
    with open(input_path, 'rb') as f_in:
        with gzip.open(output_path, 'wb', compresslevel=9) as f_out:
            shutil.copyfileobj(f_in, f_out)
    
    return output_path.stat().st_size


def show_statistics(jsonl_path: Path, gzipped_path: Path, count: int):
    """Muestra estadisticas finales."""
    jsonl_size = jsonl_path.stat().st_size
    gzip_size = gzipped_path.stat().st_size
    compression_ratio = (1 - gzip_size / jsonl_size) * 100
    
    print("\n" + "="*60)
    print("RESUMEN FINAL")
    print("="*60)
    print(f"   Productos exportados:    {count:,}")
    print(f"   Archivo JSONL:           {jsonl_path.name}")
    print(f"   Tamano JSONL:            {format_size(jsonl_size)}")
    print(f"   Archivo comprimido:      {gzipped_path.name}")
    print(f"   Tamano comprimido:       {format_size(gzip_size)}")
    print(f"   Ratio de compresion:     {compression_ratio:.1f}%")
    print(f"   Productos/MB (comprim):  {count / (gzip_size / 1024 / 1024):.0f}")
    print("="*60)
    
    # Verificar objetivos
    print("\n[VERIFICACION] Objetivos:")
    if TARGET_MIN_PRODUCTS <= count <= TARGET_MAX_PRODUCTS:
        print(f"   [OK] Cantidad de productos: {count:,} (objetivo: {TARGET_MIN_PRODUCTS:,}-{TARGET_MAX_PRODUCTS:,})")
    elif count < TARGET_MIN_PRODUCTS:
        print(f"   [WARN] Cantidad de productos: {count:,} (por debajo del objetivo minimo de {TARGET_MIN_PRODUCTS:,})")
    else:
        print(f"   [OK] Cantidad de productos: {count:,} (excede el objetivo maximo)")
    
    if gzip_size < 80 * 1024 * 1024:
        print(f"   [OK] Tamano comprimido: {format_size(gzip_size)} (objetivo: <80 MB)")
    else:
        print(f"   [WARN] Tamano comprimido: {format_size(gzip_size)} (excede objetivo de 80 MB)")
    
    print("\n[INFO] El archivo comprimido esta listo para usar en la app!")
    print(f"   Ubicacion: {gzipped_path}")


def cleanup(csv_path: Path, keep_csv: bool = False):
    """Limpia archivos temporales."""
    if not keep_csv and csv_path.exists():
        size = csv_path.stat().st_size
        print(f"\n[LIMPIEZA] Limpiando archivo temporal: {csv_path.name} ({format_size(size)})")
        csv_path.unlink()
        print("   Archivo temporal eliminado.")


# =============================================================================
# FUNCION PRINCIPAL
# =============================================================================

def main():
    """Funcion principal del script."""
    start_time = time.time()
    
    print("="*60)
    print("Open Food Facts - Spain Subset Creator")
    print("="*60)
    print(f"   Directorio de trabajo: {WORK_DIR}")
    print(f"   Target de productos: {TARGET_MIN_PRODUCTS:,}-{TARGET_MAX_PRODUCTS:,}")
    
    # Verificar/Descargar CSV
    need_download = check_existing_file(CSV_PATH)
    
    if need_download:
        success = download_file(DUMP_URL, CSV_PATH)
        if not success:
            print("\n[ERROR] No se pudo descargar el dump. Abortando.")
            sys.exit(1)
    else:
        print(f"\n[ARCHIVO] Usando archivo existente: {CSV_PATH.name}")
    
    # Verificar que el archivo existe
    if not CSV_PATH.exists():
        print(f"\n[ERROR] No se encuentra el archivo {CSV_PATH}")
        sys.exit(1)
    
    # Eliminar archivos de salida si existen
    for path in [JSONL_PATH, GZIPPED_PATH]:
        if path.exists():
            path.unlink()
    
    # Procesar con DuckDB
    try:
        print("\n[DUCKDB] Inicializando DuckDB...")
        conn = create_duckdb_connection()
        
        # Procesar y exportar
        count = process_and_export(conn, JSONL_PATH)
        
        if count == 0:
            print("\n[ERROR] No se encontraron productos que cumplan los criterios.")
            conn.close()
            sys.exit(1)
        
        # Cerrar conexion
        conn.close()
        
        # Comprimir
        compress_jsonl(JSONL_PATH, GZIPPED_PATH)
        
        # Mostrar estadisticas
        show_statistics(JSONL_PATH, GZIPPED_PATH, count)
        
        # Preguntar si mantener el JSONL sin comprimir
        print(f"\n[INFO] El archivo JSONL sin comprimir ocupa {format_size(JSONL_PATH.stat().st_size)}")
        response = input("   Eliminar el JSONL sin comprimir y quedarse solo con el .gz? [s/n]: ").strip().lower()
        if response in ['s', 'si', 'yes', 'y']:
            JSONL_PATH.unlink()
            print("   Archivo JSONL eliminado.")
        
        # Preguntar si mantener el CSV original
        print(f"\n[INFO] El CSV original ocupa {format_size(CSV_PATH.stat().st_size)}")
        response = input("   Eliminar el CSV original para ahorrar espacio? [s/n]: ").strip().lower()
        if response in ['s', 'si', 'yes', 'y']:
            cleanup(CSV_PATH, keep_csv=False)
        else:
            print("   CSV original conservado.")
        
    except Exception as e:
        print(f"\n[ERROR] Error durante el procesamiento: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    
    # Tiempo total
    elapsed = time.time() - start_time
    print(f"\n[TIEMPO] Total: {elapsed:.1f} segundos ({elapsed/60:.1f} minutos)")
    print("\n[OK] Proceso completado!")


if __name__ == "__main__":
    main()
