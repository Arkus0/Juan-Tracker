import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/providers/information_density_provider.dart';
import '../../models/serie_log.dart';
import '../../screens/plate_calculator_dialog.dart';
import 'numpad_input_modal.dart';

/// ============================================================================
/// FOCUSED SET ROW — Intensidad Roja (Underground Gym)
/// ============================================================================
///
/// Widget de fila de serie con jerarquía visual clara:
///
/// Estados visuales:
/// - ACTIVA: Rojo profundo, prominente, touch targets grandes
/// - COMPLETADA: Verde brillante, check claro
/// - PASADA (sin completar): Muy sutil, gris
/// - FUTURA: Casi invisible
///
/// Vibe: Gym underground con luces rojas
/// ============================================================================

/// Colores de sesión — Rojo sangre + Verde check
class TrainingColors {
  // FOCO: Rojo profundo para serie activa (intensidad)
  static const activeSet = AppColors.bloodRed;
  static const activeBg = Color(0xFF241416); // Rojo oscuro (no vivo)

  // COMPLETADO: Verde brillante (éxito)
  static const completed = AppColors.completedGreen;
  static const completedBg = Color(0xFF121A12); // Sutil tinte verde

  // NEUTROS: Grises para todo lo demás
  static const textPrimary = AppColors.textPrimary;
  static const textSecondary = AppColors.textSecondary;
  static const textDisabled = AppColors.textDisabled;
  static const bgCard = AppColors.bgElevated;
  static const bgInput = AppColors.bgInteractive;

  // ACCIÓN: Rojo profundo para confirmar
  static const confirmButton = AppColors.bloodRed;
}

// ⚡ OPTIMIZACIÓN: Estilos pre-computados para evitar GoogleFonts en build
class _SetRowStyles {
  static final badgeLabel = AppTypography.labelLarge.copyWith(
    fontWeight: FontWeight.w800,
    color: AppColors.textOnAccent,
  );

  static final badgeLabelDisabled = AppTypography.labelLarge.copyWith(
    fontWeight: FontWeight.w800,
    color: TrainingColors.textDisabled,
  );

  // Serie activa: números grandes pero no exagerados
  static final valueActiveText = AppTypography.dataMedium;

  static final valueNormalText = AppTypography.titleLarge;

  // Labels muy sutiles para no competir con datos
  static final labelActiveText = AppTypography.labelSmall.copyWith(
    color: AppColors.textTertiary,
  );

  static final labelNormalText = AppTypography.labelSmall.copyWith(
    color: AppColors.textTertiary,
  );
}

// ⚡ OPTIMIZACIÓN: RowStyle constantes - JERARQUÍA VISUAL CLARA
// 🆕 Padding aumentado para mejor usabilidad con dedos sudados/fatiga
/// Genera estilos de fila según densidad y estado
class _RowStyles {
  // COMPLETADA: Verde apagado, sutil pero satisfactoria
  static RowStyle completed(DensityValues values) => RowStyle(
    bgColor: TrainingColors.completedBg,
    borderColor: Color(0x402E8B57),
    textColor: TrainingColors.textSecondary,
    opacity: 0.6,
    padding: EdgeInsets.symmetric(
      vertical: values.dense ? 8 : 10,
      horizontal: values.horizontalPadding,
    ),
  );

  // ACTIVA: Rojo prominente, LA ÚNICA que destaca
  static RowStyle active(DensityValues values) => RowStyle(
    bgColor: TrainingColors.activeBg,
    borderColor: TrainingColors.activeSet,
    textColor: TrainingColors.textPrimary,
    opacity: 1.0,
    padding: EdgeInsets.symmetric(
      vertical: values.dense ? 10 : 14,
      horizontal: values.horizontalPadding,
    ),
  );

  // FUTURA: Casi invisible
  static RowStyle future(DensityValues values) => RowStyle(
    bgColor: Colors.transparent,
    borderColor: Colors.transparent,
    textColor: TrainingColors.textDisabled,
    opacity: 0.3,
    padding: EdgeInsets.symmetric(
      vertical: values.dense ? 4 : 6,
      horizontal: values.horizontalPadding,
    ),
  );

  // PASADA (sin completar): Sutil
  static RowStyle past(DensityValues values) => RowStyle(
    bgColor: Colors.transparent,
    borderColor: Colors.transparent,
    textColor: TrainingColors.textSecondary,
    opacity: 0.5,
    padding: EdgeInsets.symmetric(
      vertical: values.dense ? 6 : 8,
      horizontal: values.horizontalPadding,
    ),
  );
}

// 🎯 HIGH-005: Helper para detectar pesos sospechosos
/// Retorna un peso sugerido si el valor parece erróneo, null si es válido
double? _detectSuspiciousWeight(double enteredWeight, double? previousWeight) {
  // Si no hay peso previo, no podemos detectar errores
  if (previousWeight == null || previousWeight <= 0) return null;

  // Si el peso ingresado es 0, no es sospechoso (bodyweight)
  if (enteredWeight <= 0) return null;

  // Detectar error de magnitud (500kg cuando quería 50kg)
  // Si el peso es 8-12x el anterior, probablemente sobra un 0
  if (enteredWeight >= previousWeight * 8 && enteredWeight >= 100) {
    final suggested = enteredWeight / 10;
    // Solo sugerir si el resultado es cercano al peso previo (±50%)
    if ((suggested - previousWeight).abs() / previousWeight <= 0.5) {
      return suggested;
    }
  }

  // Detectar error inverso (5kg cuando quería 50kg)
  // Si el peso es <0.15x el anterior y el anterior era significativo
  if (previousWeight >= 20 &&
      enteredWeight < previousWeight * 0.15 &&
      enteredWeight >= 1) {
    final suggested = enteredWeight * 10;
    // Solo sugerir si el resultado es cercano al peso previo (±50%)
    if ((suggested - previousWeight).abs() / previousWeight <= 0.5) {
      return suggested;
    }
  }

  // Detectar cambio muy grande (>100% de cambio)
  // Pero ser más permisivo si el usuario está bajando peso
  if (enteredWeight > previousWeight * 2) {
    // Peso duplicado+ probablemente es error
    return previousWeight;
  }

  return null; // El peso parece válido
}

class FocusedSetRow extends ConsumerStatefulWidget {
  final int index;
  final SerieLog log;
  final SerieLog? prevLog;
  final bool isActive;
  final bool isFuture;
  final String exerciseName;
  final int totalSets;
  final Function(double) onWeightChanged;
  final Function(int) onRepsChanged;
  final ValueChanged<bool?> onCompleted;
  final bool showAdvanced;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete; // 🆕 Callback para eliminar serie
  final bool canDelete; // 🆕 Si se puede eliminar (>1 serie)
  final bool showPrBadge;
  // 🆕 Quick toggles de tipo de set
  final VoidCallback? onToggleWarmup;
  final VoidCallback? onToggleFailure;
  final VoidCallback? onToggleDropset;
  final VoidCallback? onToggleRestPause;
  final VoidCallback? onToggleMyoReps;
  final VoidCallback? onToggleAmrap;

  const FocusedSetRow({
    super.key,
    required this.index,
    required this.log,
    this.prevLog,
    required this.isActive,
    required this.isFuture,
    required this.exerciseName,
    required this.totalSets,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onCompleted,
    required this.showAdvanced,
    this.onLongPress,
    this.onDelete,
    this.canDelete = false,
    this.showPrBadge = false,
    this.onToggleWarmup,
    this.onToggleFailure,
    this.onToggleDropset,
    this.onToggleRestPause,
    this.onToggleMyoReps,
    this.onToggleAmrap,
  });

  @override
  ConsumerState<FocusedSetRow> createState() => _FocusedSetRowState();
}

class _FocusedSetRowState extends ConsumerState<FocusedSetRow>
    with SingleTickerProviderStateMixin {
  /// Animación de flash verde al completar
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  /// Tracking del estado anterior para detectar completado
  bool _wasCompleted = false;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flashAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeOut));
    _wasCompleted = widget.log.completed;
  }

  @override
  void didUpdateWidget(FocusedSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detectar si se acaba de completar la serie
    if (widget.log.completed && !_wasCompleted) {
      _flashController.forward().then((_) => _flashController.reset());
    }
    _wasCompleted = widget.log.completed;
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final density = ref.watch(informationDensityProvider);
    final densityValues = DensityValues.forMode(density);
    final isCompleted = widget.log.completed;
    final showSetTypeChips =
        widget.showAdvanced ||
        widget.log.isWarmup ||
        widget.log.isFailure ||
        widget.log.isDropset ||
        widget.log.isRestPause ||
        widget.log.isMyoReps ||
        widget.log.isAmrap;

    // Colores y estilos según estado
    final style = _getRowStyle(isCompleted, widget.isActive, widget.isFuture, densityValues);

    // Contenido base de la fila
    final Widget rowContent = GestureDetector(
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _flashAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              child!,
              // Flash verde overlay cuando se completa
              if (_flashAnimation.value > 0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: TrainingColors.completed.withValues(
                        alpha: 0.3 * (1 - _flashAnimation.value),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: style.opacity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(
              vertical: densityValues.dense ? 2 : 4,
            ), // Ajustado según densidad
            padding: style.padding,
            decoration: BoxDecoration(
              color: style.bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: style.borderColor,
                width: widget.isActive ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Número de serie
                    _SetNumberBadge(
                      index: widget.index,
                      isCompleted: isCompleted,
                      isActive: widget.isActive,
                      isWarmup: widget.log.isWarmup,
                      isDropset: widget.log.isDropset,
                    ),

                    const SizedBox(width: 12),

                    // Input KG (táctil grande)
                    // 🎯 FIX #3: Muestra peso incluso si es 0 o negativo (máquinas asistidas)
                    // 🎯 HIGH-005: Detectar peso sospechoso y mostrar sugerencia inline
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final suspiciousWeight = _detectSuspiciousWeight(
                            widget.log.peso,
                            widget.prevLog?.peso,
                          );
                          return _TappableValueInput(
                            value: widget.log.peso,
                            label: 'KG',
                            isActive: widget.isActive,
                            isCompleted: isCompleted,
                            textColor: style.textColor,
                            allowZeroAndNegative: true, // 🎯 FIX #3
                            onTap: isCompleted ? null : () => _openWeightInput(context),
                            // 🎯 HIGH-005: Mostrar sugerencia si el peso parece erróneo
                            suggestedValue: suspiciousWeight,
                            onAcceptSuggestion: suspiciousWeight != null
                                ? () => widget.onWeightChanged(suspiciousWeight)
                                : null,
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Input REPS (táctil grande)
                    // 🎯 FIX #3: Muestra reps incluso si es 0 (isométricos, holds)
                    Expanded(
                      child: _TappableValueInput(
                        value: widget.log.reps.toDouble(),
                        label: 'REPS',
                        isActive: widget.isActive,
                        isCompleted: isCompleted,
                        textColor: style.textColor,
                        isInteger: true,
                        allowZeroAndNegative:
                            true, // 🎯 FIX #3: permite 0 para isométricos
                        onTap: isCompleted ? null : () => _openRepsInput(context),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Checkbox de completado
                    _CompletionCheckbox(
                      isCompleted: isCompleted,
                      isActive: widget.isActive,
                      onChanged: widget.onCompleted,
                    ),
                  ],
                ),
                if (showSetTypeChips) ...[
                  const SizedBox(height: 6),
                  _SetTypeChipsRow(
                    log: widget.log,
                    showPrBadge: widget.showPrBadge,
                    onToggleWarmup: widget.onToggleWarmup,
                    onToggleFailure: widget.onToggleFailure,
                    onToggleDropset: widget.onToggleDropset,
                    onToggleRestPause: widget.onToggleRestPause,
                    onToggleMyoReps: widget.onToggleMyoReps,
                    onToggleAmrap: widget.onToggleAmrap,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // 🆕 SWIPE-TO-DELETE: Solo si se puede eliminar (más de 1 serie)
    if (widget.canDelete && widget.onDelete != null) {
      return Dismissible(
        key: Key('dismissible_set_${widget.log.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          // Confirmación rápida con haptic
          HapticFeedback.mediumImpact();
          return true; // Sin diálogo - acción inmediata para gimnasio
        },
        onDismissed: (direction) {
          widget.onDelete!();
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'ELIMINAR',
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onSurface, size: 20),
            ],
          ),
        ),
        child: rowContent,
      );
    }

    return rowContent;
  }

  // ⚡ OPTIMIZACIÓN: Usar constantes pre-definidas en lugar de crear nuevos objetos
  RowStyle _getRowStyle(bool isCompleted, bool isActive, bool isFuture, DensityValues values) {
    if (isCompleted) return _RowStyles.completed(values);
    if (isActive) return _RowStyles.active(values);
    if (isFuture) return _RowStyles.future(values);
    return _RowStyles.past(values);
  }

  void _openWeightInput(BuildContext context) async {
    final result = await NumpadInputModal.show(
      context: context,
      exerciseName: widget.exerciseName,
      setNumber: widget.index + 1,
      totalSets: widget.totalSets,
      fieldLabel: 'KG',
      previousValue: widget.prevLog?.peso.toDouble(),
      currentValue: widget.log.peso > 0 ? widget.log.peso.toDouble() : null,
      onOpenPlateCalc: (currentWeight, onWeightUpdate, onApplyAndClose) {
        _showPlateCalculator(context, currentWeight, onApplyAndClose);
      },
    );

    if (result != null) {
      widget.onWeightChanged(result);
      // 🆕 Auto-completar si ambos campos tienen valor
      _checkAutoComplete(result, widget.log.reps.toDouble());
    }
  }

  /// 🆕 Muestra calculadora de placas - "APLICAR" cierra todo y aplica directamente
  void _showPlateCalculator(
    BuildContext context,
    double currentWeight,
    Function(double) onApplyAndClose,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => PlateCalculatorDialog(
        currentWeight: currentWeight,
        onWeightSelected: (weight) {
          // 🎯 FIX: Aplicar directamente y cerrar numpad (el callback hace pop del numpad)
          onApplyAndClose(weight);
        },
      ),
    );
  }

  void _openRepsInput(BuildContext context) async {
    final result = await NumpadInputModal.show(
      context: context,
      exerciseName: widget.exerciseName,
      setNumber: widget.index + 1,
      totalSets: widget.totalSets,
      fieldLabel: 'REPS',
      previousValue: widget.prevLog?.reps.toDouble(),
      currentValue: widget.log.reps > 0 ? widget.log.reps.toDouble() : null,
      isInteger: true,
    );

    if (result != null) {
      widget.onRepsChanged(result.toInt());
      // 🆕 Auto-completar si ambos campos tienen valor
      _checkAutoComplete(widget.log.peso.toDouble(), result);
    }
  }

  /// 🆕 Verifica si se debe auto-completar la serie
  void _checkAutoComplete(double weight, double reps) {
    // Si ambos valores son > 0 y la serie no está completada
    if (weight > 0 && reps > 0 && !widget.log.completed) {
      // Capturar ID del set actual para verificar antes de completar
      final currentSetId = widget.log.id;
      // Dar un pequeño delay para que el estado se actualice
      Future.delayed(const Duration(milliseconds: 100), () {
        // Solo completar si el widget sigue montado y es el mismo set
        if (mounted && widget.log.id == currentSetId) {
          widget.onCompleted(true);
        }
      });
    }
  }
}

/// Estilo de fila según estado
class RowStyle {
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final double opacity;
  final EdgeInsets padding;

  const RowStyle({
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.opacity,
    required this.padding,
  });
}

/// Badge del número de serie - Jerarquía visual clara
class _SetNumberBadge extends StatelessWidget {
  final int index;
  final bool isCompleted;
  final bool isActive;
  final bool isWarmup;
  final bool isDropset;

  const _SetNumberBadge({
    required this.index,
    required this.isCompleted,
    required this.isActive,
    this.isWarmup = false,
    this.isDropset = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    var textColor = AppColors.textOnAccent;
    var label = '${index + 1}';

    if (isWarmup) {
      bgColor = AppColors.info;
      label = 'W';
    } else if (isDropset) {
      bgColor = Colors.purple[700]!;
      label = 'D';
    } else if (isCompleted) {
      bgColor = TrainingColors.completed; // Verde apagado
    } else if (isActive) {
      bgColor = TrainingColors.activeSet; // Cyan
    } else {
      bgColor = TrainingColors.bgInput;
      textColor = TrainingColors.textDisabled;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
        child: isCompleted && !isWarmup && !isDropset
            ? const Icon(Icons.check, color: AppColors.textOnAccent, size: 18)
            : Text(
                label,
                // ⚡ OPTIMIZACIÓN: Usar estilo pre-computado
                style: textColor == AppColors.textOnAccent
                    ? _SetRowStyles.badgeLabel
                    : _SetRowStyles.badgeLabelDisabled,
              ),
      ),
    );
  }
}

/// Input táctil grande para KG/REPS - TOUCH TARGETS GRANDES
class _TappableValueInput extends StatelessWidget {
  final double? value;
  final String label;
  final bool isActive;
  final bool isCompleted;
  final Color textColor;
  final bool isInteger;
  final VoidCallback? onTap;
  final bool allowZeroAndNegative; // 🎯 FIX #3
  // 🎯 HIGH-005: Inline weight validation
  final double? suggestedValue;
  final VoidCallback? onAcceptSuggestion;

  const _TappableValueInput({
    this.value,
    required this.label,
    required this.isActive,
    required this.isCompleted,
    required this.textColor,
    this.isInteger = false,
    this.onTap,
    this.allowZeroAndNegative = false, // 🎯 FIX #3
    this.suggestedValue,
    this.onAcceptSuggestion,
  });

  String get _displayValue {
    if (value == null) return '—';
    // 🎯 FIX #3: Solo mostrar "—" si no permite cero/negativo Y el valor es 0
    if (!allowZeroAndNegative && value == 0) return '—';
    if (isInteger) return value!.toInt().toString();
    // Quitar .0 si es entero
    if (value == value!.truncateToDouble()) {
      return value!.toInt().toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Touch target mínimo 64dp (activo 72dp) para dedos sudados
    final height = isActive ? 72.0 : 56.0;

    // 🎯 HIGH-005: Determinar si mostrar sugerencia
    final showSuggestion = suggestedValue != null && isActive && !isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isActive ? TrainingColors.bgInput : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          // Borde sutil cyan, NO rojo ni agresivo
          border: isActive
              ? Border.all(
                  color: TrainingColors.activeSet.withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _displayValue,
                    // ⚡ OPTIMIZACIÓN: Estilos pre-computados - valores MUY prominentes
                    style:
                        (isActive
                                ? _SetRowStyles.valueActiveText
                                : _SetRowStyles.valueNormalText)
                            .copyWith(
                              color: value == null || value == 0
                                  ? TrainingColors.textDisabled
                                  : textColor,
                            ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    // Labels muy sutiles para no competir con datos
                    style: isActive
                        ? _SetRowStyles.labelActiveText
                        : _SetRowStyles.labelNormalText,
                  ),
                ],
              ),
            ),
            // 🎯 HIGH-005: Badge de sugerencia inline
            if (showSuggestion)
              Positioned(
                right: 4,
                top: 4,
                child: _WeightSuggestionBadge(
                  suggestedValue: suggestedValue!,
                  onAccept: onAcceptSuggestion,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 🎯 HIGH-005: Badge de sugerencia de peso inline
/// Aparece cuando el peso ingresado parece sospechoso
/// (ej: 500kg cuando probablemente quiso decir 50kg)
class _WeightSuggestionBadge extends StatelessWidget {
  final double suggestedValue;
  final VoidCallback? onAccept;

  const _WeightSuggestionBadge({
    required this.suggestedValue,
    this.onAccept,
  });

  String get _displaySuggestion {
    if (suggestedValue == suggestedValue.truncateToDouble()) {
      return '¿${suggestedValue.toInt()}kg?';
    }
    return '¿${suggestedValue.toStringAsFixed(1)}kg?';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onAccept?.call();
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.warning.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 4),
              Text(
                _displaySuggestion,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chips rápidos para marcar tipo de set
class _SetTypeChipsRow extends StatelessWidget {
  final SerieLog log;
  final bool showPrBadge;
  final VoidCallback? onToggleWarmup;
  final VoidCallback? onToggleFailure;
  final VoidCallback? onToggleDropset;
  final VoidCallback? onToggleRestPause;
  final VoidCallback? onToggleMyoReps;
  final VoidCallback? onToggleAmrap;

  const _SetTypeChipsRow({
    required this.log,
    this.showPrBadge = false,
    this.onToggleWarmup,
    this.onToggleFailure,
    this.onToggleDropset,
    this.onToggleRestPause,
    this.onToggleMyoReps,
    this.onToggleAmrap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44, right: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (showPrBadge)
            _SetTypeChip(
              label: 'PR',
              selected: true,
              color: AppColors.goldAccent,
              onToggle: null,
            ),
          _SetTypeChip(
            label: 'WARM',
            selected: log.isWarmup,
            color: AppColors.info,
            onToggle: onToggleWarmup,
          ),
          _SetTypeChip(
            label: 'FALLO',
            selected: log.isFailure,
            color: AppColors.error,
            onToggle: onToggleFailure,
          ),
          _SetTypeChip(
            label: 'DROP',
            selected: log.isDropset,
            color: AppColors.warning,
            onToggle: onToggleDropset,
          ),
          _SetTypeChip(
            label: 'R-P',
            selected: log.isRestPause,
            color: AppColors.info,
            onToggle: onToggleRestPause,
          ),
          _SetTypeChip(
            label: 'MYO',
            selected: log.isMyoReps,
            color: AppColors.info,
            onToggle: onToggleMyoReps,
          ),
          _SetTypeChip(
            label: 'AMRAP',
            selected: log.isAmrap,
            color: AppColors.warning,
            onToggle: onToggleAmrap,
          ),
        ],
      ),
    );
  }
}

class _SetTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onToggle;

  const _SetTypeChip({
    required this.label,
    required this.selected,
    required this.color,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = selected
        ? color
        : colorScheme.outline.withValues(alpha: 0.3);
    final bgColor = selected
        ? color.withValues(alpha: 0.15)
        : colorScheme.surfaceContainerHighest;

    return FilterChip(
      label: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: selected ? color : colorScheme.onSurfaceVariant,
        ),
      ),
      selected: selected,
      onSelected: onToggle == null ? null : (_) => onToggle?.call(),
      showCheckmark: false,
      selectedColor: bgColor,
      backgroundColor: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      side: BorderSide(color: borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

/// Checkbox de completado con zona táctil grande (64dp)
class _CompletionCheckbox extends StatelessWidget {
  final bool isCompleted;
  final bool isActive;
  final ValueChanged<bool?> onChanged;

  const _CompletionCheckbox({
    required this.isCompleted,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onChanged(!isCompleted);
          },
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? TrainingColors
                          .completed // Verde apagado
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCompleted
                      ? TrainingColors.completed
                      : isActive
                      ? TrainingColors
                            .activeSet // Cyan
                      : TrainingColors.textDisabled,
                  width: 2.5,
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppColors.textOnAccent,
                      size: 28,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
