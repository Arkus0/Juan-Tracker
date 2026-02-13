import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../diet/providers/coach_providers.dart';
import '../../../features/diary/presentation/diary_screen.dart';
import '../../../features/home/providers/home_providers.dart';
import '../../../features/progress/presentation/progress_screen.dart';
import '../../../features/settings/presentation/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _checkInReminderShown = false;

  // 3 tabs: Diario, Progreso (Weight+Summary+Coach), Perfil
  static const _tabs = <Widget>[
    DiaryScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(currentMealTypeProvider);
      _checkForPendingCheckIn();
    });
  }

  /// Comprueba si hay un check-in semanal pendiente y muestra recordatorio
  void _checkForPendingCheckIn() {
    if (_checkInReminderShown) return;

    final isCheckInDue = ref.read(isCheckInDueProvider);
    if (isCheckInDue && mounted) {
      _checkInReminderShown = true;
      _showCheckInReminder();
    }
  }

  void _showCheckInReminder() {
    final plan = ref.read(coachPlanProvider);
    if (plan == null) return;

    final lastCheckIn = plan.lastCheckInDate;
    final daysSince = lastCheckIn != null
        ? DateTime.now().difference(lastCheckIn).inDays
        : DateTime.now().difference(plan.startDate).inDays;

    showDialog(
      context: context,
      // UX fix: allow dismissal — forced modals frustrate users
      barrierDismissible: true,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(
            Icons.notifications_active,
            color: colors.primary,
            size: 48,
          ),
          title: const Text('¡Toca check-in semanal!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Han pasado $daysSince días desde tu último check-in.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Revisa tu progreso y ajusta tus objetivos calóricos si es necesario.',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('DESPUÉS'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                context.goToCoachCheckIn();
              },
              icon: const Icon(Icons.check),
              label: const Text('HACER CHECK-IN'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(currentMealTypeProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(homeTabProvider);

    return Scaffold(
      // No AppBar here — each tab provides its own AppBar/SliverAppBar
      // to avoid double headers and allow per-tab customization
      body: SafeArea(
        child: IndexedStack(index: currentTab.index, children: _tabs),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        currentIndex: currentTab.index,
        onTap: (i) =>
            ref.read(homeTabProvider.notifier).setTab(HomeTab.values[i]),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: 'Diario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Progreso',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

}
