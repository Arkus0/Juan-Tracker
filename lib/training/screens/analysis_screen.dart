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
import '../widgets/analysis/muscle_imbalance_dashboard.dart';
import '../widgets/analysis/symmetry_radar.dart';
import '../widgets/deload_alerts_widget.dart';
import 'package:juan_tracker/core/widgets/widgets.dart';
import '../services/one_rm_calculator.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: 'Fuerza'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_BitacoraTab(), _LaboratorioTab(), _FuerzaTab()],
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

/// FUERZA Tab - 1RM Calculator & Strength Analytics
class _FuerzaTab extends ConsumerStatefulWidget {
  const _FuerzaTab();

  @override
  ConsumerState<_FuerzaTab> createState() => _FuerzaTabState();
}

class _FuerzaTabState extends ConsumerState<_FuerzaTab> {
  double _weight = 100;
  int _reps = 5;
  OneRMResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    setState(() {
      _result = OneRMCalculator.calculateAll(weight: _weight, reps: _reps);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Calculator Card
        _buildCalculatorCard(colors),
        const SizedBox(height: 16),

        // Results
        if (_result != null) ...[
          _buildResultCard(colors),
          const SizedBox(height: 16),

          // Load Percentages
          _buildLoadTableCard(colors),
          const SizedBox(height: 16),

          // Confidence Indicator
          _buildConfidenceCard(colors),
        ],

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCalculatorCard(ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Calculadora 1RM',
                  style: AppTypography.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Weight Input
            Row(
              children: [
                Text('Peso:', style: AppTypography.bodyMedium),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _weight,
                    min: 10,
                    max: 300,
                    divisions: 58,
                    label: '${_weight.round()} kg',
                    onChanged: (v) => setState(() {
                      _weight = v;
                      _calculate();
                    }),
                  ),
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_weight.round()}',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleSmall.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reps Input
            Row(
              children: [
                Text('Reps:', style: AppTypography.bodyMedium),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _reps.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    label: '$_reps',
                    onChanged: (v) => setState(() {
                      _reps = v.round();
                      _calculate();
                    }),
                  ),
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_reps',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleSmall.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Tu 1RM Estimado',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _result!.rounded.toStringAsFixed(1),
                  style: AppTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'kg',
                    style: AppTypography.bodyLarge.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Formula breakdown
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: _result!.results.entries.map((e) {
                final name = e.key.name.substring(0, 1).toUpperCase() + 
                            e.key.name.substring(1, 3);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$name: ${e.value.round()}',
                    style: AppTypography.labelSmall.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadTableCard(ColorScheme colors) {
    final loads = OneRMCalculator.calculatePercentageTable(_result!.average);
    final percentages = [50, 60, 70, 75, 80, 85, 90, 95];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.table_chart, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Porcentajes de Carga',
                  style: AppTypography.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: percentages.map((pct) {
                final load = loads[pct]!;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: pct >= 90
                        ? colors.errorContainer
                        : pct >= 80
                            ? colors.tertiaryContainer
                            : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.outline.withAlpha((0.3 * 255).round()),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$pct%',
                        style: AppTypography.labelSmall.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${load.round()}kg',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: pct >= 90
                              ? colors.onErrorContainer
                              : pct >= 80
                                  ? colors.onTertiaryContainer
                                  : colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceCard(ColorScheme colors) {
    final confidenceColor = _result!.confidence / 100 > 0.8
        ? colors.tertiary
        : _result!.confidence / 100 > 0.5
            ? colors.secondary
            : colors.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: confidenceColor),
                const SizedBox(width: 8),
                Text(
                  'Confianza del Estimado',
                  style: AppTypography.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),

            LinearProgressIndicator(
              value: _result!.confidence / 100,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_result!.confidence / 100 * 100).round()}% precisión',
                  style: AppTypography.bodyMedium.copyWith(
                    color: confidenceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _reps <= 5
                      ? 'Excelente rango (≤5 reps)'
                      : _reps <= 8
                          ? 'Buen rango (6-8 reps)'
                          : 'Rango moderado (≥9 reps)',
                  style: AppTypography.labelMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              OneRMCalculator.recommend(oneRM: _result!.average, goal: TrainingGoal.hypertrophy).description,
              style: AppTypography.bodySmall.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
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

        // Muscle Imbalance Dashboard (Push/Pull, Quad/Ham)
        MuscleImbalanceDashboard(),

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
