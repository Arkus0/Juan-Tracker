#!/usr/bin/env python3
"""
Script para crear subsets de productos de Open Food Facts por mercado.

Soporta: spain, usa

INSTALACION DE DEPENDENCIAS:
    pip install duckdb requests tqdm pandas numpy

EJECUCION:
    python create_food_subset.py spain
    python create_food_subset.py usa
    python create_food_subset.py all

ARCHIVOS GENERADOS:
    - spain_subset.jsonl.gz     (~20-40 MB)
    - usa_subset.jsonl.gz       (~30-50 MB)

REQUISITOS:
    - Python 3.10+
    - ~2 GB de espacio libre temporal
    - Conexion a Internet
"""

import os
import sys
import json
import gzip
import shutil
import argparse
import time
import math
from pathlib import Path
from typing import Optional, List, Dict, Any, Mapping
from urllib.parse import urlparse

# Dependencias externas
try:
    import duckdb
    import requests
    from tqdm import tqdm
except ImportError as e:
    print(f"Error: Falta dependencia {e.name}")
    print("Instala con: pip install duckdb requests tqdm")
    sys.exit(1)


# =============================================================================
# CONFIGURACION POR MERCADO
# =============================================================================

# URL del dump de Open Food Facts (global, principalmente europeo)
DUMP_URL = 'https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz'

CSV_FILENAME = "openfoodfacts_products.csv.gz"
WORK_DIR = Path(__file__).parent.resolve()
CSV_PATH = WORK_DIR / CSV_FILENAME

TARGET_MIN_PRODUCTS = 300_000  # Aumentado a 300k mínimo
TARGET_MAX_PRODUCTS = 800_000  # Aumentado a 800k máximo

# Marcas por mercado
MARKETS = {
    'spain': {
        'filename': 'spain_subset.jsonl.gz',
        'brands': [
            'hacendado', 'mercadona', 'dia', 'lidl', 'alcampo', 'eroski', 
            'consum', 'auchan', 'carrefour', 'aldi', 'caprabo', 'masymas',
            'el pozo', 'campofrio', 'navidul', 'gallina blanca', 'knorr',
            'mahou', 'estrella damm', 'san miguel', 'cruzcampo', 'amstel',
            'danone', 'activia', 'kaiku', 'pascual', 'central lechera asturiana',
            'asturiana', 'feiraco', 'ram', 'begano', 'bonpreu', 'bonarea',
            'condis', 'sorli', 'simply', 'froiz', 'plusfresc', 'veritas',
            'puleva', 'nestle', 'milka', 'suchard', 'valor', 'torras',
            'cuetara', 'fontaneda', 'artiach', 'principe', 'oreo', 'digestive',
            'maria', 'chiquilin', 'colacao', 'nesquik', 'elgorriaga',
            'bimbo', 'panrico', 'findus', 'la sirena', 'pitusa', 'pagoda',
            'elpozo', 'fripozo', 'casa tarradellas', 'embutidos', 'revilla',
        ],
        'countries': ['spain', 'espana', 'es:es', 'en:spain', 'portugal', 'france', 'italy', 'italia', 'germany', 'alemania', 'belgium', 'belgica', 'netherlands', 'holanda'],
    },
    'usa': {
        'filename': 'usa_subset.jsonl.gz',
        'brands': [
            # Grandes conglomerados alimentarios
            'kraft', 'heinz', 'kraft heinz', 'hellmanns', 'hellmann', 'philadelphia',
            'general mills', 'nestle', 'unilever', 'conagra', 'campbell', 'kellogg',
            'pepsico', 'frito-lay', 'frito lay', 'quaker', 'post', 'bimbo', ' Flowers',
            
            # Bebidas
            'coca-cola', 'coca cola', 'coke', 'diet coke', 'coca-cola zero', 'sprite', 'fanta',
            'pepsi', 'diet pepsi', 'pepsi zero', 'mountain dew', 'mtn dew', 'dr pepper',
            '7up', '7-up', 'seven up', 'root beer', 'barq', ' Mug',
            'snapple', 'arizona', 'hawaiian punch', 'kool-aid', 'kool aid',
            'ocean spray', 'minute maid', 'simply', 'tropicana', 'simply orange',
            'red bull', 'monster', 'rockstar', 'bang', 'celsius', 'ghost',
            'gatorade', 'powerade', 'bodyarmor', 'vitaminwater',
            'poland spring', 'aquafina', 'dasani', 'smartwater', 'fiji', 'evian',
            'starbucks', 'dunkin', 'dunkin donuts', 'folgers', 'maxwell house',
            'nescafe', 'nespresso', 'cafe bustelo',
            
            # Snacks
            'lays', 'pringles', 'doritos', 'cheetos', 'tostitos', 'fritos',
            'ruffles', 'wavy', 'kettle', 'miss vickie', 'sunchips', 'sun chips',
            'funyuns', 'smartfood', 'popcorners', 'cape cod',
            'oreo', 'chips ahoy', 'ritz', 'wheat thins', 'triscuit', 'nilla',
            'nutter butter', 'belvita', 'teddy grahams', 'honey maid',
            'keebler', 'famous amos', 'mrs fields', 'murray', 'girl scout',
            'grandma', 'pirate', 'animal crackers',
            'mars', 'm&m', 'mms', 'snickers', 'twix', 'milky way', '3 musketeers',
            'skittles', 'starburst', 'life savers', 'altoids', 'wrigley',
            'hershey', 'reeses', 'kit kat', 'kitkat', 'rolo', 'whoppers',
            'almond joy', 'mounds', 'york', 'payday', ' Heath',
            'haribo', 'sour patch', 'swedish fish', 'swedish fish', 'jolly rancher',
            'tootsie', 'blow pop', 'charms', 'dum dum', 'butterfinger', 'crunch',
            
            # Cereales y desayuno
            'kelloggs', 'kellogg', 'special k', 'corn flakes', 'frosted flakes',
            'rice krispies', 'krispies', 'froot loops', 'apple jacks', 'coco puffs',
            'cheerios', 'lucky charms', 'cinnamon toast crunch', 'honey nut cheerios',
            'wheaties', 'total', 'fiber one', 'cascadian farm', 'kashi',
            'post', 'honey bunches', 'honeycomb', 'alpha-bits', 'grape-nuts',
            'oatmeal', 'granola bars', 'clif bar', 'kind bar', 'rxbar', 'luna',
            'nature valley', 'fiber one bars', 'quaker', 'instant oatmeal',
            
            # Lacteos
            'dannon', 'yoplait', 'chobani', 'fage', 'stonyfield', 'siggis',
            'horizon organic', 'organic valley', 'fairlife', 'milk', 'lactaid',
            'breyers', 'blue bunny', 'talenti', 'haagen-dazs', 'haagen dazs',
            'ben and jerry', 'ben & jerry', 'dreyers', 'edys', 'slow churned',
            'sargento', 'kraft singles', 'velveeta', 'cabot', 'land o lakes',
            'breakstones', 'knudsen', 'friendship', 'philadelphia', 'alta dens',
            'silk', 'almond breeze', 'califia', 'oatly', 'so delicious',
            
            # Panaderia
            'wonder', 'arnold', 'pepperidge farm', 'sara lee', 'bimbo', 
            'entenmanns', 'thomas', 'lenders', 'ball park', 'martins',
            'daves killer bread', 'dave killer', 'eureka', 'oroweat',
            'tastykake', 'hostess', 'twinkies', 'cupcakes', 'donettes', 'ding dongs',
            
            # Carnes
            'oscar mayer', 'hillshire farm', 'jimmy dean', 'butterball', 'tyson',
            'perdue', 'foster farms', 'empire kosher', 'applegate',
            'smithfield', 'hormel', 'nathan', 'hebrew national', 'sabrett',
            'johnsonville', 'hillshire', 'kielbasa', 'bratwurst',
            'lunchables', 'p3', 'jack link', 'slim jim', 'jerky',
            
            # Congelados y preparados
            'stouffer', 'marie callender', 'healthy choice', 'lean cuisine',
            'smart ones', 'digiorno', 'tombstone', 'red baron', 'totino', 
            'bagel bites', 'hot pockets', 'lean pockets', 'stromboli',
            'mccain', 'ore-ida', 'alexia', 'tater tots', 'hash browns',
            'mrs ts pierogies', 'amy kitchen', 'amys', 'evol', 'sweet earth',
            'morningstar farms', 'gardein', 'beyond meat', 'impossible foods',
            'lightlife', 'field roast', 'boca', 'gardenburger',
            'birds eye', 'green giant', 'cascadian farm', 'dr praeger',
            'alexia', 'cottage', 'white castle', 'banquet', 'swanson',
            'marie callenders', 'edwards', 'mrs smith', 'sara lee desserts',
            
            # Sopas y conservas
            'progresso', 'chunky', 'campbell', 'swanson', 'healthy choice',
            'well yes', 'pace', 'ro-tel', 'rotel', 'hunts', 'contadina',
            'muir glen', 'del monte', 'dole', 'chiquita', 'sunkist', 'libbys',
            'bush', 'goya', 'la preferida', 'old el paso', 'ortega',
            
            # Salsas y condimentos
            'hidden valley', 'hidden valley ranch', 'ken', 'newman', 'wish-bone',
            'italian dressing', 'ranch', 'caesar', 'blue cheese', 'thousand island',
            'prego', 'ragu', 'classico', 'barilla', 'mueller', 'bertolli',
            'newmans own', 'paul newman', 'ken steakhouses',
            'heinz', 'hunts', 'annies', 'spectrum', 'mayo', 'miracle whip',
            'frenchs', 'greys pupon', 'grey pupon', 'hellmann', 'dukes',
            'a1', 'a.1.', 'worcestershire', 'tabasco', 'franks', 'sriracha',
            'cholula', 'tapatio', 'valentina', 'texas pete', 'louisiana',
            
            # Productos étnicos comunes en USA
            'old el paso', 'ortega', 'la victoria', 'herdez', 'goya', 'badia',
            'kikkoman', 'la choy', 'annie chun', 'thai kitchen', 'tasty bite',
            
            # Saludables/orgánicos
            'whole foods', '365', 'trader joes', 'simple truth', 'orgain',
            'vital proteins', 'ancient nutrition', 'garden of life',
        ],
        'countries': ['united states', 'usa', 'us', 'en:us', 'en:united-states', 'canada', 'ca', 'en:canada', 'en:can'],
    },
}

RELEVANT_CATEGORIES = [
    'dairies', 'milk', 'yogurt', 'cheese', 'butter', 'cream', 'dairy',
    'leche', 'yogur', 'queso', 'mantequilla', 'nata', 'lacteos',
    'meat', 'beef', 'pork', 'chicken', 'poultry', 'ham', 'sausage',
    'carne', 'ternera', 'cerdo', 'pollo', 'ave', 'jamon', 'embutido',
    'fish', 'seafood', 'tuna', 'salmon', 'sardine', 'cod',
    'pescado', 'marisco', 'atun', 'sardina', 'bacalao',
    'fruit', 'vegetable', 'apple', 'orange', 'banana', 'tomato', 'potato',
    'fruta', 'verdura', 'manzana', 'naranja', 'platano', 'tomate', 'patata',
    'bread', 'cereal', 'pasta', 'rice', 'flour', 'wheat', 'oats',
    'pan', 'cereal', 'pasta', 'arroz', 'harina', 'trigo', 'avena',
    'legume', 'bean', 'lentil', 'chickpea', 'pea', 'soy',
    'legumbre', 'judia', 'lenteja', 'garbanzo', 'guisante', 'soja',
    'beverage', 'water', 'juice', 'soft drink', 'tea', 'coffee',
    'bebida', 'agua', 'zumo', 'refresco', 'te', 'cafe', 'isotonic',
    'alcohol', 'wine', 'beer', 'spirit', 'liquor', 'cider',
    'vino', 'cerveza', 'licor', 'whisky', 'vodka', 'ron', 'ginebra',
    'canned', 'preserve', 'pickle', 'olive',
    'conserva', 'conservado', 'encurtido', 'aceituna',
    'oil', 'olive oil', 'sunflower oil', 'margarine',
    'aceite', 'aceite de oliva', 'girasol', 'margarina',
    'egg', 'huevo',
    'sauce', 'vinegar', 'salt', 'sugar', 'honey', 'mustard', 'ketchup', 'mayonnaise',
    'salsa', 'vinagre', 'sal', 'azucar', 'miel', 'mostaza', 'ketchup', 'mayonesa',
    'frozen', 'congelado', 'frozen food', 'frozen dessert', 'ice cream', 'helado',
    'cracker', 'biscuit', 'cookie', 'galleta', 'snack', 'aperitivo', 'chocolate',
    'candy', 'sweet', 'caramel', 'golosina', 'chicle', 'chewing gum',
    'cake', 'pastry', 'tart', 'pie', 'pastel', 'tarta', 'bizcocho', 'magdalena',
    'breakfast', 'desayuno', 'cereal bar', 'energy bar', 'protein bar', 'granola', 'muesli',
    'supplement', 'protein', 'suplemento', 'proteina', 'sports nutrition', 'nutricion deportiva',
    'ready meal', 'prepared meal', 'comida preparada', 'platos preparados', 'soup', 'sopa',
    'baby food', 'infant', 'bebe', 'infantil', 'formula',
]

NUTRIMENT_FIELDS = {
    'energy-kcal_100g': 'energy_kcal',
    'proteins_100g': 'proteins',
    'carbohydrates_100g': 'carbohydrates',
    'fat_100g': 'fat',
    'fiber_100g': 'fiber',
    'sugars_100g': 'sugars',
}


# =============================================================================
# FUNCIONES DE UTILIDAD
# =============================================================================

def format_size(size_bytes: int) -> str:
    size = float(size_bytes)
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size < 1024:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} TB"


def download_file(url: str, dest_path: Path, chunk_size: int = 8192) -> bool:
    try:
        print(f"\n[DESCARGA] Descargando dump de Open Food Facts...")
        print(f"   URL: {url}")
        
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
    except Exception as e:
        print(f"   [ERROR] {e}")
        return False


def check_existing_file(file_path: Path) -> bool:
    if not file_path.exists():
        return True
    size = file_path.stat().st_size
    print(f"\n[ARCHIVO] Archivo existente: {file_path.name} ({format_size(size)})")
    response = input("   Usar existente (u) o re-descargar (r)? [u/r]: ").strip().lower()
    if response in ['r', 'redescargar']:
        file_path.unlink()
        return True
    return False


def create_duckdb_connection() -> duckdb.DuckDBPyConnection:
    conn = duckdb.connect(':memory:')
    conn.execute("SET memory_limit = '2GB'")
    conn.execute("SET threads TO 4")
    return conn


def build_filter_query(market: str) -> str:
    config = MARKETS[market]
    
    country_conditions = [f"countries_tags ILIKE '%{c}%'" for c in config['countries']]
    brand_conditions = []
    for brand in config['brands']:
        brand_clean = brand.replace("'", "''")
        brand_conditions.append(f"brands_tags ILIKE '%{brand_clean}%'")
    category_conditions = []
    for cat in RELEVANT_CATEGORIES:
        cat_clean = cat.replace("'", "''")
        category_conditions.append(f"categories_tags ILIKE '%{cat_clean}%'")
    
    country_filter = ' OR '.join(country_conditions)
    brand_filter = ' OR '.join(brand_conditions)
    category_filter = ' OR '.join(category_conditions)
    
    # Para USA: también incluir productos globales populares (en inglés) con marcas conocidas
    if market == 'usa':
        # Productos con marca USA (sin requerir país) + productos de países USA/Canadá
        location_filter = f"""
        (
            ({country_filter})
            OR 
            ({brand_filter})
        )
        """
    else:
        # Para España: requiere país europeo o marca española
        location_filter = f"""
        (
            ({country_filter})
            OR 
            ({brand_filter})
        )
        """
    
    query = f"""
    {location_filter}
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


def build_nutriments_dict(row: Mapping[str, Any]) -> Dict[str, Optional[float]]:
    result = {}
    for csv_field, output_field in NUTRIMENT_FIELDS.items():
        value = row.get(csv_field)
        if value is not None and value != '':
            try:
                float_val = float(value)
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
    if not categories_tags:
        return []
    categories = [cat.strip() for cat in categories_tags.split(',')]
    cleaned = []
    for cat in categories:
        if ':' in cat:
            cleaned.append(cat.split(':', 1)[1].replace('-', ' '))
        else:
            cleaned.append(cat.replace('-', ' '))
    return cleaned[:5]


def is_valid_string(value: Any) -> bool:
    if value is None:
        return False
    s = str(value).strip()
    if not s or s.lower() == 'nan':
        return False
    return True


def get_product_name(row: Mapping[str, Any]) -> str:
    name = row.get('product_name', '')
    if is_valid_string(name):
        return str(name).strip()
    generic = row.get('generic_name', '')
    if is_valid_string(generic):
        return str(generic).strip()
    return 'Producto sin nombre'


def process_and_export(conn: duckdb.DuckDBPyConnection, output_path: Path, market: str, csv_path: Path) -> int:
    print(f"\n[FILTRO] Filtrando productos para mercado: {market.upper()}")
    print(f"   Fuente: {csv_path}")
    
    filter_query = build_filter_query(market)
    nutriment_columns = ', '.join([f'"{col}"' for col in NUTRIMENT_FIELDS.keys()])
    
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
    FROM read_csv_auto('{csv_path}', 
        header=true, 
        delim='\\t',
        quote='"',
        escape='"',
        nullstr='',
        ignore_errors=true
    )
    WHERE {filter_query}
    """
    
    result = conn.execute(select_query).fetchdf()
    total_found = len(result)
    print(f"   Productos encontrados: {total_found:,}")
    
    if total_found > TARGET_MAX_PRODUCTS:
        print(f"   Priorizando para reducir a ~{TARGET_MAX_PRODUCTS:,}...")
        result['completeness_score'] = (
            result['nutriscore_grade'].notna().astype(int) +
            result['energy-kcal_100g'].notna().astype(int) +
            result['categories_tags'].notna().astype(int) +
            result['brands'].notna().astype(int)
        )
        priority_countries = '|'.join(MARKETS[market]['countries'][:2])
        result['priority_score'] = result['countries_tags'].str.contains(priority_countries, case=False, na=False).astype(int)
        result = result.sort_values(['priority_score', 'completeness_score'], ascending=[False, False]).head(TARGET_MAX_PRODUCTS)
        result = result.drop(columns=['completeness_score', 'priority_score'])
    
    print(f"\n[EXPORT] Exportando: {output_path.name}")
    count = 0
    jsonl_temp = output_path.with_suffix('')
    
    with open(jsonl_temp, 'w', encoding='utf-8') as f:
        for _, row in tqdm(result.iterrows(), total=len(result), desc="Procesando"):
            row_dict = row.to_dict()
            nutriments = build_nutriments_dict(row_dict)
            categories = clean_categories(row_dict.get('categories_tags'))
            nutriscore = row_dict.get('nutriscore_grade')
            if nutriscore not in ['a', 'b', 'c', 'd', 'e']:
                nutriscore = None
            
            brands_val = row_dict.get('brands')
            generic_val = row_dict.get('generic_name')
            
            product = {
                'code': str(row_dict.get('code', '')).strip(),
                'name': get_product_name(row_dict),
                'brands': str(brands_val).strip() if is_valid_string(brands_val) else None,
                'generic_name': str(generic_val).strip() if is_valid_string(generic_val) else None,
                'nutriscore': nutriscore,
                'nutriments': nutriments,
                'categories': categories,
            }
            f.write(json.dumps(product, ensure_ascii=False) + '\n')
            count += 1
    
    # Comprimir
    print(f"[COMPRESION] Comprimiendo...")
    with open(jsonl_temp, 'rb') as f_in:
        with gzip.open(output_path, 'wb', compresslevel=9) as f_out:
            shutil.copyfileobj(f_in, f_out)
    jsonl_temp.unlink()
    
    return count


def show_statistics(output_path: Path, count: int, market: str):
    gzip_size = output_path.stat().st_size
    
    print("\n" + "="*60)
    print(f"RESUMEN: {market.upper()}")
    print("="*60)
    print(f"   Productos exportados:    {count:,}")
    print(f"   Archivo:                 {output_path.name}")
    print(f"   Tamaño:                  {format_size(gzip_size)}")
    print(f"   Productos/MB:            {count / (gzip_size / 1024 / 1024):.0f}")
    print("="*60)


def process_market(market: str, conn: duckdb.DuckDBPyConnection, csv_path: Path) -> bool:
    if market not in MARKETS:
        print(f"[ERROR] Mercado no soportado: {market}")
        return False
    
    output_path = WORK_DIR / MARKETS[market]['filename']
    if output_path.exists():
        output_path.unlink()
    
    try:
        count = process_and_export(conn, output_path, market, csv_path)
        if count == 0:
            print(f"[ERROR] No se encontraron productos para {market}")
            return False
        show_statistics(output_path, count, market)
        return True
    except Exception as e:
        print(f"[ERROR] Procesando {market}: {e}")
        import traceback
        traceback.print_exc()
        return False


def get_csv_path_for_market(market: str) -> Path:
    """Retorna el path del CSV. Todos los mercados usan el mismo dump global."""
    return WORK_DIR / "openfoodfacts_products.csv.gz"


def main():
    parser = argparse.ArgumentParser(description='Crear subsets de Open Food Facts por mercado')
    parser.add_argument('market', choices=['spain', 'usa', 'all'], help='Mercado a procesar')
    parser.add_argument('--keep-csv', action='store_true', help='Mantener CSV descargado')
    args = parser.parse_args()
    
    start_time = time.time()
    print("="*60)
    print("Open Food Facts - Multi-Market Subset Creator")
    print("="*60)
    
    # Determinar mercados a procesar
    markets = ['spain', 'usa'] if args.market == 'all' else [args.market]
    
    results = {}
    
    for market in markets:
        print(f"\n{'='*60}")
        print(f"PROCESANDO MERCADO: {market.upper()}")
        print('='*60)
        
        # Todos los mercados usan el mismo CSV (dump global)
        csv_path = get_csv_path_for_market(market)
        dump_url = DUMP_URL
        
        # Verificar/Descargar CSV para este mercado
        need_download = check_existing_file(csv_path)
        if need_download:
            if not download_file(dump_url, csv_path):
                print(f"\n[ERROR] No se pudo descargar el dump para {market}.")
                results[market] = False
                continue
        
        if not csv_path.exists():
            print(f"[ERROR] No se encuentra el archivo {csv_path}")
            results[market] = False
            continue
        
        # Procesar este mercado
        print(f"\n[DUCKDB] Inicializando para {market}...")
        conn = create_duckdb_connection()
        results[market] = process_market(market, conn, csv_path)
        conn.close()
        
        # Limpiar CSV si no se quiere mantener
        if not args.keep_csv and csv_path.exists():
            print(f"[LIMPIEZA] Eliminando CSV de {market}...")
            csv_path.unlink()
    
    # Resumen final
    elapsed = time.time() - start_time
    print("\n" + "="*60)
    print("RESUMEN FINAL")
    print("="*60)
    for market, success in results.items():
        status = "OK" if success else "FALLIDO"
        print(f"   {market.upper()}: {status}")
    print(f"\nTiempo total: {elapsed/60:.1f} minutos")
    print("="*60)


if __name__ == "__main__":
    main()
