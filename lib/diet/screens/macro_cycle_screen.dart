import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../diet/models/macro_cycle_model.dart';
import '../../../diet/providers/coach_providers.dart';
import '../../../diet/providers/macro_cycle_providers.dart';

const int _kMacroKcalTolerance = 50;

/// Pantalla de configuración de ciclado de macros.
///
/// Permite definir macros diferentes para días de entrenamiento vs descanso.
class MacroCycleScreen extends ConsumerStatefulWidget {
  const MacroCycleScreen({super.key});

  @override
  ConsumerState<MacroCycleScreen> createState() => _MacroCycleScreenState();
}

class _MacroCycleScreenState extends ConsumerState<MacroCycleScreen> {
  late bool _enabled;
  late Map<int, DayType> _assignments;

  late final List<TextEditingController> _macroControllers;
  late final Listenable _macroListenable;

  static const DayMacros _kDefaultFastingMacros =
      DayMacros(kcal: 500, protein: 50, carbs: 30, fat: 15);

  // Training day controllers
  final _tKcalController = TextEditingController();
  final _tProteinController = TextEditingController();
  final _tCarbsController = TextEditingController();
  final _tFatController = TextEditingController();
  
  // Rest day controllers
  final _rKcalController = TextEditingController();
  final _rProteinController = TextEditingController();
  final _rCarbsController = TextEditingController();
  final _rFatController = TextEditingController();

  // Fasting day controllers
  final _fKcalController = TextEditingController();
  final _fProteinController = TextEditingController();
  final _fCarbsController = TextEditingController();
  final _fFatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _macroControllers = [
      _tKcalController,
      _tProteinController,
      _tCarbsController,
      _tFatController,
      _rKcalController,
      _rProteinController,
      _rCarbsController,
      _rFatController,
      _fKcalController,
      _fProteinController,
      _fCarbsController,
      _fFatController,
    ];
    _macroListenable = Listenable.merge(_macroControllers);
    _loadConfig();
  }

  void _loadConfig() {
    final config = ref.read(macroCycleConfigProvider);
    final coachPlan = ref.read(coachPlanProvider);

    if (config != null) {
      _enabled = config.enabled;
      _assignments = Map.from(config.weekdayAssignments);
      _setControllers(
        config.trainingDayMacros,
        config.restDayMacros,
        config.fastingDayMacros,
      );
    } else {
      _enabled = false;
      _assignments = {
        DateTime.monday: DayType.training,
        DateTime.tuesday: DayType.training,
        DateTime.wednesday: DayType.training,
        DateTime.thursday: DayType.rest,
        DateTime.friday: DayType.training,
        DateTime.saturday: DayType.rest,
        DateTime.sunday: DayType.rest,
      };
      
      // Pre-rellenar con base del coach si existe
      if (coachPlan != null) {
        final base = MacroCycleConfig.defaultConfig(
          id: const Uuid().v4(),
          baseKcal: coachPlan.currentKcalTarget ?? coachPlan.initialTdeeEstimate,
          baseProtein: coachPlan.macroPreset.calculateGrams(
            coachPlan.currentKcalTarget ?? coachPlan.initialTdeeEstimate,
          ).protein.toDouble(),
          baseCarbs: coachPlan.macroPreset.calculateGrams(
            coachPlan.currentKcalTarget ?? coachPlan.initialTdeeEstimate,
          ).carbs.toDouble(),
          baseFat: coachPlan.macroPreset.calculateGrams(
            coachPlan.currentKcalTarget ?? coachPlan.initialTdeeEstimate,
          ).fat.toDouble(),
        );
        _setControllers(base.trainingDayMacros, base.restDayMacros, null);
      } else {
        _setControllers(
          const DayMacros(kcal: 2200, protein: 150, carbs: 250, fat: 70),
          const DayMacros(kcal: 1800, protein: 150, carbs: 180, fat: 65),
          null,
        );
      }
    }
  }

  void _setControllers(DayMacros training, DayMacros rest, DayMacros? fasting) {
    _tKcalController.text = training.kcal.toString();
    _tProteinController.text = training.protein.toStringAsFixed(0);
    _tCarbsController.text = training.carbs.toStringAsFixed(0);
    _tFatController.text = training.fat.toStringAsFixed(0);
    
    _rKcalController.text = rest.kcal.toString();
    _rProteinController.text = rest.protein.toStringAsFixed(0);
    _rCarbsController.text = rest.carbs.toStringAsFixed(0);
    _rFatController.text = rest.fat.toStringAsFixed(0);

    final f = fasting ?? _kDefaultFastingMacros;
    _fKcalController.text = f.kcal.toString();
    _fProteinController.text = f.protein.toStringAsFixed(0);
    _fCarbsController.text = f.carbs.toStringAsFixed(0);
    _fFatController.text = f.fat.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _tKcalController.dispose();
    _tProteinController.dispose();
    _tCarbsController.dispose();
    _tFatController.dispose();
    _rKcalController.dispose();
    _rProteinController.dispose();
    _rCarbsController.dispose();
    _rFatController.dispose();
    _fKcalController.dispose();
    _fProteinController.dispose();
    _fCarbsController.dispose();
    _fFatController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ciclado de macros'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'GUARDAR',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _macroListenable,
        builder: (context, _) {
          final weeklyAvg = _calculateWeeklyAvg();
          final trainingMacroKcal = _macroKcalFromControllers(
            protein: _tProteinController,
            carbs: _tCarbsController,
            fat: _tFatController,
          );
          final restMacroKcal = _macroKcalFromControllers(
            protein: _rProteinController,
            carbs: _rCarbsController,
            fat: _rFatController,
          );
          final fastingMacroKcal = _macroKcalFromControllers(
            protein: _fProteinController,
            carbs: _fCarbsController,
            fat: _fFatController,
          );
          final trainingKcal = _parseKcal(_tKcalController);
          final restKcal = _parseKcal(_rKcalController);
          final fastingKcal = _parseKcal(_fKcalController);
          final trainingDays =
              _assignments.values.where((t) => t == DayType.training).length;
          final restDays =
              _assignments.values.where((t) => t == DayType.rest).length;
          final fastingDays =
              _assignments.values.where((t) => t == DayType.fasting).length;

          final trainingColor = colors.primary;
          final restColor = colors.secondary;
          final fastingColor = colors.tertiary;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Switch de activaci?n
              Card(
                child: SwitchListTile(
                  secondary: Icon(Icons.loop, color: colors.primary),
                  title: Text(
                    'Ciclado de macros',
                    style: AppTypography.titleSmall,
                  ),
                  subtitle: Text(
                    'Macros diferentes para d?as de entreno y descanso',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ),

              if (_enabled) ...[
                const SizedBox(height: AppSpacing.lg),

                // Resumen semanal
                if (weeklyAvg > 0)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer
                          .withAlpha((0.5 * 255).round()),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: colors.primary.withAlpha((0.2 * 255).round()),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_flat,
                                color: colors.primary, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Media semanal: $weeklyAvg kcal/d?a',
                              style: AppTypography.labelLarge.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _DayCountPill(
                              label: 'Entreno',
                              count: trainingDays,
                              color: trainingColor,
                            ),
                            _DayCountPill(
                              label: 'Descanso',
                              count: restDays,
                              color: restColor,
                            ),
                            if (fastingDays > 0)
                              _DayCountPill(
                                label: 'Ayuno',
                                count: fastingDays,
                                color: fastingColor,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.lg),

                // Asignaci?n de d?as
                Text(
                  'D?AS DE LA SEMANA',
                  style: AppTypography.sectionLabel.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _WeekdaySelector(
                  assignments: _assignments,
                  onChanged: (weekday, type) {
                    setState(() => _assignments[weekday] = type);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                // Leyenda
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(color: trainingColor, label: 'Entreno'),
                    const SizedBox(width: AppSpacing.md),
                    _LegendDot(color: restColor, label: 'Descanso'),
                    const SizedBox(width: AppSpacing.md),
                    _LegendDot(color: fastingColor, label: 'Ayuno'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Toca para ciclar entre tipos',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Macros d?a de entrenamiento
                _MacroInputCard(
                  title: 'D?a de entrenamiento',
                  icon: Icons.fitness_center,
                  color: trainingColor,
                  dayCount: trainingDays,
                  kcalController: _tKcalController,
                  proteinController: _tProteinController,
                  carbsController: _tCarbsController,
                  fatController: _tFatController,
                  macroKcal: trainingMacroKcal,
                  targetKcal: trainingKcal,
                ),

                const SizedBox(height: AppSpacing.lg),

                // Macros d?a de descanso
                _MacroInputCard(
                  title: 'D?a de descanso',
                  icon: Icons.self_improvement,
                  color: restColor,
                  dayCount: restDays,
                  kcalController: _rKcalController,
                  proteinController: _rProteinController,
                  carbsController: _rCarbsController,
                  fatController: _rFatController,
                  macroKcal: restMacroKcal,
                  targetKcal: restKcal,
                ),

                // Macros d?a de ayuno (solo si hay d?as asignados)
                if (fastingDays > 0) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _MacroInputCard(
                    title: 'D?a de ayuno',
                    icon: Icons.no_food,
                    color: fastingColor,
                    dayCount: fastingDays,
                    kcalController: _fKcalController,
                    proteinController: _fProteinController,
                    carbsController: _fCarbsController,
                    fatController: _fFatController,
                    macroKcal: fastingMacroKcal,
                    targetKcal: fastingKcal,
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }


  String _normalizeNumber(String input) => input.replaceAll(',', '.');

  int _parseKcal(TextEditingController controller) {
    final value = double.tryParse(_normalizeNumber(controller.text));
    return value?.round() ?? 0;
  }

  double _parseMacro(TextEditingController controller) {
    return double.tryParse(_normalizeNumber(controller.text)) ?? 0;
  }

  int _macroKcalFromControllers({
    required TextEditingController protein,
    required TextEditingController carbs,
    required TextEditingController fat,
  }) {
    final proteinGrams = _parseMacro(protein);
    final carbsGrams = _parseMacro(carbs);
    final fatGrams = _parseMacro(fat);
    return (proteinGrams * 4 + carbsGrams * 4 + fatGrams * 9).round();
  }

  int _calculateWeeklyAvg() {
    final tKcal = _parseKcal(_tKcalController);
    final rKcal = _parseKcal(_rKcalController);
    final fKcal = _parseKcal(_fKcalController);
    final tDays = _assignments.values.where((t) => t == DayType.training).length;
    final rDays = _assignments.values.where((t) => t == DayType.rest).length;
    final fDays = _assignments.values.where((t) => t == DayType.fasting).length;
    final total = tKcal * tDays + rKcal * rDays + fKcal * fDays;
    return total > 0 ? (total / 7).round() : 0;
  }

  Future<void> _save() async {
    final hasFastingDays = _assignments.values.any((t) => t == DayType.fasting);

    final config = MacroCycleConfig(
      id: ref.read(macroCycleConfigProvider)?.id ?? const Uuid().v4(),
      enabled: _enabled,
      trainingDayMacros: DayMacros(
        kcal: _parseKcal(_tKcalController),
        protein: _parseMacro(_tProteinController),
        carbs: _parseMacro(_tCarbsController),
        fat: _parseMacro(_tFatController),
      ),
      restDayMacros: DayMacros(
        kcal: _parseKcal(_rKcalController),
        protein: _parseMacro(_rProteinController),
        carbs: _parseMacro(_rCarbsController),
        fat: _parseMacro(_rFatController),
      ),
      fastingDayMacros: hasFastingDays
          ? DayMacros(
              kcal: _parseKcal(_fKcalController) == 0
                  ? _kDefaultFastingMacros.kcal
                  : _parseKcal(_fKcalController),
              protein: _parseMacro(_fProteinController) == 0
                  ? _kDefaultFastingMacros.protein
                  : _parseMacro(_fProteinController),
              carbs: _parseMacro(_fCarbsController) == 0
                  ? _kDefaultFastingMacros.carbs
                  : _parseMacro(_fCarbsController),
              fat: _parseMacro(_fFatController) == 0
                  ? _kDefaultFastingMacros.fat
                  : _parseMacro(_fFatController),
            )
          : null,
      weekdayAssignments: Map.from(_assignments),
      updatedAt: DateTime.now(),
    );

    await ref.read(macroCycleConfigProvider.notifier).save(config);

    if (mounted) {
      AppSnackbar.show(
        context,
        message: _enabled
            ? 'Ciclado de macros activado'
            : 'Ciclado de macros desactivado',
      );
      Navigator.of(context).pop();
    }
  }
}

/// Selector visual de d?as de la semana
class _WeekdaySelector extends StatelessWidget {
  final Map<int, DayType> assignments;
  final void Function(int weekday, DayType type) onChanged;

  const _WeekdaySelector({
    required this.assignments,
    required this.onChanged,
  });

  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const _dayFullNames = [
    'Lunes',
    'Martes',
    'Mi?rcoles',
    'Jueves',
    'Viernes',
    'S?bado',
    'Domingo',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final weekday = index + 1; // 1=Monday ... 7=Sunday
        final type = assignments[weekday] ?? DayType.rest;
        final typeColor = _typeColor(type, colors);
        final typeIcon = _typeIcon(type);
        final bgAlpha = type == DayType.rest ? 0.08 : 0.15;

        return Tooltip(
          message: '${_dayFullNames[index]} ? ${type.displayName}',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Ciclar: training ? rest ? fasting ? training
                final next = switch (type) {
                  DayType.training => DayType.rest,
                  DayType.rest => DayType.fasting,
                  DayType.fasting => DayType.training,
                };
                onChanged(weekday, next);
              },
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withAlpha((bgAlpha * 255).round()),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: typeColor.withAlpha((0.6 * 255).round()),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayLabels[index],
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      typeIcon,
                      size: 14,
                      color: typeColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _typeColor(DayType type, ColorScheme colors) => switch (type) {
        DayType.training => colors.primary,
        DayType.rest => colors.secondary,
        DayType.fasting => colors.tertiary,
      };

  IconData _typeIcon(DayType type) => switch (type) {
        DayType.training => Icons.fitness_center,
        DayType.rest => Icons.self_improvement,
        DayType.fasting => Icons.no_food,
      };
}

/// Card de input de macros para un tipo de d?a
class _MacroInputCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int dayCount;
  final TextEditingController kcalController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatController;
  final int? macroKcal;
  final int? targetKcal;

  static final _macroDecimalFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

  const _MacroInputCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.dayCount,
    required this.kcalController,
    required this.proteinController,
    required this.carbsController,
    required this.fatController,
    this.macroKcal,
    this.targetKcal,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleSmall),
                      Text(
                        dayCount == 0
                            ? 'Sin d?as asignados'
                            : '$dayCount d?as/semana',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (dayCount == 0
                            ? colors.onSurfaceVariant
                            : color)
                        .withAlpha((0.12 * 255).round()),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    dayCount == 0 ? '0 d?as' : '$dayCount d?as',
                    style: AppTypography.labelSmall.copyWith(
                      color: dayCount == 0
                          ? colors.onSurfaceVariant
                          : color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Kcal
            _MacroField(
              label: 'Calor?as',
              controller: kcalController,
              suffix: 'kcal',
              color: colors.primary,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),

            const SizedBox(height: AppSpacing.md),

            // Macros en fila
            Row(
              children: [
                Expanded(
                  child: _MacroField(
                    label: 'Prote?na',
                    controller: proteinController,
                    suffix: 'g',
                    color: colors.error,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_MacroInputCard._macroDecimalFormatter],
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MacroField(
                    label: 'Carbs',
                    controller: carbsController,
                    suffix: 'g',
                    color: colors.tertiary,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_MacroInputCard._macroDecimalFormatter],
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _MacroField(
                    label: 'Grasa',
                    controller: fatController,
                    suffix: 'g',
                    color: colors.secondary,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_MacroInputCard._macroDecimalFormatter],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
              ],
            ),

            if (macroKcal != null &&
                targetKcal != null &&
                targetKcal! > 0 &&
                macroKcal! > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _MacroKcalHint(
                targetKcal: targetKcal!,
                macroKcal: macroKcal!,
              ),
            ],
          ],
        ),
      ),
    );
  }

}

class _DayCountPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _DayCountPill({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        '$label: $count',
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MacroKcalHint extends StatelessWidget {
  final int targetKcal;
  final int macroKcal;

  const _MacroKcalHint({
    required this.targetKcal,
    required this.macroKcal,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final diff = macroKcal - targetKcal;
    final diffAbs = diff.abs();
    final isOk = diffAbs <= _kMacroKcalTolerance;

    final Color accent;
    final IconData icon;
    final String diffLabel;

    if (isOk) {
      accent = colors.secondary;
      icon = Icons.check_circle;
      diffLabel = 'En objetivo';
    } else if (diff > 0) {
      accent = colors.error;
      icon = Icons.trending_up;
      diffLabel = '+$diffAbs kcal';
    } else {
      accent = colors.tertiary;
      icon = Icons.trending_down;
      diffLabel = '-$diffAbs kcal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: accent.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: accent.withAlpha((0.4 * 255).round()),
        ),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(icon, size: 14, color: accent),
          Text(
            'Macros ? $macroKcal kcal',
            style: AppTypography.labelSmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            diffLabel,
            style: AppTypography.labelSmall.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de input para un macro individual
class _MacroField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;
  final Color color;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  const _MacroField({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.color,
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        isDense: true,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
    );
  }
}

/// Dot de leyenda para el selector de días
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
