/// Contrato para el servicio de scoring de alimentos
abstract class FoodScoringService {
  /// Calcula el score de relevancia de un producto para una query
  /// 
  /// Retorna un valor entre 0 y 1, donde 1 es máxima relevancia
  double calculateScore({
    required String query,
    required String name,
    required String? brand,
    required List<String> countriesTags,
    required List<String> storesTags,
    required String? nutriScore,
    required int? novaGroup,
    required DateTime fetchedAt,
  });

  /// Ordena productos por relevancia
  List<ScoredFood> rankProducts(
    List<ScorableFood> products,
    String query,
  );
}

/// Datos necesarios para scorar un producto
class ScorableFood {
  final String id;
  final String name;
  final String? brand;
  final List<String> countriesTags;
  final List<String> storesTags;
  final String? nutriScore;
  final int? novaGroup;
  final DateTime fetchedAt;
  final Map<String, dynamic> metadata;

  const ScorableFood({
    required this.id,
    required this.name,
    this.brand,
    this.countriesTags = const [],
    this.storesTags = const [],
    this.nutriScore,
    this.novaGroup,
    required this.fetchedAt,
    this.metadata = const {},
  });
}

/// Producto con score calculado
class ScoredFood {
  final ScorableFood food;
  final double score;
  final ScoreBreakdown breakdown;

  const ScoredFood({
    required this.food,
    required this.score,
    required this.breakdown,
  });
}

/// Desglose del scoring para debugging
class ScoreBreakdown {
  final double textMatch;
  final double availability;
  final double quality;
  final double freshness;
  final double total;

  const ScoreBreakdown({
    required this.textMatch,
    required this.availability,
    required this.quality,
    required this.freshness,
    required this.total,
  });

  @override
  String toString() => 
      'ScoreBreakdown(text: ${textMatch.toStringAsFixed(2)}, '
      'availability: ${availability.toStringAsFixed(2)}, '
      'quality: ${quality.toStringAsFixed(2)}, '
      'freshness: ${freshness.toStringAsFixed(2)}, '
      'total: ${total.toStringAsFixed(2)})';
}
