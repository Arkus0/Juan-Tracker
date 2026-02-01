import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';

import '../../../../core/providers/database_provider.dart';
import '../../../../training/database/database.dart';

/// Bottom sheet para añadir alimento manualmente
/// 
/// Campos:
/// - Nombre (obligatorio)
/// - Marca (opcional)
/// - Porción por defecto (default 100g)
/// - Kcal/100g
/// - Proteínas, Carbs, Grasas
/// 
/// Calcula automáticamente las kcal si faltan (4*P + 4*C + 9*G)
class AddFoodManualSheet extends ConsumerStatefulWidget {
  final String? prefillName;
  final double? prefillKcal;
  final double? prefillProteins;
  final double? prefillCarbs;
  final double? prefillFat;

  const AddFoodManualSheet({
    super.key,
    this.prefillName,
    this.prefillKcal,
    this.prefillProteins,
    this.prefillCarbs,
    this.prefillFat,
  });

  @override
  ConsumerState<AddFoodManualSheet> createState() => _AddFoodManualSheetState();
}

class _AddFoodManualSheetState extends ConsumerState<AddFoodManualSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  
  double _defaultPortion = 100;
  bool _autoCalculateKcal = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.prefillName ?? '';
    if (widget.prefillKcal != null) {
      _kcalController.text = widget.prefillKcal!.toStringAsFixed(1);
    }
    if (widget.prefillProteins != null) {
      _proteinController.text = widget.prefillProteins!.toStringAsFixed(1);
    }
    if (widget.prefillCarbs != null) {
      _carbsController.text = widget.prefillCarbs!.toStringAsFixed(1);
    }
    if (widget.prefillFat != null) {
      _fatController.text = widget.prefillFat!.toStringAsFixed(1);
    }
    
    // Calcular kcal inicial si tenemos macros
    _calculateKcal();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _calculateKcal() {
    if (!_autoCalculateKcal) return;
    
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;
    
    final calculated = (protein * 4) + (carbs * 4) + (fat * 9);
    
    // Solo actualizar si el campo está vacío o si los macros cambiaron significativamente
    final currentKcal = double.tryParse(_kcalController.text) ?? 0;
    if ((currentKcal - calculated).abs() > 1 || _kcalController.text.isEmpty) {
      setState(() {
        _kcalController.text = calculated.toStringAsFixed(1);
      });
    }
  }

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) return;
    
    final food = FoodsCompanion(
      id: Value(const Uuid().v4()),
      name: Value(_nameController.text.trim()),
      brand: Value(_brandController.text.trim().isEmpty ? null : _brandController.text.trim()),
      kcalPer100g: Value(double.parse(_kcalController.text).round()),
      proteinPer100g: Value(double.tryParse(_proteinController.text)),
      carbsPer100g: Value(double.tryParse(_carbsController.text)),
      fatPer100g: Value(double.tryParse(_fatController.text)),
      portionGrams: Value(_defaultPortion),
      userCreated: const Value(true),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    
    try {
      final db = ref.read(appDatabaseProvider);
      await db.into(db.foods).insert(food);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alimento guardado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Añadir alimento',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Nombre
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          hintText: 'Ej: Pechuga de pollo',
                          prefixIcon: Icon(Icons.food_bank_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      
                      // Marca
                      TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Marca (opcional)',
                          hintText: 'Ej: Hacendado',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),
                      
                      // Porción por defecto
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Porción por defecto',
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<double>(
                              segments: const [
                                ButtonSegment(value: 100, label: Text('100g')),
                                ButtonSegment(value: 50, label: Text('50g')),
                                ButtonSegment(value: 30, label: Text('30g')),
                              ],
                              selected: {_defaultPortion},
                              onSelectionChanged: (value) {
                                setState(() => _defaultPortion = value.first);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Macros
                      Text(
                        'Valores por 100g',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Proteínas
                      _buildMacroField(
                        controller: _proteinController,
                        label: 'Proteínas',
                        icon: Icons.fitness_center,
                        color: Colors.green,
                        onChanged: () => _calculateKcal(),
                      ),
                      const SizedBox(height: 12),
                      
                      // Carbohidratos
                      _buildMacroField(
                        controller: _carbsController,
                        label: 'Carbohidratos',
                        icon: Icons.grain,
                        color: Colors.orange,
                        onChanged: () => _calculateKcal(),
                      ),
                      const SizedBox(height: 12),
                      
                      // Grasas
                      _buildMacroField(
                        controller: _fatController,
                        label: 'Grasas',
                        icon: Icons.water_drop,
                        color: Colors.blue,
                        onChanged: () => _calculateKcal(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Checkbox auto-calcular
                      CheckboxListTile(
                        value: _autoCalculateKcal,
                        onChanged: (value) {
                          setState(() => _autoCalculateKcal = value ?? true);
                          if (_autoCalculateKcal) _calculateKcal();
                        },
                        title: const Text('Calcular kcal automáticamente'),
                        subtitle: const Text('4×P + 4×C + 9×G'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      
                      // Kcal
                      TextFormField(
                        controller: _kcalController,
                        decoration: const InputDecoration(
                          labelText: 'Kcal/100g *',
                          hintText: 'Ej: 165',
                          prefixIcon: Icon(Icons.local_fire_department),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Las calorías son obligatorias';
                          }
                          final number = double.tryParse(value);
                          if (number == null || number < 0) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Botón guardar
                      FilledButton.icon(
                        onPressed: _saveFood,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar alimento'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMacroField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        suffixText: 'g',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (_) => onChanged(),
    );
  }
}
