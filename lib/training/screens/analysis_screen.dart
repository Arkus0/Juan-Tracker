import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/widgets/home_button.dart';
import '../models/external_session.dart';
import '../providers/analysis_provider.dart';
import '../providers/training_provider.dart';
import '../widgets/external_session_sheet.dart';
import '../widgets/analysis/activity_heatmap.dart';
import '../widgets/analysis/calendar_view.dart';
import '../widgets/analysis/hall_of_fame.dart';
import '../widgets/analysis/recovery_monitor.dart';
import '../widgets/analysis/session_list_view.dart';
import '../widgets/analysis/streak_counter.dart';
import '../widgets/analysis/strength_trend.dart';
import '../widgets/analysis/symmetry_radar.dart';
import '../widgets/deload_alerts_widget.dart';
import 'export_screen.dart';

/// Centro de Comando Anabólico - Analysis Screen
/// Replaces HistoryScreen with advanced analytics
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(analysisTabIndexProvider.notifier)
            .setIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(analysisTabIndexProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: HomeButton(),
        ),
        title: const Text('Análisis'),
        centerTitle: true,
        actions: [
          // Export menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export_csv') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExportScreen()),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'export_csv',
                child: Row(
                  children: [
                    Icon(
                      Icons.download_rounded,
                      size: 20,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Exportar datos (CSV)',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTypography.labelLarge,
          onTap: (_) => HapticFeedback.selectionClick(),
          tabs: const [
            Tab(text: 'Historial'),
            Tab(text: 'Estadísticas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_BitacoraTab(), _LaboratorioTab()],
      ),
      floatingActionButton: tabIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'add_external_session',
              onPressed: () => _addExternalSession(context),
              icon: const Icon(Icons.add),
              label: Text(
                'Sesión externa',
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _addExternalSession(BuildContext context) async {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}

    final session = await ExternalSessionSheet.show(context);
    if (session == null) return;

    final repo = ref.read(trainingRepositoryProvider);
    try {
      await repo.saveSesion(session.toSesion());
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    _showUndoSnack(context, repo, session);
  }

  void _showUndoSnack(
    BuildContext context,
    dynamic repo,
    ExternalSession session,
  ) {
    final colors = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: colors.primary, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Sesión guardada (${session.exercises.length} ejercicios)',
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onInverseSurface,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'DESHACER',
          onPressed: () => repo.deleteSesion(session.id),
        ),
        duration: const Duration(seconds: 10),
      ),
    );
  }
}

/// BITÁCORA Tab - Discipline & Consistency
class _BitacoraTab extends ConsumerWidget {
  const _BitacoraTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(bitacoraViewModeProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Streak Counter
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: StreakCounter(),
          ),
        ),

        // Activity Heatmap
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: ActivityHeatmap(
              onDayTap: (date) {
                ref.read(selectedCalendarDateProvider.notifier).setDate(date);
                ref
                    .read(bitacoraViewModeProvider.notifier)
                    .setMode(BitacoraViewMode.calendar);
              },
            ),
          ),
        ),

        // View Mode Selector
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ViewModeSelector(
              currentMode: viewMode,
              onModeChanged: (mode) {
                HapticFeedback.selectionClick();
                ref.read(bitacoraViewModeProvider.notifier).setMode(mode);
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Content based on view mode
        if (viewMode == BitacoraViewMode.calendar)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: AnalysisCalendarView(),
            ),
          )
        else
          const SessionListView(),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

/// LABORATORIO Tab - Science & Analytics
class _LaboratorioTab extends ConsumerWidget {
  const _LaboratorioTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        // 🎯 MED-005: Alertas de deload/sobreentrenamiento
        DeloadAlertsWidget(),

        SizedBox(height: 20),

        // Recovery Monitor
        RecoveryMonitor(),

        SizedBox(height: 20),

        // Symmetry Radar
        SymmetryRadar(),

        SizedBox(height: 20),

        // Hall of Fame (PRs)
        HallOfFame(),

        SizedBox(height: 20),

        // Strength Trend
        StrengthTrend(),

        // Bottom padding for nav bar
        SizedBox(height: 100),
      ],
    );
  }
}

/// View mode selector (Calendar vs List)
class _ViewModeSelector extends StatelessWidget {
  final BitacoraViewMode currentMode;
  final ValueChanged<BitacoraViewMode> onModeChanged;

  const _ViewModeSelector({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outline.withAlpha((0.5 * 255).round())),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          _buildOption(
            context,
            icon: Icons.calendar_month,
            label: 'Calendario',
            isSelected: currentMode == BitacoraViewMode.calendar,
            onTap: () => onModeChanged(BitacoraViewMode.calendar),
          ),
          _buildOption(
            context,
            icon: Icons.list_alt,
            label: 'Lista',
            isSelected: currentMode == BitacoraViewMode.list,
            onTap: () => onModeChanged(BitacoraViewMode.list),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryContainer : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
