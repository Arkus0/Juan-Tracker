import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../../diet/models/diary_entry_model.dart';
import '../../diet/models/weighin_model.dart';
import '../models/sesion.dart';
import '../models/serie_log.dart';

/// Tipo de exportación disponible
enum ExportType { training, diet, both }

/// Opción de columna para el export
class ColumnOption {
  final String key;
  final String label;
  final bool selectedByDefault;

  const ColumnOption(this.key, this.label, this.selectedByDefault);
}

/// Datos de sesión exportados
class SessionExportData {
  final DateTime date;
  final String? notes;
  final List<ExerciseExportData> exercises;

  SessionExportData({
    required this.date,
    this.notes,
    required this.exercises,
  });
}

/// Datos de ejercicio exportados
class ExerciseExportData {
  final String name;
  final List<SetExportData> sets;

  ExerciseExportData({
    required this.name,
    required this.sets,
  });
}

/// Datos de serie exportados
class SetExportData {
  final double weight;
  final int reps;
  final int? rpe;
  final String? notes;
  final bool isWarmup;
  final bool isFailure;
  final bool isDropset;
  final bool isRestPause;
  final bool isMyoReps;
  final bool isAmrap;

  double get volume => weight * reps;

  SetExportData({
    required this.weight,
    required this.reps,
    this.rpe,
    this.notes,
    this.isWarmup = false,
    this.isFailure = false,
    this.isDropset = false,
    this.isRestPause = false,
    this.isMyoReps = false,
    this.isAmrap = false,
  });
}

/// Servicio para generar archivos CSV de exportación
class CsvExportService {
  /// Columnas disponibles para exportación de entrenamiento
  static const List<ColumnOption> availableColumns = [
    ColumnOption('date', 'Fecha', true),
    ColumnOption('exercise', 'Ejercicio', true),
    ColumnOption('weight', 'Peso (kg)', true),
    ColumnOption('reps', 'Reps', true),
    ColumnOption('rpe', 'RPE', true),
    ColumnOption('volume', 'Volumen', true),
    ColumnOption('session_notes', 'Notas Sesión', false),
    ColumnOption('set_notes', 'Notas Serie', false),
    ColumnOption('is_warmup', 'Calentamiento', false),
    ColumnOption('is_failure', 'Fallo', false),
    ColumnOption('is_dropset', 'Dropset', false),
    ColumnOption('is_rest_pause', 'Rest-pause', false),
    ColumnOption('is_myo_reps', 'Myo reps', false),
    ColumnOption('is_amrap', 'AMRAP', false),
  ];

  /// Genera CSV de entrenamiento
  static String generateTrainingCSV({
    required List<SessionExportData> sessions,
    required List<String> columns,
  }) {
    final rows = <List<String>>[];

    // Header
    rows.add(columns.map(_getColumnHeader).toList());

    // Data rows
    for (final session in sessions) {
      for (final exercise in session.exercises) {
        for (final set in exercise.sets) {
          rows.add(_buildRow(session, exercise, set, columns));
        }
      }
    }

    // Convert to CSV con separador ; para compatibilidad Excel español
    // y UTF-8 BOM para caracteres especiales
    return '\uFEFF${const ListToCsvConverter(fieldDelimiter: ';').convert(rows)}';
  }

  static String _getColumnHeader(String column) {
    return switch (column) {
      'date' => 'Fecha',
      'exercise' => 'Ejercicio',
      'weight' => 'Peso (kg)',
      'reps' => 'Repeticiones',
      'rpe' => 'RPE',
      'volume' => 'Volumen (kg)',
      'session_notes' => 'Notas Sesión',
      'set_notes' => 'Notas Serie',
      'is_warmup' => 'Calentamiento',
      'is_failure' => 'Fallo',
      'is_dropset' => 'Dropset',
      'is_rest_pause' => 'Rest-pause',
      'is_myo_reps' => 'Myo reps',
      'is_amrap' => 'AMRAP',
      _ => column,
    };
  }

  static List<String> _buildRow(
    SessionExportData session,
    ExerciseExportData exercise,
    SetExportData set,
    List<String> columns,
  ) {
    return columns.map((column) {
      return switch (column) {
        'date' => DateFormat('dd/MM/yyyy').format(session.date),
        'exercise' => exercise.name,
        'weight' => set.weight.toStringAsFixed(1).replaceAll('.', ','),
        'reps' => set.reps.toString(),
        'rpe' => set.rpe?.toString() ?? '',
        'volume' => set.volume.toStringAsFixed(1).replaceAll('.', ','),
        'session_notes' => session.notes ?? '',
        'set_notes' => set.notes ?? '',
        'is_warmup' => set.isWarmup ? 'Sí' : 'No',
        'is_failure' => set.isFailure ? 'Sí' : 'No',
        'is_dropset' => set.isDropset ? 'Sí' : 'No',
        'is_rest_pause' => set.isRestPause ? 'Sí' : 'No',
        'is_myo_reps' => set.isMyoReps ? 'Sí' : 'No',
        'is_amrap' => set.isAmrap ? 'Sí' : 'No',
        _ => '',
      };
    }).toList();
  }

  /// Convierte sesiones del modelo a datos de exportación
  static List<SessionExportData> convertSessionsToExportData(
    List<Sesion> sessions, {
    List<String>? exerciseFilter,
  }) {
    return sessions.where((session) {
      // Filtrar por ejercicios si se especifica
      if (exerciseFilter != null && exerciseFilter.isNotEmpty) {
        return session.ejerciciosCompletados.any(
          (e) => exerciseFilter.contains(e.nombre),
        );
      }
      return true;
    }).map((session) {
      return SessionExportData(
        date: session.fecha,
        notes: null, // Sesion no tiene notas directamente
        exercises: session.ejerciciosCompletados
            .where((e) {
              // Filtrar ejercicios si es necesario
              if (exerciseFilter != null && exerciseFilter.isNotEmpty) {
                return exerciseFilter.contains(e.nombre);
              }
              return true;
            })
            .expand((ejercicio) => [
                  ExerciseExportData(
                    name: ejercicio.nombre,
                    sets: ejercicio.logs
                        .where((log) => log.completed)
                        .map((log) => _convertLogToSetData(log))
                        .toList(),
                  ),
                ])
            .toList(),
      );
    }).toList();
  }

  static SetExportData _convertLogToSetData(SerieLog log) {
    return SetExportData(
      weight: log.peso,
      reps: log.reps,
      rpe: log.rpe,
      notes: log.notas,
      isWarmup: log.isWarmup,
      isFailure: log.isFailure,
      isDropset: log.isDropset,
      isRestPause: log.isRestPause,
      isMyoReps: log.isMyoReps,
      isAmrap: log.isAmrap,
    );
  }

  /// Obtiene el nombre del archivo sugerido
  static String generateFileName(ExportType type) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmm').format(now);
    final typeStr = switch (type) {
      ExportType.training => 'entrenamiento',
      ExportType.diet => 'dieta',
      ExportType.both => 'completo',
    };
    return 'juan_tracker_${typeStr}_$dateStr.csv';
  }

  /// Obtiene lista de ejercicios únicos de las sesiones
  static List<String> getUniqueExercises(List<Sesion> sessions) {
    final exercises = <String>{};
    for (final session in sessions) {
      for (final ejercicio in session.ejerciciosCompletados) {
        exercises.add(ejercicio.nombre);
      }
    }
    return exercises.toList()..sort();
  }

  /// Calcula preview de filas (primeras 5)
  static List<List<String>> generatePreview({
    required List<SessionExportData> sessions,
    required List<String> columns,
    int maxRows = 5,
  }) {
    final rows = <List<String>>[];
    final headers = columns.map(_getColumnHeader).toList();

    var count = 0;
    for (final session in sessions) {
      for (final exercise in session.exercises) {
        for (final set in exercise.sets) {
          if (count >= maxRows) break;
          rows.add(_buildRow(session, exercise, set, columns));
          count++;
        }
        if (count >= maxRows) break;
      }
      if (count >= maxRows) break;
    }

    return [headers, ...rows];
  }

  /// Cuenta total de filas que se exportarían
  static int countTotalRows(List<SessionExportData> sessions) {
    var count = 0;
    for (final session in sessions) {
      for (final exercise in session.exercises) {
        count += exercise.sets.length;
      }
    }
    return count;
  }

  // ==========================================================================
  // DIET EXPORT
  // ==========================================================================

  /// Columnas disponibles para exportación de dieta
  static const List<ColumnOption> availableDietColumns = [
    ColumnOption('d_date', 'Fecha', true),
    ColumnOption('d_meal', 'Comida', true),
    ColumnOption('d_food', 'Alimento', true),
    ColumnOption('d_brand', 'Marca', false),
    ColumnOption('d_amount', 'Cantidad', true),
    ColumnOption('d_unit', 'Unidad', true),
    ColumnOption('d_kcal', 'Kcal', true),
    ColumnOption('d_protein', 'Proteína (g)', true),
    ColumnOption('d_carbs', 'Carbos (g)', true),
    ColumnOption('d_fat', 'Grasa (g)', true),
    ColumnOption('d_fiber', 'Fibra (g)', false),
    ColumnOption('d_sugar', 'Azúcar (g)', false),
    ColumnOption('d_saturated_fat', 'Grasa Sat. (g)', false),
    ColumnOption('d_sodium', 'Sodio (mg)', false),
    ColumnOption('d_notes', 'Notas', false),
  ];

  /// Columnas por defecto para diet export
  static List<String> get defaultDietColumns => availableDietColumns
      .where((c) => c.selectedByDefault)
      .map((c) => c.key)
      .toList();

  /// Genera CSV de dieta
  static String generateDietCSV({
    required List<DiaryEntryModel> entries,
    required List<String> columns,
  }) {
    final rows = <List<String>>[];

    // Header
    rows.add(columns.map(_getDietColumnHeader).toList());

    // Ordenar por fecha y comida
    final sorted = [...entries]..sort((a, b) {
        final dateComp = a.date.compareTo(b.date);
        if (dateComp != 0) return dateComp;
        return a.mealType.index.compareTo(b.mealType.index);
      });

    // Data rows
    for (final entry in sorted) {
      rows.add(_buildDietRow(entry, columns));
    }

    return '\uFEFF${const ListToCsvConverter(fieldDelimiter: ';').convert(rows)}';
  }

  /// Genera CSV de registros de peso
  static String generateWeightCSV({
    required List<WeighInModel> weighIns,
  }) {
    final rows = <List<String>>[];

    // Header
    rows.add(['Fecha', 'Hora', 'Peso (kg)', 'Notas']);

    // Ordenar por fecha
    final sorted = [...weighIns]..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    for (final w in sorted) {
      rows.add([
        DateFormat('dd/MM/yyyy').format(w.dateTime),
        DateFormat('HH:mm').format(w.dateTime),
        w.weightKg.toStringAsFixed(1).replaceAll('.', ','),
        w.note ?? '',
      ]);
    }

    return '\uFEFF${const ListToCsvConverter(fieldDelimiter: ';').convert(rows)}';
  }

  /// Genera CSV combinado (dieta + peso en hojas separadas por separador)
  static String generateFullDietCSV({
    required List<DiaryEntryModel> entries,
    required List<WeighInModel> weighIns,
    required List<String> columns,
  }) {
    final sb = StringBuffer();

    // Sección Diario
    sb.writeln('--- DIARIO DE ALIMENTOS ---');
    sb.write(generateDietCSV(entries: entries, columns: columns));

    if (weighIns.isNotEmpty) {
      sb.writeln();
      sb.writeln();
      sb.writeln('--- REGISTROS DE PESO ---');
      // Quitar BOM del segundo CSV
      final weightCsv = generateWeightCSV(weighIns: weighIns);
      sb.write(weightCsv.startsWith('\uFEFF')
          ? weightCsv.substring(1)
          : weightCsv);
    }

    return sb.toString();
  }

  static String _getDietColumnHeader(String column) {
    return switch (column) {
      'd_date' => 'Fecha',
      'd_meal' => 'Comida',
      'd_food' => 'Alimento',
      'd_brand' => 'Marca',
      'd_amount' => 'Cantidad',
      'd_unit' => 'Unidad',
      'd_kcal' => 'Kcal',
      'd_protein' => 'Proteína (g)',
      'd_carbs' => 'Carbos (g)',
      'd_fat' => 'Grasa (g)',
      'd_fiber' => 'Fibra (g)',
      'd_sugar' => 'Azúcar (g)',
      'd_saturated_fat' => 'Grasa Sat. (g)',
      'd_sodium' => 'Sodio (mg)',
      'd_notes' => 'Notas',
      _ => column,
    };
  }

  static List<String> _buildDietRow(
    DiaryEntryModel entry,
    List<String> columns,
  ) {
    return columns.map((column) {
      return switch (column) {
        'd_date' => DateFormat('dd/MM/yyyy').format(entry.date),
        'd_meal' => entry.mealType.displayName,
        'd_food' => entry.foodName,
        'd_brand' => entry.foodBrand ?? '',
        'd_amount' =>
          entry.amount.toStringAsFixed(1).replaceAll('.', ','),
        'd_unit' => _unitDisplayName(entry.unit),
        'd_kcal' => entry.kcal.toString(),
        'd_protein' =>
          entry.protein?.toStringAsFixed(1).replaceAll('.', ',') ?? '',
        'd_carbs' =>
          entry.carbs?.toStringAsFixed(1).replaceAll('.', ',') ?? '',
        'd_fat' =>
          entry.fat?.toStringAsFixed(1).replaceAll('.', ',') ?? '',
        'd_fiber' =>
          entry.fiber?.toStringAsFixed(1).replaceAll('.', ',') ?? '',
        'd_sugar' =>
          entry.sugar?.toStringAsFixed(1).replaceAll('.', ',') ?? '',
        'd_saturated_fat' =>
          entry.saturatedFat?.toStringAsFixed(1).replaceAll('.', ',') ?? '',
        'd_sodium' =>
          entry.sodium?.toStringAsFixed(1).replaceAll('.', ',') ?? '',
        'd_notes' => entry.notes ?? '',
        _ => '',
      };
    }).toList();
  }

  static String _unitDisplayName(ServingUnit unit) {
    return switch (unit) {
      ServingUnit.grams => 'g',
      ServingUnit.portion => 'porción',
      ServingUnit.milliliter => 'ml',
    };
  }

  /// Genera preview de datos de dieta
  static List<List<String>> generateDietPreview({
    required List<DiaryEntryModel> entries,
    required List<String> columns,
    int maxRows = 5,
  }) {
    final headers = columns.map(_getDietColumnHeader).toList();

    final sorted = [...entries]..sort((a, b) {
        final dateComp = a.date.compareTo(b.date);
        if (dateComp != 0) return dateComp;
        return a.mealType.index.compareTo(b.mealType.index);
      });

    final rows = sorted
        .take(maxRows)
        .map((e) => _buildDietRow(e, columns))
        .toList();

    return [headers, ...rows];
  }
}
