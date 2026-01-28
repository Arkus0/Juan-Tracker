# PR Draft - MVP Training Flow (In-Memory)

Titulo sugerido
- feat(porting): MVP training flow (in-memory repo)

Descripcion corta
- Reimplementa el dominio y flujo minimo de entrenamiento (sesion, ejercicios, series) siguiendo PORTING_SPEC.
- Incluye repo in-memory + controller Riverpod 3 + UI minima de historial/detalle y export (texto/JSON).
- Agrega tests unitarios y widget basicos.

Referencias
- docs/PORTING_SPEC.md
- docs/TRAINING_MVP_NOTES.md

Checklist
- [ ] flutter test
- [ ] dart analyze
- [ ] dart format .
- [ ] UI smoke: crear sesion, agregar series, deshacer, finalizar, ver en historial, exportar

Etiquetas sugeridas
- area:porting
- type:feat
