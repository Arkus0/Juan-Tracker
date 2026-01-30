/// Pantalla para crear/editar el plan del Coach
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_profile_model.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/tdee_calculator.dart';
import '../../providers/coach_providers.dart';
import '../../services/adaptive_coach_service.dart';

class PlanSetupScreen extends ConsumerStatefulWidget {
  final CoachPlan? existingPlan;

  const PlanSetupScreen({super.key, this.existingPlan});

  @override
  ConsumerState<PlanSetupScreen> createState() => _PlanSetupScreenState();
}

class _PlanSetupScreenState extends ConsumerState<PlanSetupScreen> {
  late WeightGoal _goal;
  late double _weeklyRatePercent; // -0.025 a +0.025
  late final TextEditingController _tdeeController;
  late final TextEditingController _weightController;
  late MacroPreset _macroPreset;
  late double _customProteinPercent;
  late double _customCarbsPercent;
  late double _customFatPercent;
  bool _useCustomMacros = false;
  bool _isLoading = false;

  final List<_GoalOption> _goalOptions = [
    _GoalOption(
      goal: WeightGoal.lose,
      title: 'Perder peso',
      subtitle: 'Déficit calórico para pérdida de grasa',
      icon: Icons.trending_down,
      color: Colors.green,
    ),
    _GoalOption(
      goal: WeightGoal.maintain,
      title: 'Mantener peso',
      subtitle: 'Balance calórico para mantenimiento',
      icon: Icons.trending_flat,
      color: Colors.blue,
    ),
    _GoalOption(
      goal: WeightGoal.gain,
      title: 'Ganar peso',
      subtitle: 'Superávit calórico para ganancia muscular',
      icon: Icons.trending_up,
      color: Colors.orange,
    ),
  ];

  final List<_MacroPresetOption> _macroPresetOptions = [
    _MacroPresetOption(
      preset: MacroPreset.lowCarb,
      title: 'Low Carb',
      subtitle: '25% prot · 45% grasa · 30% carb',
      description: 'Ideal para cetosis leve y control de hambre',
    ),
    _MacroPresetOption(
      preset: MacroPreset.balanced,
      title: 'Balanceado',
      subtitle: '30% prot · 35% carb · 35% grasa',
      description: 'Distribución equilibrada para la mayoría',
    ),
    _MacroPresetOption(
      preset: MacroPreset.highProtein,
      title: 'High Protein',
      subtitle: '40% prot · 30% carb · 30% grasa',
      description: 'Máxima proteína para ganancia muscular',
    ),
    _MacroPresetOption(
      preset: MacroPreset.highCarb,
      title: 'High Carb',
      subtitle: '25% prot · 50% carb · 25% grasa',
      description: 'Alto rendimiento deportivo y energía',
    ),
    _MacroPresetOption(
      preset: MacroPreset.keto,
      title: 'Keto',
      subtitle: '30% prot · 5% carb · 65% grasa',
      description: 'Cetosis estricta',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final plan = widget.existingPlan;
    _goal = plan?.goal ?? WeightGoal.lose;
    _weeklyRatePercent = _goal == WeightGoal.maintain ? 0.0 : 
                        (_goal == WeightGoal.lose ? -0.005 : 0.005);
    _macroPreset = plan?.macroPreset ?? MacroPreset.balanced;
    _customProteinPercent = _macroPreset.proteinPercent * 100;
    _customCarbsPercent = _macroPreset.carbsPercent * 100;
    _customFatPercent = _macroPreset.fatPercent * 100;
    _tdeeController = TextEditingController(
      text: plan?.initialTdeeEstimate.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: plan?.startingWeight.toString() ?? '',
    );
    
    // Cargar último peso si no hay plan existente
    if (plan == null) {
      _loadLatestWeight();
    }
  }
  
  Future<void> _loadLatestWeight() async {
    final container = ProviderScope.containerOf(context);
    final repo = container.read(weighInRepositoryProvider);
    final latest = await repo.getLatest();
    
    if (latest != null && mounted) {
      setState(() {
        _weightController.text = latest.weightKg.toStringAsFixed(1);
      });
    }
  }

  @override
  void dispose() {
    _tdeeController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  double get _weight => double.tryParse(_weightController.text) ?? 80;

  double get _weeklyRateKg => _weight * _weeklyRatePercent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingPlan == null ? 'Nuevo Plan' : 'Editar Plan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selección de objetivo
            Text(
              '1. Elige tu objetivo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._goalOptions.map((option) => _GoalCard(
                  option: option,
                  isSelected: _goal == option.goal,
                  onTap: () => setState(() {
                    _goal = option.goal;
                    if (_goal == WeightGoal.maintain) {
                      _weeklyRatePercent = 0.0;
                    } else if (_goal == WeightGoal.lose && _weeklyRatePercent >= 0) {
                      _weeklyRatePercent = -0.005;
                    } else if (_goal == WeightGoal.gain && _weeklyRatePercent <= 0) {
                      _weeklyRatePercent = 0.005;
                    }
                  }),
                )),

            const SizedBox(height: 24),

            // Tasa de cambio en % del peso (mostrado en kg)
            Text(
              '2. Velocidad de cambio',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajusta según tu peso actual (${_weight.toStringAsFixed(1)} kg)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(179),
              ),
            ),
            const SizedBox(height: 16),
            _buildRateSlider(),

            const SizedBox(height: 24),

            // Preset de macros
            Text(
              '3. Distribución de macros',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._macroPresetOptions.map((option) => _MacroPresetCard(
                  option: option,
                  isSelected: _macroPreset == option.preset && !_useCustomMacros,
                  onTap: () => setState(() {
                    _macroPreset = option.preset;
                    _useCustomMacros = false;
                    _customProteinPercent = option.preset.proteinPercent * 100;
                    _customCarbsPercent = option.preset.carbsPercent * 100;
                    _customFatPercent = option.preset.fatPercent * 100;
                  }),
                )),
            
            const SizedBox(height: 12),
            
            // Toggle personalizado
            Card(
              color: _useCustomMacros 
                  ? colorScheme.primaryContainer 
                  : colorScheme.surfaceContainerHighest.withAlpha(128),
              child: InkWell(
                onTap: () => setState(() {
                  _useCustomMacros = !_useCustomMacros;
                }),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _useCustomMacros ? Icons.check_circle : Icons.tune,
                        color: _useCustomMacros ? colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personalizado',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Ajusta los porcentajes manualmente',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _useCustomMacros,
                        onChanged: (v) => setState(() => _useCustomMacros = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sliders personalizables
            if (_useCustomMacros) ...[
              const SizedBox(height: 24),
              _buildMacroSliders(),
            ],

            const SizedBox(height: 24),

            // TDEE estimado
            Text(
              '4. Estimación inicial de TDEE',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes usar una calculadora online o tu mejor estimación',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(179),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tdeeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'TDEE estimado (kcal)',
                suffixText: 'kcal',
                border: const OutlineInputBorder(),
                helperText: _tdeeController.text.isNotEmpty 
                    ? 'Según tu perfil: ${_tdeeController.text} kcal'
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _calculateTDEE,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calculate),
                  SizedBox(width: 8),
                  Text('Calcular automáticamente'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Peso actual
            Text(
              '5. Tu peso actual',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Peso actual (kg)',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            // Resumen
            Card(
              color: colorScheme.primaryContainer.withAlpha(51),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Objetivo', _getGoalDescription()),
                    _buildSummaryRow('Velocidad', _getRateDescription()),
                    _buildSummaryRow('Macros', _useCustomMacros 
                        ? 'Personalizado (${_customProteinPercent.toInt()}% P)' 
                        : _macroPreset.displayName),
                    _buildSummaryRow(
                        'TDEE inicial', '${_tdeeController.text} kcal'),
                    _buildSummaryRow(
                        'Peso inicial', '${_weightController.text} kg'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botón guardar
            FilledButton.icon(
              onPressed: _isLoading ? null : _savePlan,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading
                  ? 'GUARDANDO...'
                  : (widget.existingPlan == null ? 'CREAR PLAN' : 'ACTUALIZAR')),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRateSlider() {
    if (_goal == WeightGoal.maintain) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('Mantenimiento: sin cambio de peso'),
          ),
        ),
      );
    }

    // FIX: El slider siempre muestra valores positivos (0.1% a 2.5%)
    // El signo se aplica según el objetivo
    final isLosing = _goal == WeightGoal.lose;
    final minRate = 0.001; // 0.1%
    final maxRate = 0.025; // 2.5%
    
    // Valor absoluto para mostrar en el slider
    final displayPercent = _weeklyRatePercent.abs().clamp(minRate, maxRate);
    final kgPerWeek = _weight * displayPercent;
    final kcalAdjustment = (kgPerWeek * 7700 / 7).round();

    return Column(
      children: [
        Slider(
          value: displayPercent,
          min: minRate,
          max: maxRate,
          divisions: 24, // Steps de 0.1%
          label: '${(displayPercent * 100).toStringAsFixed(1)}%',
          onChanged: (value) {
            setState(() {
              // Aplicar signo según objetivo
              _weeklyRatePercent = isLosing ? -value : value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Conservador (0.1%)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Column(
              children: [
                Text(
                  '${kgPerWeek.toStringAsFixed(2)} kg/semana',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${isLosing ? "-" : "+"}$kcalAdjustment kcal/día',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isLosing ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            Text(
              'Agresivo (2.5%)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _getRateGuidance(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMacroSliders() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _MacroPercentSlider(
              label: 'Proteína',
              value: _customProteinPercent,
              color: Colors.red.shade400,
              onChanged: (v) => setState(() {
                _customProteinPercent = v;
                _normalizeMacros();
              }),
            ),
            const SizedBox(height: 16),
            _MacroPercentSlider(
              label: 'Carbohidratos',
              value: _customCarbsPercent,
              color: Colors.orange.shade400,
              onChanged: (v) => setState(() {
                _customCarbsPercent = v;
                _normalizeMacros();
              }),
            ),
            const SizedBox(height: 16),
            _MacroPercentSlider(
              label: 'Grasas',
              value: _customFatPercent,
              color: Colors.yellow.shade700,
              onChanged: (v) => setState(() {
                _customFatPercent = v;
                _normalizeMacros();
              }),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_customProteinPercent + _customCarbsPercent + _customFatPercent - 100).abs() < 0.1
                    ? Colors.green.withAlpha(51)
                    : Colors.red.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total: ${_customProteinPercent.toStringAsFixed(0)}% + ${_customCarbsPercent.toStringAsFixed(0)}% + ${_customFatPercent.toStringAsFixed(0)}% = ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '${(_customProteinPercent + _customCarbsPercent + _customFatPercent).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: (_customProteinPercent + _customCarbsPercent + _customFatPercent - 100).abs() < 0.1
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _normalizeMacros() {
    final total = _customProteinPercent + _customCarbsPercent + _customFatPercent;
    if (total > 0 && (total - 100).abs() > 0.1) {
      final factor = 100 / total;
      _customProteinPercent *= factor;
      _customCarbsPercent *= factor;
      _customFatPercent *= factor;
    }
  }

  String _getRateGuidance() {
    final percent = _weeklyRatePercent.abs() * 100;
    if (_goal == WeightGoal.lose) {
      if (percent < 0.5) return '🐢 Pérdida conservadora, mínima pérdida muscular';
      if (percent < 1.0) return '🐕 Pérdida moderada, recomendada para la mayoría';
      if (percent < 1.5) return '🏃 Pérdida agresiva, riesgo de pérdida muscular';
      return '⚠️ Muy agresivo, solo recomendado para casos especiales';
    } else if (_goal == WeightGoal.gain) {
      if (percent < 0.5) return '🐢 Ganancia limpia, mínima grasa';
      if (percent < 1.0) return '🐕 Ganancia moderada, balance muscular/grasa';
      return '🏃 Ganancia rápida, más grasa acumulada';
    }
    return '';
  }

  String _getGoalDescription() {
    return switch (_goal) {
      WeightGoal.lose => 'Perder peso',
      WeightGoal.maintain => 'Mantener peso',
      WeightGoal.gain => 'Ganar peso',
    };
  }

  String _getRateDescription() {
    if (_goal == WeightGoal.maintain) return '0% (0 kg/semana)';
    final percent = (_weeklyRatePercent * 100).abs();
    final kgString = _weeklyRateKg.abs().toStringAsFixed(2);
    final kcalString = (_weeklyRateKg * 7700 / 7).round().abs();
    return '${percent.toStringAsFixed(1)}% ($kgString kg/semana, ${kcalString}kcal ${
      _goal == WeightGoal.lose ? 'déficit' : 'superávit'
    })';
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _calculateTDEE() async {
    // Obtener perfil del usuario
    final profile = await ref.read(userProfileRepositoryProvider).get();
    
    if (profile == null || !profile.isComplete) {
      // Mostrar diálogo para completar perfil
      if (!mounted) return;
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => _CompleteProfileDialog(
          existingProfile: profile,
        ),
      );
      
      if (result == true) {
        // Recargar perfil y calcular
        final updatedProfile = await ref.read(userProfileRepositoryProvider).get();
        if (updatedProfile != null && updatedProfile.isComplete) {
          final tdee = TdeeCalculator.calculateTDEEFromProfile(updatedProfile);
          if (tdee != null && mounted) {
            setState(() {
              _tdeeController.text = tdee.round().toString();
            });
          }
        }
      }
      return;
    }
    
    // Calcular TDEE directamente
    final tdee = TdeeCalculator.calculateTDEEFromProfile(profile);
    if (tdee != null && mounted) {
      setState(() {
        _tdeeController.text = tdee.round().toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('TDEE calculado: ${tdee.round()} kcal'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _savePlan() async {
    final tdee = int.tryParse(_tdeeController.text);
    final weight = double.tryParse(_weightController.text);

    if (tdee == null || tdee < 1000 || tdee > 6000) {
      _showError('TDEE inválido. Debe estar entre 1000 y 6000 kcal.');
      return;
    }

    if (weight == null || weight < 30 || weight > 300) {
      _showError('Peso inválido. Debe estar entre 30 y 300 kg.');
      return;
    }

    // Validar que macros sumen 100%
    if (_useCustomMacros) {
      final total = _customProteinPercent + _customCarbsPercent + _customFatPercent;
      if ((total - 100).abs() > 1) {
        _showError('Los porcentajes de macros deben sumar 100% (actual: ${total.toStringAsFixed(0)}%)');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear preset personalizado si es necesario
      MacroPreset finalPreset = _macroPreset;
      if (_useCustomMacros) {
        finalPreset = _MacroPresetOption.createCustom(
          proteinPercent: _customProteinPercent / 100,
          carbsPercent: _customCarbsPercent / 100,
          fatPercent: _customFatPercent / 100,
        );
      }

      await ref.read(coachPlanProvider.notifier).createPlan(
            goal: _goal,
            weeklyRatePercent: _weeklyRatePercent,
            initialTdeeEstimate: tdee,
            startingWeight: weight,
            macroPreset: finalPreset,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan creado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showError('Error al guardar: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Diálogo para completar el perfil desde el Coach
class _CompleteProfileDialog extends ConsumerStatefulWidget {
  final UserProfileModel? existingProfile;

  const _CompleteProfileDialog({this.existingProfile});

  @override
  ConsumerState<_CompleteProfileDialog> createState() => _CompleteProfileDialogState();
}

class _CompleteProfileDialogState extends ConsumerState<_CompleteProfileDialog> {
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  Gender? _gender;
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _ageController = TextEditingController(text: p?.age?.toString() ?? '');
    _heightController = TextEditingController(
      text: p?.heightCm?.toStringAsFixed(0) ?? '',
    );
    _weightController = TextEditingController(
      text: p?.currentWeightKg?.toStringAsFixed(1) ?? '',
    );
    _gender = p?.gender;
    _activityLevel = p?.activityLevel ?? ActivityLevel.moderatelyActive;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Completa tu Perfil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Necesitamos algunos datos para calcular tu TDEE con precisión.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Edad *',
                suffixText: 'años',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<Gender?>(
              selected: {_gender},
              onSelectionChanged: (set) => setState(() => _gender = set.first),
              segments: const [
                ButtonSegment(
                  value: Gender.male,
                  label: Text('Hombre'),
                  icon: Icon(Icons.male),
                ),
                ButtonSegment(
                  value: Gender.female,
                  label: Text('Mujer'),
                  icon: Icon(Icons.female),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Altura *',
                suffixText: 'cm',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso actual *',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ActivityLevel>(
              value: _activityLevel,
              decoration: const InputDecoration(
                labelText: 'Nivel de actividad',
                border: OutlineInputBorder(),
              ),
              items: ActivityLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(level.displayName),
                );
              }).toList(),
              onChanged: (v) => setState(() => _activityLevel = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Guardar y Calcular'),
        ),
      ],
    );
  }

  void _save() async {
    final age = int.tryParse(_ageController.text);
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (age == null || height == null || weight == null || _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    final error = TdeeCalculator.validateProfile(
      age: age,
      heightCm: height,
      weightKg: weight,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    final profile = UserProfileModel(
      id: 'user_profile',
      age: age,
      gender: _gender,
      heightCm: height,
      currentWeightKg: weight,
      activityLevel: _activityLevel,
      createdAt: widget.existingProfile?.createdAt,
      updatedAt: DateTime.now(),
    );

    await ref.read(userProfileRepositoryProvider).save(profile);

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }
}

class _GoalOption {
  final WeightGoal goal;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  _GoalOption({
    required this.goal,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _MacroPresetOption {
  final MacroPreset preset;
  final String title;
  final String subtitle;
  final String description;

  _MacroPresetOption({
    required this.preset,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  static MacroPreset createCustom({
    required double proteinPercent,
    required double carbsPercent,
    required double fatPercent,
  }) {
    return MacroPreset.custom;
  }
}

class _GoalCard extends StatelessWidget {
  final _GoalOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? option.color.withAlpha(26)
          : colorScheme.surfaceContainerHighest.withAlpha(77),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: option.color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: option.color.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  option.icon,
                  color: option.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: option.color,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroPresetCard extends StatelessWidget {
  final _MacroPresetOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _MacroPresetCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? colorScheme.primaryContainer.withAlpha(128)
          : colorScheme.surfaceContainerHighest.withAlpha(77),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? colorScheme.primary.withAlpha(51)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pie_chart,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroPercentSlider extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _MacroPercentSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(label),
              ],
            ),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value.clamp(0, 100),
          min: 0,
          max: 100,
          divisions: 20,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
