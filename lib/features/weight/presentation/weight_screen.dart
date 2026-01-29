// Weight Screen - Simplified version
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juan_tracker/core/design_system/design_system.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import 'package:juan_tracker/diet/providers/diet_providers.dart';
import 'package:juan_tracker/diet/models/weighin_model.dart';

import 'package:intl/intl.dart';

class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Peso'),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _MainStatsSection(),
            ),
          ),
          _WeighInsListSliver(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);

          final result = await showDialog<bool> (
            context: context,
            builder: (context) => const AddWeightDialog(),
          );

          if (result == true && context.mounted) {
            messenger.showSnackBar(const SnackBar(content: Text('Peso registrado')));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
    );
  }
}

class AddWeightDialog extends ConsumerStatefulWidget {
  const AddWeightDialog({super.key});

  @override
  ConsumerState<AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends ConsumerState<AddWeightDialog> {
  late final TextEditingController _weightController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    final text = _weightController.text.trim();
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null) return;
    final repo = ref.read(weighInRepositoryProvider);
    final id = 'wi_${DateTime.now().millisecondsSinceEpoch}';
    await repo.insert(WeighInModel(id: id, dateTime: _selectedDate, weightKg: value));
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar peso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Peso (kg)'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Fecha: '),
              TextButton(
                onPressed: _selectDate,
                child: Text(DateFormat('d MMM yyyy', 'es').format(_selectedDate)),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('GUARDAR'),
        ),
      ],
    );
  }
}

class _MainStatsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(weightTrendProvider);

    return trendAsync.when(
      data: (result) {
        if (result == null) {
          return AppEmpty(
            icon: Icons.scale_outlined,
            title: 'Sin registros',
            subtitle: 'Registra tu primer peso',
          );
        }
        return Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: 'Ultimo',
                value: result.latestWeight.toStringAsFixed(1),
                unit: 'kg',
                icon: Icons.scale_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatCard(
                label: 'Tendencia',
                value: result.trendWeight.toStringAsFixed(1),
                unit: 'kg',
                icon: Icons.trending_flat,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatCard(
                label: 'Semana',
                value: result.weeklyRate.toStringAsFixed(1),
                unit: 'kg',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
            ),
          ],
        );
      },
      loading: () => const AppLoading(),
      error: (_, _) => AppError(
        message: 'Error al cargar',
        onRetry: () => ref.invalidate(weightTrendProvider),
      ),
    );
  }
}

class _WeighInsListSliver extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weighInsAsync = ref.watch(recentWeighInsProvider);

    return weighInsAsync.when(
      data: (weighIns) {
        if (weighIns.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final w = weighIns[index];
              return Dismissible(
                key: Key(w.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  await ref.read(weighInRepositoryProvider).delete(w.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Peso eliminado')),
                    );
                  }
                },
                child: ListTile(
                  leading: Icon(Icons.scale, color: Theme.of(context).colorScheme.primary),
                  title: Text('${w.weightKg.toStringAsFixed(1)} kg'),
                  subtitle: Text(DateFormat('d MMM', 'es').format(w.dateTime)),
                ),
              );
            },
            childCount: weighIns.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: AppLoading()),
      error: (e, _) => SliverToBoxAdapter(
        child: AppError(message: 'Error: $e'),
      ),
    );
  }
}
