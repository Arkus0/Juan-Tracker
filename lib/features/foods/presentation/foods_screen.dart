import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/food_providers.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/models/food.dart';

class FoodsScreen extends ConsumerWidget {
  const FoodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodsAsync = ref.watch(foodListStreamProvider);

    return Scaffold(
      body: foodsAsync.when(
        data: (foods) => ListView.builder(
          itemCount: foods.length,
          itemBuilder: (context, i) {
            final f = foods[i];
            return ListTile(
              title: Text(f.name),
              subtitle: Text('${f.kcalPer100g} kcal /100g'),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // minimal add dialog
          final nameCtl = TextEditingController();
          final kcalCtl = TextEditingController();
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Add Food'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: kcalCtl,
                    decoration: const InputDecoration(labelText: 'kcal/100g'),
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
                    final food = Food(
                      id: id,
                      name: nameCtl.text,
                      brand: null,
                      barcode: null,
                      kcalPer100g: int.tryParse(kcalCtl.text) ?? 0,
                    );
                    ref.read(foodRepositoryProvider).add(food);
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
