import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

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

  double get volume => weight * reps;

  SetExportData({
    required this.weight,
    required this.reps,
    this.rpe,
    this.notes,
    this.isWarmup = false,
    this.isFailure = false,
    this.isDropset = false,
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
}
