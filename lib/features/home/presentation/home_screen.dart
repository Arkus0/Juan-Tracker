import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../diet/providers/coach_providers.dart';
import '../../../features/diary/presentation/diary_screen.dart';
import '../../../features/home/providers/home_providers.dart';
import '../../../features/weight/presentation/weight_screen.dart';
import '../../../features/summary/presentation/summary_screen.dart';
import '../../../features/settings/presentation/settings_screen.dart';
import '../../../diet/screens/coach/coach_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _checkInReminderShown = false;

  // Usamos IndexedStack para preservar el estado de cada tab
  // y evitar rebuilds innecesarios al cambiar entre tabs
  static const _tabs = <Widget>[
    DiaryScreen(),
    WeightScreen(),
    SummaryScreen(),
    CoachScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh meal type provider to get current time-based value
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

    final t = ref.read(translationsProvider).valueOrNull;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(
            Icons.notifications_active,
            color: colors.primary,
            size: 48,
          ),
          title: Text(t?.translate('checkin.title') ?? '¡Toca check-in semanal!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t?.translate('checkin.daysSince',
                        args: {'count': '$daysSince'}) ??
                    'Han pasado $daysSince días desde tu último check-in.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                t?.translate('checkin.suggestion') ??
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
              child: Text(t?.translate('common.later') ?? 'DESPUÉS'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                context.goToCoachCheckIn();
              },
              icon: const Icon(Icons.check),
              label: Text(t?.translate('checkin.doCheckin') ?? 'HACER CHECK-IN'),
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
    // Refresh meal type when app resumes from background
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(currentMealTypeProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(homeTabProvider);
    final t = ref.tr;

    return Scaffold(
      appBar: AppBar(title: Text(t('home.title'))),
      // IndexedStack mantiene todos los tabs en memoria pero solo muestra uno
      // Esto preserva el scroll position y evita re-fetch de datos
      body: SafeArea(
        child: IndexedStack(index: currentTab.index, children: _tabs),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        currentIndex: currentTab.index,
        onTap: (i) =>
            ref.read(homeTabProvider.notifier).setTab(HomeTab.values[i]),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.book), label: t('home.tabs.diary')),
          BottomNavigationBarItem(icon: const Icon(Icons.scale), label: t('home.tabs.weight')),
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: t('home.tabs.summary'),
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.auto_graph), label: t('home.tabs.coach')),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: t('home.tabs.profile')),
        ],
      ),
    );
  }
}
