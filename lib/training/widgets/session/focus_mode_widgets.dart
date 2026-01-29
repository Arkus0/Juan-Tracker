import 'package:flutter/material.dart';
import '../../../core/design_system/design_system.dart';
import '../../../core/feedback/haptics.dart';

/// Input numérico grande para modo Focus en entrenamiento
class FocusNumberInput extends StatefulWidget {
  final String label;
  final double? initialValue;
  final ValueChanged<double> onChanged;
  final String? suffix;
  final double min;
  final double max;
  final int decimalPlaces;

  const FocusNumberInput({
    super.key,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.suffix,
    this.min = 0,
    this.max = 999,
    this.decimalPlaces = 1,
  });

  @override
  State<FocusNumberInput> createState() => _FocusNumberInputState();
}

class _FocusNumberInputState extends State<FocusNumberInput> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toStringAsFixed(widget.decimalPlaces) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateValue(double delta) {
    final current = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;
    final newValue = (current + delta).clamp(widget.min, widget.max);
    
    _controller.text = newValue.toStringAsFixed(widget.decimalPlaces);
    widget.onChanged(newValue);
    AppHaptics.light();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isFocused ? colors.primary : colors.outline,
            width: _isFocused ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                widget.label.toUpperCase(),
                style: AppTypography.labelMedium.copyWith(
                  color: _isFocused ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            // Input con botones +/-
            Row(
              children: [
                // Botón menos
                _AdjustButton(
                  icon: Icons.remove,
                  onTap: () => _updateValue(-(widget.decimalPlaces > 0 ? 2.5 : 1.0)),
                ),
                
                // Input central
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: AppTypography.dataLarge.copyWith(
                      color: colors.onSurface,
                      fontSize: 36,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      suffixText: widget.suffix,
                      suffixStyle: AppTypography.bodyLarge.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      final number = double.tryParse(value.replaceAll(',', '.'));
                      if (number != null) {
                        widget.onChanged(number.clamp(widget.min, widget.max));
                      }
                    },
                  ),
                ),
                
                // Botón más
                _AdjustButton(
                  icon: Icons.add,
                  onTap: () => _updateValue(widget.decimalPlaces > 0 ? 2.5 : 1.0),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Botón de ajuste +/-
class _AdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AdjustButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: colors.onSurfaceVariant,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// Timer persistente para modo Focus
class FocusTimerWidget extends StatelessWidget {
  final int remainingSeconds;
  final bool isRunning;
  final bool isPaused;
  final VoidCallback? onToggle;
  final VoidCallback? onAddTime;
  final VoidCallback? onSkip;

  const FocusTimerWidget({
    super.key,
    required this.remainingSeconds,
    required this.isRunning,
    this.isPaused = false,
    this.onToggle,
    this.onAddTime,
    this.onSkip,
  });

  String get _formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = isRunning 
        ? remainingSeconds / 180 
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRunning ? colors.secondary : colors.outline,
          width: isRunning ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer,
                color: isRunning ? colors.secondary : colors.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _formattedTime,
                style: AppTypography.dataMedium.copyWith(
                  color: isRunning ? colors.secondary : colors.onSurface,
                  fontSize: 32,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 1 - progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: colors.surfaceContainerLow,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPaused ? AppColors.warning : colors.secondary,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Controles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimerControl(
                icon: isRunning 
                    ? (isPaused ? Icons.play_arrow : Icons.pause)
                    : Icons.play_arrow,
                label: isRunning 
                    ? (isPaused ? 'REANUDAR' : 'PAUSAR')
                    : 'INICIAR',
                onTap: onToggle,
                isPrimary: true,
                colors: colors,
              ),
              if (isRunning) ...[
                const SizedBox(width: 16),
                _TimerControl(
                  icon: Icons.add,
                  label: '+30s',
                  onTap: onAddTime,
                  colors: colors,
                ),
                const SizedBox(width: 16),
                _TimerControl(
                  icon: Icons.skip_next,
                  label: 'SALTAR',
                  onTap: onSkip,
                  colors: colors,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Botón de control del timer
class _TimerControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final ColorScheme colors;

  const _TimerControl({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? colors.secondary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isPrimary ? colors.onSecondary : colors.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isPrimary ? colors.onSecondary : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card de set en modo Focus
class FocusSetCard extends StatelessWidget {
  final int setNumber;
  final double? weight;
  final int? reps;
  final double? rpe;
  final bool isCompleted;
  final VoidCallback? onToggleComplete;

  const FocusSetCard({
    super.key,
    required this.setNumber,
    this.weight,
    this.reps,
    this.rpe,
    this.isCompleted = false,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onToggleComplete,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? AppColors.success 
                      : colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                      : Text(
                          '$setNumber',
                          style: AppTypography.titleMedium.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    _DataItem(
                      label: 'PESO',
                      value: weight != null ? '${weight!.toStringAsFixed(1)} kg' : '--',
                    ),
                    const SizedBox(width: 24),
                    _DataItem(
                      label: 'REPS',
                      value: reps?.toString() ?? '--',
                    ),
                    if (rpe != null) ...[
                      const SizedBox(width: 24),
                      _DataItem(
                        label: 'RPE',
                        value: rpe!.toStringAsFixed(1),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item de datos para FocusSetCard
class _DataItem extends StatelessWidget {
  final String label;
  final String value;

  const _DataItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.dataSmall.copyWith(
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}
