import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/database_provider.dart';

import '../models/ejercicio.dart';
import '../models/ejercicio_en_rutina.dart';
import '../models/library_exercise.dart';
import '../models/progression_engine_models.dart';
import '../models/rutina.dart';
import '../models/serie_log.dart';
import '../models/sesion.dart';
import '../models/training_set_type.dart';
import '../models/session_template.dart';

import '../repositories/drift_training_repository.dart';
import '../repositories/i_training_repository.dart';
import '../services/error_tolerance_system.dart';
import '../services/rest_timer_controller.dart';
import '../services/session_history_manager.dart';
import '../services/session_persistence_service.dart';
import 'session_tolerance_provider.dart';
import 'settings_provider.dart';

final trainingRepositoryProvider = Provider<ITrainingRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftTrainingRepository(db);
});

final rutinasStreamProvider = StreamProvider<List<Rutina>>((ref) {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.watchRutinas();
});

/// Provider de historial con límite por defecto de 50 sesiones
/// Para paginación, usar sesionesHistoryPaginatedProvider
final sesionesHistoryStreamProvider = StreamProvider<List<Sesion>>((ref) {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.watchSesionesHistory(limit: 50);
});

/// Provider paginado para el historial de sesiones
/// Permite cargar más sesiones bajo demanda para mejor rendimiento
///
/// Uso: ref.watch(sesionesHistoryPaginatedProvider(page))
/// page 0 = primeras 20, page 1 = siguientes 20, etc.
final sesionesHistoryPaginatedProvider =
    StreamProvider.family<List<Sesion>, int>((ref, page) {
      final repo = ref.watch(trainingRepositoryProvider);
      // Cada página trae 20 sesiones, acumulando con páginas anteriores
      return repo.watchSesionesHistory(limit: (page + 1) * 20);
    });

/// Notifier para controlar la paginación del historial
class HistoryPaginationNotifier extends Notifier<int> {
  @override
  int build() => 0; // Empezar en página 0

  void loadMore() => state++;
  void reset() => state = 0;
}

final historyPaginationProvider =
    NotifierProvider<HistoryPaginationNotifier, int>(
      HistoryPaginationNotifier.new,
    );

final activeSessionStreamProvider = StreamProvider<ActiveSessionData?>((ref) {
  final repo = ref.watch(trainingRepositoryProvider);
  return repo.watchActiveSession();
});

// RestTimerState importado desde rest_timer_controller.dart

class TrainingState {
  final Rutina? activeRutina;
  final String? dayName; // Nombre del día siendo entrenado
  final int? dayIndex; // Índice del día en la rutina
  final List<Ejercicio> exercises; // The working copy with logs
  final List<Ejercicio> targets; // Snapshot of targets
  final DateTime? startTime;
  final int defaultRestSeconds;
  final bool isRestActive; // DEPRECATED: usar restTimer.isActive
  final RestTimerState restTimer; // Nuevo estado avanzado del timer

  // New State Fields
  final Map<String, List<SerieLog>>
  history; // Key: Exercise Name, Value: Last Session Logs
  final bool showAdvancedOptions;
  final bool showTimerBar; // Mostrar/ocultar barra inactiva del timer

  TrainingState({
    this.activeRutina,
    this.dayName,
    this.dayIndex,
    this.exercises = const [],
    this.targets = const [],
    this.startTime,
    this.defaultRestSeconds = 90,
    this.isRestActive = false,
    this.restTimer = const RestTimerState(),
    this.history = const {},
    this.showAdvancedOptions = true, // Siempre visible por defecto
    this.showTimerBar = true, // UX: Visible por defecto - core feature del gym
  });

  TrainingState copyWith({
    Rutina? activeRutina,
    String? dayName,
    int? dayIndex,
    List<Ejercicio>? exercises,
    List<Ejercicio>? targets,
    DateTime? startTime,
    int? defaultRestSeconds,
    bool? isRestActive,
    RestTimerState? restTimer,
    Map<String, List<SerieLog>>? history,
    bool? showAdvancedOptions,
    bool? showTimerBar,
  }) {
    return TrainingState(
      activeRutina: activeRutina ?? this.activeRutina,
      dayName: dayName ?? this.dayName,
      dayIndex: dayIndex ?? this.dayIndex,
      exercises: exercises ?? this.exercises,
      targets: targets ?? this.targets,
      startTime: startTime ?? this.startTime,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      isRestActive: isRestActive ?? this.isRestActive,
      restTimer: restTimer ?? this.restTimer,
      history: history ?? this.history,
      showAdvancedOptions: showAdvancedOptions ?? this.showAdvancedOptions,
      showTimerBar: showTimerBar ?? this.showTimerBar,
    );
  }

  /// Obtiene el índice del siguiente set no completado (para auto-focus).
  ///
  /// Nota: Itera en orden lineal por índice de ejercicio. Si el usuario añade
  /// ejercicios dinámicamente y luego edita ejercicios anteriores, el auto-focus
  /// siempre irá al primer set no completado en orden de lista, lo cual puede
  /// resultar en saltos de foco no intuitivos en algunos casos edge.
  ({int exerciseIndex, int setIndex})? get nextIncompleteSet {
    for (var exIdx = 0; exIdx < exercises.length; exIdx++) {
      final exercise = exercises[exIdx];
      for (var setIdx = 0; setIdx < exercise.logs.length; setIdx++) {
        if (!exercise.logs[setIdx].completed) {
          return (exerciseIndex: exIdx, setIndex: setIdx);
        }
      }
    }
    return null;
  }
}

class TrainingSessionNotifier extends Notifier<TrainingState> {
  late final ITrainingRepository _repository;

  final Logger _logger = Logger();

  /// Controlador de timer de descanso (delegación de responsabilidad)
  late final RestTimerController _timerController;

  /// Servicio de persistencia (delegación de responsabilidad)
  late final SessionPersistenceService _persistenceService;

  /// Manager de historial de ejercicios (delegación de responsabilidad)
  ///
  /// Extraído del God Object para mejorar testabilidad y separación de responsabilidades
  SessionHistoryManager? _historyManager;

  ({int exerciseIndex, int setIndex, SerieLog previousLog})?
  _lastCompletedSet;

  @override
  TrainingState build() {
    _repository = ref.read(trainingRepositoryProvider);
    _initializeServices();
    ref.onDispose(() {
      _timerController.dispose();
      _persistenceService.dispose();
    });
    return TrainingState();
  }

  /// Inicializa los servicios delegados
  Future<void> _initializeServices() async {
    // Inicializar controlador de timer
    _timerController = RestTimerController();
    _timerController.onStateChanged = _onTimerStateChanged;
    _timerController.onTimerFinishedWhileAway = () {
      // Timer terminó mientras app cerrada - el getter lo expondrá al UI
    };
    await _timerController.initialize();

    // Inicializar servicio de persistencia
    _persistenceService = SessionPersistenceService(_repository);
    _persistenceService.getSessionData = _getCurrentSessionData;

    // Inicializar manager de historial
    _historyManager = SessionHistoryManager(_repository);
  }

  /// Callback cuando el timer cambia de estado
  void _onTimerStateChanged(RestTimerState timerState) {
    state = state.copyWith(
      restTimer: timerState,
      isRestActive: timerState.isActive,
    );
  }

  /// Obtiene los datos de sesión actuales para persistencia
  ActiveSessionData _getCurrentSessionData() {
    return ActiveSessionData(
      activeRutina: state.activeRutina,
      exercises: state.exercises,
      targets: state.targets,
      startTime: state.startTime,
      defaultRestSeconds: state.defaultRestSeconds,
      history: state.history,
    );
  }

  /// Getter para que el UI pueda verificar si el timer terminó mientras estaba cerrado
  bool get timerFinishedWhileAway => _timerController.timerFinishedWhileAway;

  /// Limpia el flag de timer terminado (llamar después de mostrar feedback)
  void clearTimerFinishedWhileAway() {
    _timerController.clearTimerFinishedWhileAway();
  }

  SerieLog _buildDefaultLog(TrainingSetType setType) {
    return SerieLog(
      peso: 0.0,
      reps: 0,
      completed: false,
      isDropset: setType == TrainingSetType.dropSet,
      isRestPause: setType == TrainingSetType.restPause,
      isMyoReps: setType == TrainingSetType.myoReps,
      isAmrap: setType == TrainingSetType.amrap,
    );
  }

  Future<void> startSession(
    Rutina rutina,
    List<EjercicioEnRutina> routineExercises, {
    String? dayName,
    int? dayIndex,
  }) async {
    final autoRestEnabled =
        ref.read(settingsProvider).autoRestFromHistoryEnabled;
    final restByLibraryId = autoRestEnabled
        ? await _repository.getAverageRestSecondsByLibraryId(
            routineExercises.map((e) => e.id).toList(),
          )
        : <String, int>{};

    // Map EjercicioEnRutina (Type 5) -> Ejercicio (Type 0, Session Model)
    final sessionExercises = routineExercises.map((e) {
      final suggestedRest =
          e.descansoSugerido?.inSeconds ?? restByLibraryId[e.id];
      return Ejercicio(
        id: e.instanceId, // Use the stable Instance ID
        libraryId: e.id, // Reference to the library
        nombre: e.nombre,
        musculosPrincipales: e.musculosPrincipales,
        musculosSecundarios: e.musculosSecundarios,
        series: e.series,
        reps:
            int.tryParse(e.repsRange.split('-').first) ??
            0, // Best effort parse
        notas: e.notas,
        supersetId:
            e.supersetId, // Copiar superset para lógica de timer encadenado
        descansoSugeridoSeconds: suggestedRest,
        logs: List.generate(e.series, (_) => _buildDefaultLog(e.setType)),
      );
    }).toList();

    // Build History Map usando SessionHistoryManager (extraído del God Object)
    // Esto mejora testabilidad y permite cacheo LRU del historial
    final historyMap =
        await _historyManager?.loadHistoryForExercises(sessionExercises) ?? {};

    state = TrainingState(
      activeRutina: rutina,
      dayName: dayName,
      dayIndex: dayIndex,
      exercises: sessionExercises,
      targets: sessionExercises
          .map((e) => e.copyWith())
          .toList(), // Snapshot targets
      startTime: DateTime.now(),
      history: historyMap,
      showAdvancedOptions: false,
    );
    _saveState();

    // Auto-rellenar con la última sesión si está habilitado
    final autoFill = ref.read(settingsProvider).autoFillLastSession;
    if (autoFill) {
      applyHistoryToCurrentSession(overwriteExisting: true);
    }
  }

  /// Inicia una sesión de entrenamiento libre sin rutina predefinida.
  ///
  /// Permite al usuario empezar a entrenar inmediatamente y añadir
  /// ejercicios sobre la marcha. Reduce TTV de 14 clics a 2.
  void startFreeSession() {
    state = TrainingState(
      activeRutina: null, // Sin rutina base
      dayName: 'Entrenamiento Libre',
      dayIndex: null,
      exercises: [], // Vacío - usuario añade ejercicios
      targets: [],
      startTime: DateTime.now(),
      history: const {},
      showAdvancedOptions: false,
    );
    _saveState();
  }

  /// Inicia una sesión desde una plantilla guardada
  Future<void> startSessionFromTemplate(SessionTemplate template) async {
    final sessionExercises = template.exercises.map((e) {
      final logs = e.sets.map((set) {
        return SerieLog(
          peso: set.weight,
          reps: set.reps,
          completed: false,
          isWarmup: set.isWarmup,
          isFailure: set.isFailure,
          isDropset: set.isDropset,
          isRestPause: set.isRestPause,
          isMyoReps: set.isMyoReps,
          isAmrap: set.isAmrap,
        );
      }).toList();

      return Ejercicio(
        id: const Uuid().v4(),
        libraryId: e.libraryId,
        nombre: e.name,
        musculosPrincipales: e.musclesPrimary,
        musculosSecundarios: e.musclesSecondary,
        series: logs.length,
        reps: logs.isNotEmpty ? logs.first.reps : 0,
        peso: logs.isNotEmpty ? logs.first.peso : 0.0,
        descansoSugeridoSeconds: e.suggestedRestSeconds,
        logs: logs,
      );
    }).toList();

    final historyMap =
        await _historyManager?.loadHistoryForExercises(sessionExercises) ?? {};

    state = TrainingState(
      activeRutina: null,
      dayName: 'Plantilla: ${template.name}',
      dayIndex: null,
      exercises: sessionExercises,
      targets: sessionExercises.map((e) => e.copyWith()).toList(),
      startTime: DateTime.now(),
      history: historyMap,
      showAdvancedOptions: false,
    );
    _saveState();
  }

  void updateLog(
    int exerciseIndex,
    int setIndex, {
    double? peso,
    int? reps,
    bool? completed,
    int? rpe,
    String? notas,
    int? restSeconds,
    bool? isFailure,
    bool? isDropset,
    bool? isRestPause,
    bool? isWarmup,
    bool? isMyoReps,
    bool? isAmrap,
    bool skipToleranceCheck =
        false, // 🎯 Skip validation when user accepted a correction
  }) {
    final exercises = [...state.exercises];
    final exercise = exercises[exerciseIndex];
    final logs = [...exercise.logs];
    final log = logs[setIndex];
    final wasCompleted = log.completed;
    final previousLog = log.copyWith();
    final completedValue = completed ?? log.completed;

    // ═══════════════════════════════════════════════════════════════════════
    // ERROR TOLERANCE: Validación tolerante de peso (nunca bloquea)
    // ═══════════════════════════════════════════════════════════════════════
    final validatedPeso = peso;
    ToleranceResult? toleranceResult;

    // 🎯 FIX: Skip validation if user already accepted a correction (prevents infinite loop)
    if (peso != null && peso > 0 && !skipToleranceCheck) {
      final category = ExerciseCategory.inferFromName(exercise.nombre);
      final lastKnownWeight = log.peso > 0
          ? log.peso
          : _getLastKnownWeight(exercise);

      toleranceResult = ErrorToleranceRules.evaluateDataEntry(
        enteredWeight: peso,
        lastKnownWeight: lastKnownWeight,
        exerciseName: exercise.nombre,
        category: category,
      );

      // 🎯 ERROR TOLERANCE: Si es sospechoso, notificar al provider para mostrar diálogo
      if (toleranceResult.severity == ToleranceSeverity.medium &&
          toleranceResult.userMessage != null &&
          lastKnownWeight > 0) {
        // Calcular peso sugerido (detectar error de dedo: 500 → 50)
        var suggestedWeight = lastKnownWeight;
        if (peso > lastKnownWeight * 5) {
          suggestedWeight = peso / 10; // Probablemente un 0 de más
        } else if (peso < lastKnownWeight * 0.2) {
          suggestedWeight = peso * 10; // Probablemente falta un 0
        }

        final currentSuspicious = ref.read(suspiciousDataProvider);
        // Evitar sobrescribir si ya hay un diálogo mostrándose y programar la notificación
        if (!currentSuspicious.dialogShowing) {
          Future.microtask(() {
            ref
                .read(suspiciousDataProvider.notifier)
                .setSuspiciousData(
                  exerciseName: exercise.nombre,
                  enteredWeight: peso,
                  suggestedWeight: suggestedWeight,
                  exerciseIndex: exerciseIndex,
                  setIndex: setIndex,
                );
          });
        }
        Logger().w(
          'Peso sospechoso en ${exercise.nombre}: $peso kg (sugerido: $suggestedWeight kg)',
        );
      } else if (toleranceResult.needsCorrection &&
          toleranceResult.correctedValue != null) {
        Logger().w(
          'Peso sospechoso en ${exercise.nombre}: $peso kg (esperado ~$lastKnownWeight kg)',
        );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HARD LIMITS: Forzar límites absolutos para proteger integridad de datos
    // Esto evita que outliers arruinen gráficas y análisis
    // ═══════════════════════════════════════════════════════════════════════
    final finalPeso = ErrorToleranceRules.enforceWeightLimits(
      validatedPeso ?? log.peso,
    );
    final finalReps = ErrorToleranceRules.enforceRepsLimits(reps ?? log.reps);

    // Validar RPE en rango 1-10
    final validRpe = rpe != null ? rpe.clamp(1, 10) : log.rpe;

    final newLog = SerieLog(
      id: log.id, // Preserve UUID
      peso: finalPeso,
      reps: finalReps,
      completed: completedValue,
      rpe: validRpe,
      notas: notas ?? log.notas,
      restSeconds: restSeconds ?? log.restSeconds,
      isFailure: isFailure ?? log.isFailure,
      isDropset: isDropset ?? log.isDropset,
      isRestPause: isRestPause ?? log.isRestPause,
      isWarmup: isWarmup ?? log.isWarmup,
      isMyoReps: isMyoReps ?? log.isMyoReps,
      isAmrap: isAmrap ?? log.isAmrap,
    );

    logs[setIndex] = newLog;
    final newExercise = exercise.copyWith(logs: logs);
    exercises[exerciseIndex] = newExercise;

    state = state.copyWith(exercises: exercises);
    _saveState();

    if (!wasCompleted && completedValue) {
      _lastCompletedSet = (
        exerciseIndex: exerciseIndex,
        setIndex: setIndex,
        previousLog: previousLog,
      );
      _maybeAutoStartRest(
        exerciseIndex: exerciseIndex,
        setIndex: setIndex,
        log: newLog,
      );
    }
  }

  void _maybeAutoStartRest({
    required int exerciseIndex,
    required int setIndex,
    required SerieLog log,
  }) {
    final settings = ref.read(settingsProvider);
    if (!settings.autoStartTimer) return;
    if (log.peso <= 0 && log.reps <= 0) return;

    startRestForExercise(exerciseIndex, setIndex: setIndex);
  }

  bool undoLastCompletedSet() {
    final last = _lastCompletedSet;
    if (last == null) return false;

    updateLog(
      last.exerciseIndex,
      last.setIndex,
      peso: last.previousLog.peso,
      reps: last.previousLog.reps,
      completed: last.previousLog.completed,
      rpe: last.previousLog.rpe,
      notas: last.previousLog.notas,
      restSeconds: last.previousLog.restSeconds,
      isFailure: last.previousLog.isFailure,
        isDropset: last.previousLog.isDropset,
        isRestPause: last.previousLog.isRestPause,
        isWarmup: last.previousLog.isWarmup,
        isMyoReps: last.previousLog.isMyoReps,
        isAmrap: last.previousLog.isAmrap,
        skipToleranceCheck: true,
      );

    _lastCompletedSet = null;
    return true;
  }

  /// Obtiene el último peso conocido para un ejercicio (del historial)
  ///
  /// Ahora delega a SessionHistoryManager para mejor separación de responsabilidades
  double _getLastKnownWeight(Ejercicio exercise) {
    // Primero intentar con el cache del manager
    final managerWeight = _historyManager?.getLastKnownWeight(
      exercise.historyKey,
    );
    if (managerWeight != null && managerWeight > 0) return managerWeight;

    // Fallback al estado actual (para compatibilidad con sesiones restauradas)
    final key = exercise.historyKey;
    final historyLogs = state.history[key] ?? state.history[exercise.nombre];
    if (historyLogs != null && historyLogs.isNotEmpty) {
      // Buscar el primer log con peso > 0
      for (final log in historyLogs) {
        if (log.peso > 0) return log.peso;
      }
    }
    return 0.0;
  }

  void copyPreviousSet(int exerciseIndex, int setIndex) {
    if (setIndex == 0) return; // Cannot copy for first set

    final exercise = state.exercises[exerciseIndex];
    final prevLog = exercise.logs[setIndex - 1];

    updateLog(
      exerciseIndex,
      setIndex,
      peso: prevLog.peso,
      reps: prevLog.reps,
      rpe: prevLog.rpe,
      notas: prevLog.notas,
      // Don't copy completed status usually
    );
  }

  /// Aplica el historial de la última sesión a la sesión actual.
  ///
  /// - Si [overwriteExisting] es false, solo rellena sets vacíos.
  /// - Si [overwriteExisting] es true, reemplaza valores existentes.
  ///
  /// Devuelve cuántas series fueron aplicadas y en cuántos ejercicios.
  ({int setsApplied, int exercisesUpdated}) applyHistoryToCurrentSession({
    bool overwriteExisting = false,
  }) {
    if (state.exercises.isEmpty || state.history.isEmpty) {
      return (setsApplied: 0, exercisesUpdated: 0);
    }

    final exercises = [...state.exercises];
    var setsApplied = 0;
    var exercisesUpdated = 0;

    for (var exerciseIndex = 0;
        exerciseIndex < exercises.length;
        exerciseIndex++) {
      final exercise = exercises[exerciseIndex];
      final historyLogs =
          state.history[exercise.historyKey] ??
          state.history[exercise.nombre] ??
          const <SerieLog>[];

      if (historyLogs.isEmpty) continue;

      final logs = [...exercise.logs];
      var changed = false;
      final limit = historyLogs.length < logs.length
          ? historyLogs.length
          : logs.length;

      for (var setIndex = 0; setIndex < limit; setIndex++) {
        final current = logs[setIndex];
        final history = historyLogs[setIndex];

        // No sobrescribir si ya hay datos (modo relleno)
        if (!overwriteExisting &&
            (current.peso > 0 || current.reps > 0 || current.completed)) {
          continue;
        }

        // Evitar copiar sets vacíos
        if (history.peso <= 0 && history.reps <= 0) continue;

        logs[setIndex] = current.copyWith(
          peso: history.peso,
          reps: history.reps,
          rpe: history.rpe,
          completed: false,
        );
        changed = true;
        setsApplied++;
      }

      if (changed) {
        exercises[exerciseIndex] = exercise.copyWith(logs: logs);
        exercisesUpdated++;
      }
    }

    if (setsApplied > 0) {
      state = state.copyWith(exercises: exercises);
      _saveState();
    }

    return (setsApplied: setsApplied, exercisesUpdated: exercisesUpdated);
  }

  /// Aplica el historial a un ejercicio especÃ­fico de la sesiÃ³n.
  ///
  /// - Si [overwriteExisting] es false, solo rellena sets vacÃ­os.
  /// - Si [overwriteExisting] es true, reemplaza valores existentes.
  ///
  /// Devuelve cuÃ¡ntas series fueron aplicadas.
  int applyHistoryToExercise(
    int exerciseIndex, {
    bool overwriteExisting = false,
  }) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) {
      return 0;
    }

    final exercise = state.exercises[exerciseIndex];
    final historyLogs =
        state.history[exercise.historyKey] ??
        state.history[exercise.nombre] ??
        const <SerieLog>[];
    if (historyLogs.isEmpty) return 0;

    final logs = [...exercise.logs];
    var setsApplied = 0;
    final limit =
        historyLogs.length < logs.length ? historyLogs.length : logs.length;

    for (var setIndex = 0; setIndex < limit; setIndex++) {
      final current = logs[setIndex];
      final history = historyLogs[setIndex];

      if (!overwriteExisting &&
          (current.peso > 0 || current.reps > 0 || current.completed)) {
        continue;
      }

      if (history.peso <= 0 && history.reps <= 0) continue;

      logs[setIndex] = current.copyWith(
        peso: history.peso,
        reps: history.reps,
        rpe: history.rpe,
        completed: false,
      );
      setsApplied++;
    }

    if (setsApplied > 0) {
      final exercises = [...state.exercises];
      exercises[exerciseIndex] = exercise.copyWith(logs: logs);
      state = state.copyWith(exercises: exercises);
      _saveState();
    }

    return setsApplied;
  }

  /// Añade una serie adicional a un ejercicio durante la sesión
  void addSetToExercise(int exerciseIndex) {
    if (exerciseIndex >= state.exercises.length) return;

    final exercises = [...state.exercises];
    final exercise = exercises[exerciseIndex];

    // Crear una nueva serie vacía (o copiando peso/reps de la última si existe)
    SerieLog newLog;
      if (exercise.logs.isNotEmpty) {
        final lastLog = exercise.logs.last;
        newLog = SerieLog(
          peso: lastLog.peso,
          reps: lastLog.reps,
          completed: false,
          isFailure: lastLog.isFailure,
          isDropset: lastLog.isDropset,
          isRestPause: lastLog.isRestPause,
          isWarmup: lastLog.isWarmup,
          isMyoReps: lastLog.isMyoReps,
          isAmrap: lastLog.isAmrap,
        );
      } else {
        newLog = SerieLog(peso: 0.0, reps: 0, completed: false);
      }

    final newLogs = [...exercise.logs, newLog];
    final newExercise = exercise.copyWith(
      logs: newLogs,
      series: newLogs.length,
    );
    exercises[exerciseIndex] = newExercise;

    // NO actualizamos targets - la rutina original permanece intacta
    // Esto permite que la sesión sea flexible sin afectar futuros entrenamientos

    state = state.copyWith(exercises: exercises);
    _saveState();
  }

  /// Duplica una serie dentro del ejercicio en la sesion activa.
  void duplicateSet(int exerciseIndex, int setIndex) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercises = [...state.exercises];
    final exercise = exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= exercise.logs.length) return;

    final original = exercise.logs[setIndex];
      final newLog = SerieLog(
        peso: original.peso,
        reps: original.reps,
        completed: false,
        rpe: original.rpe,
        notas: original.notas,
        restSeconds: original.restSeconds,
        isFailure: original.isFailure,
        isDropset: original.isDropset,
        isRestPause: original.isRestPause,
        isWarmup: original.isWarmup,
        isMyoReps: original.isMyoReps,
        isAmrap: original.isAmrap,
      );

    final newLogs = [...exercise.logs]..insert(setIndex + 1, newLog);
    final newExercise = exercise.copyWith(
      logs: newLogs,
      series: newLogs.length,
    );
    exercises[exerciseIndex] = newExercise;

    state = state.copyWith(exercises: exercises);
    _saveState();
  }

  /// Reordena ejercicios dentro de la sesion activa.
  void reorderExercises(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.exercises.length) return;
    if (newIndex < 0) return;

    final exercises = [...state.exercises];
    final targets = [...state.targets];

    if (newIndex > exercises.length) {
      newIndex = exercises.length;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final movedExercise = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, movedExercise);

    if (targets.length == state.exercises.length) {
      final movedTarget = targets.removeAt(oldIndex);
      targets.insert(newIndex, movedTarget);
    }

    state = state.copyWith(exercises: exercises, targets: targets);
    _saveState();
  }

  /// Inserta un set en una posición específica (para warm-up)
  void insertSetAt({
    required int exerciseIndex,
    required int setIndex,
    required double weight,
    required int reps,
    bool isWarmup = false,
  }) {
    if (exerciseIndex >= state.exercises.length) return;

    final exercises = [...state.exercises];
    final exercise = exercises[exerciseIndex];

      final referenceLog = exercise.logs.isNotEmpty
          ? exercise.logs[
              (setIndex - 1).clamp(0, exercise.logs.length - 1).toInt()
            ]
          : null;

      // Crear nueva serie con valores especificados
      final newLog = SerieLog(
        peso: weight,
        reps: reps,
        completed: false,
        isWarmup: isWarmup,
        isFailure: !isWarmup && (referenceLog?.isFailure ?? false),
        isDropset: !isWarmup && (referenceLog?.isDropset ?? false),
        isRestPause: !isWarmup && (referenceLog?.isRestPause ?? false),
        isMyoReps: !isWarmup && (referenceLog?.isMyoReps ?? false),
        isAmrap: !isWarmup && (referenceLog?.isAmrap ?? false),
      );

    // Insertar en la posición específica
    final newLogs = [...exercise.logs];
    if (setIndex >= 0 && setIndex <= newLogs.length) {
      newLogs.insert(setIndex, newLog);
    } else {
      newLogs.add(newLog);
    }

    final newExercise = exercise.copyWith(
      logs: newLogs,
      series: newLogs.length,
    );
    exercises[exerciseIndex] = newExercise;

    state = state.copyWith(exercises: exercises);
    _saveState();
  }

  /// Elimina una serie de un ejercicio durante la sesión activa
  ///
  /// IMPORTANTE: Solo afecta a la sesión actual, NO modifica:
  /// - La rutina base (targets permanecen intactos)
  /// - Futuros entrenamientos
  /// - El motor de progresión (usa ejerciciosCompletados, no targets)
  void removeSetFromExercise(int exerciseIndex, int setIndex) {
    if (exerciseIndex >= state.exercises.length) return;

    final exercises = [...state.exercises];
    final exercise = exercises[exerciseIndex];

    // Protección: no eliminar si solo queda una serie
    if (exercise.logs.length <= 1) return;

    // Protección: índice válido
    if (setIndex < 0 || setIndex >= exercise.logs.length) return;

    final newLogs = [...exercise.logs]..removeAt(setIndex);
    final newExercise = exercise.copyWith(
      logs: newLogs,
      series: newLogs.length,
    );
    exercises[exerciseIndex] = newExercise;

    // NO tocamos targets - la rutina original permanece intacta
    state = state.copyWith(exercises: exercises);
    _saveState();
  }

  /// Marca o desmarca todas las series de un ejercicio en la sesión activa.
  void setExerciseCompletion(int exerciseIndex, {required bool completed}) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercises = [...state.exercises];
    final exercise = exercises[exerciseIndex];
    final newLogs = exercise.logs
        .map((log) => log.copyWith(completed: completed))
        .toList();

    exercises[exerciseIndex] = exercise.copyWith(logs: newLogs);
    state = state.copyWith(exercises: exercises);
    _saveState();
  }

  /// Añade un ejercicio a la sesión activa desde la biblioteca
  void addExerciseToSession(
    LibraryExercise libExercise, {
    int series = 3,
    int reps = 10,
  }) {
    final newExercise = Ejercicio(
      id: const Uuid().v4(),
      libraryId: libExercise.id.toString(),
      nombre: libExercise.name,
      musculosPrincipales: libExercise.muscles,
      musculosSecundarios: libExercise.secondaryMuscles,
      series: series,
      reps: reps,
        logs: List.generate(
          series,
          (_) => _buildDefaultLog(TrainingSetType.normal),
        ),
      );

    final exercises = [...state.exercises, newExercise];
    final targets = [...state.targets, newExercise.copyWith()];

    state = state.copyWith(exercises: exercises, targets: targets);
    _saveState();
  }

  /// 🆕 QUICK SWAP: Reemplaza un ejercicio en la sesión activa por una alternativa.
  ///
  /// CRÍTICO: Este método solo modifica la sesión activa (state.exercises),
  /// NO modifica la rutina base (targets se preserva intacto).
  ///
  /// [exerciseIndex] - Índice del ejercicio a reemplazar en state.exercises
  /// [newExercise] - Nuevo ejercicio de la biblioteca
  /// [preserveCompletedSets] - Si es true, intenta transferir series completadas
  ///                           del ejercicio original al nuevo (misma cantidad)
  void swapExerciseInSession({
    required int exerciseIndex,
    required LibraryExercise newExercise,
    bool preserveCompletedSets = true,
  }) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final originalExercise = state.exercises[exerciseIndex];
    final originalLogs = originalExercise.logs;

    // Calcular cuántas series preservar (las completadas, hasta un máximo razonable)
    final completedSetsCount = originalLogs.where((l) => l.completed).length;
    final targetSets = preserveCompletedSets && completedSetsCount > 0
        ? originalLogs
              .length // Mantener misma cantidad de series
        : originalExercise.series; // O usar el default del ejercicio

    // Crear logs para el nuevo ejercicio
    // Si preservamos, copiamos peso/reps de las series completadas como sugerencia
    final newLogs = List<SerieLog>.generate(targetSets, (index) {
      if (preserveCompletedSets &&
          index < completedSetsCount &&
          index < originalLogs.length) {
        // Copiar datos de la serie completada como "sugerencia" (no completada)
        final originalLog = originalLogs[index];
          return SerieLog(
            peso: originalLog.peso,
            reps: originalLog.reps,
            completed: false, // Resetear estado de completado
            rpe: originalLog.rpe,
            notas: index == 0
                ? 'Sustituido desde: ${originalExercise.nombre}'
                : null,
            restSeconds: originalLog.restSeconds,
            isFailure: originalLog.isFailure,
            isDropset: originalLog.isDropset,
            isRestPause: originalLog.isRestPause,
            isWarmup: originalLog.isWarmup,
            isMyoReps: originalLog.isMyoReps,
            isAmrap: originalLog.isAmrap,
          );
        }
        return _buildDefaultLog(TrainingSetType.normal);
      });

    // Crear el nuevo ejercicio con los logs preparados
    final swappedExercise = Ejercicio(
      id: const Uuid().v4(), // Nuevo ID de instancia
      libraryId: newExercise.id.toString(),
      nombre: newExercise.name,
      musculosPrincipales: newExercise.muscles,
      musculosSecundarios: newExercise.secondaryMuscles,
      series: targetSets,
      reps: originalExercise.reps, // Preservar target de reps
      notas: 'Sustituido desde: ${originalExercise.nombre}',
      logs: newLogs,
    );

    // Reemplazar en la lista de ejercicios activos
    final exercises = [...state.exercises];
    exercises[exerciseIndex] = swappedExercise;

    // NOTA: Los targets NO se modifican - la rutina base permanece intacta
    state = state.copyWith(exercises: exercises);
    _saveState();

    _logger.d(
      'QuickSwap: ${originalExercise.nombre} → ${newExercise.name} '
      '(preservados $completedSetsCount sets)',
    );
  }

  void toggleAdvancedOptions(bool show) {
    state = state.copyWith(showAdvancedOptions: show);
    _saveState();
  }

  void toggleTimerBar(bool show) {
    state = state.copyWith(showTimerBar: show);
    // No guardar en BD, es solo UI temporal
  }

  void setRestDuration(int seconds) {
    state = state.copyWith(
      defaultRestSeconds: seconds,
      restTimer: state.restTimer.copyWith(totalSeconds: seconds),
    );
    _saveState();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIMER DE DESCANSO - Delegado a RestTimerController
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inicia el timer de descanso para un ejercicio específico
  /// @param exerciseIndex Índice del ejercicio que acaba de completarse
  /// @param setIndex Índice del set que acaba de completarse (para auto-focus)
  /// @return true si el timer se inició, false si estamos en medio de un superset
  bool startRestForExercise(int exerciseIndex, {int? setIndex}) {
    // Verificar lógica de superseries usando el controlador
    if (setIndex != null &&
        !_timerController.shouldStartTimerForSuperset(
          exerciseIndex: exerciseIndex,
          setIndex: setIndex,
          exercises: state.exercises,
        )) {
      return false;
    }

    final exercise = state.exercises[exerciseIndex];
    var restTime = _timerController.getSupersetRestTime(
      exerciseIndex: exerciseIndex,
      exercises: state.exercises,
      defaultRestSeconds: state.defaultRestSeconds,
    );

    // Fallback: buscar tiempo configurado en la rutina activa
    if (restTime == state.defaultRestSeconds && state.activeRutina != null) {
      for (final day in state.activeRutina!.dias) {
        final match = day.ejercicios.firstWhereOrNull(
          (e) => e.instanceId == exercise.id,
        );
        if (match != null && match.descansoSugerido != null) {
          restTime = match.descansoSugerido!.inSeconds;
          break;
        }
      }
    }

    state = state.copyWith(defaultRestSeconds: restTime);
    _timerController.start(
      seconds: restTime,
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
    );
    _saveState();
    return true;
  }

  void startRest() {
    _timerController.start(seconds: state.defaultRestSeconds);
    _saveState();
  }

  void stopRest({bool saveRestTime = true}) {
    // Guardar el tiempo de descanso real en el SerieLog (para analytics)
    if (saveRestTime && state.restTimer.isActive) {
      final exerciseIndex = state.restTimer.lastCompletedExerciseIndex;
      final setIndex = state.restTimer.lastCompletedSetIndex;
      if (exerciseIndex != null && setIndex != null) {
        final actualRestTime = _timerController.stop();
        if (actualRestTime != null && actualRestTime > 0) {
          _updateLogRestTime(exerciseIndex, setIndex, actualRestTime);
        }
      } else {
        _timerController.stop(saveRestTime: false);
      }
    } else {
      _timerController.stop(saveRestTime: false);
    }
    _saveState();
  }

  /// Actualiza el tiempo de descanso en un SerieLog específico (para analytics)
  void _updateLogRestTime(int exerciseIndex, int setIndex, int restSeconds) {
    final exercises = [...state.exercises];
    if (exerciseIndex >= exercises.length) return;

    final exercise = exercises[exerciseIndex];
    if (setIndex >= exercise.logs.length) return;

    final logs = [...exercise.logs];
    final log = logs[setIndex];

    logs[setIndex] = SerieLog(
      id: log.id,
      peso: log.peso,
      reps: log.reps,
      completed: log.completed,
      rpe: log.rpe,
      notas: log.notas,
      restSeconds: restSeconds,
      isFailure: log.isFailure,
      isDropset: log.isDropset,
      isRestPause: log.isRestPause,
      isWarmup: log.isWarmup,
      isMyoReps: log.isMyoReps,
      isAmrap: log.isAmrap,
    );

    exercises[exerciseIndex] = exercise.copyWith(logs: logs);
    state = state.copyWith(exercises: exercises);
  }

  void pauseRest() {
    _timerController.pause();
    _saveState();
  }

  void resumeRest() {
    _timerController.resume();
    _saveState();
  }

  void addRestTime(int seconds) {
    _timerController.addTime(seconds);
    _saveState();
  }

  void restartRest() {
    final lastIndex = state.restTimer.lastCompletedExerciseIndex;
    final restTime = lastIndex != null
        ? _timerController.getSupersetRestTime(
            exerciseIndex: lastIndex,
            exercises: state.exercises,
            defaultRestSeconds: state.defaultRestSeconds,
          )
        : state.defaultRestSeconds;
    _timerController.restart(restTime);
    _saveState();
  }

  /// Actualiza el tiempo de descanso sugerido para un ejercicio específico
  void updateExerciseRestTime(int exerciseIndex, int seconds) {
    final exercises = [...state.exercises];
    final exercise = exercises[exerciseIndex];

    exercises[exerciseIndex] = exercise.copyWith(
      descansoSugeridoSeconds: seconds,
    );
    state = state.copyWith(exercises: exercises);
    _saveState();
  }

  /// Resultado del guardado de sesión para feedback al usuario
  SessionSaveResult? _lastSaveResult;

  /// Getter para obtener el resultado del último guardado
  SessionSaveResult? get lastSaveResult => _lastSaveResult;

  /// Limpia el resultado del guardado (llamar después de mostrar feedback)
  void clearLastSaveResult() {
    _lastSaveResult = null;
  }

  Future<void> finishSession() async {
    if (state.startTime == null) return;
    if (state.exercises.isEmpty) return;

    await flushPendingSave();

    final endTime = DateTime.now();
    final durationSeconds = endTime.difference(state.startTime!).inSeconds;

    // Contar series completadas para feedback
    var completedSets = 0;
    var totalSets = 0;
    for (final ex in state.exercises) {
      for (final log in ex.logs) {
        totalSets++;
        if (log.completed) completedSets++;
      }
    }

    final sesion = Sesion(
      id: const Uuid().v4(),
      rutinaId: state.activeRutina?.id ?? '',
      dayName: state.dayName,
      dayIndex: state.dayIndex,
      fecha: endTime,
      ejerciciosCompletados: state.exercises,
      ejerciciosObjetivo: state.targets,
      durationSeconds: durationSeconds,
    );

    // Guardar sesión y limpiar de forma atómica
    await _repository.finishAndClearSession(sesion);
    await _timerController.clearPrefs();

    // Guardar resultado para feedback
    _lastSaveResult = SessionSaveResult(
      success: true,
      completedSets: completedSets,
      totalSets: totalSets,
      durationMinutes: durationSeconds ~/ 60,
    );

    state = TrainingState();
  }

  /// Descarta la sesión activa sin guardarla
  Future<void> discardSession() async {
    // Detener timer si está activo
    if (state.restTimer.isActive) {
      _timerController.stop(saveRestTime: false);
    }

    // Descartar sesión (cancela saves pendientes internamente)
    await _persistenceService.discardSession();
    await _timerController.clearPrefs();

    state = TrainingState();
    Logger().d('Sesión descartada correctamente');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSISTENCIA - Delegado a SessionPersistenceService
  // ═══════════════════════════════════════════════════════════════════════════

  /// Guarda el estado con debounce para evitar saves excesivos
  void _saveState() {
    _persistenceService.saveWithDebounce();
    _timerController.saveToPrefs();
  }

  /// Fuerza el save si hay uno pendiente (llamar antes de operaciones críticas)
  Future<void> flushPendingSave() async {
    await _persistenceService.flushPendingSave();
  }

  Future<void> clearStorage() async {
    await _persistenceService.clearActiveSession();
    await _timerController.clearPrefs();
  }

  Future<void> restoreFromStorage() async {
    final data = await _persistenceService.restoreSession();
    if (data != null) {
      state = TrainingState(
        activeRutina: data.activeRutina,
        exercises: data.exercises,
        targets: data.targets,
        startTime: data.startTime ?? DateTime.now(),
        defaultRestSeconds: data.defaultRestSeconds,
        history: data.history,
        showAdvancedOptions: false,
      );

      // Restaurar timer desde SharedPreferences
      await _timerController.loadFromPrefs();
      state = state.copyWith(
        restTimer: _timerController.state,
        isRestActive: _timerController.state.isActive,
      );
    }
  }
}

final trainingSessionProvider =
    NotifierProvider<TrainingSessionNotifier, TrainingState>(
      TrainingSessionNotifier.new,
    );

/// Resultado del guardado de sesión para feedback visual
class SessionSaveResult {
  final bool success;
  final int completedSets;
  final int totalSets;
  final int durationMinutes;

  const SessionSaveResult({
    required this.success,
    required this.completedSets,
    required this.totalSets,
    required this.durationMinutes,
  });

  double get completionRate => totalSets > 0 ? completedSets / totalSets : 0;
  bool get isComplete => completedSets == totalSets;
}

/// 🎯 HIGH-001: Niveles de urgencia para el scheduling
enum WorkoutUrgency {
  /// Descanso sugerido (entrenó hace <20h)
  rest,

  /// Listo para entrenar (20h-48h desde última sesión)
  ready,

  /// Deberías entrenar (48h-72h)
  shouldTrain,

  /// Urgente, perdiendo momentum (>72h)
  urgent,

  /// Nuevo usuario o reinicio (sin historial)
  fresh,
}

/// Modelo de sugerencia inteligente de próximo día a entrenar.
class SmartWorkoutSuggestion {
  final Rutina rutina;
  final int dayIndex;
  final String dayName;
  final String reason;

  /// Tiempo desde la última sesión de entrenamiento
  final Duration? timeSinceLastSession;

  /// Fecha de la última sesión
  final DateTime? lastSessionDate;

  /// Indica si es día de descanso (sugerido no entrenar)
  final bool isRestDay;

  /// 🎯 HIGH-001: Nivel de urgencia para priorización visual
  final WorkoutUrgency urgency;

  /// 🎯 HIGH-001: Subtítulo contextual adicional
  final String? contextualSubtitle;

  const SmartWorkoutSuggestion({
    required this.rutina,
    required this.dayIndex,
    required this.dayName,
    required this.reason,
    this.timeSinceLastSession,
    this.lastSessionDate,
    this.isRestDay = false,
    this.urgency = WorkoutUrgency.ready,
    this.contextualSubtitle,
  });

  /// Formato legible del tiempo desde última sesión - VERSIÓN BÁSICA
  String get timeSinceFormatted {
    if (timeSinceLastSession == null) return 'nuevo';
    final hours = timeSinceLastSession!.inHours;
    if (hours < 24) return 'hace ${hours}h';
    final days = timeSinceLastSession!.inDays;
    if (days == 1) return 'ayer';
    return 'hace $days días';
  }

  /// 🎯 QW-04: Formato contextual enriquecido con urgencia implícita
  String get timeSinceFormattedContextual {
    if (timeSinceLastSession == null) return 'Primera vez';
    final days = timeSinceLastSession!.inDays;
    final hours = timeSinceLastSession!.inHours;

    if (isRestDay) {
      return hours < 24
          ? 'Hace ${hours}h (recuperando)'
          : 'Ayer (lista para otra)';
    }

    if (days == 0) return hours < 12 ? 'Esta mañana' : 'Hoy temprano';
    if (days == 1) return 'Ayer';
    if (days <= 3) return 'Hace $days días';
    if (days <= 7) return 'Hace $days días (esta semana)';
    if (days <= 14) return 'Hace ${(days / 7).floor()} semanas';
    return '¡Hace $days días!';
  }

  /// 🎯 QW-04: Versión ultra-compacta para cards pequeñas
  String get timeSinceCompact {
    if (timeSinceLastSession == null) return '1ª vez';
    final days = timeSinceLastSession!.inDays;
    if (days == 0) return 'hoy';
    if (days == 1) return '1d';
    return '${days}d';
  }

  /// 🎯 QW-04: Mensaje motivacional basado en tiempo transcurrido
  String get motivationalMessage {
    if (timeSinceLastSession == null) return '¡Comienza tu viaje!';
    if (isRestDay) return 'Descansa, mañana más 💪';

    final days = timeSinceLastSession!.inDays;
    switch (urgency) {
      case WorkoutUrgency.ready:
        return days == 0 ? '¿Doble sesión? 🔥' : 'Recuperado al 100%';
      case WorkoutUrgency.shouldTrain:
        return 'No pierdas el ritmo 🎯';
      case WorkoutUrgency.urgent:
        return days > 7 ? '¡Te extrañamos! 🏋️' : 'Hoy toca 💪';
      default:
        return reason;
    }
  }
}

/// 🎯 HIGH-001: Provider que calcula el próximo día sugerido con scheduling inteligente.
///
/// Lógica mejorada:
/// 1. Si entrenó hace <20h → Sugerir DESCANSO (recuperación activa)
/// 2. Si entrenó hace 20-48h → LISTO para entrenar
/// 3. Si entrenó hace 48-72h → DEBERÍA entrenar
/// 4. Si entrenó hace >72h → URGENTE, perdiendo momentum
/// 5. Sin historial → FRESH start
final smartSuggestionProvider = FutureProvider<SmartWorkoutSuggestion?>((
  ref,
) async {
  final rutinasAsync = ref.watch(rutinasStreamProvider);
  final sessionsAsync = ref.watch(sesionesHistoryStreamProvider);

  final rutinas = rutinasAsync.asData?.value ?? [];
  final sessions = sessionsAsync.asData?.value ?? [];

  if (rutinas.isEmpty) return null;

  // Buscar la rutina más reciente usada en sesiones
  Rutina? lastUsedRutina;
  Sesion? lastSession;

  for (final session in sessions) {
    final matchingRutina = rutinas.firstWhereOrNull(
      (r) => r.id == session.rutinaId,
    );
    if (matchingRutina != null) {
      lastUsedRutina = matchingRutina;
      lastSession = session;
      break;
    }
  }

  // Si no hay historial, sugerir el primer día con ejercicios de la primera rutina
  if (lastUsedRutina == null) {
    final firstRutina = rutinas.first;
    if (firstRutina.dias.isEmpty) return null;
    // Buscar primer día que tenga ejercicios
    final firstValidDayIndex = firstRutina.dias.indexWhere(
      (d) => d.ejercicios.isNotEmpty,
    );
    if (firstValidDayIndex == -1) return null; // No hay días con ejercicios
    return SmartWorkoutSuggestion(
      rutina: firstRutina,
      dayIndex: firstValidDayIndex,
      dayName: firstRutina.dias[firstValidDayIndex].nombre,
      reason: 'Tu primer entreno',
      timeSinceLastSession: null,
      lastSessionDate: null,
      urgency: WorkoutUrgency.fresh,
      contextualSubtitle: 'El viaje de mil reps empieza con una serie',
    );
  }

  // Calcular siguiente día basado en el último entrenado
  if (lastSession != null && lastUsedRutina.dias.isNotEmpty) {
    final lastDayIndex = lastSession.dayIndex ?? -1;
    final totalDays = lastUsedRutina.dias.length;

    // Buscar siguiente día que tenga ejercicios (saltando días vacíos)
    var nextDayIndex = (lastDayIndex + 1) % totalDays;
    var attempts = 0;
    while (lastUsedRutina.dias[nextDayIndex].ejercicios.isEmpty &&
        attempts < totalDays) {
      nextDayIndex = (nextDayIndex + 1) % totalDays;
      attempts++;
    }

    // Si todos los días están vacíos, no sugerir nada
    if (attempts >= totalDays) return null;

    final nextDay = lastUsedRutina.dias[nextDayIndex];

    // Calcular tiempo desde última sesión
    final timeSince = DateTime.now().difference(lastSession.fecha);
    final hoursSince = timeSince.inHours;
    final daysSince = timeSince.inDays;

    // 🎯 HIGH-001: Determinar urgencia y razón basada en tiempo transcurrido
    WorkoutUrgency urgency;
    String reason;
    String? contextualSubtitle;
    bool isRestDay = false;

    if (hoursSince < 20) {
      // ═══════════════════════════════════════════════════════════════════════
      // DESCANSO SUGERIDO: Entrenó hace menos de 20 horas
      // La recuperación es donde ocurre la ganancia real
      // ═══════════════════════════════════════════════════════════════════════
      urgency = WorkoutUrgency.rest;
      reason = 'Día de recuperación';
      contextualSubtitle =
          'Entrenaste hace ${hoursSince}h. Los músculos crecen descansando.';
      isRestDay = true;
    } else if (hoursSince < 48) {
      // ═══════════════════════════════════════════════════════════════════════
      // LISTO: Ventana óptima para entrenar (20-48h)
      // ═══════════════════════════════════════════════════════════════════════
      urgency = WorkoutUrgency.ready;
      if (daysSince == 0) {
        reason = 'Recuperado y listo';
        contextualSubtitle =
            'Entrenaste hoy temprano, pero ya pasaron ${hoursSince}h';
      } else {
        reason = 'Toca ${nextDay.nombre}';
        contextualSubtitle = 'Última sesión: ayer';
      }
    } else if (hoursSince < 72) {
      // ═══════════════════════════════════════════════════════════════════════
      // DEBERÍA ENTRENAR: Pasaron 2-3 días
      // ═══════════════════════════════════════════════════════════════════════
      urgency = WorkoutUrgency.shouldTrain;
      reason = 'Sigue la racha';
      contextualSubtitle = 'Hace $daysSince días desde tu última sesión';
    } else {
      // ═══════════════════════════════════════════════════════════════════════
      // URGENTE: Más de 3 días sin entrenar
      // ═══════════════════════════════════════════════════════════════════════
      urgency = WorkoutUrgency.urgent;
      if (daysSince <= 7) {
        reason = 'Retoma el ritmo';
        contextualSubtitle = '$daysSince días sin entrenar. ¡Hoy es el día!';
      } else {
        reason = '¡Vuelve al gym!';
        contextualSubtitle = '$daysSince días. El hierro te extraña.';
      }
    }

    return SmartWorkoutSuggestion(
      rutina: lastUsedRutina,
      dayIndex: nextDayIndex,
      dayName: isRestDay ? 'DESCANSO' : nextDay.nombre,
      reason: reason,
      timeSinceLastSession: timeSince,
      lastSessionDate: lastSession.fecha,
      isRestDay: isRestDay,
      urgency: urgency,
      contextualSubtitle: contextualSubtitle,
    );
  }

  return null;
});
