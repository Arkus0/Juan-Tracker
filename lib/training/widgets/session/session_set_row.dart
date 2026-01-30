import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/information_density_provider.dart';
import '../../models/progression_type.dart';
import '../../models/serie_log.dart';
import '../../screens/plate_calculator_dialog.dart';
import '../../utils/design_system.dart';
import '../../utils/performance_utils.dart';
import 'log_input.dart';

// ============================================================================
// PRE-COMPUTED CONST STYLES (Avoid GoogleFonts in build methods)
// ============================================================================

typedef NullableBoolChanged = void Function({required bool? value});

class _SetRowStyles {
  static final setNumberText = GoogleFonts.montserrat(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static final prevLabel = GoogleFonts.montserrat(
    fontSize: 7,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static final prevValue = GoogleFonts.montserrat(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );

  static final prevReps = GoogleFonts.montserrat(
    fontSize: 9,
    fontWeight: FontWeight.w500,
  );

  static final sugLabel = GoogleFonts.montserrat(
    fontSize: 7,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );

  static final sugValue = GoogleFonts.montserrat(
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );

  static final sugReps = GoogleFonts.montserrat(
    fontSize: 9,
    fontWeight: FontWeight.w600,
  );

  static final tagText = GoogleFonts.montserrat(
    fontSize: 8,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static final noteText = GoogleFonts.montserrat(
    fontSize: 9,
    fontStyle: FontStyle.italic,
  );
}

/// Widget de fila para logging de una serie individual
///
/// Optimizaciones aplicadas:
/// - Estilos pre-computados (sin GoogleFonts en build)
/// - Animación condicional según PerformanceMode
/// - RepaintBoundary para inputs
/// - Widgets const donde posible
/// - Minimizado número de setState
class SessionSetRow extends ConsumerStatefulWidget {
  final int index;
  final SerieLog log;
  final SerieLog? prevLog;
  final ProgressionSuggestion? suggestion;
  final Function(String) onWeightChanged;
  final Function(String) onRepsChanged;
  final NullableBoolChanged onCompleted;
  final Function(double) onPlateCalc;
  final VoidCallback onLongPress;
  final bool showAdvanced;
  final bool shouldFocus; // Auto-focus cuando timer termina
  final bool shouldFocusReps; // Focus específico en reps

  const SessionSetRow({
    super.key,
    required this.index,
    required this.log,
    required this.prevLog,
    this.suggestion,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onCompleted,
    required this.onPlateCalc,
    required this.onLongPress,
    required this.showAdvanced,
    this.shouldFocus = false,
    this.shouldFocusReps = false,
  });

  @override
  ConsumerState<SessionSetRow> createState() => _SessionSetRowState();
}

class _SessionSetRowState extends ConsumerState<SessionSetRow> {
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _repsFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Auto-focus inicial si es necesario
    if (widget.shouldFocus) {
      afterFrame(() {
        if (mounted) _weightFocusNode.requestFocus();
      });
    } else if (widget.shouldFocusReps) {
      afterFrame(() {
        if (mounted) _repsFocusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(SessionSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-focus cuando shouldFocus cambia a true
    if (widget.shouldFocus && !oldWidget.shouldFocus) {
      afterFrame(() {
        if (mounted) {
          _weightFocusNode.requestFocus();
          _triggerFocusVibration();
        }
      });
    }

    // Auto-focus en reps
    if (widget.shouldFocusReps && !oldWidget.shouldFocusReps) {
      afterFrame(() {
        if (mounted) {
          _repsFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _weightFocusNode.dispose();
    _repsFocusNode.dispose();
    super.dispose();
  }

  Future<void> _triggerFocusVibration() async {
    if (PerformanceMode.instance.reduceVibrations) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void _openPlateCalc() async {
    final currentVal = double.tryParse(widget.log.peso.toString()) ?? 0.0;
    final selected = await showDialog<double>(
      context: context,
      builder: (_) => PlateCalculatorDialog(currentWeight: currentVal),
    );
    if (selected != null) {
      widget.onPlateCalc(selected);
      widget.onWeightChanged(selected.toString()); // Forzar refresco visual
    }
  }

  void _applySuggestionOrPrev() {
    HapticFeedback.selectionClick();
    if (widget.suggestion != null) {
      widget.onWeightChanged(widget.suggestion!.suggestedWeight.toString());
      widget.onRepsChanged(widget.suggestion!.suggestedReps.toString());
    } else if (widget.prevLog != null) {
      widget.onWeightChanged(widget.prevLog!.peso.toString());
      widget.onRepsChanged(widget.prevLog!.reps.toString());
    }
  }

  void _handleComplete({required bool? value}) {
    if (value == true && !PerformanceMode.instance.reduceVibrations) {
      HapticFeedback.mediumImpact();
    }
    widget.onCompleted(value: value);
  }

  /// 🎯 P0: Auto-completar serie si peso > 0 y reps > 0 y no está completada
  void _autoCompleteIfReady() {
    if (widget.log.completed) return; // Ya completada
    if (widget.log.peso > 0 && widget.log.reps > 0) {
      // Marcar como completada automáticamente
      _handleComplete(value: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener valores de densidad
    final density = ref.watch(informationDensityProvider);
    final densityValues = DensityValues.forMode(density);

    // Determinar ghost values
    String? weightGhost;
    String? repsGhost;
    var isSuggestion = false;

    if (widget.suggestion != null) {
      weightGhost = widget.suggestion!.suggestedWeight.toString();
      repsGhost = widget.suggestion!.suggestedReps.toString();
      isSuggestion = true;
    } else if (widget.prevLog != null) {
      weightGhost = widget.prevLog!.peso.toString();
      repsGhost = widget.prevLog!.reps.toString();
    }

    // Colores según estado - REDISEÑO: Verde para completado
    final isCompleted = widget.log.completed;
    final rowColor = isCompleted
        ? AppColors.success.withValues(alpha: 0.12)
        : Colors.transparent;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: densityValues.dense ? 4 : 6,
          horizontal: densityValues.horizontalPadding,
        ),
        decoration: BoxDecoration(
          color: rowColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Número de serie
                _SetNumber(
                  index: widget.index,
                  isCompleted: isCompleted,
                  isWarmup: widget.log.isWarmup,
                  isDropset: widget.log.isDropset,
                ),

                const SizedBox(width: 4),

                // Columna de valor previo/sugerencia (tocable)
                _PrevValueColumn(
                  suggestion: widget.suggestion,
                  prevLog: widget.prevLog,
                  onTap: _applySuggestionOrPrev,
                ),

                const SizedBox(width: 8),

                // Input de peso (KG) - con RepaintBoundary
                Expanded(
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      LogInput(
                        value: widget.log.peso > 0
                            ? widget.log.peso.toString()
                            : '',
                        ghostValue: weightGhost,
                        onChanged: widget.onWeightChanged,
                        onGhostTap: () => widget.onWeightChanged(weightGhost!),
                        shouldFocus: widget.shouldFocus,
                        focusNode: _weightFocusNode,
                        swipeIncrement: 2.5, // 2.5kg por swipe
                        isSuggestion: isSuggestion,
                        onEditingComplete: () {
                          _repsFocusNode.requestFocus();
                        },
                      ),
                      // Botón calculadora de discos - 🎯 NEON IRON: Mayor visibilidad
                      Positioned(
                        right: 2,
                        child: Tooltip(
                          message: 'Calculadora de discos',
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _openPlateCalc();
                              },
                              customBorder: const CircleBorder(),
                              child: Semantics(
                                label: 'Calculadora de discos',
                                button: true,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.calculate_outlined,
                                    size: 20,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Input de reps
                Expanded(
                  child: LogInput(
                    value: widget.log.reps > 0
                        ? widget.log.reps.toString()
                        : '',
                    ghostValue: repsGhost,
                    onChanged: widget.onRepsChanged,
                    onGhostTap: () => widget.onRepsChanged(repsGhost!),
                    shouldFocus: widget.shouldFocusReps,
                    focusNode: _repsFocusNode,
                    isInteger: true,
                    isSuggestion: isSuggestion,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: () {
                      FocusScope.of(context).unfocus();
                      // 🎯 P0: Auto-completar si peso > 0 y reps > 0
                      _autoCompleteIfReady();
                    },
                  ),
                ),

                const SizedBox(width: 8),

                // Checkbox de completado
                _CompletedCheckbox(
                  isCompleted: isCompleted,
                  onChanged: _handleComplete,
                ),
              ],
            ),

            // Fila de tags (RPE, Failure, notas, sugerencia)
            _TagsRow(
              log: widget.log,
              suggestion: widget.suggestion,
              showAdvanced: widget.showAdvanced,
            ),
          ],
        ),
      ),
    );
  }
}

/// Número de serie con indicadores visuales
class _SetNumber extends StatelessWidget {
  final int index;
  final bool isCompleted;
  final bool isWarmup;
  final bool isDropset;

  const _SetNumber({
    required this.index,
    required this.isCompleted,
    required this.isWarmup,
    required this.isDropset,
  });

  @override
  Widget build(BuildContext context) {
    var bgColor = Colors.grey[800]!;
    var label = '${index + 1}';

    if (isWarmup) {
      bgColor = Colors.blue[700]!;
      label = 'W';
    } else if (isDropset) {
      bgColor = Colors.purple[700]!;
      label = 'D';
    } else if (isCompleted) {
      // 🎯 REDISEÑO: Verde para completado
      bgColor = AppColors.success;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        // 🎯 REDISEÑO: Sombra verde sutil, no roja
        boxShadow: isCompleted && PerformanceMode.instance.showShadows
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(child: Text(label, style: _SetRowStyles.setNumberText)),
    );
  }
}

/// Columna de valor previo/sugerencia (tocable para copiar)
class _PrevValueColumn extends StatelessWidget {
  final ProgressionSuggestion? suggestion;
  final SerieLog? prevLog;
  final VoidCallback onTap;

  const _PrevValueColumn({this.suggestion, this.prevLog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (suggestion != null) {
      final isImprovement = suggestion!.isImprovement;
      return Tooltip(
        message: 'Copiar sugerencia',
        child: Material(
          color: isImprovement
              ? AppColors.success.withValues(alpha: 0.15)
              : Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: isImprovement
                  ? AppColors.success.withValues(alpha: 0.5)
                  : Colors.grey[700]!,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🎯 P0: Indicador TAP prominente
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 8,
                        color: isImprovement
                            ? AppColors.success
                            : Colors.grey[500],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'SUG',
                        style: _SetRowStyles.sugLabel.copyWith(
                          color: isImprovement
                              ? AppColors.success
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${suggestion!.suggestedWeight}',
                    style: _SetRowStyles.sugValue.copyWith(
                      color: isImprovement
                          ? AppColors.neonCyanBright
                          : Colors.grey[300],
                    ),
                  ),
                  Text(
                    'x${suggestion!.suggestedReps}',
                    style: _SetRowStyles.sugReps.copyWith(
                      color: isImprovement
                          ? AppColors.success
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (prevLog != null) {
      return Tooltip(
        message: 'Copiar anterior',
        child: Material(
          color: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: Colors.grey[800]!),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🎯 P0: Indicador TAP prominente
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, size: 8, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Text(
                        'PREV',
                        style: _SetRowStyles.prevLabel.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${prevLog!.peso}',
                    style: _SetRowStyles.prevValue.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                  Text(
                    'x${prevLog!.reps}',
                    style: _SetRowStyles.prevReps.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 52,
      child: Center(
        child: Text('-', style: TextStyle(color: Colors.grey[700])),
      ),
    );
  }
}

/// Checkbox de completado con animación UX-004
class _CompletedCheckbox extends StatefulWidget {
  final bool isCompleted;
  final NullableBoolChanged onChanged;

  const _CompletedCheckbox({
    required this.isCompleted,
    required this.onChanged,
  });

  @override
  State<_CompletedCheckbox> createState() => _CompletedCheckboxState();
}

class _CompletedCheckboxState extends State<_CompletedCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(_CompletedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // UX-004: Animación de escala al completar
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: SizedBox(
        width: 44,
        height: 44,
        child: Transform.scale(
          scale: 1.3,
          child: Checkbox(
            value: widget.isCompleted,
            activeColor: AppColors.success,
            checkColor: Colors.white,
            onChanged: (value) => widget.onChanged(value: value),
            side: BorderSide(
              color: widget.isCompleted ? AppColors.success : Colors.grey[600]!,
              width: 2,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ),
    );
  }
}

/// Fila de tags (RPE, Failure, Dropset, notas, progreso)
class _TagsRow extends StatelessWidget {
  final SerieLog log;
  final ProgressionSuggestion? suggestion;
  final bool showAdvanced;

  const _TagsRow({
    required this.log,
    this.suggestion,
    required this.showAdvanced,
  });

  @override
  Widget build(BuildContext context) {
    final hasContent =
        showAdvanced ||
        log.rpe != null ||
        log.isFailure ||
        log.isDropset ||
        (log.notas != null && log.notas!.isNotEmpty) ||
        (suggestion?.message != null && suggestion!.isImprovement);

    if (!hasContent) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 36, right: 40, top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          if (suggestion?.isImprovement == true && suggestion?.message != null)
            _Tag(
              text: suggestion!.message!,
              color: AppColors.success,
              icon: Icons.trending_up,
            ),
          if (log.rpe != null)
            _Tag(text: 'RPE ${log.rpe}', color: AppColors.warning),
          if (log.isFailure)
            const _Tag(
              text: 'FALLO',
              color: AppColors.error,
              icon: Icons.warning_amber_rounded,
            ),
          if (log.isDropset)
            const _Tag(text: 'DROP', color: AppColors.neonPrimary),
          if (log.isWarmup) const _Tag(text: 'WARM', color: AppColors.info),
          if (log.notas != null && log.notas!.isNotEmpty)
            Expanded(
              child: Text(
                log.notas!,
                style: _SetRowStyles.noteText.copyWith(color: Colors.grey[500]),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }
}

/// Tag pequeño para indicadores de serie
class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _Tag({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: color),
            const SizedBox(width: 2),
          ],
          Text(text, style: _SetRowStyles.tagText.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Tag widget exportado para uso en otros lugares (backward compatibility)
class Tag extends StatelessWidget {
  final String text;
  final Color color;

  const Tag({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return _Tag(text: text, color: color);
  }
}
