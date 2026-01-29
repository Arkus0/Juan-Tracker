# Contribuir

Gracias por querer contribuir a Juan Tracker 👏. Sigue estas pautas para facilitar revisiones y mantener calidad.

## Checklist mínimo antes de abrir un PR
- Ejecuta `flutter analyze` y corrige advertencias relevantes.
- Ejecuta `flutter test` y asegúrate de que los tests pasen.
- Formatea el código con `dart format lib/ test/`.
- Si modificas tablas Drift o modelos, ejecuta:
  - `dart run build_runner build --delete-conflicting-outputs` (o `watch` en desarrollo).

## Flujo sugerido
1. Crea una rama descriptiva: `feature/<breve-descripción>` o `fix/<ticket>`.
2. Mantén commits pequeños y con mensajes claros.
3. Abre un PR apuntando a `main` y añade descripción con pasos para reproducir, cambios y tests agregados.

## Estándares rápidos
- Idioma del código: Inglés preferido; UI y comentarios de dominio en Español.
- Sigue las reglas del linter (`flutter_lints`), ejecuta `flutter analyze` antes de solicitar revisión.

## Reportar bugs y pedir features
- Usa el Issue tracker del repositorio; añade pasos para reproducir, contexto y logs si aplica.

Si necesitas ayuda para configurar el entorno, abre un issue y te ayudamos.
