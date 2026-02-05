// Modelos para el seguimiento de progreso corporal
// Incluye medidas corporales y fotos de progreso

/// Categorías de fotos de progreso
enum PhotoCategory {
  front, // Frente
  side, // Lado
  back, // Espalda
  upper, // Torso superior
  lower, // Torso inferior
  other; // Otra

  String get displayName => switch (this) {
        PhotoCategory.front => 'Frente',
        PhotoCategory.side => 'Lateral',
        PhotoCategory.back => 'Espalda',
        PhotoCategory.upper => 'Superior',
        PhotoCategory.lower => 'Inferior',
        PhotoCategory.other => 'Otra',
      };

  String get icon => switch (this) {
        PhotoCategory.front => '👤',
        PhotoCategory.side => '↔️',
        PhotoCategory.back => '🔙',
        PhotoCategory.upper => '💪',
        PhotoCategory.lower => '🦵',
        PhotoCategory.other => '📷',
      };

  static PhotoCategory fromString(String value) {
    return PhotoCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PhotoCategory.front,
    );
  }
}

/// {@template body_measurement_model}
/// Modelo de medidas corporales.
/// 
/// Almacena todas las mediciones del cuerpo en centímetros
/// y permite calcular diferencias entre mediciones.
/// {@endtemplate}
class BodyMeasurementModel {
  final String id;
  final DateTime date;
  
  // Medidas en cm
  final double? weightKg;
  final double? waistCm;
  final double? chestCm;
  final double? hipsCm;
  final double? leftArmCm;
  final double? rightArmCm;
  final double? leftThighCm;
  final double? rightThighCm;
  final double? leftCalfCm;
  final double? rightCalfCm;
  final double? neckCm;
  
  // Porcentaje de grasa corporal (opcional)
  final double? bodyFatPercentage;
  
  // Notas
  final String? notes;
  final DateTime createdAt;

  const BodyMeasurementModel({
    required this.id,
    required this.date,
    this.weightKg,
    this.waistCm,
    this.chestCm,
    this.hipsCm,
    this.leftArmCm,
    this.rightArmCm,
    this.leftThighCm,
    this.rightThighCm,
    this.leftCalfCm,
    this.rightCalfCm,
    this.neckCm,
    this.bodyFatPercentage,
    this.notes,
    required this.createdAt,
  });

  /// Calcula el promedio de ambos brazos
  double? get avgArmCm {
    if (leftArmCm != null && rightArmCm != null) {
      return (leftArmCm! + rightArmCm!) / 2;
    }
    return leftArmCm ?? rightArmCm;
  }

  /// Calcula el promedio de ambos muslos
  double? get avgThighCm {
    if (leftThighCm != null && rightThighCm != null) {
      return (leftThighCm! + rightThighCm!) / 2;
    }
    return leftThighCm ?? rightThighCm;
  }

  /// Calcula el promedio de ambas pantorrillas
  double? get avgCalfCm {
    if (leftCalfCm != null && rightCalfCm != null) {
      return (leftCalfCm! + rightCalfCm!) / 2;
    }
    return leftCalfCm ?? rightCalfCm;
  }

  /// Calcula la diferencia de medidas comparando con otra medición
  BodyMeasurementDiff diff(BodyMeasurementModel other) {
    return BodyMeasurementDiff(
      weightKg: _calcDiff(weightKg, other.weightKg),
      waistCm: _calcDiff(waistCm, other.waistCm),
      chestCm: _calcDiff(chestCm, other.chestCm),
      hipsCm: _calcDiff(hipsCm, other.hipsCm),
      leftArmCm: _calcDiff(leftArmCm, other.leftArmCm),
      rightArmCm: _calcDiff(rightArmCm, other.rightArmCm),
      leftThighCm: _calcDiff(leftThighCm, other.leftThighCm),
      rightThighCm: _calcDiff(rightThighCm, other.rightThighCm),
      leftCalfCm: _calcDiff(leftCalfCm, other.leftCalfCm),
      rightCalfCm: _calcDiff(rightCalfCm, other.rightCalfCm),
      neckCm: _calcDiff(neckCm, other.neckCm),
      bodyFatPercentage: _calcDiff(bodyFatPercentage, other.bodyFatPercentage),
    );
  }

  double? _calcDiff(double? current, double? previous) {
    if (current == null || previous == null) return null;
    return current - previous;
  }

  /// Crea una copia con algunos campos modificados
  BodyMeasurementModel copyWith({
    String? id,
    DateTime? date,
    double? weightKg,
    double? waistCm,
    double? chestCm,
    double? hipsCm,
    double? leftArmCm,
    double? rightArmCm,
    double? leftThighCm,
    double? rightThighCm,
    double? leftCalfCm,
    double? rightCalfCm,
    double? neckCm,
    double? bodyFatPercentage,
    String? notes,
    DateTime? createdAt,
  }) {
    return BodyMeasurementModel(
      id: id ?? this.id,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      waistCm: waistCm ?? this.waistCm,
      chestCm: chestCm ?? this.chestCm,
      hipsCm: hipsCm ?? this.hipsCm,
      leftArmCm: leftArmCm ?? this.leftArmCm,
      rightArmCm: rightArmCm ?? this.rightArmCm,
      leftThighCm: leftThighCm ?? this.leftThighCm,
      rightThighCm: rightThighCm ?? this.rightThighCm,
      leftCalfCm: leftCalfCm ?? this.leftCalfCm,
      rightCalfCm: rightCalfCm ?? this.rightCalfCm,
      neckCm: neckCm ?? this.neckCm,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'waistCm': waistCm,
        'chestCm': chestCm,
        'hipsCm': hipsCm,
        'leftArmCm': leftArmCm,
        'rightArmCm': rightArmCm,
        'leftThighCm': leftThighCm,
        'rightThighCm': rightThighCm,
        'leftCalfCm': leftCalfCm,
        'rightCalfCm': rightCalfCm,
        'neckCm': neckCm,
        'bodyFatPercentage': bodyFatPercentage,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BodyMeasurementModel.fromJson(Map<String, dynamic> json) {
    return BodyMeasurementModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      waistCm: (json['waistCm'] as num?)?.toDouble(),
      chestCm: (json['chestCm'] as num?)?.toDouble(),
      hipsCm: (json['hipsCm'] as num?)?.toDouble(),
      leftArmCm: (json['leftArmCm'] as num?)?.toDouble(),
      rightArmCm: (json['rightArmCm'] as num?)?.toDouble(),
      leftThighCm: (json['leftThighCm'] as num?)?.toDouble(),
      rightThighCm: (json['rightThighCm'] as num?)?.toDouble(),
      leftCalfCm: (json['leftCalfCm'] as num?)?.toDouble(),
      rightCalfCm: (json['rightCalfCm'] as num?)?.toDouble(),
      neckCm: (json['neckCm'] as num?)?.toDouble(),
      bodyFatPercentage: (json['bodyFatPercentage'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// {@template body_measurement_diff}
/// Representa la diferencia entre dos mediciones.
/// 
/// Usado para mostrar cambios (ej: "-2.5 cm en cintura desde la última medición")
/// {@endtemplate}
class BodyMeasurementDiff {
  final double? weightKg;
  final double? waistCm;
  final double? chestCm;
  final double? hipsCm;
  final double? leftArmCm;
  final double? rightArmCm;
  final double? leftThighCm;
  final double? rightThighCm;
  final double? leftCalfCm;
  final double? rightCalfCm;
  final double? neckCm;
  final double? bodyFatPercentage;

  const BodyMeasurementDiff({
    this.weightKg,
    this.waistCm,
    this.chestCm,
    this.hipsCm,
    this.leftArmCm,
    this.rightArmCm,
    this.leftThighCm,
    this.rightThighCm,
    this.leftCalfCm,
    this.rightCalfCm,
    this.neckCm,
    this.bodyFatPercentage,
  });

  bool get hasChanges => [
        weightKg,
        waistCm,
        chestCm,
        hipsCm,
        leftArmCm,
        rightArmCm,
        leftThighCm,
        rightThighCm,
        leftCalfCm,
        rightCalfCm,
        neckCm,
        bodyFatPercentage,
      ].any((v) => v != null && v != 0);
}

/// {@template progress_photo_model}
/// Modelo de foto de progreso.
/// 
/// Almacena la referencia a una imagen guardada localmente
/// con metadatos sobre la fecha y categoría.
/// {@endtemplate}
class ProgressPhotoModel {
  final String id;
  final DateTime date;
  final String imagePath;
  final PhotoCategory category;
  final String? notes;
  final String? measurementId; // Relación opcional con medidas
  final DateTime createdAt;

  const ProgressPhotoModel({
    required this.id,
    required this.date,
    required this.imagePath,
    this.category = PhotoCategory.front,
    this.notes,
    this.measurementId,
    required this.createdAt,
  });

  ProgressPhotoModel copyWith({
    String? id,
    DateTime? date,
    String? imagePath,
    PhotoCategory? category,
    String? notes,
    String? measurementId,
    DateTime? createdAt,
  }) {
    return ProgressPhotoModel(
      id: id ?? this.id,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      measurementId: measurementId ?? this.measurementId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'imagePath': imagePath,
        'category': category.name,
        'notes': notes,
        'measurementId': measurementId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProgressPhotoModel.fromJson(Map<String, dynamic> json) {
    return ProgressPhotoModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      imagePath: json['imagePath'] as String,
      category: PhotoCategory.fromString(json['category'] as String),
      notes: json['notes'] as String?,
      measurementId: json['measurementId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Resumen de medidas para mostrar en UI
class BodyMeasurementsSummary {
  final BodyMeasurementModel? latest;
  final BodyMeasurementModel? first;
  final int totalMeasurements;
  final BodyMeasurementDiff? overallDiff;

  const BodyMeasurementsSummary({
    this.latest,
    this.first,
    required this.totalMeasurements,
    this.overallDiff,
  });

  bool get hasData => latest != null;
}
