import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../diet/models/models.dart';
import '../../../../diet/providers/food_search_provider.dart';
import '../../../../diet/repositories/alimento_repository.dart';
import '../../../diary/presentation/add_entry_dialog.dart';
import '../providers/food_input_providers.dart';
import '../providers/unified_search_provider.dart';
import '../widgets/add_food_manual_sheet.dart';
import '../widgets/food_list_item.dart';
import '../widgets/input_method_fab.dart';
import '../utils/food_mapper.dart';
import '../widgets/search_empty_state.dart';

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
  Timer? _debounceTimer;
  
  static const _debounceDuration = Duration(milliseconds: 400);
  
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
      ref.read(foodInputModeProvider.notifier).state = FoodInputMode.recent;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _textRecognizer.close();
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
      listenMode: ListenMode.confirmation,
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
      ref.read(foodSearchQueryProvider.notifier).query = parsed.foodName;
      
      // Si especificó cantidad, guardarla para el diálogo
      if (parsed.amount != null) {
        ref.read(voiceInputAmountProvider.notifier).state = parsed.amount;
      }
      
      // Mostrar snackbar con opción rápida
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Buscando: ${parsed.foodName}'),
          action: parsed.amount != null
              ? SnackBarAction(
                  label: 'Añadir ${parsed.amount}g',
                  onPressed: () => _quickAddFromVoice(parsed),
                )
              : null,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  _ParsedVoiceInput _parseVoiceInput(String text) {
    // Regex simple para extraer cantidad y nombre
    // Soporta: "200g de pollo", "200 gramos de pollo", "dos huevos", etc.
    
    final amountRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(g|gramos|gr|ml|mililitros|l|litros)?', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(text);
    
    double? amount;
    String foodName = text;
    
    if (amountMatch != null) {
      final amountStr = amountMatch.group(1)?.replaceAll(',', '.');
      amount = double.tryParse(amountStr ?? '');
      
      // Eliminar la cantidad del nombre
      foodName = text.replaceFirst(amountMatch.group(0)!, '').trim();
      // Limpiar preposiciones comunes
      foodName = foodName.replaceFirst(RegExp(r'^(de\s+|d\')', caseSensitive: false), '').trim();
    }
    
    return _ParsedVoiceInput(foodName: foodName, amount: amount);
  }

  Future<void> _quickAddFromVoice(_ParsedVoiceInput parsed) async {
    final results = ref.read(foodSearchResultsProvider);
    results.whenData((foods) {
      if (foods.isNotEmpty) {
        _selectFood(foods.first);
      }
    });
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
      ref.read(foodSearchQueryProvider.notifier).query = extractedData.name;
      
      // Mostrar opciones
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => _OcrResultsSheet(
          extractedData: extractedData,
          fullText: text,
          onSearch: (query) {
            _searchController.text = query;
            ref.read(foodSearchQueryProvider.notifier).query = query;
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
      // Filtrar líneas muy cortas o que parezcan código de barras/numeros
      final candidates = lines.where((l) => l.length > 3 && !RegExp(r'^\d+$').hasMatch(l));
      if (candidates.isNotEmpty) {
        name = candidates.first;
      }
    }
    
    // Buscar valores nutricionales
    final kcalRegex = RegExp(r'(\d+(?:[.,]\d+)?)\s*(kcal|kJ)', caseSensitive: false);
    final kcalMatch = kcalRegex.firstMatch(text);
    final kcal = kcalMatch != null
        ? double.tryParse(kcalMatch.group(1)!.replaceAll(',', '.'))
        : null;
    
    // Proteínas
    final proteinRegex = RegExp(r'prote[ií]nas?[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false);
    final proteinMatch = proteinRegex.firstMatch(text);
    final proteins = proteinMatch != null
        ? double.tryParse(proteinMatch.group(1)!.replaceAll(',', '.'))
        : null;
    
    // Carbohidratos
    final carbsRegex = RegExp(r'(carbohidratos?|hidratos?|carbs?)[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false);
    final carbsMatch = carbsRegex.firstMatch(text);
    final carbs = carbsMatch != null
        ? double.tryParse(carbsMatch.group(2)!.replaceAll(',', '.'))
        : null;
    
    // Grasas
    final fatRegex = RegExp(r'(grasas?|l[ií]pidos?)[:\s]*(\d+(?:[.,]\d+)?)', caseSensitive: false);
    final fatMatch = fatRegex.firstMatch(text);
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
      
      if (localResults != null) {
        Navigator.of(context).pop(); // Cerrar loading
        _selectFood(localResults);
        return;
      }
      
      // Si no está en local, llamar a Open Food Facts (requiere internet)
      final remoteResult = await ref.read(alimentoRepositoryProvider).searchByBarcodeOnline(barcode);
      
      Navigator.of(context).pop(); // Cerrar loading
      
      if (remoteResult != null) {
        // Guardar en local automáticamente
        await ref.read(alimentoRepositoryProvider).insertFood(remoteResult);
        _selectFood(remoteResult);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto guardado localmente')),
        );
      } else {
        // No encontrado
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Producto no encontrado'),
            content: Text('No se encontró información para el código: $barcode'),
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
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar loading
      _showError('Error al buscar producto: $e');
    }
  }

  // ============================================================================
  // BÚSQUEDA POR TEXTO
  // ============================================================================
  
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    
    if (value.trim().isEmpty) {
      ref.read(foodInputModeProvider.notifier).state = FoodInputMode.recent;
      ref.read(foodSearchQueryProvider.notifier).query = '';
      return;
    }
    
    ref.read(foodInputModeProvider.notifier).state = FoodInputMode.search;
    
    _debounceTimer = Timer(_debounceDuration, () {
      ref.read(searchQueryProvider.notifier).setQuery(value.trim());
    });
  }

  // ============================================================================
  // UTILIDADES
  // ============================================================================
  
  Future<void> _selectFood(Food food) async {
    final result = await showDialog<DiaryEntryModel>(
      context: context,
      builder: (ctx) => AddEntryDialog(
        food: food.toModel(),
      ),
    );

    if (result != null && mounted) {
      Navigator.of(context).pop(result);
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
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Alimento' : 'Alimentos'),
        centerTitle: true,
        actions: [
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
              searchQuery: searchQuery,
            ),
          ),
        ],
      ),
      floatingActionButton: InputMethodFab(
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
                    ref.read(foodSearchQueryProvider.notifier).query = '';
                    ref.read(foodInputModeProvider.notifier).state = FoodInputMode.recent;
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
              ref.read(foodInputModeProvider.notifier).state = FoodInputMode.recent;
              _searchController.clear();
              ref.read(foodSearchQueryProvider.notifier).query = '';
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Favoritos'),
            selected: currentMode == FoodInputMode.favorites,
            onSelected: (_) {
              ref.read(foodInputModeProvider.notifier).state = FoodInputMode.favorites;
              _searchController.clear();
              ref.read(foodSearchQueryProvider.notifier).query = '';
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
    required AsyncValue<List<FoodModel>> recentFoods,
    required String searchQuery,
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
          return _buildFoodList(foods.map((f) => f.food).toList());
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error al cargar recientes')),
      );
    }
    
    // Modo búsqueda
    if (inputMode == FoodInputMode.search) {
      return searchResults.when(
        data: (foods) {
          if (foods.isEmpty && searchQuery.isNotEmpty) {
            return SearchEmptyState(
              query: searchQuery,
              onManualAdd: () => _showManualAddSheet(prefillData: _OcrExtractedData(name: searchQuery)),
              onVoiceInput: _startListening,
              onOcrScan: () => _scanLabel(),
              onBarcodeScan: _scanBarcode,
            );
          }
          if (foods.isEmpty) {
            return SearchEmptyState(
              onManualAdd: () => _showManualAddSheet(),
              onVoiceInput: _startListening,
              onOcrScan: () => _scanLabel(),
              onBarcodeScan: _scanBarcode,
            );
          }
          return _buildFoodList(foods);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error al buscar')),
      );
    }
    
    // Modo favoritos
    if (inputMode == FoodInputMode.favorites) {
      return const Center(child: Text('Favoritos - Próximamente'));
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildFoodList(List<Food> foods) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return FoodListItem(
          food: food,
          onTap: () => _selectFood(food),
        );
      },
    );
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

class _OcrResultsSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Texto detectado',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Nombre extraído
                  if (extractedData.name.isNotEmpty) ...[
                    const Text(
                      'Nombre detectado:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(extractedData.name, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSearch(extractedData.name);
                      },
                      child: const Text('Buscar este producto'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Valores nutricionales detectados
                  if (extractedData.kcal != null || 
                      extractedData.proteins != null || 
                      extractedData.carbs != null || 
                      extractedData.fat != null) ...[
                    const Text(
                      'Valores nutricionales detectados:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (extractedData.kcal != null)
                          Chip(label: Text('${extractedData.kcal} kcal')),
                        if (extractedData.proteins != null)
                          Chip(label: Text('P: ${extractedData.proteins}g')),
                        if (extractedData.carbs != null)
                          Chip(label: Text('C: ${extractedData.carbs}g')),
                        if (extractedData.fat != null)
                          Chip(label: Text('G: ${extractedData.fat}g')),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Texto completo
                  ExpansionTile(
                    title: const Text('Ver texto completo'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(fullText, style: TextStyle(color: Colors.grey[600])),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Acciones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onManualAdd();
                          },
                          child: const Text('Añadir manual'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BarcodeScannerScreen extends StatelessWidget {
  const _BarcodeScannerScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {}, // Toggle flash
          ),
        ],
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final barcode = barcodes.first.rawValue;
            if (barcode != null && barcode.isNotEmpty) {
              Navigator.of(context).pop(barcode);
            }
          }
        },
        overlay: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(50),
        ),
      ),
    );
  }
}
