import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/training/models/dia.dart';
import 'package:juan_tracker/training/models/ejercicio_en_rutina.dart';
import 'package:juan_tracker/training/models/rutina.dart';
import 'package:juan_tracker/training/models/training_block.dart';
import 'package:juan_tracker/training/providers/training_provider.dart';
import 'package:uuid/uuid.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ESTADO DEL EDITOR
// ═══════════════════════════════════════════════════════════════════════════

/// Estado completo del editor de rutinas con tracking de cambios
class RoutineEditorState {
  final Rutina routine;
  final bool isDirty;
  final bool isSaving;
  final String? error;
  final DateTime lastModified;

  const RoutineEditorState({
    required this.routine,
    this.isDirty = false,
    this.isSaving = false,
    this.error,
    required this.lastModified,
  });

  RoutineEditorState copyWith({
    Rutina? routine,
    bool? isDirty,
    bool? isSaving,
    String? error,
    bool clearError = false,
    DateTime? lastModified,
  }) {
    return RoutineEditorState(
      routine: routine ?? this.routine,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Verifica si la rutina es válida para guardar
  ValidationResult validate() {
    final errors = <String>[];
    final warnings = <String>[];

    if (routine.nombre.trim().isEmpty) {
      errors.add('La rutina necesita un nombre');
    }

    if (routine.dias.isEmpty) {
      errors.add('Añade al menos un día');
    }

    var hasExercises = false;
    for (int i = 0; i < routine.dias.length; i++) {
      final day = routine.dias[i];
      
      if (day.nombre.trim().isEmpty) {
        warnings.add('Día ${i + 1} sin nombre');
      }
      
      if (day.ejercicios.isNotEmpty) {
        hasExercises = true;
      } else {
        warnings.add('Día "${day.nombre}" sin ejercicios');
      }

      // Detectar duplicados
      final names = day.ejercicios.map((e) => e.nombre.toLowerCase()).toList();
      final duplicates = names.toSet().where((name) => 
        names.where((n) => n == name).length > 1
      ).toList();
      
      if (duplicates.isNotEmpty) {
        warnings.add('Ejercicios duplicados en ${day.nombre}: ${duplicates.join(', ')}');
      }
    }

    if (!hasExercises && routine.dias.isNotEmpty) {
      errors.add('Añade al menos un ejercicio');
    }

    // Validar modo Pro
    if (routine.isProMode) {
      if (routine.blocks.isEmpty) {
        warnings.add('Modo Pro activado sin bloques definidos');
      }
      
      // Verificar solapamientos
      for (int i = 0; i < routine.blocks.length; i++) {
        for (int j = i + 1; j < routine.blocks.length; j++) {
          if (routine.blocks[i].overlapsWith(routine.blocks[j])) {
            errors.add('Los bloques ${i + 1} y ${j + 1} se solapan');
          }
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }
}

/// Resultado de validación
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFIER PRINCIPAL DEL EDITOR
// ═══════════════════════════════════════════════════════════════════════════

/// Notifier principal para la edición de rutinas
/// 
/// Gestiona el estado completo de una rutina en edición, incluyendo:
/// - Tracking de cambios (dirty state)
/// - Deep copy para evitar modificaciones accidentales
/// - Historial para undo/redo (futuro)
/// - Validación en tiempo real
class RoutineEditorNotifier extends StateNotifier<RoutineEditorState> {
  final Ref _ref;
  Rutina? _originalRoutine;
  final _equality = const DeepCollectionEquality();

  RoutineEditorNotifier(this._ref, {Rutina? initialRoutine}) 
      : super(RoutineEditorState(
          routine: initialRoutine?.deepCopy() ?? _createEmptyRoutine(),
          lastModified: DateTime.now(),
        )) {
    _originalRoutine = initialRoutine?.deepCopy();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREACIÓN Y UTILIDADES
  // ─────────────────────────────────────────────────────────────────────────

  static Rutina _createEmptyRoutine() {
    return Rutina(
      id: const Uuid().v4(),
      nombre: '',
      dias: [],
      creada: DateTime.now(),
    );
  }

  /// Compara la rutina actual con la original para detectar cambios
  bool _detectChanges(Rutina current) {
    if (_originalRoutine == null) {
      // Nueva rutina: tiene cambios si tiene contenido
      return current.nombre.isNotEmpty || 
             current.dias.any((d) => d.ejercicios.isNotEmpty);
    }

    return !_equality.equals(current.toJson(), _originalRoutine!.toJson());
  }

  /// Actualiza el estado y detecta cambios
  void _updateState(Rutina newRoutine) {
    final isDirty = _detectChanges(newRoutine);
    state = state.copyWith(
      routine: newRoutine,
      isDirty: isDirty,
      lastModified: DateTime.now(),
      clearError: true,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACCIONES DE RUTINA
  // ─────────────────────────────────────────────────────────────────────────

  /// Actualiza el nombre de la rutina
  void updateName(String name) {
    _updateState(state.routine.copyWith(nombre: name));
  }

  /// Guarda la rutina en la base de datos
  Future<String?> save() async {
    final validation = state.validate();
    if (!validation.isValid) {
      state = state.copyWith(error: validation.errors.first);
      return validation.errors.first;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      // Validar IDs únicos
      final dayIds = state.routine.dias.map((d) => d.id).toList();
      if (dayIds.length != dayIds.toSet().length) {
        throw Exception('IDs de días duplicados');
      }

      final exerciseIds = state.routine.dias
          .expand((d) => d.ejercicios.map((e) => e.instanceId))
          .toList();
      if (exerciseIds.length != exerciseIds.toSet().length) {
        throw Exception('IDs de ejercicios duplicados');
      }

      final repository = _ref.read(trainingRepositoryProvider);
      await repository.saveRutina(state.routine);

      // Actualizar referencia original después de guardar
      _originalRoutine = state.routine.deepCopy();
      
      state = state.copyWith(
        isDirty: false,
        isSaving: false,
        clearError: true,
      );
      
      return null; // Éxito
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Error al guardar: $e',
      );
      return 'Error al guardar: $e';
    }
  }

  /// Descarta cambios y restaura la rutina original
  void discardChanges() {
    if (_originalRoutine != null) {
      state = RoutineEditorState(
        routine: _originalRoutine!.deepCopy(),
        isDirty: false,
        lastModified: DateTime.now(),
      );
    } else {
      state = RoutineEditorState(
        routine: _createEmptyRoutine(),
        isDirty: false,
        lastModified: DateTime.now(),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACCIONES DE DÍAS
  // ─────────────────────────────────────────────────────────────────────────

  /// Añade un nuevo día
  void addDay({String? name}) {
    final newDay = Dia(
      nombre: name ?? '',
      ejercicios: [],
    );
    
    _updateState(state.routine.copyWith(
      dias: [...state.routine.dias, newDay],
    ));
  }

  /// Elimina un día
  void removeDay(int index) {
    if (index < 0 || index >= state.routine.dias.length) return;
    
    final newDias = [...state.routine.dias]..removeAt(index);
    _updateState(state.routine.copyWith(dias: newDias));
  }

  /// Duplica un día completo
  void duplicateDay(int index) {
    if (index < 0 || index >= state.routine.dias.length) return;
    
    final original = state.routine.dias[index];
    final newDay = _duplicateDay(original);
    
    final newDias = [...state.routine.dias, newDay];
    _updateState(state.routine.copyWith(dias: newDias));
  }

  Dia _duplicateDay(Dia original) {
    final supersetMap = <String, String>{};
    const uuid = Uuid();

    final newExercises = original.ejercicios.map((ex) {
      String? newSupersetId;
      if (ex.supersetId != null) {
        newSupersetId = supersetMap.putIfAbsent(ex.supersetId!, () => uuid.v4());
      }
      
      return ex.copyWith(
        instanceId: uuid.v4(),
        supersetId: newSupersetId,
      );
    }).toList();

    return Dia(
      id: uuid.v4(),
      nombre: '${original.nombre} (Copia)',
      ejercicios: newExercises,
      progressionType: original.progressionType,
    );
  }

  /// Reordena días
  void reorderDays(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.routine.dias.length) return;
    
    final newDias = [...state.routine.dias];
    final item = newDias.removeAt(oldIndex);
    
    // Ajustar índice si es necesario
    var targetIndex = newIndex;
    if (oldIndex < newIndex) targetIndex--;
    if (targetIndex < 0) targetIndex = 0;
    if (targetIndex > newDias.length) targetIndex = newDias.length;
    
    newDias.insert(targetIndex, item);
    _updateState(state.routine.copyWith(dias: newDias));
  }

  /// Actualiza un día completo
  void updateDay(int index, Dia updatedDay) {
    if (index < 0 || index >= state.routine.dias.length) return;
    
    final newDias = [...state.routine.dias];
    newDias[index] = updatedDay;
    _updateState(state.routine.copyWith(dias: newDias));
  }

  /// Actualiza el nombre de un día
  void updateDayName(int index, String name) {
    if (index < 0 || index >= state.routine.dias.length) return;
    
    final day = state.routine.dias[index];
    updateDay(index, day.copyWith(nombre: name));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACCIONES DE EJERCICIOS
  // ─────────────────────────────────────────────────────────────────────────

  /// Añade un ejercicio a un día
  void addExercise(int dayIndex, EjercicioEnRutina exercise) {
    if (dayIndex < 0 || dayIndex >= state.routine.dias.length) return;
    
    final day = state.routine.dias[dayIndex];
    final newExercises = [...day.ejercicios, exercise];
    
    updateDay(dayIndex, day.copyWith(ejercicios: newExercises));
  }

  /// Elimina un ejercicio
  void removeExercise(int dayIndex, int exerciseIndex) {
    if (dayIndex < 0 || dayIndex >= state.routine.dias.length) return;
    
    final day = state.routine.dias[dayIndex];
    if (exerciseIndex < 0 || exerciseIndex >= day.ejercicios.length) return;
    
    final newExercises = [...day.ejercicios];
    final removed = newExercises.removeAt(exerciseIndex);
    
    // Limpiar superset si queda solo uno
    if (removed.supersetId != null) {
      final remaining = newExercises.where((e) => e.supersetId == removed.supersetId).toList();
      if (remaining.length == 1) {
        final idx = newExercises.indexOf(remaining.first);
        newExercises[idx] = newExercises[idx].copyWith(supersetId: null);
      }
    }
    
    updateDay(dayIndex, day.copyWith(ejercicios: newExercises));
  }

  /// Actualiza un ejercicio específico
  void updateExercise(int dayIndex, int exerciseIndex, EjercicioEnRutina updated) {
    if (dayIndex < 0 || dayIndex >= state.routine.dias.length) return;
    
    final day = state.routine.dias[dayIndex];
    if (exerciseIndex < 0 || exerciseIndex >= day.ejercicios.length) return;
    
    final newExercises = [...day.ejercicios];
    newExercises[exerciseIndex] = updated;
    
    updateDay(dayIndex, day.copyWith(ejercicios: newExercises));
  }

  /// Duplica un ejercicio
  void duplicateExercise(int dayIndex, int exerciseIndex) {
    if (dayIndex < 0 || dayIndex >= state.routine.dias.length) return;
    
    final day = state.routine.dias[dayIndex];
    if (exerciseIndex < 0 || exerciseIndex >= day.ejercicios.length) return;
    
    final original = day.ejercicios[exerciseIndex];
    final duplicate = original.copyWith(
      instanceId: const Uuid().v4(),
      supersetId: null, // No copiar superset
    );
    
    final newExercises = [...day.ejercicios];
    newExercises.insert(exerciseIndex + 1, duplicate);
    
    updateDay(dayIndex, day.copyWith(ejercicios: newExercises));
  }

  /// Reordena ejercicios
  void reorderExercises(int dayIndex, int oldIndex, int newIndex) {
    if (dayIndex < 0 || dayIndex >= state.routine.dias.length) return;
    
    final day = state.routine.dias[dayIndex];
    if (oldIndex < 0 || oldIndex >= day.ejercicios.length) return;
    
    final newExercises = [...day.ejercicios];
    final item = newExercises.removeAt(oldIndex);
    
    var targetIndex = newIndex;
    if (oldIndex < newIndex) targetIndex--;
    if (targetIndex < 0) targetIndex = 0;
    if (targetIndex > newExercises.length) targetIndex = newExercises.length;
    
    newExercises.insert(targetIndex, item);
    
    updateDay(dayIndex, day.copyWith(ejercicios: newExercises));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUPERSETS
  // ─────────────────────────────────────────────────────────────────────────

  /// Crea un superset entre dos ejercicios
  void createSuperset(int dayIndex, int indexA, int indexB) {
    if (dayIndex < 0 || dayIndex >= state.routine.dias.length) return;
    if (indexA == indexB) return;
    
    final day = state.routine.dias[dayIndex];
    if (indexA < 0 || indexA >= day.ejercicios.length) return;
    if (indexB < 0 || indexB >= day.ejercicios.length) return;
    
    final newExercises = [...day.ejercicios];
    final exA = newExercises[indexA];
    final exB = newExercises[indexB];
    
    // Usar ID existente o crear nuevo
    final supersetId = exA.supersetId ?? exB.supersetId ?? const Uuid().v4();
    
    newExercises[indexA] = exA.copyWith(supersetId: supersetId);
    newExercises[indexB] = exB.copyWith(supersetId: supersetId);
    
    // Reordenar para que estén contiguos
    _makeSupersetContiguous(newExercises, supersetId);
    
    updateDay(dayIndex, day.copyWith(ejercicios: newExercises));
  }

  /// Elimina un ejercicio de un superset
  void removeFromSuperset(int dayIndex, int exerciseIndex) {
    if (dayIndex < 0 || dayIndex >= state.routine.dias.length) return;
    
    final day = state.routine.dias[dayIndex];
    if (exerciseIndex < 0 || exerciseIndex >= day.ejercicios.length) return;
    
    final exercise = day.ejercicios[exerciseIndex];
    if (exercise.supersetId == null) return;
    
    final newExercises = [...day.ejercicios];
    newExercises[exerciseIndex] = exercise.copyWith(supersetId: null);
    
    // Si queda solo uno, limpiar su supersetId también
    final remaining = newExercises.where((e) => e.supersetId == exercise.supersetId).toList();
    if (remaining.length == 1) {
      final idx = newExercises.indexOf(remaining.first);
      newExercises[idx] = newExercises[idx].copyWith(supersetId: null);
    }
    
    updateDay(dayIndex, day.copyWith(ejercicios: newExercises));
  }

  void _makeSupersetContiguous(List<EjercicioEnRutina> exercises, String supersetId) {
    final supersetExercises = exercises.where((e) => e.supersetId == supersetId).toList();
    if (supersetExercises.length < 2) return;
    
    // Encontrar la primera posición
    final firstIndex = exercises.indexWhere((e) => e.supersetId == supersetId);
    
    // Remover todos los del superset
    exercises.removeWhere((e) => e.supersetId == supersetId);
    
    // Insertar en la primera posición
    exercises.insertAll(firstIndex, supersetExercises);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODO PRO (BLOQUES)
  // ─────────────────────────────────────────────────────────────────────────

  /// Activa/desactiva modo Pro
  void toggleProMode() {
    final newProMode = !state.routine.isProMode;
    _updateState(state.routine.copyWith(
      isProMode: newProMode,
      blocks: newProMode ? state.routine.blocks : [],
    ));
  }

  /// Añade un bloque
  void addBlock(TrainingBlock block) {
    _updateState(state.routine.copyWith(
      blocks: [...state.routine.blocks, block],
    ));
  }

  /// Actualiza un bloque
  void updateBlock(TrainingBlock updated) {
    final index = state.routine.blocks.indexWhere((b) => b.id == updated.id);
    if (index < 0) return;
    
    final newBlocks = [...state.routine.blocks];
    newBlocks[index] = updated;
    
    _updateState(state.routine.copyWith(blocks: newBlocks));
  }

  /// Elimina un bloque
  void removeBlock(String blockId) {
    _updateState(state.routine.copyWith(
      blocks: state.routine.blocks.where((b) => b.id != blockId).toList(),
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════

/// Provider family para el editor de rutinas
/// 
/// Usar: ref.watch(routineEditorProvider(rutinaExistente))
/// Para nueva rutina: ref.watch(routineEditorProvider(null))
final routineEditorProvider = StateNotifierProvider.family<RoutineEditorNotifier, RoutineEditorState, Rutina?>(
  (ref, initialRoutine) => RoutineEditorNotifier(ref, initialRoutine: initialRoutine),
);

/// Provider para el estado de validación actual
final routineValidationProvider = Provider<ValidationResult>((ref) {
  final editorState = ref.watch(routineEditorProvider(null));
  return editorState.validate();
});

/// Provider para saber si hay cambios sin guardar
final routineIsDirtyProvider = Provider<bool>((ref) {
  final editorState = ref.watch(routineEditorProvider(null));
  return editorState.isDirty;
});

/// Provider para estadísticas de la rutina
final routineStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final routine = ref.watch(routineEditorProvider(null)).routine;
  
  final totalExercises = routine.dias.fold<int>(
    0, (sum, d) => sum + d.ejercicios.length,
  );
  
  final totalSets = routine.dias.fold<int>(
    0, (sum, d) => sum + d.ejercicios.fold(0, (s, e) => s + e.series),
  );
  
  final muscleGroups = <String>{};
  for (final day in routine.dias) {
    for (final ex in day.ejercicios) {
      muscleGroups.addAll(ex.musculosPrincipales);
    }
  }
  
  // Estimación de tiempo: ~2 min por ejercicio + ~30s por serie
  final estimatedMinutes = (routine.dias.length * 5) + (totalSets * 2);
  
  return {
    'totalDays': routine.dias.length,
    'totalExercises': totalExercises,
    'totalSets': totalSets,
    'muscleGroups': muscleGroups.toList(),
    'estimatedMinutes': estimatedMinutes,
    'isProMode': routine.isProMode,
    'blocksCount': routine.blocks.length,
  };
});

// ═══════════════════════════════════════════════════════════════════════════
// EXTENSIONES ÚTILES
// ═══════════════════════════════════════════════════════════════════════════

extension TrainingBlockOverlap on TrainingBlock {
  bool overlapsWith(TrainingBlock other) {
    if (id == other.id) return false;
    return startDate.isBefore(other.endDate) && endDate.isAfter(other.startDate);
  }
}
