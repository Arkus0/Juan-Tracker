# MVP Training (in-memory) - notas

Alcance MVP
- Modelos: Sesion, Ejercicio, SerieLog, Rutina.
- ITrainingRepository + InMemoryTrainingRepository (stream con emision inicial por listener).
- Controller Riverpod 3 (Notifier) con startSession/addSet/undoLastSet/finishSession/addExternalSession.
- UI minima: HistoryScreen + SessionDetailScreen con export a texto/JSON y accion DESHACER.

Decisiones
- Estado in-memory para MVP; la API de ITrainingRepository se mantiene estable para migrar a Drift.
- Agrupacion de historial por: ESTA SEMANA, SEMANA PASADA, ESTE MES, MES ANIO.
- Export usa texto legible y JSON con toMap de modelos; se copia via clipboard.

Pendientes para PRs siguientes
- Persistencia Drift + migraciones.
- Servicios nativos (timer/voz/ocr/media) como stubs primero.

Preguntas abiertas
- Preferis Drift como persistencia final u otra alternativa?
- Que features nativas son obligatorias para el MVP?
- Migracion completa a Notifier/AsyncNotifier o gradual?
