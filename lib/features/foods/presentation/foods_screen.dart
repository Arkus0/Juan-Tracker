import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'food_search_unified_screen.dart';

/// Pantalla de biblioteca de alimentos
/// 
/// NOTA: Esta pantalla está siendo reemplazada por FoodSearchUnifiedScreen.
/// Se mantiene para compatibilidad temporal.
class FoodsScreen extends ConsumerStatefulWidget {
  const FoodsScreen({super.key});

  @override
  ConsumerState<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends ConsumerState<FoodsScreen> {
  @override
  Widget build(BuildContext context) {
    // Redirigir a la pantalla unificada
    return const FoodSearchUnifiedScreen();
  }
}
