# MVP Training (in-memory) - notas

Alcance MVP
- Modelos: Sesion, Ejercicio, SerieLog, Rutina, TrainingExercise (biblioteca).
- ITrainingRepository + InMemoryTrainingRepository (stream con emision inicial por listener).
- Controller Riverpod 3 (Notifier) con startSession/addSet/undoLastSet/finishSession/addExternalSession.
- UI gym: TrainingHome con tabs (Inicio/Biblioteca/Rutinas/Historial) + export a texto/JSON y accion DESHACER.
- Biblioteca local de ejercicios (seed JSON + ejercicios custom en SharedPreferences).
- Timer de descanso basico (dialog).

Decisiones
- Estado in-memory para MVP; la API de ITrainingRepository se mantiene estable para migrar a Drift.
- Agrupacion de historial por: ESTA SEMANA, SEMANA PASADA, ESTE MES, MES ANIO.
- Export usa texto legible y JSON con toMap de modelos; se copia via clipboard.

Pendientes para PRs siguientes
- Persistencia Drift + migraciones.
- Servicios nativos (timer/voz/ocr/media) como stubs primero.

Respuestas (28 Jan 2026)
- Persistencia final: Drift.
- Features nativas: todas las posibles (timer/voz/ocr/media/haptics).
- Migracion: completa a Notifier/AsyncNotifier desde ya.
