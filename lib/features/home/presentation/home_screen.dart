import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Juan Tracker'),
      ),
      body: Center(
        child: Text(
          greeting,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
