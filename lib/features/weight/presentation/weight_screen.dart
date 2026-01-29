import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../diet/models/models.dart';
import '../../../diet/providers/diet_providers.dart';

/// Pantalla de seguimiento de peso corporal
class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weighInsAsync = ref.watch(weightStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peso'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Peso actual
          _CurrentWeightCard(),
          const Divider(height: 1),

          // Lista de registros
          Expanded(
            child: weighInsAsync.when(
              data: (weighIns) => _WeightList(weighIns: weighIns),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWeightDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
    );
  }

  Future<void> _showAddWeightDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (ctx) => const _AddWeightDialog(),
    );
  }
}

/// Provider de stream de pesos (últimos 90 días)
final weightStreamProvider = StreamProvider<List<WeighInModel>>((ref) {
  final repo = ref.watch(weighInRepositoryProvider);
  final now = DateTime.now();
  final from = now.subtract(const Duration(days: 90));
  return repo.watchByDateRange(from, now);
});

/// Card con el peso actual
class _CurrentWeightCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(latestWeightProvider);

    return latestAsync.when(
      data: (latest) {
        if (latest == null) return const _EmptyWeightState();
        return _WeightCard(weighIn: latest);
      },
      loading: () => const _LoadingWeightState(),
      error: (_, __) => const _EmptyWeightState(),
    );
  }
}

class _WeightCard extends StatelessWidget {
  final WeighInModel weighIn;

  const _WeightCard({required this.weighIn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'Tu peso actual',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                weighIn.weightKg.toStringAsFixed(1),
                style: GoogleFonts.montserrat(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'kg',
                  style: TextStyle(
                    fontSize: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Registrado ${DateFormat('d MMM', 'es').format(weighIn.dateTime)}',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          if (weighIn.note != null && weighIn.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              weighIn.note!,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyWeightState extends StatelessWidget {
  const _EmptyWeightState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.scale,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin registros de peso',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Registra tu primer peso con el botón +',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingWeightState extends StatelessWidget {
  const _LoadingWeightState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Lista de registros de peso
class _WeightList extends StatelessWidget {
  final List<WeighInModel> weighIns;

  const _WeightList({required this.weighIns});

  @override
  Widget build(BuildContext context) {
    if (weighIns.isEmpty) {
      return const Center(child: Text('No hay registros'));
    }

    // Agrupar por mes
    final grouped = <String, List<WeighInModel>>{};
    for (final w in weighIns) {
      final key = DateFormat('MMMM yyyy', 'es').format(w.dateTime);
      grouped.putIfAbsent(key, () => []).add(w);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final month = grouped.keys.elementAt(index);
        final entries = grouped[month]!;
        return _MonthSection(
          month: month,
          entries: entries,
        );
      },
    );
  }
}

class _MonthSection extends StatelessWidget {
  final String month;
  final List<WeighInModel> entries;

  const _MonthSection({
    required this.month,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            month.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...entries.map((w) => _WeightListTile(weighIn: w)),
      ],
    );
  }
}

class _WeightListTile extends ConsumerWidget {
  final WeighInModel weighIn;

  const _WeightListTile({required this.weighIn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(weighIn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        final repo = ref.read(weighInRepositoryProvider);
        await repo.delete(weighIn.id);
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.scale,
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          '${weighIn.weightKg.toStringAsFixed(1)} kg',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          DateFormat('EEEE d, HH:mm', 'es').format(weighIn.dateTime),
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _editWeight(context, ref),
        ),
      ),
    );
  }

  Future<void> _editWeight(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (ctx) => _EditWeightDialog(weighIn: weighIn),
    );
  }
}

/// Diálogo para añadir peso
class _AddWeightDialog extends ConsumerStatefulWidget {
  const _AddWeightDialog();

  @override
  ConsumerState<_AddWeightDialog> createState() => _AddWeightDialogState();
}

class _AddWeightDialogState extends ConsumerState<_AddWeightDialog> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Peso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Peso (kg)',
              hintText: 'Ej: 75.5',
              border: OutlineInputBorder(),
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              hintText: 'Ej: Por la mañana, en ayunas',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saveWeight,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _saveWeight() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) return;

    final weighIn = WeighInModel(
      id: const Uuid().v4(),
      dateTime: DateTime.now(),
      weightKg: weight,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    final repo = ref.read(weighInRepositoryProvider);
    await repo.insert(weighIn);

    if (mounted) Navigator.of(context).pop();
  }
}

/// Diálogo para editar peso
class _EditWeightDialog extends ConsumerStatefulWidget {
  final WeighInModel weighIn;

  const _EditWeightDialog({required this.weighIn});

  @override
  ConsumerState<_EditWeightDialog> createState() => _EditWeightDialogState();
}

class _EditWeightDialogState extends ConsumerState<_EditWeightDialog> {
  late final TextEditingController _weightController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.weighIn.weightKg.toStringAsFixed(1),
    );
    _noteController = TextEditingController(text: widget.weighIn.note ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Peso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso (kg)',
              border: OutlineInputBorder(),
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Nota',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _updateWeight,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _updateWeight() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) return;

    final updated = widget.weighIn.copyWith(
      weightKg: weight,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    final repo = ref.read(weighInRepositoryProvider);
    await repo.update(updated);

    if (mounted) Navigator.of(context).pop();
  }
}
