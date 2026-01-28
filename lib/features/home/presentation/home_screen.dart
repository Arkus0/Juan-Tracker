import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/diary/presentation/diary_screen.dart';
import '../../../features/foods/presentation/foods_screen.dart';
import '../../../features/weight/presentation/weight_screen.dart';
import '../../../features/summary/presentation/summary_screen.dart';
import '../../../features/training/presentation/history_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  static const _tabs = <Widget>[
    DiaryScreen(),
    FoodsScreen(),
    WeightScreen(),
    SummaryScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Juan Tracker')),
      body: SafeArea(child: _tabs[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
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
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Entreno'),
        ],
      ),
    );
  }
}
