import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/diary_providers.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/models/diary_entry.dart';

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(dayEntriesProvider);

    return Scaffold(
      body: entriesAsync.when(
        data: (entries) => ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final e = entries[i];
            return ListTile(
              title: Text(e.customName ?? e.foodId ?? 'Entry'),
              subtitle: Text('${e.kcal} kcal • ${e.grams} g'),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // minimal manual entry dialog
          final nameCtl = TextEditingController();
          final gramsCtl = TextEditingController();
          final kcalCtl = TextEditingController();
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Add Manual Entry'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: gramsCtl,
                    decoration: const InputDecoration(labelText: 'grams'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: kcalCtl,
                    decoration: const InputDecoration(labelText: 'kcal'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final id = DateTime.now().millisecondsSinceEpoch.toString();
                    final entry = DiaryEntry(
                      id: id,
                      date: DateTime.now(),
                      mealType: MealType.snack,
                      customName: nameCtl.text,
                      foodId: null,
                      grams: double.tryParse(gramsCtl.text) ?? 0,
                      kcal: int.tryParse(kcalCtl.text) ?? 0,
                    );
                    ref.read(diaryRepositoryProvider).add(entry);
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
