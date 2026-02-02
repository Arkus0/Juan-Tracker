import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/rutina.dart';
import '../models/dia.dart';
import '../models/ejercicio_en_rutina.dart';
import '../models/sesion.dart';
import '../models/ejercicio.dart';
import '../models/serie_log.dart';
import '../repositories/i_training_repository.dart';

/// Servicio de backup/restore completo de datos de entrenamiento
/// Exporta/importa todo: rutinas, sesiones, notas
class BackupService {
  final ITrainingRepository _repo;

  BackupService(this._repo);

  /// Genera un backup completo de todos los datos
  Future<BackupData> generateBackup() async {
    // Obtener todas las rutinas
    final rutinas = await _repo.watchRutinas().first;
    
    // Obtener todas las sesiones históricas (sin límite)
    final sesiones = await _repo.watchSesionesHistory(limit: 100000).first;

    return BackupData(
      exportDate: DateTime.now(),
      version: 1,
      routines: rutinas.map((r) => RoutineBackup.fromModel(r)).toList(),
      sessions: sesiones.map((s) => SessionBackup.fromModel(s)).toList(),
    );
  }

  /// Exporta backup a archivo JSON compartible
  Future<String> exportToJson() async {
    final backup = await generateBackup();
    return jsonEncode(backup.toJson());
  }

  /// Comparte el backup via share sheet
  Future<void> shareBackup() async {
    final json = await exportToJson();
    final tempDir = await getTemporaryDirectory();
    final fileName = 'juan_tracker_backup_${
      DateTime.now().toIso8601String().split('T')[0]
    }.json';
    final file = File('${tempDir.path}/$fileName');
    
    await file.writeAsString(json);
    
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Juan Tracker Backup',
        text: 'Backup completo de Juan Tracker (${await _getSummary()})',
      ),
    );
  }

  /// Obtiene resumen de datos para el mensaje
  Future<String> _getSummary() async {
    final rutinas = await _repo.watchRutinas().first;
    final sesiones = await _repo.watchSesionesHistory(limit: 100000).first;
    return '${rutinas.length} rutinas, ${sesiones.length} sesiones';
  }

  /// Importa backup desde JSON
  Future<ImportResult> importFromJson(String json) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final backup = BackupData.fromJson(data);
      
      int routinesCount = 0;
      int sessionsCount = 0;

      // Importar rutinas
      for (final routine in backup.routines) {
        await _repo.saveRutina(routine.toModel());
        routinesCount++;
      }

      // Importar sesiones
      for (final session in backup.sessions) {
        await _repo.saveSesion(session.toModel());
        sessionsCount++;
      }

      return ImportResult.success(
        routinesImported: routinesCount,
        sessionsImported: sessionsCount,
      );
    } catch (e) {
      return ImportResult.error(e.toString());
    }
  }

  /// Importa desde CSV de Strong.app
  /// 
  /// Formato esperado: Date,Workout Name,Exercise Name,Set Order,Weight,Reps
  Future<ImportResult> importFromStrongApp(String csvContent) async {
    try {
      final lines = csvContent.split('\n');
      if (lines.isEmpty || lines.length < 2) {
        return ImportResult.error('CSV vacío o inválido');
      }

      // Parsear header
      final headers = _parseCsvLine(lines.first.toLowerCase());
      final nameIndex = headers.indexOf('exercise name');
      final weightIndex = headers.indexOf('weight');
      final repsIndex = headers.indexOf('reps');
      final dateIndex = headers.indexOf('date');

      if (nameIndex == -1 || dateIndex == -1) {
        return ImportResult.error('Formato CSV de Strong inválido. Se esperaban columnas: Date, Exercise Name, Weight, Reps');
      }

      // Agrupar por fecha
      final sessionsByDate = <String, List<_StrongSet>>{};

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final values = _parseCsvLine(line);
        if (values.length <= dateIndex) continue;

        final date = values[dateIndex];
        final exerciseName = nameIndex < values.length ? values[nameIndex] : '';
        final weight = weightIndex >= 0 && weightIndex < values.length 
            ? double.tryParse(values[weightIndex].replaceAll(',', '.')) ?? 0.0 
            : 0.0;
        final reps = repsIndex >= 0 && repsIndex < values.length 
            ? int.tryParse(values[repsIndex]) ?? 0 
            : 0;

        if (date.isEmpty || exerciseName.isEmpty) continue;

        sessionsByDate.putIfAbsent(date, () => []);
        sessionsByDate[date]!.add(_StrongSet(
          exerciseName: exerciseName,
          weight: weight,
          reps: reps,
        ));
      }

      int sessionsImported = 0;
      int setsImported = 0;

      // Crear sesiones
      for (final entry in sessionsByDate.entries) {
        final dateParts = entry.key.split(RegExp(r'[-/]'));
        DateTime? date;
        
        // Intentar parsear diferentes formatos de fecha
        if (dateParts.length == 3) {
          try {
            // Formato: YYYY-MM-DD o DD/MM/YYYY
            if (dateParts[0].length == 4) {
              date = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              );
            } else {
              date = DateTime(
                int.parse(dateParts[2]),
                int.parse(dateParts[1]),
                int.parse(dateParts[0]),
              );
            }
          } catch (_) {}
        }
        
        if (date == null) continue;

        // Agrupar sets por ejercicio
        final exercisesByName = <String, List<_StrongSet>>{};
        for (final set in entry.value) {
          exercisesByName.putIfAbsent(set.exerciseName, () => []);
          exercisesByName[set.exerciseName]!.add(set);
        }

        // Crear ejercicios
        final exercises = <Ejercicio>[];
        for (final exEntry in exercisesByName.entries) {
          final logs = exEntry.value.map((s) => SerieLog(
            peso: s.weight,
            reps: s.reps,
            completed: true,
          )).toList();

          exercises.add(Ejercicio(
            id: '${date.millisecondsSinceEpoch}_${exEntry.key.hashCode}',
            libraryId: '',
            nombre: exEntry.key,
            series: logs.length,
            reps: logs.isNotEmpty ? logs.first.reps : 0,
            musculosPrincipales: const [],
            logs: logs,
          ));

          setsImported += logs.length;
        }

        // Crear sesión
        final session = Sesion(
          id: 'strong_${date.millisecondsSinceEpoch}',
          rutinaId: '',
          fecha: date,
          ejerciciosCompletados: exercises,
          ejerciciosObjetivo: exercises,
        );

        await _repo.saveSesion(session);
        sessionsImported++;
      }

      return ImportResult.success(
        sessionsImported: sessionsImported,
        setsImported: setsImported,
        source: 'Strong.app',
      );
    } catch (e) {
      return ImportResult.error('Error importando: $e');
    }
  }

  /// Parsea una línea CSV respetando comillas
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = '';
    var inQuotes = false;

    for (final char in line.split('')) {
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    result.add(current.trim());
    return result;
  }
}

/// Datos completos de backup
class BackupData {
  final DateTime exportDate;
  final int version;
  final List<RoutineBackup> routines;
  final List<SessionBackup> sessions;

  BackupData({
    required this.exportDate,
    required this.version,
    required this.routines,
    required this.sessions,
  });

  Map<String, dynamic> toJson() => {
    'exportDate': exportDate.toIso8601String(),
    'version': version,
    'appName': 'Juan Tracker',
    'appVersion': '1.0.0',
    'routines': routines.map((r) => r.toJson()).toList(),
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };

  factory BackupData.fromJson(Map<String, dynamic> json) => BackupData(
    exportDate: DateTime.parse(json['exportDate'] as String),
    version: json['version'] as int,
    routines: (json['routines'] as List)
        .map((r) => RoutineBackup.fromJson(r as Map<String, dynamic>))
        .toList(),
    sessions: (json['sessions'] as List)
        .map((s) => SessionBackup.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}

/// Backup de rutina
class RoutineBackup {
  final String id;
  final String name;
  final DateTime created;
  final List<Map<String, dynamic>> days;
  final bool isProMode;
  final String schedulingMode;

  RoutineBackup({
    required this.id,
    required this.name,
    required this.created,
    required this.days,
    this.isProMode = false,
    this.schedulingMode = 'sequential',
  });
  
  factory RoutineBackup.fromModel(Rutina r) => RoutineBackup(
    id: r.id,
    name: r.nombre,
    created: r.creada,
    days: r.dias.map((d) => {
      'id': d.id,
      'name': d.nombre,
      'progressionType': d.progressionType,
      'weekdays': d.weekdays,
      'minRestHours': d.minRestHours,
      'exercises': d.ejercicios.map((e) => {
        'id': e.id,
        'name': e.nombre,
        'libraryId': e.id, // El id es el libraryId
        'series': e.series,
        'repsRange': e.repsRange,
        'descansoSugerido': e.descansoSugerido?.inSeconds,
        'supersetId': e.supersetId,
        'musculosPrincipales': e.musculosPrincipales,
        'musculosSecundarios': e.musculosSecundarios,
        'equipo': e.equipo,
      }).toList(),
    }).toList(),
    isProMode: r.isProMode,
    schedulingMode: r.schedulingMode.name,
  );

  Rutina toModel() => Rutina(
    id: id,
    nombre: name,
    creada: created,
    dias: days.map((d) => Dia(
      id: d['id'] as String,
      nombre: d['name'] as String,
      progressionType: d['progressionType'] as String? ?? 'none',
      weekdays: (d['weekdays'] as List?)?.cast<int>(),
      minRestHours: d['minRestHours'] as int?,
      ejercicios: (d['exercises'] as List).map((e) => EjercicioEnRutina(
        id: e['libraryId'] as String? ?? e['id'] as String,
        nombre: e['name'] as String,
        musculosPrincipales: (e['musculosPrincipales'] as List?)?.cast<String>() ?? [],
        musculosSecundarios: (e['musculosSecundarios'] as List?)?.cast<String>() ?? [],
        equipo: e['equipo'] as String? ?? '',
        series: e['series'] as int? ?? 3,
        repsRange: e['repsRange'] as String? ?? '8-12',
        descansoSugerido: e['descansoSugerido'] != null 
            ? Duration(seconds: e['descansoSugerido'] as int) 
            : null,
        supersetId: e['supersetId'] as String?,
      )).toList(),
    )).toList(),
    isProMode: isProMode,
    schedulingMode: SchedulingMode.values.firstWhere(
      (v) => v.name == schedulingMode,
      orElse: () => SchedulingMode.sequential,
    ),
  );
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created': created.toIso8601String(),
    'days': days,
    'isProMode': isProMode,
    'schedulingMode': schedulingMode,
  };

  factory RoutineBackup.fromJson(Map<String, dynamic> json) => RoutineBackup(
    id: json['id'] as String,
    name: json['name'] as String,
    created: DateTime.parse(json['created'] as String),
    days: (json['days'] as List).cast<Map<String, dynamic>>(),
    isProMode: json['isProMode'] as bool? ?? false,
    schedulingMode: json['schedulingMode'] as String? ?? 'sequential',
  );
}

/// Backup de sesión
class SessionBackup {
  final String id;
  final String? routineId;
  final DateTime date;
  final String? dayName;
  final int? dayIndex;
  final List<Map<String, dynamic>> exercises;
  final int? durationSeconds;
  final bool isBadDay;

  SessionBackup({
    required this.id,
    this.routineId,
    required this.date,
    this.dayName,
    this.dayIndex,
    required this.exercises,
    this.durationSeconds,
    this.isBadDay = false,
  });

  factory SessionBackup.fromModel(Sesion s) => SessionBackup(
    id: s.id,
    routineId: s.rutinaId,
    date: s.fecha,
    dayName: s.dayName,
    dayIndex: s.dayIndex,
    exercises: s.ejerciciosCompletados.map((e) => {
      'id': e.id,
      'name': e.nombre,
      'libraryId': e.libraryId,
      'sets': e.logs.map((l) => {
        'weight': l.peso,
        'reps': l.reps,
        'completed': l.completed,
        'rpe': l.rpe,
        'isWarmup': l.isWarmup,
        'notas': l.notas,
      }).toList(),
    }).toList(),
    durationSeconds: s.durationSeconds,
    isBadDay: s.isBadDay,
  );

  Sesion toModel() => Sesion(
    id: id,
    rutinaId: routineId ?? '',
    fecha: date,
    dayName: dayName,
    dayIndex: dayIndex,
    ejerciciosCompletados: exercises.map((e) {
      final logs = (e['sets'] as List).map((l) => SerieLog(
        peso: (l['weight'] as num).toDouble(),
        reps: l['reps'] as int,
        completed: l['completed'] as bool? ?? true,
        rpe: l['rpe'] as int?,
        isWarmup: l['isWarmup'] as bool? ?? false,
        notas: l['notas'] as String?,
      )).toList();
      
      return Ejercicio(
        id: e['id'] as String,
        libraryId: e['libraryId'] ?? '',
        nombre: e['name'] as String,
        series: logs.length,
        reps: logs.isNotEmpty ? logs.first.reps : 0,
        musculosPrincipales: const [],
        logs: logs,
      );
    }).toList(),
    ejerciciosObjetivo: [],
    durationSeconds: durationSeconds,
    isBadDay: isBadDay,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'routineId': routineId,
    'date': date.toIso8601String(),
    'dayName': dayName,
    'dayIndex': dayIndex,
    'exercises': exercises,
    'durationSeconds': durationSeconds,
    'isBadDay': isBadDay,
  };

  factory SessionBackup.fromJson(Map<String, dynamic> json) => SessionBackup(
    id: json['id'] as String,
    routineId: json['routineId'] as String?,
    date: DateTime.parse(json['date'] as String),
    dayName: json['dayName'] as String?,
    dayIndex: json['dayIndex'] as int?,
    exercises: (json['exercises'] as List).cast<Map<String, dynamic>>(),
    durationSeconds: json['durationSeconds'] as int?,
    isBadDay: json['isBadDay'] as bool? ?? false,
  );
}

/// Set de Strong.app (helper interno)
class _StrongSet {
  final String exerciseName;
  final double weight;
  final int reps;

  _StrongSet({
    required this.exerciseName,
    required this.weight,
    required this.reps,
  });
}

/// Resultado de importación
class ImportResult {
  final bool success;
  final String? error;
  final int routinesImported;
  final int sessionsImported;
  final int setsImported;
  final String? source;

  ImportResult._({
    required this.success,
    this.error,
    this.routinesImported = 0,
    this.sessionsImported = 0,
    this.setsImported = 0,
    this.source,
  });

  factory ImportResult.success({
    int routinesImported = 0,
    int sessionsImported = 0,
    int setsImported = 0,
    String? source,
  }) => ImportResult._(
    success: true,
    routinesImported: routinesImported,
    sessionsImported: sessionsImported,
    setsImported: setsImported,
    source: source,
  );

  factory ImportResult.error(String error) => ImportResult._(
    success: false,
    error: error,
  );
}
