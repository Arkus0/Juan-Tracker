import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/weight_providers.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/models/weight_entry.dart';

class WeightScreen extends ConsumerWidget {
  const WeightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightsAsync = ref.watch(weightListStreamProvider);

    return Scaffold(
      body: weightsAsync.when(
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            final w = list[i];
            return ListTile(
              title: Text('${w.weightKg} kg'),
              subtitle: Text(w.date.toIso8601String()),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final weightCtl = TextEditingController();
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Add Weight'),
              content: TextField(
                controller: weightCtl,
                decoration: const InputDecoration(labelText: 'kg'),
                keyboardType: TextInputType.number,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    final w = double.tryParse(weightCtl.text) ?? 0.0;
                    final entry = WeightEntry(
                      id: id,
                      date: DateTime.now(),
                      weightKg: w,
                    );
                    ref.read(weightRepositoryProvider).add(entry);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
