import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/design_system.dart' show AppTypography;

import '../../../diet/models/models.dart';
import '../../../diet/providers/diet_providers.dart';

/// Pantalla de gestión de objetivos diarios (Targets).
/// 
/// Permite:
/// - Ver historial de targets configurados
/// - Crear nuevos targets (con fecha de inicio)
/// - Editar targets existentes
/// - Eliminar targets
class TargetsScreen extends ConsumerWidget {
  const TargetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetsAsync = ref.watch(allTargetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetivos'),
        centerTitle: true,
      ),
      body: targetsAsync.when(
        data: (targets) => _TargetsList(targets: targets),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Error al cargar objetivos: $e'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTarget(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo objetivo'),
      ),
    );
  }

  void _showCreateTarget(BuildContext context, WidgetRef ref) {
    ref.read(targetsFormProvider.notifier).reset();
    _showTargetModal(context, isEditing: false);
  }

  void _showTargetModal(BuildContext context, {required bool isEditing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _TargetForm(
          scrollController: scrollController,
          isEditing: isEditing,
        ),
      ),
    );
  }
}

/// Lista de targets históricos.
class _TargetsList extends ConsumerWidget {
  final List<TargetsModel> targets;

  const _TargetsList({required this.targets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (targets.isEmpty) {
      return const _EmptyState();
    }

    // Ordenar por fecha de validez descendente
    final sorted = List<TargetsModel>.from(targets)
      ..sort((a, b) => b.validFrom.compareTo(a.validFrom));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final target = sorted[index];
        final isCurrent = index == 0; // El más reciente es el actual

        return _TargetCard(
          target: target,
          isCurrent: isCurrent,
          onTap: () => _showEditTarget(context, ref, target),
        );
      },
    );
  }

  void _showEditTarget(BuildContext context, WidgetRef ref, TargetsModel target) {
    ref.read(targetsFormProvider.notifier).loadFromModel(target);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _TargetForm(
          scrollController: scrollController,
          isEditing: true,
        ),
      ),
    );
  }
}

/// Estado vacío cuando no hay targets.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.track_changes_outlined,
              size: 64,
              color: theme.colorScheme.primary.withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin objetivos configurados',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Define tus objetivos diarios de calorías y macros para hacer seguimiento de tu progreso.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de un target individual.
class _TargetCard extends StatelessWidget {
  final TargetsModel target;
  final bool isCurrent;
  final VoidCallback onTap;

  const _TargetCard({
    required this.target,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrent ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con fecha y badge "Actual"
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Desde ${DateFormat('d MMMM yyyy', 'es').format(target.validFrom)}',
                          style: AppTypography.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ACTUAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Macros
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MacroDisplay(
                    label: 'Calorías',
                    value: '${target.kcalTarget}',
                    unit: 'kcal',
                    color: Colors.orange,
                    icon: Icons.local_fire_department,
                  ),
                  if (target.proteinTarget != null)
                    _MacroDisplay(
                      label: 'Proteína',
                      value: target.proteinTarget!.toStringAsFixed(0),
                      unit: 'g',
                      color: Colors.red,
                      icon: Icons.fitness_center,
                    ),
                  if (target.carbsTarget != null)
                    _MacroDisplay(
                      label: 'Carbs',
                      value: target.carbsTarget!.toStringAsFixed(0),
                      unit: 'g',
                      color: Colors.amber,
                      icon: Icons.grain,
                    ),
                  if (target.fatTarget != null)
                    _MacroDisplay(
                      label: 'Grasa',
                      value: target.fatTarget!.toStringAsFixed(0),
                      unit: 'g',
                      color: Colors.blue,
                      icon: Icons.water_drop,
                    ),
                ],
              ),
              if (target.notes != null && target.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  target.notes!,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Display de un macro individual.
class _MacroDisplay extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _MacroDisplay({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 10,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Formulario de creación/edición de target.
class _TargetForm extends ConsumerWidget {
  final ScrollController scrollController;
  final bool isEditing;

  const _TargetForm({
    required this.scrollController,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(targetsFormProvider);
    final formNotifier = ref.read(targetsFormProvider.notifier);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'Editar objetivo' : 'Nuevo objetivo',
                    style: AppTypography.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Form
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Fecha de inicio
                _DatePickerTile(
                  label: 'Aplica desde',
                  date: formState.validFrom,
                  onChanged: formNotifier.setValidFrom,
                ),
                const SizedBox(height: 24),
                // Calorías
                _NumberField(
                  label: 'Calorías objetivo',
                  value: formState.kcalTarget,
                  suffix: 'kcal',
                  onChanged: (v) => formNotifier.setKcal(v?.toInt() ?? 0),
                ),
                const SizedBox(height: 16),
                // Macros
                Text(
                  'MACROS (opcional)',
                  style: AppTypography.titleSmall.copyWith(
                    letterSpacing: 1,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _NumberField(
                        label: 'Proteína',
                        value: formState.proteinTarget?.toInt() ?? 0,
                        suffix: 'g',
                        onChanged: (v) => formNotifier.setProtein(
                          v != null && v > 0 ? v.toDouble() : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberField(
                        label: 'Carbs',
                        value: formState.carbsTarget?.toInt() ?? 0,
                        suffix: 'g',
                        onChanged: (v) => formNotifier.setCarbs(
                          v != null && v > 0 ? v.toDouble() : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberField(
                        label: 'Grasa',
                        value: formState.fatTarget?.toInt() ?? 0,
                        suffix: 'g',
                        onChanged: (v) => formNotifier.setFat(
                          v != null && v > 0 ? v.toDouble() : null,
                        ),
                      ),
                    ),
                  ],
                ),
                // Validación de calorías de macros
                if (formState.kcalFromMacros != null) ...[
                  const SizedBox(height: 12),
                  _MacroValidationBanner(state: formState),
                ],
                const SizedBox(height: 24),
                // Notas
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Notas (opcional)',
                    hintText: 'Ej: Bulking suave, déficit para competición...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: formNotifier.setNotes,
                  controller: TextEditingController(text: formState.notes),
                ),
              ],
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                if (isEditing) ...[
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context, ref, formState.id!),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: formNotifier.isValid
                        ? () => _saveTarget(context, ref)
                        : null,
                    child: Text(isEditing ? 'Guardar cambios' : 'Crear objetivo'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTarget(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(targetsFormProvider.notifier);
    final repo = ref.read(targetsRepositoryProvider);
    final model = notifier.toModel();

    try {
      if (isEditing) {
        await repo.update(model);
      } else {
        await repo.insert(model);
      }
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar objetivo'),
        content: const Text(
          '¿Estás seguro? Los días pasados que usaban este objetivo mantendrán sus valores históricos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repo = ref.read(targetsRepositoryProvider);
      try {
        await repo.delete(id);
        if (context.mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }
}

/// Banner de validación de macros vs calorías.
class _MacroValidationBanner extends StatelessWidget {
  final TargetsFormState state;

  const _MacroValidationBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final diff = state.kcalDifference;
    if (diff == null) return const SizedBox.shrink();

    final isClose = diff.abs() < 50;
    final isOver = diff < 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isClose
            ? Colors.green.withAlpha((0.1 * 255).round())
            : Colors.orange.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isClose
              ? Colors.green.withAlpha((0.3 * 255).round())
              : Colors.orange.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isClose ? Icons.check_circle : Icons.info,
            color: isClose ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isClose
                  ? 'Los macros coinciden aproximadamente con las calorías objetivo.'
                  : isOver
                      ? 'Los macros suman ${diff.abs()} kcal más que el objetivo.'
                      : 'Los macros suman ${diff.abs()} kcal menos que el objetivo.',
              style: TextStyle(
                fontSize: 12,
                color: isClose ? Colors.green.shade700 : Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo numérico con validación.
class _NumberField extends StatelessWidget {
  final String label;
  final int value;
  final String suffix;
  final ValueChanged<int?> onChanged;

  const _NumberField({
    required this.label,
    required this.value,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      controller: TextEditingController(
        text: value > 0 ? value.toString() : '',
      ),
      onChanged: (v) {
        final parsed = int.tryParse(v);
        onChanged(parsed);
      },
    );
  }
}

/// Selector de fecha.
class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        DateFormat('EEEE d MMMM yyyy', 'es').format(date),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
    );
  }
}
