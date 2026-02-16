import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../models/rutina.dart';

/// Widget de configuración de scheduling para rutinas en modo Pro
/// 
/// Permite configurar:
/// - Modo de scheduling (secuencial, weekly anchored, floating cycle)
/// - Días de la semana asignados (para weekly anchored)
/// - Horas mínimas de descanso (para floating cycle)
class SchedulingConfigWidget extends StatelessWidget {
  final Rutina rutina;
  final Function(SchedulingMode mode, Map<String, dynamic>? config) onSchedulingChanged;
  final Function(int dayIndex, List<int>? weekdays, int? minRestHours) onDayConfigChanged;

  const SchedulingConfigWidget({
    super.key,
    required this.rutina,
    required this.onSchedulingChanged,
    required this.onDayConfigChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgElevated.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.neonPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppColors.neonPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'CONFIGURACIÓN DE SCHEDULING',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.neonPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selector de modo
          _buildModeSelector(context),
          const SizedBox(height: 16),

          // Configuración específica según modo
          if (rutina.schedulingMode == SchedulingMode.weeklyAnchored)
            _buildWeeklyAnchoredConfig(context),
          
          if (rutina.schedulingMode == SchedulingMode.floatingCycle)
            _buildFloatingCycleConfig(context),

          // Info del modo seleccionado
          _buildModeInfo(context),
        ],
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modo de Programación',
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<SchedulingMode>(
              value: rutina.schedulingMode,
              isExpanded: true,
              dropdownColor: AppColors.bgElevated,
              icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface.withAlpha(178)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              items: [
                _buildDropdownItem(
                  context,
                  SchedulingMode.sequential,
                  'Secuencial',
                  Icons.format_list_numbered,
                ),
                _buildDropdownItem(
                  context,
                  SchedulingMode.weeklyAnchored,
                  'Anclado a Semana',
                  Icons.calendar_today,
                ),
                _buildDropdownItem(
                  context,
                  SchedulingMode.floatingCycle,
                  'Ciclo Flotante',
                  Icons.timelapse,
                ),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  onSchedulingChanged(mode, rutina.schedulingConfig);
                }
              },
              selectedItemBuilder: (context) => [
                _buildSelectedItem(context, 'Secuencial', Icons.format_list_numbered),
                _buildSelectedItem(context, 'Anclado a Semana', Icons.calendar_today),
                _buildSelectedItem(context, 'Ciclo Flotante', Icons.timelapse),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<SchedulingMode> _buildDropdownItem(
    BuildContext context,
    SchedulingMode mode,
    String label,
    IconData icon,
  ) {
    return DropdownMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface.withAlpha(178), size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedItem(BuildContext context, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.neonPrimary, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyAnchoredConfig(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Asignar Días de la Semana',
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
          ),
        ),
        const SizedBox(height: 12),
        ...rutina.dias.asMap().entries.map((entry) {
          final index = entry.key;
          final dia = entry.value;
          return _DayWeekdaySelector(
            dayName: dia.nombre.isEmpty ? 'Día ${index + 1}' : dia.nombre,
            selectedWeekdays: dia.weekdays ?? [],
            onChanged: (weekdays) {
              onDayConfigChanged(index, weekdays.isEmpty ? null : weekdays, dia.minRestHours);
            },
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFloatingCycleConfig(BuildContext context) {
    final minRestHours = rutina.minRestHours;
    final maxRestHours = rutina.maxRestHours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración de Descanso',
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
          ),
        ),
        const SizedBox(height: 12),
        
        // Min rest hours slider
        Row(
          children: [
            Icon(Icons.bedtime, color: Theme.of(context).colorScheme.onSurface.withAlpha(138), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descanso mínimo: $minRestHours horas',
                    style: AppTypography.bodyMedium,
                  ),
                  Slider(
                    value: minRestHours.toDouble(),
                    min: 12,
                    max: 72,
                    divisions: 20,
                    activeColor: AppColors.neonPrimary,
                    onChanged: (value) {
                      final newConfig = {
                        ...?rutina.schedulingConfig,
                        'minRestHours': value.round(),
                      };
                      onSchedulingChanged(rutina.schedulingMode, newConfig);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        // Max rest hours slider
        Row(
          children: [
            Icon(Icons.timer_off, color: Theme.of(context).colorScheme.onSurface.withAlpha(138), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Descanso máximo: $maxRestHours horas',
                    style: AppTypography.bodyMedium,
                  ),
                  Slider(
                    value: maxRestHours.toDouble(),
                    min: 48,
                    max: 168,
                    divisions: 20,
                    activeColor: AppColors.neonPrimary,
                    onChanged: (value) {
                      final newConfig = {
                        ...?rutina.schedulingConfig,
                        'maxRestHours': value.round(),
                      };
                      onSchedulingChanged(rutina.schedulingMode, newConfig);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildModeInfo(BuildContext context) {
    String info;
    switch (rutina.schedulingMode) {
      case SchedulingMode.sequential:
        info = 'Secuencial: Los días se sugieren en orden (Día 1 → Día 2 → Día 3...) sin importar el día de la semana.';
        break;
      case SchedulingMode.weeklyAnchored:
        info = 'Anclado a Semana: Cada día de rutina está asignado a días específicos de la semana (ej: Lunes=Pecho).';
        break;
      case SchedulingMode.floatingCycle:
        info = 'Ciclo Flotante: Las sugerencias se basan en el tiempo transcurrido desde la última sesión.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              info,
              style: AppTypography.bodySmall.copyWith(
                color: Colors.blue,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de días de la semana para un día de rutina específico
class _DayWeekdaySelector extends StatelessWidget {
  final String dayName;
  final List<int> selectedWeekdays;
  final Function(List<int> weekdays) onChanged;

  const _DayWeekdaySelector({
    required this.dayName,
    required this.selectedWeekdays,
    required this.onChanged,
  });

  static const _weekdayNames = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dayName,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final weekday = index + 1; // 1 = Lunes
                final isSelected = selectedWeekdays.contains(weekday);
                return GestureDetector(
                  onTap: () {
                    final newWeekdays = List<int>.from(selectedWeekdays);
                    if (isSelected) {
                      newWeekdays.remove(weekday);
                    } else {
                      newWeekdays.add(weekday);
                      newWeekdays.sort();
                    }
                    onChanged(newWeekdays);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.neonPrimary
                          : colorScheme.onSurface.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        _weekdayNames[index],
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? colorScheme.surface : colorScheme.onSurface.withAlpha(178),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
