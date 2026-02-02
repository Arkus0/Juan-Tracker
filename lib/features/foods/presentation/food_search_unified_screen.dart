import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../diet/models/models.dart';
// Hide MealType from database.dart - we use the one from diet/models
import '../../../../diet/providers/food_search_provider.dart' hide favoriteFoodsProvider;
import '../../../../diet/repositories/alimento_repository.dart';
import '../../../../training/database/database.dart' hide MealType, ServingUnit;
import '../../diary/presentation/add_entry_dialog.dart';
import '../providers/food_input_providers.dart';
import '../providers/unified_search_provider.dart';
import '../widgets/add_food_manual_sheet.dart';
import '../widgets/food_list_item.dart';
import '../widgets/input_method_fab.dart';
import '../utils/food_mapper.dart';
import '../widgets/search_empty_state.dart';

// ============================================================================
// PERF: Pre-compiled regex patterns - avoid creating RegExp per call
// ============================================================================

/// Voice input: matches amounts like "200g", "200 gramos", "150ml"
final _voiceAmountRegex = RegExp(
  r'(\d+(?:[.,]\d+)?)\s*(g|gramos|gr|ml|mililitros|l|litros)?',
  caseSensitive: false,
);

/// Voice input: removes leading prepositions like "de " or "d'"
final _voicePrepositionRegex = RegExp(r"^(de\s+|d')", caseSensitive: false);

/// OCR: matches calorie values like "250 kcal" or "1000 kJ"
final _ocrKcalRegex = RegExp(
  r'(\d+(?:[.,]\d+)?)\s*(kcal|kJ)',
  caseSensitive: false,
);

/// OCR: matches protein values
final _ocrProteinRegex = RegExp(
  r'prote[ií]nas?[:\s]*(\d+(?:[.,]\d+)?)',
  caseSensitive: false,
);

/// OCR: matches carbohydrate values
final _ocrCarbsRegex = RegExp(
  r'(carbohidratos?|hidratos?|carbs?)[:\s]*(\d+(?:[.,]\d+)?)',
  caseSensitive: false,
);

/// OCR: matches fat values
final _ocrFatRegex = RegExp(
  r'(grasas?|l[ií]pidos?)[:\s]*(\d+(?:[.,]\d+)?)',
  caseSensitive: false,
);

/// OCR: identifies lines that are just numbers (barcodes, etc.)
final _ocrDigitsOnlyRegex = RegExp(r'^\d+$');

// ============================================================================

/// Pantalla unificada de búsqueda de alimentos - Offline First
/// 
/// Combina todos los métodos de entrada:
/// 1. Búsqueda por texto (local, instantánea)
/// 2. Entrada por voz (speech-to-text)
/// 3. OCR de etiquetas (cámara/galería)
/// 4. Escaneo de barcode (único que requiere internet)
class FoodSearchUnifiedScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  final DateTime? selectedDate;

  const FoodSearchUnifiedScreen({
    super.key,
    this.isEditing = false,
    this.selectedDate,
  });

  @override
  ConsumerState<FoodSearchUnifiedScreen> createState() => _FoodSearchUnifiedScreenState();
}

class _FoodSearchUnifiedScreenState extends ConsumerState<FoodSearchUnifiedScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  
  // Speech to text
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  
  // ML Kit OCR
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessingOcr = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _initSpeech();
    
    // Cargar recientes al inicio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).setQuery('');
      ref.read(foodInputModeProvider.notifier).setMode(FoodInputMode.recent);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _textRecognizer.close();
    // Limpiar estado de batch al salir para evitar que persista
    // en futuras visitas a esta pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(batchSelectionProvider.notifier).cancelBatch();
    });
    super.dispose();
  }

  // ============================================================================
  // SPEECH TO TEXT
  // ============================================================================
  
  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        _showError('Error en reconocimiento de voz: $error');
      },
    );
    setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showError('Reconocimiento de voz no disponible');
      return;
    }

    HapticFeedback.mediumImpact();
    
    setState(() => _isListening = true);
    
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords;
          _processVoiceInput(text);
        }
      },
      localeId: 'es_ES',
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _processVoiceInput(String text) {
    // Parsear texto de voz: "200 gramos de pechuga de pollo hacendado"
    final parsed = _parseVoiceInput(text);
    
    if (parsed.foodName.isNotEmpty) {
      // Buscar el alimento
      _searchController.text = parsed.foodName;
      ref.read(searchQueryProvider.notifier).setQuery(parsed.foodName);
      
      // Si especificó cantidad, guardarla para el diálogo
      if (parsed.amount != null) {
        ref.read(voiceInputAmountProvider.notifier).setAmount(parsed.amount);
      }
      
      // Mostrar snackbar con opción de añadir rápido
      final hasAmount = parsed.amount != null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mic, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasAmount 
                    ? '${parsed.foodName} (${parsed.amount!.toStringAsFixed(0)}g)'
                    : parsed.foodName,
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: hasAmount ? '✓ AÑADIR' : 'BUSCAR',
            textColor: Colors.amber,
            onPressed: () => _quickAddFromVoice(parsed),
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // No se pudo parsear el texto
      AppSnackbar.showError(context, message: 'No se entendió. Intenta de nuevo.');
    }
  }

  _ParsedVoiceInput _parseVoiceInput(String text) {
    // PERF: Use pre-compiled regex patterns
    // Soporta: "200g de pollo", "200 gramos de pollo", "dos huevos", etc.

    final amountMatch = _voiceAmountRegex.firstMatch(text);

    double? amount;
    String foodName = text;

    if (amountMatch != null) {
      final amountStr = amountMatch.group(1)?.replaceAll(',', '.');
      amount = double.tryParse(amountStr ?? '');

      // Eliminar la cantidad del nombre
      foodName = text.replaceFirst(amountMatch.group(0)!, '').trim();
      // PERF: Use pre-compiled regex for preposition removal
      foodName = foodName.replaceFirst(_voicePrepositionRegex, '').trim();
    }

    return _ParsedVoiceInput(foodName: foodName, amount: amount);
  }

  Future<void> _quickAddFromVoice(_ParsedVoiceInput parsed) async {
    // Buscar alimentos con el query parseado
    final repository = ref.read(alimentoRepositoryProvider);
    final results = await repository.search(parsed.foodName, limit: 5);
    
    if (!mounted) return;
    
    if (results.isEmpty) {
      // Sin resultados: abrir formulario manual
      AppSnackbar.show(context, message: 'No encontrado. Añade manualmente.');
      _showManualAddSheet(prefillData: _OcrExtractedData(name: parsed.foodName));
      return;
    }
    
    // Si hay un resultado muy bueno (score alto), usarlo directamente
    final bestMatch = results.first;
    
    if (results.length == 1 || bestMatch.score > 150) {
      // Match único o muy bueno: abrir diálogo con cantidad pre-rellenada
      final result = await showDialog<DiaryEntryModel>(
        context: context,
        builder: (ctx) => AddEntryDialog(
          food: bestMatch.food.toModel(),
          initialAmount: parsed.amount,
        ),
      );
      
      if (result != null && mounted) {
        try {
          await ref.read(diaryRepositoryProvider).insert(result);
          if (!mounted) return;
          AppSnackbar.show(context, message: '${bestMatch.food.name} añadido');
          Navigator.of(context).pop();
        } catch (e) {
          if (mounted) {
            AppSnackbar.showError(context, message: 'Error al guardar: $e');
          }
        }
      }
    } else {
      // Múltiples resultados: mostrar sheet para elegir
      _showVoiceResultsSheet(parsed, results.map((r) => r.food).toList());
    }
  }
  
  /// Sheet para elegir entre varios resultados de voz
  void _showVoiceResultsSheet(_ParsedVoiceInput parsed, List<Food> results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.mic, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selecciona el alimento',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (parsed.amount != null)
                      Chip(
                        label: Text('${parsed.amount!.toStringAsFixed(0)}g'),
                        backgroundColor: theme.colorScheme.primaryContainer,
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Results list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final food = results[index];
                    return ListTile(
                      title: Text(food.name),
                      subtitle: Text(
                        '${food.kcalPer100g} kcal/100g${food.brand != null ? ' • ${food.brand}' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        Navigator.of(context).pop();
                        
                        final result = await showDialog<DiaryEntryModel>(
                          context: this.context,
                          builder: (ctx) => AddEntryDialog(
                            food: food.toModel(),
                            initialAmount: parsed.amount,
                          ),
                        );
                        
                        if (result != null && mounted) {
                          try {
                            await ref.read(diaryRepositoryProvider).insert(result);
                            if (!mounted) return;
                            AppSnackbar.show(this.context, message: '${food.name} añadido');
                            Navigator.of(this.context).pop();
                          } catch (e) {
                            if (mounted) {
                              AppSnackbar.showError(this.context, message: 'Error: $e');
                            }
                          }
                        }
                      },
                    );
                  },
                ),
              ),
              
              // Add manual option
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showManualAddSheet(prefillData: _OcrExtractedData(name: parsed.foodName));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir manualmente'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================================
  // OCR / ETIQUETA
  // ============================================================================
  
  Future<void> _scanLabel({bool fromGallery = false}) async {
    try {
      final XFile? image = fromGallery
          ? await _imagePicker.pickImage(source: ImageSource.gallery)
          : await _imagePicker.pickImage(source: ImageSource.camera, preferredCameraDevice: CameraDevice.rear);
      
      if (image == null) return;
      
      setState(() => _isProcessingOcr = true);
      
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      setState(() => _isProcessingOcr = false);
      
      if (recognizedText.text.isNotEmpty) {
        _processOcrText(recognizedText.text);
      } else {
        _showError('No se detectó texto en la imagen');
      }
    } catch (e) {
      setState(() => _isProcessingOcr = false);
      _showError('Error al procesar imagen: $e');
    }
  }

  void _processOcrText(String text) {
    // Extraer posibles nombres de alimentos y valores nutricionales
    final extractedData = _extractFoodDataFromOcr(text);
    
    // Buscar coincidencias en la base local
    if (extractedData.name.isNotEmpty) {
      _searchController.text = extractedData.name;
      ref.read(searchQueryProvider.notifier).setQuery(extractedData.name);
      
      // Mostrar opciones
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => _OcrResultsSheet(
          extractedData: extractedData,
          fullText: text,
          onSearch: (query) {
            _searchController.text = query;
            ref.read(searchQueryProvider.notifier).setQuery(query);
          },
          onManualAdd: () => _showManualAddSheet(prefillData: extractedData),
        ),
      );
    } else {
      // No se pudo extraer nombre, mostrar opción de añadir manual
      _showManualAddSheet(prefillData: _OcrExtractedData(name: '', rawText: text));
    }
  }

  _OcrExtractedData _extractFoodDataFromOcr(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // Buscar nombre (primera línea significativa, típicamente el nombre del producto)
    String name = '';
    if (lines.isNotEmpty) {
      // PERF: Use pre-compiled regex for digit-only check
      final candidates = lines.where((l) => l.length > 3 && !_ocrDigitsOnlyRegex.hasMatch(l));
      if (candidates.isNotEmpty) {
        name = candidates.first;
      }
    }

    // PERF: Use pre-compiled regex patterns for all nutritional value extraction
    final kcalMatch = _ocrKcalRegex.firstMatch(text);
    final kcal = kcalMatch != null
        ? double.tryParse(kcalMatch.group(1)!.replaceAll(',', '.'))
        : null;

    final proteinMatch = _ocrProteinRegex.firstMatch(text);
    final proteins = proteinMatch != null
        ? double.tryParse(proteinMatch.group(1)!.replaceAll(',', '.'))
        : null;

    final carbsMatch = _ocrCarbsRegex.firstMatch(text);
    final carbs = carbsMatch != null
        ? double.tryParse(carbsMatch.group(2)!.replaceAll(',', '.'))
        : null;

    final fatMatch = _ocrFatRegex.firstMatch(text);
    final fat = fatMatch != null
        ? double.tryParse(fatMatch.group(2)!.replaceAll(',', '.'))
        : null;

    return _OcrExtractedData(
      name: name,
      kcal: kcal,
      proteins: proteins,
      carbs: carbs,
      fat: fat,
      rawText: text,
    );
  }

  // ============================================================================
  // BARCODE SCANNER
  // ============================================================================
  
  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (ctx) => const _BarcodeScannerScreen(),
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      _processBarcode(result);
    }
  }

  void _processBarcode(String barcode) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Primero buscar en local
      final localResults = await ref.read(alimentoRepositoryProvider).searchByBarcode(barcode);

      // T1 FIX: Check mounted before Navigator operations after async gap
      if (!mounted) return;

      if (localResults != null) {
        Navigator.of(context).pop(); // Cerrar loading
        _selectFood(localResults);
        return;
      }

      // Si no está en local, buscar online via el provider híbrido
      debugPrint('[Barcode] No encontrado local, buscando online: $barcode');
      final onlineResult = await ref.read(onlineBarcodeSearchProvider(barcode).future);

      if (!mounted) return;

      if (onlineResult != null) {
        Navigator.of(context).pop(); // Cerrar loading
        _selectFood(onlineResult);
        return;
      }

      // No encontrado ni local ni online
      Navigator.of(context).pop(); // Cerrar loading

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Producto no encontrado'),
          content: Text('No se encontró información para el código: $barcode\n\nNo está en la base local ni en Open Food Facts.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showManualAddSheet(prefillData: _OcrExtractedData(name: 'Producto $barcode'));
              },
              child: const Text('Añadir manual'),
            ),
          ],
        ),
      );
    } catch (e) {
      // T1 FIX: Check mounted before Navigator operations after async gap
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar loading
      _showError('Error al buscar producto: $e');
    }
  }

  // ============================================================================
  // BÚSQUEDA POR TEXTO
  // ============================================================================

  /// Buscar en Open Food Facts (acción explícita del usuario)
  /// 
  /// Usa el nuevo método searchOnline() del provider que añade los resultados
  /// de OFF a la lista actual sin bloquear la UI.
  Future<void> _searchOnline(String query) async {
    if (query.trim().isEmpty) return;

    debugPrint('[SearchOnline] Buscando en OFF: $query');
    
    // Llamar al provider - esto añade los resultados a la lista actual
    await ref.read(foodSearchProvider.notifier).searchOnline();
    
    // Mostrar feedback
    if (!mounted) return;
    final state = ref.read(foodSearchProvider);
    if (state.results.any((r) => r.isFromRemote)) {
      AppSnackbar.show(context, message: 'Resultados de internet añadidos');
    } else if (state.status == SearchStatus.error) {
      AppSnackbar.showError(context, message: state.errorMessage ?? 'Error de conexión');
    }
  }

  void _onSearchChanged(String value) {
    final trimmed = value.trim();
    
    if (trimmed.isEmpty) {
      ref.read(foodInputModeProvider.notifier).setMode(FoodInputMode.recent);
      ref.read(searchQueryProvider.notifier).setQuery('');
      ref.read(foodSearchProvider.notifier).search(''); // Resetea el provider
      return;
    }
    
    ref.read(foodInputModeProvider.notifier).setMode(FoodInputMode.search);
    ref.read(searchQueryProvider.notifier).setQuery(trimmed);
    // El provider ya tiene debounce interno de 300ms
    ref.read(foodSearchProvider.notifier).search(trimmed);
  }

  // ============================================================================
  // UTILIDADES
  // ============================================================================
  
  Future<void> _selectFood(Food food) async {
    // Si el alimento no tiene datos nutricionales, ofrecer editar primero
    if (food.kcalPer100g <= 0) {
      final shouldEdit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Datos incompletos'),
          content: Text(
            '${food.name} no tiene información nutricional. '
            '¿Quieres añadir los datos manualmente?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('EDITAR'),
            ),
          ],
        ),
      );
      
      if (shouldEdit == true && mounted) {
        _showManualAddSheet(prefillData: _OcrExtractedData(
          name: food.name,
          kcal: null,
          proteins: food.proteinPer100g,
          carbs: food.carbsPer100g,
          fat: food.fatPer100g,
        ));
      }
      return;
    }
    
    final result = await showDialog<DiaryEntryModel>(
      context: context,
      builder: (ctx) => AddEntryDialog(
        food: food.toModel(),
      ),
    );

    if (result != null && mounted) {
      try {
        await ref.read(diaryRepositoryProvider).insert(result);
        // Registrar uso del alimento para que aparezca en recientes
        // Nota: No pasamos mealType por conflicto de tipos entre diet/models y database
        await ref.read(alimentoRepositoryProvider).recordSelection(food.id);
        // Invalidar recientes para que se actualice la UI
        ref.invalidate(recentFoodsForUnifiedProvider);
        if (!mounted) return;
        AppSnackbar.show(context, message: '${food.name} añadido al diario');
        Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, message: 'Error al guardar: $e');
        }
      }
    }
  }

  void _showManualAddSheet({_OcrExtractedData? prefillData}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddFoodManualSheet(
        prefillName: prefillData?.name,
        prefillKcal: prefillData?.kcal,
        prefillProteins: prefillData?.proteins,
        prefillCarbs: prefillData?.carbs,
        prefillFat: prefillData?.fat,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(unifiedSearchProvider);
    final inputMode = ref.watch(foodInputModeProvider);
    final recentFoods = ref.watch(recentFoodsForUnifiedProvider);
    final batchState = ref.watch(batchSelectionProvider);
    final favoriteFoods = ref.watch(favoriteFoodsForUnifiedProvider);
    
    return Scaffold(
      resizeToAvoidBottomInset: true, // Asegurar que el body se ajuste al teclado
      appBar: AppBar(
        title: batchState.isActive 
          ? Text('${batchState.count} seleccionados')
          : Text(widget.isEditing ? 'Editar Alimento' : 'Alimentos'),
        centerTitle: true,
        leading: batchState.isActive
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => ref.read(batchSelectionProvider.notifier).cancelBatch(),
              tooltip: 'Cancelar selección',
            )
          : null,
        actions: [
          if (!batchState.isActive)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _showSettingsMenu(),
              tooltip: 'Ajustes',
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda principal
          _buildSearchBar(searchQuery),
          
          // Chips de modo de entrada
          _buildInputModeChips(inputMode),
          
          // Indicador de escucha de voz
          if (_isListening) _buildVoiceListeningIndicator(),
          
          // Indicador de procesamiento OCR
          if (_isProcessingOcr) _buildOcrProcessingIndicator(),
          
          // Lista de resultados
          Expanded(
            child: _buildResultsList(
              searchResults: searchResults,
              inputMode: inputMode,
              recentFoods: recentFoods,
              favoriteFoods: favoriteFoods,
              searchQuery: searchQuery,
              batchState: batchState,
            ),
          ),
        ],
      ),
      // Show batch add FAB when items selected, otherwise normal FAB
      floatingActionButton: batchState.isActive
        ? FloatingActionButton.extended(
            onPressed: () => _addBatchSelection(),
            icon: const Icon(Icons.add_circle),
            label: Text('Añadir ${batchState.count}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          )
        : InputMethodFab(
            onManualAdd: () => _showManualAddSheet(),
            onVoiceInput: _startListening,
            onOcrScan: () => _scanLabel(),
            onBarcodeScan: _scanBarcode,
          ),
    );
  }

  Widget _buildSearchBar(String searchQuery) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Buscar alimentos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón micrófono
              IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.red : null,
                ),
                onPressed: _isListening ? _stopListening : _startListening,
                tooltip: 'Dictar con voz',
              ),
              // Botón limpiar (solo si hay texto)
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).setQuery('');
                    ref.read(foodInputModeProvider.notifier).setMode(FoodInputMode.recent);
                    _searchFocusNode.requestFocus();
                  },
                ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildInputModeChips(FoodInputMode currentMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Recientes'),
            selected: currentMode == FoodInputMode.recent,
            onSelected: (_) {
              ref.read(foodInputModeProvider.notifier).setMode(FoodInputMode.recent);
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).setQuery('');
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Favoritos'),
            selected: currentMode == FoodInputMode.favorites,
            onSelected: (_) {
              ref.read(foodInputModeProvider.notifier).setMode(FoodInputMode.favorites);
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).setQuery('');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceListeningIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withAlpha((0.3 * 255).round())),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escuchando...',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Text(
                  'Di algo como "200 gramos de pechuga de pollo"',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _stopListening,
            child: const Text('Detener'),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrProcessingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Analizando etiqueta...'),
        ],
      ),
    );
  }

  Widget _buildResultsList({
    required AsyncValue<List<ScoredFood>> searchResults,
    required FoodInputMode inputMode,
    required AsyncValue<List<Food>> recentFoods,
    required AsyncValue<List<Food>> favoriteFoods,
    required String searchQuery,
    required BatchSelectionState batchState,
  }) {
    // Modo recientes
    if (inputMode == FoodInputMode.recent) {
      return recentFoods.when(
        data: (foods) {
          if (foods.isEmpty) {
            return SearchEmptyState(
              onManualAdd: () => _showManualAddSheet(),
              onVoiceInput: _startListening,
              onOcrScan: () => _scanLabel(),
              onBarcodeScan: _scanBarcode,
            );
          }
          return _buildFoodList(foods, batchState: batchState, showFavorites: true);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Error al cargar recientes')),
      );
    }

    // Modo búsqueda
    if (inputMode == FoodInputMode.search) {
      final searchState = ref.watch(foodSearchProvider);
      
      // SHORT QUERY: Show recents + hint message
      if (searchQuery.isNotEmpty && searchQuery.length < 3) {
        return _buildShortQueryView(searchQuery, searchState);
      }
      
      return searchResults.when(
        data: (scoredFoods) {
          if (scoredFoods.isEmpty && searchQuery.isNotEmpty) {
            return SearchEmptyState(
              query: searchQuery,
              onManualAdd: () => _showManualAddSheet(prefillData: _OcrExtractedData(name: searchQuery)),
              onVoiceInput: _startListening,
              onOcrScan: () => _scanLabel(),
              onBarcodeScan: _scanBarcode,
              onSearchOnline: () => _searchOnline(searchQuery),
            );
          }
          if (scoredFoods.isEmpty) {
            return SearchEmptyState(
              onManualAdd: () => _showManualAddSheet(),
              onVoiceInput: _startListening,
              onOcrScan: () => _scanLabel(),
              onBarcodeScan: _scanBarcode,
            );
          }
          // Convertir ScoredFood a Food - pasar searchQuery para botón online
          return _buildFoodList(
            scoredFoods.map((s) => s.food).toList(),
            searchQuery: searchQuery,
            batchState: batchState,
            showFavorites: true,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Error al buscar')),
      );
    }

    // Modo favoritos
    if (inputMode == FoodInputMode.favorites) {
      return favoriteFoods.when(
        data: (foods) {
          if (foods.isEmpty) {
            return _buildEmptyFavoritesView();
          }
          return _buildFoodList(foods, batchState: batchState, showFavorites: true);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Error al cargar favoritos')),
      );
    }

    return const SizedBox.shrink();
  }
  
  /// Vista cuando no hay favoritos
  Widget _buildEmptyFavoritesView() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin favoritos',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mantén pulsado un alimento para añadirlo a favoritos',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds view for short queries (<3 chars)
  /// Shows hint message + recent foods as alternatives
  Widget _buildShortQueryView(String query, FoodSearchState searchState) {
    final theme = Theme.of(context);
    final recents = searchState.popularAlternatives;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hint message
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Escribe 3 o más caracteres para buscar',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Recent foods as alternatives
        if (recents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Alimentos recientes',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildFoodList(recents),
          ),
        ] else ...[
          const Expanded(
            child: Center(
              child: Text('Continúa escribiendo...'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFoodList(
    List<Food> foods, {
    String? searchQuery,
    BatchSelectionState? batchState,
    bool showFavorites = false,
  }) {
    final hasQuery = searchQuery != null && searchQuery.isNotEmpty;
    final searchState = ref.watch(foodSearchProvider);
    final isSearchingOnline = searchState.isLoading && searchState.results.isNotEmpty;
    final isBatchMode = batchState?.isActive ?? false;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      // +1 para el botón de buscar online
      itemCount: hasQuery ? foods.length + 1 : foods.length,
      itemBuilder: (context, index) {
        // Último item: botón de buscar online
        if (hasQuery && index == foods.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: isSearchingOnline
              ? const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Buscando en internet...'),
                    ],
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () => _searchOnline(searchQuery),
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('Buscar en internet'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
          );
        }
        
        final food = foods[index];
        return FoodListItem(
          food: food,
          onTap: () => _selectFood(food),
          isSelected: batchState?.isSelected(food.id) ?? false,
          onSelectionToggle: isBatchMode || showFavorites
            ? () => ref.read(batchSelectionProvider.notifier).toggleSelection(food.id)
            : null,
          showFavoriteButton: showFavorites && !isBatchMode,
          onFavoriteToggle: showFavorites && !isBatchMode
            ? () => _toggleFavorite(food)
            : null,
        );
      },
    );
  }
  
  /// Toggle favorite status de un alimento
  Future<void> _toggleFavorite(Food food) async {
    try {
      final toggleFavorite = ref.read(toggleFavoriteProvider);
      final newState = await toggleFavorite(food.id);
      if (mounted) {
        AppSnackbar.show(
          context, 
          message: newState ? 'Añadido a favoritos' : 'Eliminado de favoritos',
        );
        // Refrescar providers
        ref.invalidate(favoriteFoodsForUnifiedProvider);
        ref.invalidate(favoriteFoodsProvider);
        ref.invalidate(recentFoodsForUnifiedProvider);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showError(context, message: 'Error al actualizar favorito');
      }
    }
  }
  
  /// Añadir todos los alimentos seleccionados en batch
  Future<void> _addBatchSelection() async {
    final selectedIds = ref.read(batchSelectionProvider.notifier).consumeSelection();
    if (selectedIds.isEmpty) return;
    
    // Obtener los alimentos por ID usando AlimentoRepository
    final repository = ref.read(alimentoRepositoryProvider);
    final foods = <Food>[];
    for (final id in selectedIds) {
      final food = await repository.getById(id);
      if (food != null) foods.add(food);
    }
    
    if (foods.isEmpty || !mounted) return;
    
    // Mostrar diálogo de batch add
    await _showBatchAddDialog(foods);
  }
  
  /// Diálogo para añadir múltiples alimentos con cantidades
  Future<void> _showBatchAddDialog(List<Food> foods) async {
    final date = widget.selectedDate ?? DateTime.now();
    
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _BatchAddSheet(
        foods: foods,
        selectedDate: date,
        onConfirm: (entries) async {
          Navigator.of(ctx).pop();
          await _saveBatchEntries(entries);
        },
      ),
    );
  }
  
  /// Guardar entradas en batch
  Future<void> _saveBatchEntries(List<DiaryEntryModel> entries) async {
    if (entries.isEmpty) return;
    
    final diaryRepo = ref.read(diaryRepositoryProvider);
    var successCount = 0;
    
    for (final entry in entries) {
      try {
        await diaryRepo.insert(entry);
        successCount++;
      } catch (e) {
        debugPrint('[BatchAdd] Error saving entry: $e');
      }
    }
    
    if (mounted) {
      AppSnackbar.show(
        context,
        message: 'Añadidos $successCount alimentos',
      );
      Navigator.of(context).pop(); // Volver a diary
    }
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Limpiar caché de búsquedas'),
              onTap: () {
                Navigator.of(ctx).pop();
                // Implementar limpieza de caché
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Forzar actualización de base de datos'),
              onTap: () {
                Navigator.of(ctx).pop();
                // Implementar actualización
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Acerca de la base de datos'),
              onTap: () {
                Navigator.of(ctx).pop();
                showAboutDialog(
                  context: context,
                  applicationName: 'Base de datos de alimentos',
                  children: const [
                    Text('Base local: 600,000+ productos'),
                    Text('Fuentes: Open Food Facts + contribuciones'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CLASES AUXILIARES
// ============================================================================

class _ParsedVoiceInput {
  final String foodName;
  final double? amount;
  
  _ParsedVoiceInput({required this.foodName, this.amount});
}

class _OcrExtractedData {
  final String name;
  final double? kcal;
  final double? proteins;
  final double? carbs;
  final double? fat;
  final String rawText;
  
  _OcrExtractedData({
    required this.name,
    this.kcal,
    this.proteins,
    this.carbs,
    this.fat,
    this.rawText = '',
  });
}

// ============================================================================
// WIDGETS INTERNOS
// ============================================================================

class _OcrResultsSheet extends ConsumerStatefulWidget {
  final _OcrExtractedData extractedData;
  final String fullText;
  final Function(String) onSearch;
  final VoidCallback onManualAdd;
  
  const _OcrResultsSheet({
    required this.extractedData,
    required this.fullText,
    required this.onSearch,
    required this.onManualAdd,
  });

  @override
  ConsumerState<_OcrResultsSheet> createState() => _OcrResultsSheetState();
}

class _OcrResultsSheetState extends ConsumerState<_OcrResultsSheet> {
  late TextEditingController _nameController;
  List<Food> _searchResults = [];
  bool _isSearching = false;
  bool _showFullText = false;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.extractedData.name);
    // Buscar automáticamente si tenemos nombre
    if (widget.extractedData.name.isNotEmpty) {
      _searchForMatches();
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _searchForMatches() async {
    final query = _nameController.text.trim();
    if (query.isEmpty) return;
    
    setState(() => _isSearching = true);
    
    try {
      final repository = ref.read(alimentoRepositoryProvider);
      final results = await repository.search(query, limit: 5);
      
      if (mounted) {
        setState(() {
          _searchResults = results.map((r) => r.food).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.extractedData;
    final hasNutrition = data.kcal != null || data.proteins != null || 
                         data.carbs != null || data.fat != null;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.document_scanner, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Etiqueta escaneada',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (hasNutrition)
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
            ),
            
            const Divider(),
            
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Nombre editable
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del producto',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchForMatches,
                      ),
                    ),
                    onSubmitted: (_) => _searchForMatches(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Valores nutricionales detectados
                  if (hasNutrition) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withAlpha(50),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(100),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.restaurant_menu, 
                                size: 16, 
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Por 100g',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _NutritionChip(
                                label: 'kcal',
                                value: data.kcal?.toStringAsFixed(0),
                                color: Colors.orange,
                              ),
                              _NutritionChip(
                                label: 'Prot',
                                value: data.proteins?.toStringAsFixed(1),
                                color: Colors.red,
                              ),
                              _NutritionChip(
                                label: 'Carbs',
                                value: data.carbs?.toStringAsFixed(1),
                                color: Colors.blue,
                              ),
                              _NutritionChip(
                                label: 'Grasa',
                                value: data.fat?.toStringAsFixed(1),
                                color: Colors.amber,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Resultados de búsqueda
                  if (_isSearching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_searchResults.isNotEmpty) ...[
                    Text(
                      'Coincidencias encontradas:',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_searchResults.length, (index) {
                      final food = _searchResults[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(food.name),
                          subtitle: Text('${food.kcalPer100g} kcal/100g'),
                          trailing: FilledButton.tonal(
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onSearch(food.name);
                            },
                            child: const Text('Usar'),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                  
                  // Mostrar texto completo
                  TextButton.icon(
                    onPressed: () => setState(() => _showFullText = !_showFullText),
                    icon: Icon(_showFullText ? Icons.expand_less : Icons.expand_more),
                    label: Text(_showFullText ? 'Ocultar texto' : 'Ver texto completo'),
                  ),
                  if (_showFullText)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.fullText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Actions
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onManualAdd();
                        },
                        icon: const Icon(Icons.add),
                        label: Text(
                          hasNutrition ? 'Crear alimento' : 'Añadir manual',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Chip para mostrar valor nutricional
class _NutritionChip extends StatelessWidget {
  final String label;
  final String? value;
  final Color color;
  
  const _NutritionChip({
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    
    return Column(
      children: [
        Text(
          value!,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  bool _flashOn = false;
  
  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }
  
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  void _toggleFlash() {
    _controller?.toggleTorch();
    setState(() => _flashOn = !_flashOn);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Escanear código'),
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            color: _flashOn ? Colors.amber : Colors.white,
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_hasScanned) return; // Evitar múltiples detecciones
              
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first.rawValue;
                if (barcode != null && barcode.isNotEmpty) {
                  _hasScanned = true;
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop(barcode);
                }
              }
            },
          ),
          
          // Overlay con marco de escaneo
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Esquinas decorativas
                  ..._buildCorners(theme.colorScheme.primary),
                ],
              ),
            ),
          ),
          
          // Instrucciones
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Apunta al código de barras',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'EAN-13, EAN-8, UPC-A, UPC-E',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildCorners(Color color) {
    const size = 24.0;
    const thickness = 4.0;
    
    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),
    ];
  }
}

/// Sheet para añadir múltiples alimentos con cantidades
class _BatchAddSheet extends StatefulWidget {
  final List<Food> foods;
  final DateTime selectedDate;
  final Future<void> Function(List<DiaryEntryModel>) onConfirm;

  const _BatchAddSheet({
    required this.foods,
    required this.selectedDate,
    required this.onConfirm,
  });

  @override
  State<_BatchAddSheet> createState() => _BatchAddSheetState();
}

class _BatchAddSheetState extends State<_BatchAddSheet> {
  late final List<TextEditingController> _controllers;
  late final List<MealType> _mealTypes;
  
  @override
  void initState() {
    super.initState();
    // Default 100g para cada alimento
    _controllers = List.generate(
      widget.foods.length,
      (_) => TextEditingController(text: '100'),
    );
    // Default meal type basado en hora
    final defaultMeal = _getMealTypeForHour(DateTime.now().hour);
    _mealTypes = List.filled(widget.foods.length, defaultMeal);
  }
  
  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }
  
  MealType _getMealTypeForHour(int hour) {
    if (hour < 11) return MealType.breakfast;
    if (hour < 15) return MealType.lunch;
    if (hour < 18) return MealType.snack;
    return MealType.dinner;
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Añadir ${widget.foods.length} alimentos',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Lista de alimentos con campos de cantidad
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.foods.length,
                  itemBuilder: (context, index) {
                    final food = widget.foods[index];
                    return _buildFoodEntryRow(food, index);
                  },
                ),
              ),
              
              const Divider(height: 1),
              
              // Botón confirmar
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _onConfirm,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text('Añadir ${widget.foods.length} alimentos'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFoodEntryRow(Food food, int index) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del alimento
            Text(
              food.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (food.brand != null)
              Text(
                food.brand!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Cantidad y tipo de comida
            Row(
              children: [
                // Campo de cantidad
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _controllers[index],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad (g)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Selector de tipo de comida
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<MealType>(
                    initialValue: _mealTypes[index],
                    decoration: const InputDecoration(
                      labelText: 'Comida',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: MealType.values.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _mealTypes[index] = val);
                      }
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Preview de kcal
            Builder(
              builder: (context) {
                final grams = double.tryParse(_controllers[index].text) ?? 100;
                final kcal = (food.kcalPer100g * grams / 100).round();
                return Text(
                  '$kcal kcal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _onConfirm() async {
    const uuid = Uuid();
    final entries = <DiaryEntryModel>[];
    
    for (var i = 0; i < widget.foods.length; i++) {
      final food = widget.foods[i];
      final grams = double.tryParse(_controllers[i].text) ?? 100;
      final mealType = _mealTypes[i];
      
      entries.add(DiaryEntryModel.fromFood(
        id: uuid.v4(),
        food: food.toModel(),
        amount: grams,
        unit: ServingUnit.grams,
        date: widget.selectedDate,
        mealType: mealType,
      ));
    }
    
    await widget.onConfirm(entries);
  }
}
