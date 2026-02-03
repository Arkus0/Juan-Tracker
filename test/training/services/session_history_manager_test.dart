import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/training/models/ejercicio.dart';
import 'package:juan_tracker/training/models/serie_log.dart';
import 'package:juan_tracker/training/models/sesion.dart';
import 'package:juan_tracker/training/repositories/i_training_repository.dart';
import 'package:juan_tracker/training/services/session_history_manager.dart';

/// Tests unitarios para SessionHistoryManager
/// 
/// Nota: Estos tests usan un mock simple del repositorio
/// para enfocarse en la lógica de cache LRU.
void main() {
  group('SessionHistoryManager Unit Tests', () {
    late _MockRepository mockRepo;
    late SessionHistoryManager historyManager;

    setUp(() {
      mockRepo = _MockRepository();
      historyManager = SessionHistoryManager(mockRepo);
    });

    tearDown(() {
      historyManager.clearCache();
      mockRepo.clear();
    });

    group('Basic Operations', () {
      test('debe retornar 0 cuando no hay historial', () {
        final weight = historyManager.getLastKnownWeight('lib:nonexistent');
        expect(weight, 0.0);
      });

      test('debe cachear y recuperar historial', () async {
        // Configurar mock con datos
        mockRepo.addSession(
          Sesion(
            id: 's1',
            rutinaId: 'r1',
            fecha: DateTime.now(),
            ejerciciosCompletados: [
              Ejercicio(
                id: 'ex-1',
                libraryId: 'lib-1',
                nombre: 'Press Banca',
                series: 3,
                reps: 10,
                logs: [
                  SerieLog(peso: 80.0, reps: 10, completed: true),
                  SerieLog(peso: 85.0, reps: 8, completed: true),
                ],
              ),
            ],
            ejerciciosObjetivo: [],
          ),
        );
        
        // Cargar datos
        await historyManager.loadHistoryForExercises([
          Ejercicio(
            id: 'ex-1',
            libraryId: 'lib-1',
            nombre: 'Press Banca',
            series: 3,
            reps: 10,
            logs: [],
          ),
        ]);
        
        // Verificar que stats funcionan
        final stats = historyManager.stats;
        expect(stats['maxSize'], 50);
        expect(stats['cacheSize'], 1);
      });
      
      test('debe retornar null para historial no existente', () {
        final history = historyManager.getHistory('lib:nonexistent');
        expect(history, isNull);
      });
    });

    group('Cache Management', () {
      test('debe limpiar cache correctamente', () async {
        // Configurar mock
        mockRepo.addSession(
          Sesion(
            id: 's1',
            rutinaId: 'r1',
            fecha: DateTime.now(),
            ejerciciosCompletados: [
              Ejercicio(
                id: 'ex-1',
                libraryId: 'lib-1',
                nombre: 'Test',
                series: 3,
                reps: 10,
                logs: [],
              ),
            ],
            ejerciciosObjetivo: [],
          ),
        );
        
        // Cargar datos primero
        await historyManager.loadHistoryForExercises([
          Ejercicio(id: 'ex-1', libraryId: 'lib-1', nombre: 'Test', series: 3, reps: 10, logs: []),
        ]);
        
        // Verificar que hay datos
        expect(historyManager.stats['cacheSize'], 1);
        
        // Limpiar cache
        historyManager.clearCache();
        
        final stats = historyManager.stats;
        expect(stats['cacheSize'], 0);
      });

      test('debe invalidar entrada específica', () async {
        // Configurar mock
        mockRepo.addSession(
          Sesion(
            id: 's1',
            rutinaId: 'r1',
            fecha: DateTime.now(),
            ejerciciosCompletados: [
              Ejercicio(
                id: 'ex-1',
                libraryId: 'lib-1',
                nombre: 'Test',
                series: 3,
                reps: 10,
                logs: [],
              ),
            ],
            ejerciciosObjetivo: [],
          ),
        );
        
        // Cargar datos
        await historyManager.loadHistoryForExercises([
          Ejercicio(id: 'ex-1', libraryId: 'lib-1', nombre: 'Test', series: 3, reps: 10, logs: []),
        ]);
        
        // Verificar que existe
        expect(historyManager.getHistory('lib:lib-1'), isNotNull);
        
        // Invalidar
        historyManager.invalidateCache('lib:lib-1');
        
        // Verificar que ya no existe
        expect(historyManager.getHistory('lib:lib-1'), isNull);
      });
    });

    group('Get Last Known Weight', () {
      test('debe encontrar peso cuando existe en cache por key exacta', () async {
        // Configurar mock con datos
        mockRepo.addSession(
          Sesion(
            id: 's1',
            rutinaId: 'r1',
            fecha: DateTime.now(),
            ejerciciosCompletados: [
              Ejercicio(
                id: 'ex-1',
                libraryId: 'lib-1',
                nombre: 'Press Banca',
                series: 3,
                reps: 10,
                logs: [
                  SerieLog(peso: 100.0, reps: 10, completed: true),
                ],
              ),
            ],
            ejerciciosObjetivo: [],
          ),
        );
        
        // Cargar datos
        await historyManager.loadHistoryForExercises([
          Ejercicio(
            id: 'ex-1', 
            libraryId: 'lib-1', 
            nombre: 'Press Banca', 
            series: 3, 
            reps: 10, 
            logs: [],
          ),
        ]);
        
        // Verificar que se puede obtener por key del cache
        final weight = historyManager.getLastKnownWeight('lib:lib-1');
        expect(weight, 100.0);
      });
      
      test('debe retornar 0 cuando no se encuentra por nombre', () {
        final weight = historyManager.getLastKnownWeightByName('NonExistent');
        expect(weight, 0.0);
      });
    });
    
    group('LRU Eviction', () {
      test('debe respetar límite máximo de cache', () async {
        // Crear múltiples entradas con datos reales
        for (var i = 0; i < 60; i++) {
          mockRepo.addSession(
            Sesion(
              id: 's$i',
              rutinaId: 'r$i',
              fecha: DateTime.now(),
              ejerciciosCompletados: [
                Ejercicio(
                  id: 'ex-$i',
                  libraryId: 'lib-$i',
                  nombre: 'Exercise $i',
                  series: 3,
                  reps: 10,
                  logs: [],
                ),
              ],
              ejerciciosObjetivo: [],
            ),
          );
          
          await historyManager.loadHistoryForExercises([
            Ejercicio(
              id: 'ex-$i', 
              libraryId: 'lib-$i', 
              nombre: 'Exercise $i', 
              series: 3, 
              reps: 10, 
              logs: [],
            ),
          ]);
        }
        
        // Verificar que no excede el máximo
        final stats = historyManager.stats;
        expect(stats['cacheSize'], lessThanOrEqualTo(50));
      });
    });
  });
}

/// Mock de ITrainingRepository que permite agregar sesiones
class _MockRepository implements ITrainingRepository {
  final List<Sesion> _sessions = [];
  
  void addSession(Sesion session) {
    _sessions.add(session);
  }
  
  void clear() {
    _sessions.clear();
  }
  
  @override
  Future<List<Sesion>> getHistoryForExercise(String exerciseName) async {
    return _sessions.where((s) => 
      s.ejerciciosCompletados.any((e) => e.nombre == exerciseName)
    ).toList();
  }
  
  // Implementaciones stub para la interfaz completa
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
