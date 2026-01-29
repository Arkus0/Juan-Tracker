import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/diary/presentation/diary_screen.dart';
import '../../../features/foods/presentation/foods_screen.dart';
import '../../../features/weight/presentation/weight_screen.dart';
import '../../../features/summary/presentation/summary_screen.dart';
import '../../../diet/screens/coach/coach_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  // Usamos IndexedStack para preservar el estado de cada tab
  // y evitar rebuilds innecesarios al cambiar entre tabs
  static const _tabs = <Widget>[
    DiaryScreen(),
    FoodsScreen(),
    WeightScreen(),
    SummaryScreen(),
    CoachScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Juan Tracker')),
      // IndexedStack mantiene todos los tabs en memoria pero solo muestra uno
      // Esto preserva el scroll position y evita re-fetch de datos
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Diario'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Alimentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Peso',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Resumen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph),
            label: 'Coach',
          ),
        ],
      ),
    );
  }
}
