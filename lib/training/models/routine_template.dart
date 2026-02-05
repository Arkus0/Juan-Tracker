/// Modelo de plantilla de rutina predefinida.
/// 
/// Las plantillas son rutinas preconstruidas que los usuarios pueden
/// importar con un solo toque para empezar a entrenar rápidamente.
class RoutineTemplate {
  final String id;
  final String nombre;
  final String categoria;
  final String nivel;
  final int diasPorSemana;
  final String descripcion;
  final List<TemplateDia> dias;

  const RoutineTemplate({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.nivel,
    required this.diasPorSemana,
    required this.descripcion,
    required this.dias,
  });

  factory RoutineTemplate.fromJson(Map<String, dynamic> json) {
    return RoutineTemplate(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      categoria: json['categoria'] as String,
      nivel: json['nivel'] as String,
      diasPorSemana: json['diasPorSemana'] as int,
      descripcion: json['descripcion'] as String,
      dias: (json['dias'] as List<dynamic>)
          .map((d) => TemplateDia.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'categoria': categoria,
    'nivel': nivel,
    'diasPorSemana': diasPorSemana,
    'descripcion': descripcion,
    'dias': dias.map((d) => d.toJson()).toList(),
  };

  /// Número total de ejercicios en la plantilla
  int get totalEjercicios => dias.fold(0, (sum, d) => sum + d.ejercicios.length);
}

/// Día de una plantilla de rutina
class TemplateDia {
  final String nombre;
  final List<TemplateEjercicio> ejercicios;

  const TemplateDia({
    required this.nombre,
    required this.ejercicios,
  });

  factory TemplateDia.fromJson(Map<String, dynamic> json) {
    return TemplateDia(
      nombre: json['nombre'] as String,
      ejercicios: (json['ejercicios'] as List<dynamic>)
          .map((e) => TemplateEjercicio.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'ejercicios': ejercicios.map((e) => e.toJson()).toList(),
  };
}

/// Ejercicio dentro de una plantilla
class TemplateEjercicio {
  final String exerciseId;
  final int series;
  final String repsRange;

  const TemplateEjercicio({
    required this.exerciseId,
    required this.series,
    required this.repsRange,
  });

  factory TemplateEjercicio.fromJson(Map<String, dynamic> json) {
    return TemplateEjercicio(
      exerciseId: json['exerciseId'] as String,
      series: json['series'] as int,
      repsRange: json['repsRange'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'series': series,
    'repsRange': repsRange,
  };
}

/// Categoría de plantillas
class TemplateCategory {
  final String id;
  final String nombre;
  final String icono;

  const TemplateCategory({
    required this.id,
    required this.nombre,
    required this.icono,
  });

  factory TemplateCategory.fromJson(Map<String, dynamic> json) {
    return TemplateCategory(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      icono: json['icono'] as String,
    );
  }
}

/// Nivel de dificultad
class TemplateLevel {
  final String id;
  final String nombre;
  final String descripcion;

  const TemplateLevel({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });

  factory TemplateLevel.fromJson(Map<String, dynamic> json) {
    return TemplateLevel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String,
    );
  }
}
