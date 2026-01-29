import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

/// Resultado del escaneo OCR de una etiqueta de alimento
class FoodLabelScanResult {
  /// Texto completo extraído de la etiqueta
  final String fullText;
  
  /// Líneas de texto individuales
  final List<String> lines;
  
  /// Nombre del producto detectado (mejor estimación)
  final String? detectedProductName;
  
  /// Palabras clave extraídas (útiles para búsqueda)
  final List<String> keywords;
  
  /// Indica si se encontró algún texto
  final bool hasText;
  
  /// Indica si parece ser una etiqueta de alimento válida
  final bool isLikelyFoodLabel;
  
  /// Marca detectada (si se encuentra)
  final String? detectedBrand;

  const FoodLabelScanResult({
    required this.fullText,
    required this.lines,
    this.detectedProductName,
    this.keywords = const [],
    this.hasText = false,
    this.isLikelyFoodLabel = false,
    this.detectedBrand,
  });

  /// Resultado vacío para cuando no hay imagen
  const FoodLabelScanResult.empty()
      : fullText = '',
        lines = const [],
        detectedProductName = null,
        keywords = const [],
        hasText = false,
        isLikelyFoodLabel = false,
        detectedBrand = null;

  /// Construye una query de búsqueda a partir del resultado
  String get searchQuery {
    if (detectedProductName != null && detectedProductName!.isNotEmpty) {
      return detectedProductName!;
    }
    if (keywords.isNotEmpty) {
      return keywords.take(3).join(' ');
    }
    return fullText.split('\n').firstWhere(
          (line) => line.trim().length > 3,
          orElse: () => '',
        );
  }
}

/// Servicio para escanear etiquetas de alimentos usando OCR
/// 
/// Usa Google ML Kit para extraer texto de imágenes de etiquetas
/// y aplicar heurísticas para detectar el nombre del producto.
class FoodLabelOcrService {
  static final FoodLabelOcrService instance = FoodLabelOcrService._internal();
  FoodLabelOcrService._internal();

  final _picker = ImagePicker();
  final _logger = Logger();

  // Palabras clave que indican que es una etiqueta de alimento
  static const List<String> _foodIndicatorWords = [
    'nutrición', 'nutricional', 'información',
    'ingredientes', 'valor', 'valores',
    'energía', 'proteínas', 'grasas', 'carbohidratos',
    'kcal', 'calorías', 'porción', '100g', '100ml',
    'contenido', 'neto', 'peso',
  ];

  // Palabras que suelen aparecer en nombres de productos pero no son el nombre
  static const List<String> _commonNonProductWords = [
    'ingredientes', 'información', 'nutricional',
    'valor', 'valores', 'nutrición', 'tabla',
    'energía', 'proteínas', 'grasas', 'carbohidratos',
    'azúcares', 'fibra', 'sodio', 'sal',
    'porción', 'porciones', 'ración', 'raciones',
    'conservar', 'conservación', 'consumir', 'consumo',
    'elaborado', 'distribuido', 'fabricado',
    'fecha', 'caducidad', 'consumo preferente',
    'lote', 'código', 'tel', 'www', 'http',
    'g', 'mg', 'ml', 'kg', '%', 'kcal', 'kj',
  ];

  /// Escanea una etiqueta desde cámara o galería
  Future<FoodLabelScanResult> scanLabel(ImageSource source) async {
    try {
      if (kIsWeb) {
        _logger.w('OCR no disponible en web');
        return const FoodLabelScanResult.empty();
      }

      final image = await _picker.pickImage(
        source: source,
        imageQuality: 90, // Alta calidad para OCR preciso
        maxWidth: 2500,
        maxHeight: 2500,
      );

      if (image == null) {
        _logger.d('Usuario canceló selección de imagen');
        return const FoodLabelScanResult.empty();
      }

      return _processImage(image.path);
    } on PlatformException catch (e) {
      _logger.e('Error de plataforma al escanear: $e');
      rethrow;
    } catch (e, s) {
      _logger.e('Error escaneando etiqueta', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Procesa una imagen y extrae texto
  Future<FoodLabelScanResult> _processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      if (recognizedText.text.isEmpty) {
        return const FoodLabelScanResult.empty();
      }

      // Extraer líneas de texto
      final lines = <String>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final trimmed = line.text.trim();
          if (trimmed.isNotEmpty && trimmed.length > 2) {
            lines.add(trimmed);
          }
        }
      }

      _logger.i('OCR extrajo ${lines.length} líneas de la etiqueta');

      // Analizar el texto extraído
      return _analyzeText(recognizedText.text, lines);
    } finally {
      await textRecognizer.close();
    }
  }

  /// Analiza el texto extraído para detectar el producto
  FoodLabelScanResult _analyzeText(String fullText, List<String> lines) {
    final lowerText = fullText.toLowerCase();
    
    // Detectar si parece ser una etiqueta de alimento
    final isFoodLabel = _foodIndicatorWords.any(
      (word) => lowerText.contains(word),
    );

    // Intentar detectar el nombre del producto
    final productName = _detectProductName(lines);
    
    // Intentar detectar la marca
    final brand = _detectBrand(lines);
    
    // Extraer palabras clave relevantes
    final keywords = _extractKeywords(lines);

    return FoodLabelScanResult(
      fullText: fullText,
      lines: lines,
      detectedProductName: productName,
      keywords: keywords,
      hasText: lines.isNotEmpty,
      isLikelyFoodLabel: isFoodLabel,
      detectedBrand: brand,
    );
  }

  /// Intenta detectar el nombre del producto
  /// 
  /// Heurísticas:
  /// 1. La línea más grande/gruesa suele ser el nombre
  /// 2. Suele estar cerca del inicio de la etiqueta
  /// 3. No contiene palabras de la tabla nutricional
  String? _detectProductName(List<String> lines) {
    if (lines.isEmpty) return null;

    // Filtrar líneas candidatas (excluir líneas muy cortas o con palabras no-producto)
    final candidates = lines.where((line) {
      final lower = line.toLowerCase();
      
      // Debe tener más de 3 caracteres
      if (line.trim().length <= 3) return false;
      
      // No debe ser puramente numérica o contener solo símbolos
      if (RegExp(r'^[\d\s\W]+$').hasMatch(line)) return false;
      
      // No debe ser principalmente palabras de tabla nutricional
      final words = lower.split(RegExp(r'\s+'));
      final nonProductWordCount = words.where(
        (w) => _commonNonProductWords.contains(w),
      ).length;
      
      // Si más de la mitad son palabras no-producto, descartar
      if (nonProductWordCount > words.length / 2) return false;
      
      return true;
    }).toList();

    if (candidates.isEmpty) return null;

    // Preferir la primera línea larga (suele ser el nombre del producto)
    // pero descartar si parece ser solo la marca
    for (final candidate in candidates.take(5)) {
      final lower = candidate.toLowerCase();
      
      // Si contiene palabras que indican descripción de producto, es buen candidato
      final hasProductWords = [
        'con ', 'de ', 'sin ', 'natural', 'fresco', 'entero',
        'light', '0%', 'desnatado', 'semi', 'integral',
        'yogur', 'leche', 'pan', 'queso', 'carne', 'pescado',
        'arroz', 'pasta', 'cereal', 'galleta', 'chocolate',
        'zumo', 'agua', 'refresco', 'vino', 'cerveza',
      ].any((word) => lower.contains(word));
      
      if (hasProductWords || candidate.length > 10) {
        return candidate.trim();
      }
    }

    // Fallback: primera línea candidata
    return candidates.first.trim();
  }

  /// Intenta detectar la marca del producto
  String? _detectBrand(List<String> lines) {
    for (final line in lines.take(3)) {
      final trimmed = line.trim();
      
      // Si es corto y está al principio, puede ser marca
      if (trimmed.length > 2 && trimmed.length < 25) {
        // Verificar que no sea una palabra de tabla nutricional
        final lower = trimmed.toLowerCase();
        if (!_commonNonProductWords.contains(lower) &&
            !_foodIndicatorWords.contains(lower)) {
          return trimmed;
        }
      }
    }
    return null;
  }

  /// Extrae palabras clave relevantes para búsqueda
  List<String> _extractKeywords(List<String> lines) {
    final keywords = <String>[];
    
    for (final line in lines) {
      final words = line.toLowerCase().split(RegExp(r'[^\w\s]'));
      for (final word in words) {
        final trimmed = word.trim();
        // Palabras de longitud media que no son comunes
        if (trimmed.length > 4 && 
            trimmed.length < 20 &&
            !_commonNonProductWords.contains(trimmed)) {
          keywords.add(trimmed);
        }
      }
    }
    
    // Eliminar duplicados y limitar
    return keywords.toSet().take(10).toList();
  }

  /// Obtiene texto del portapapeles
  /// 
  /// Útil para cuando el usuario quiere pegar texto de una foto
  /// o de un mensaje/website.
  Future<String?> getClipboardText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (e) {
      _logger.w('Error leyendo portapapeles: $e');
      return null;
    }
  }

  /// Limpia y normaliza texto para búsqueda
  /// 
  /// Elimina caracteres especiales, números sueltos,
  /// y normaliza espacios.
  String cleanTextForSearch(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')           // Normalizar espacios
        .replaceAll(RegExp(r'^[^a-zA-Z]+'), '')    // Quitar prefijos no-letra
        .replaceAll(RegExp(r'[^a-zA-Z\s]+$'), '') // Quitar sufijos no-letra
        .trim();
  }

  /// Sugiere correcciones para texto OCR con errores comunes
  /// 
  /// Por ejemplo: 'Y0gur' -> 'Yogur', 'L3che' -> 'Leche'
  List<String> suggestCorrections(String text) {
    final corrections = <String>[];
    
    // Reemplazos comunes de OCR
    final ocrReplacements = {
      '0': 'o',
      '1': 'i',
      '3': 'e',
      '4': 'a',
      '5': 's',
      '7': 't',
      '8': 'b',
    };
    
    var corrected = text;
    ocrReplacements.forEach((wrong, right) {
      corrected = corrected.replaceAll(wrong, right);
    });
    
    if (corrected != text) {
      corrections.add(corrected);
    }
    
    return corrections;
  }
}
