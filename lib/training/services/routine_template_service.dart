import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../models/dia.dart';
import '../models/ejercicio_en_rutina.dart';
import '../models/library_exercise.dart';
import '../models/routine_template.dart';
import '../models/rutina.dart';
import 'exercise_library_service.dart';

/// Servicio para cargar y gestionar plantillas de rutinas predefinidas.
/// 
/// Las plantillas se cargan desde un archivo JSON en assets y pueden
/// convertirse en rutinas reales para el usuario.
class RoutineTemplateService {
  static final RoutineTemplateService instance = RoutineTemplateService._();
  RoutineTemplateService._();

  static const _bundlePath = 'assets/data/routine_templates.json';
  final _logger = Logger();

  List<RoutineTemplate> _templates = [];
  List<TemplateCategory> _categories = [];
  List<TemplateLevel> _levels = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<RoutineTemplate> get templates => List.unmodifiable(_templates);
  List<TemplateCategory> get categories => List.unmodifiable(_categories);
  List<TemplateLevel> get levels => List.unmodifiable(_levels);

  /// Inicializa el servicio cargando las plantillas desde assets
  Future<void> init() async {
    if (_isLoaded) return;
    await loadTemplates();
  }

  /// Carga las plantillas desde el archivo JSON
  Future<void> loadTemplates() async {
    try {
      final jsonStr = await rootBundle.loadString(_bundlePath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Cargar plantillas
      final templatesJson = data['templates'] as List<dynamic>;
      _templates = templatesJson
          .map((t) => RoutineTemplate.fromJson(t as Map<String, dynamic>))
          .toList();

      // Cargar categorías
      final categoriesJson = data['categories'] as List<dynamic>;
      _categories = categoriesJson
          .map((c) => TemplateCategory.fromJson(c as Map<String, dynamic>))
          .toList();

      // Cargar niveles
      final levelsJson = data['levels'] as List<dynamic>;
      _levels = levelsJson
          .map((l) => TemplateLevel.fromJson(l as Map<String, dynamic>))
          .toList();

      _isLoaded = true;
      _logger.i('Loaded ${_templates.length} routine templates');
    } catch (e, s) {
      _logger.e('Error loading routine templates', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Obtiene plantillas filtradas por categoría
  List<RoutineTemplate> getByCategory(String categoryId) {
    return _templates.where((t) => t.categoria == categoryId).toList();
  }

  /// Obtiene plantillas filtradas por nivel
  List<RoutineTemplate> getByLevel(String levelId) {
    return _templates.where((t) => t.nivel == levelId).toList();
  }

  /// Obtiene plantillas filtradas por categoría y nivel
  List<RoutineTemplate> filter({String? categoryId, String? levelId}) {
    return _templates.where((t) {
      if (categoryId != null && t.categoria != categoryId) return false;
      if (levelId != null && t.nivel != levelId) return false;
      return true;
    }).toList();
  }

  /// Busca plantillas por nombre
  List<RoutineTemplate> search(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return _templates;

    return _templates.where((t) {
      return t.nombre.toLowerCase().contains(normalizedQuery) ||
          t.descripcion.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  /// Convierte una plantilla en una rutina real para el usuario.
  /// 
  /// Los ejercicios se mapean desde la biblioteca de ejercicios usando
  /// el ID del ejercicio. Si un ejercicio no se encuentra, se omite.
  Rutina convertToRutina(RoutineTemplate template) {
    final library = ExerciseLibraryService.instance;
    final exerciseMap = <String, LibraryExercise>{};
    
    // Crear mapa de ejercicios por ID para búsqueda rápida
    for (final exercise in library.exercises) {
      exerciseMap[exercise.id.toString()] = exercise;
    }

    final dias = <Dia>[];
    
    for (final templateDia in template.dias) {
      final ejercicios = <EjercicioEnRutina>[];
      
      for (final templateEj in templateDia.ejercicios) {
        final libraryExercise = exerciseMap[templateEj.exerciseId];
        
        if (libraryExercise != null) {
          ejercicios.add(EjercicioEnRutina(
            id: libraryExercise.id.toString(),
            nombre: libraryExercise.name,
            descripcion: libraryExercise.description,
            musculosPrincipales: libraryExercise.muscles,
            musculosSecundarios: libraryExercise.secondaryMuscles,
            equipo: libraryExercise.equipment,
            localImagePath: libraryExercise.localImagePath,
            series: templateEj.series,
            repsRange: templateEj.repsRange,
          ));
        } else {
          _logger.w(
            'Exercise ${templateEj.exerciseId} not found in library, skipping',
          );
        }
      }

      dias.add(Dia(
        nombre: templateDia.nombre,
        ejercicios: ejercicios,
      ));
    }

    return Rutina(
      id: const Uuid().v4(),
      nombre: template.nombre,
      dias: dias,
      creada: DateTime.now(),
    );
  }

  /// Obtiene el nombre de la categoría por ID
  String getCategoryName(String categoryId) {
    return _categories
        .firstWhere(
          (c) => c.id == categoryId,
          orElse: () => TemplateCategory(
            id: categoryId,
            nombre: categoryId,
            icono: 'fitness_center',
          ),
        )
        .nombre;
  }

  /// Obtiene el nombre del nivel por ID
  String getLevelName(String levelId) {
    return _levels
        .firstWhere(
          (l) => l.id == levelId,
          orElse: () => TemplateLevel(
            id: levelId,
            nombre: levelId,
            descripcion: '',
          ),
        )
        .nombre;
  }

  /// Cuenta plantillas por categoría
  Map<String, int> getTemplateCountByCategory() {
    final counts = <String, int>{};
    for (final template in _templates) {
      counts[template.categoria] = (counts[template.categoria] ?? 0) + 1;
    }
    return counts;
  }
}
