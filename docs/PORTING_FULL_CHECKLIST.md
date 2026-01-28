# Checklist exhaustivo de funcionalidades — Portado (EXCLUYENDO ejercicios)

**Resumen:** checklist accionable para rehacer la app desde cero en otro repositorio. Incluye modelos, flujos, UI, servicios, persistencia, tests, QA, edge-cases y criterios de aceptación. Se excluyen todos los puntos relacionados con la librería de ejercicios (assets/JSON) por petición.

---

## Prioridad: MVP (Imprescindible) 🚨
- [ ] Implementar modelos del dominio:
  - [ ] `Sesion` con campos: `id`, `fecha`, `durationSeconds?`, `totalVolume`, `ejerciciosCompletados[]`, `rutinaId?`, `dayName?`, getters: `formattedDuration`, `completedSetsCount`.
  - [ ] `Ejercicio` con campos: `id/nombre`, `logs: List<SerieLog>`, métodos `completedSetsCount()` y `maxWeight()`.
  - [ ] `SerieLog` con campos: `peso`, `reps`, `completed`, `rpe?`.
  - [ ] `Rutina` simple: `id`, `nombre`, `ejerciciosPlantilla`.

- [ ] Implementar API pública mínima (contratos):
  - [ ] `ITrainingRepository` con `saveSession`, `watchSessions`, `deleteSession`, `getRutinas`.
  - [ ] `ITimerService` (métodos: `start`, `stop`, `remaining$`) — al menos stub.
  - [ ] `IVoiceInputService` (método: `listenAndParse()`) — stub inicial.

- [ ] State management (Riverpod 3):
  - [ ] `TrainingSessionController` como `Notifier`/`AsyncNotifier` con métodos: `startSession`, `addSet`, `undoLastSet`, `finishSession`, `addExternalSession`.
  - [ ] `sesionesHistoryStreamProvider` (StreamProvider que expone `watchSessions()` del repo).
  - [ ] `rutinasStreamProvider` o `FutureProvider` que use `ITrainingRepository.getRutinas()`.

- [ ] Implementación de repositorio in-memory (para MVP):
  - [ ] `InMemoryTrainingRepository` con StreamController broadcast y CRUD mínimo.
  - [ ] Tests unitarios que validen la emisión de sesiones guardadas.

- [ ] Pantallas y UX mínimos:
  - [ ] `HistoryScreen` con agrupación por: `ESTA SEMANA`, `SEMANA PASADA`, `ESTE MES`, `MMMM YYYY`.
  - [ ] `SessionDetailScreen` que muestre ejercicios y series.
  - [ ] `TrainingSessionScreen` básico para iniciar sesión, añadir sets y finalizar.
  - [ ] `ExternalSessionSheet` (modal/ficha para crear sesión externa manualmente).
  - [ ] FAB para `SESIÓN EXTERNA` con `heroTag: 'add_external_session'`.

- [ ] Export & Share:
  - [ ] Export individual session (texto legible + JSON shareable).
  - [ ] Export “Exportar todo” desde `History` (JSON con indentado).

- [ ] Undo UX:
  - [ ] SnackBar con DESHACER en acciones de guardado (llamar `ScaffoldMessenger.of(context).hideCurrentSnackBar()` antes de mostrar).
  - [ ] DESHACER restaura estado previo (ej.: borra sesión guardada).

- [ ] Tests mínimos (ejecución obligatoria en PR):
  - [ ] Unit: controller behavior (start/addSet/finish/undo).
  - [ ] Unit: in-memory repo CRUD + stream.
  - [ ] Widget: `HistoryScreen` loads and groups sessions.

- [ ] Documentación y PR:
  - [ ] Añadir `docs/PORTING_SPEC.md` (o enlazar a la que ya existe) y notas en PR sobre decisiones (stubs, Drift pendiente).
  - [ ] Checklist de PR completado (tests, analyze, format).

---

## Prioridad: Post-MVP (Alta → Media)
- [ ] Persistencia local (Drift/SQLite):
  - [ ] `lib/database/database.dart` con `schemaVersion` y `MigrationStrategy`.
  - [ ] Implementar `DriftTrainingRepository` que satisface `ITrainingRepository`.
  - [ ] Ejecutar `dart run build_runner build --delete-conflicting-outputs` para generar archivos.
  - [ ] Tests de migraciones (crear DB vieja y actualizar, validar onUpgrade).

- [ ] Timer & Notifications:
  - [ ] Implementar `ITimerService` real con `rest timers` y streams de tiempo restante.
  - [ ] Integrar notificaciones locales y foreground service (Android) para timers si es necesario.

- [ ] Voice & OCR (si decidido):
  - [ ] `IVoiceInputService` con `speech_to_text` para reconocimiento; parser para construir `ExternalSession`.
  - [ ] OCR con ML Kit si se quiere leer pantallas/ PDFs (opcional y device-required).

- [ ] MediaSession & audio UX:
  - [ ] `MediaSessionService` nativo para lock screen media controls (Android) y `just_audio` para audio.
  - [ ] Beeps / feedback sonoro (`NativeBeepService`).

- [ ] Haptics & feedback:
  - [ ] Haptic feedback en interacciones importantes (selectionClick, mediumImpact).

- [ ] Progresión & recomendaciones:
  - [ ] Implementar reglas básicas de progresión (ej.: aumentar peso tras N sets exitosos, milestone detection).
  - [ ] Widgets para celebrar milestones (`MilestoneCelebration`).

- [ ] Undo & historicidad avanzada:
  - [ ] Guardar meta-datos adicionales de la sesión (isBadDay, dayIndex) si se requiere.

---

## UI & Widgets (detallado)
- [ ] Cards expandibles para sesiones (`_SessionTile`): tap para expandir, long-press para ir a detalle.
- [ ] `AnimatedCrossFade` para mostrar detalles expandibles.
- [ ] `RestTimerBar`, `FocusedSetRow`, `NumpadInputModal` para input de sets.
- [ ] SnackBar con tipo floating, color y acción DESHACER.
- [ ] Buttons estilizados (OutlinedButton.styleFrom con colores y borders especificados).

---

## Tests, QA & CI (detallado)
- [ ] Unit tests:
  - [ ] TrainingSessionController transitions (Idle → Active → Finished).
  - [ ] Cálculos: `totalVolume`, `completedSetsCount`, `maxWeight`.
  - [ ] Repo behavior: save/load/delete/watch emits.
- [ ] Widget tests:
  - [ ] History screen shows grouping and items.
  - [ ] Session detail shows exercises/series and metrics.
- [ ] Integration tests (device required):
  - [ ] Flow: start session → add sets → finish → verify in history.
  - [ ] Voice/OCR flows (manual test or E2E if devices available).
- [ ] CI checks:
  - [ ] `flutter pub get` passes.
  - [ ] `flutter analyze` passes with no errors.
  - [ ] `flutter test` all green.
  - [ ] `dart format .` aplicado.

---

## Edge-cases, validaciones y seguridad
- [ ] Validar input: `peso >= 0`, `reps > 0`, `rpe` en rango si aplica.
- [ ] Manejar sesiones vacías: prevenir guardado accidental o avisar al usuario.
- [ ] Sessions con fecha futura: mostrar alerta o normalizar.
- [ ] Rutina eliminada: `rutinaId` no encontrada → mostrar etiqueta `RUTINA ELIMINADA`.
- [ ] SnackBar undo timeout: 10s por diseño; restauración segura y atómica.
- [ ] Permisos faltantes: mostrar fallback/explicación (voice/ocr/camera/microphone).

---

## Observability y logs
- [ ] Usar `logger` para mensajes de debugging relevantes (no prints en producción).
- [ ] Tener tests que simulen errores y validen manejo correcto.

---

## Dev tools, scripts y mantenimiento
- [ ] `scripts/extract_providers.dart` para auditar providers y acelerar portado.
- [ ] `bin/` scripts (si necesario): generación/normalización de assets (aunque estamos ignorando exercises).
- [ ] Documentar pasos de codegen (`dart run build_runner build --delete-conflicting-outputs`).
- [ ] Añadir instrucciones en README y notas en PR sobre pasos manuales a completar (migraciones DB, permisos Android).

---

## PR checklist (para cada PR relacionado con portado)
- [ ] El PR es small y enfocado (MVP → Drift → Nativas).
- [ ] Todas las pruebas pasadas localmente y en CI.
- [ ] Archivos de docs actualizados (`docs/PORTING_SPEC.md`, `docs/PORTING_CHECKLIST.md`).
- [ ] Descripción del PR incluye cómo validar el cambio y pasos de QA manual.
- [ ] Marca el PR como Draft hasta validación completa por QA.

---

## Criterios de aceptación (finales)
- [ ] La app arranca y no falla en modo debug.
- [ ] Se puede crear sesión, añadir sets, finalizar y verla en `History` correctamente agrupada.
- [ ] Export individual y export all funcionan y producen JSON válido y texto legible.
- [ ] Undo funciona en las acciones de guardado con Snackbar (DESHACER) durante 10s.
- [ ] `flutter test` y `flutter analyze` pasan en la rama del PR.

---

## Preguntas abiertas (para decidir antes de implementar)
- [ ] ¿Drift será la persistencia preferida o se prefiere otra solución local? (Influye en migraciones y codegen)
- [ ] ¿Qué features nativas son obligatorias para MVP (timer/media/voice/OCR)?
- [ ] ¿Se desea migración completa a `Notifier/AsyncNotifier` ya o se hará gradual?

---

Si quieres, convierto este checklist en un conjunto de issues/Trello cards o en un JSON para import al bugtracker del equipo. ¿Lo exporto ahora?