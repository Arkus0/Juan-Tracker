# Manejo de datasets grandes (política rápida)

Pequeña guía para evitar commits accidentales de archivos muy pesados y para decidir dónde almacenar datasets que no deben ir al repositorio.

## Resumen (regla de oro)
- **No commitear** archivos > 100 MB (GitHub los rechazará). Usa almacenamiento externo o Git LFS.
- Ya se añadió `scripts/*.gz` a `.gitignore` para evitar commits accidentales.

## Opciones recomendadas
- Almacenamiento en cloud (preferido): S3, Google Cloud Storage, Azure Blob, o un drive privado. Mantén el dataset como artefacto externo y descarga en CI o local cuando haga falta.
- Subconjuntos en el repo: guarda **subset** reducidos en `assets/data/` o `data/` (ej.: `assets/data/usa_subset.jsonl.gz`). Genera subsets con `scripts/create_food_subset.py`.
- Versionado en repo (sólo si es imprescindible): usa **Git LFS** (ver sección "Git LFS" más abajo).

## Recuperación / respaldo
- Tras la limpieza reciente, hay una rama de respaldo con la copia local: `backup/main-local-before-clean`.
  - Recuperar el fichero grande (si realmente lo necesitas):
    - `git checkout backup/main-local-before-clean -- scripts/openfoodfacts_products.csv.gz`

## Git LFS (opcional)
Si decides versionar un dataset en el repositorio:

1. Instalar y activar LFS en tu máquina:
   - `git lfs install`
2. Trackear archivos grandes (ej. gz en `scripts/`):
   - `git lfs track "scripts/*.gz"`
   - `git add .gitattributes` && `git commit -m "track datasets with git-lfs"`
3. Añadir el archivo y push (nota: el remoto debe soportar LFS):
   - `git add scripts/openfoodfacts_products.csv.gz`
   - `git commit -m "add dataset via git-lfs"`
   - `git push origin main`

> Nota: Git LFS requiere soporte en el remoto y puede generar costes. Preferir almacenamiento en cloud público/privado cuando sea posible.

## CI / Descarga automatizada
- Evita almacenar datasets grandes en el repo; añade pasos en CI para descargar el dataset desde un bucket seguro.
- Ejemplo (GitHub Actions):

```yaml
- name: Descargar dataset
  run: |
    aws s3 cp s3://my-bucket/openfoodfacts_products.csv.gz scripts/openfoodfacts_products.csv.gz
```

## Resumen rápido (checklist)
- [x] No subir archivos >100 MB al repo
- [x] Mantener subsets ligeros en `assets/data/`
- [x] Usar cloud storage para datasets grandes
- [x] Usar Git LFS sólo si es imprescindible

---

Archivo generado automáticamente por la política del repositorio — mantener actualizada la ruta en `.gitignore` si cambian los nombres de los datasets.
