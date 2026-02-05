import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/widgets/widgets.dart';
import '../../../diet/models/body_progress_models.dart';
import '../../../diet/providers/body_progress_providers.dart';

/// Pantalla de Progreso Corporal
/// 
/// Permite al usuario:
/// - Registrar y ver medidas corporales (cintura, pecho, brazos, etc.)
/// - Subir y ver fotos de progreso
/// - Comparar evolución a lo largo del tiempo
class BodyProgressScreen extends ConsumerStatefulWidget {
  const BodyProgressScreen({super.key});

  @override
  ConsumerState<BodyProgressScreen> createState() => _BodyProgressScreenState();
}

class _BodyProgressScreenState extends ConsumerState<BodyProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Mi Progreso'),
            centerTitle: true,
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: BackButton(),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.straighten), text: 'Medidas'),
                Tab(icon: Icon(Icons.photo_library), text: 'Fotos'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _MeasurementsTab(),
            _PhotosTab(),
          ],
        ),
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          return FloatingActionButton.extended(
            onPressed: () {
              if (_tabController.index == 0) {
                _showAddMeasurementDialog(context);
              } else {
                _showAddPhotoDialog(context);
              }
            },
            icon: const Icon(Icons.add),
            label: Text(_tabController.index == 0 ? 'Añadir Medidas' : 'Añadir Foto'),
          );
        },
      ),
    );
  }

  void _showAddMeasurementDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => const _AddMeasurementSheet(),
    );
  }

  void _showAddPhotoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => const _AddPhotoSheet(),
    );
  }
}

// ============================================================================
// TAB: MEDIDAS
// ============================================================================

class _MeasurementsTab extends ConsumerWidget {
  const _MeasurementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(measurementsSummaryProvider);
    final measurementsAsync = ref.watch(bodyMeasurementsStreamProvider);

    return CustomScrollView(
      slivers: [
        // Resumen de progreso
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: summaryAsync.when(
              data: (summary) => _MeasurementsSummaryCard(summary: summary),
              loading: () => const AppLoading(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ),

        // Lista de medidas
        measurementsAsync.when(
          data: (measurements) {
            if (measurements.isEmpty) {
              return const SliverFillRemaining(
                child: AppEmpty(
                  icon: Icons.straighten,
                  title: 'Sin medidas registradas',
                  subtitle: 'Empieza a registrar tus medidas para ver tu progreso',
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList.builder(
                itemCount: measurements.length,
                itemBuilder: (context, index) {
                  final measurement = measurements[index];
                  final previous = index < measurements.length - 1 
                      ? measurements[index + 1] 
                      : null;
                  
                  return _MeasurementCard(
                    measurement: measurement,
                    diff: previous != null ? measurement.diff(previous) : null,
                  );
                },
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: AppLoading(),
          ),
          error: (_, _) => SliverFillRemaining(
            child: AppError(
              message: 'Error al cargar medidas',
              onRetry: () => ref.invalidate(bodyMeasurementsStreamProvider),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

/// Card de resumen con las diferencias desde la primera medición
class _MeasurementsSummaryCard extends StatelessWidget {
  final BodyMeasurementsSummary summary;

  const _MeasurementsSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (!summary.hasData) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Icon(
                Icons.straighten,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withAlpha(128),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Registra tu primera medición',
                style: AppTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Toma medidas cada 2-4 semanas para ver tu evolución',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final diff = summary.overallDiff;
    final colors = Theme.of(context).colorScheme;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_down, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Tu Progreso',
                  style: AppTypography.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${summary.totalMeasurements} registros',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            
            // Grid de cambios principales
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                if (diff?.weightKg != null)
                  _DiffChip(
                    label: 'Peso',
                    value: diff!.weightKg!,
                    unit: 'kg',
                    inverseColors: true, // Menos peso es positivo
                  ),
                if (diff?.waistCm != null)
                  _DiffChip(
                    label: 'Cintura',
                    value: diff!.waistCm!,
                    unit: 'cm',
                    inverseColors: true,
                  ),
                if (diff?.chestCm != null && diff!.chestCm != 0)
                  _DiffChip(
                    label: 'Pecho',
                    value: diff.chestCm!,
                    unit: 'cm',
                  ),
                if (diff?.hipsCm != null && diff!.hipsCm != 0)
                  _DiffChip(
                    label: 'Cadera',
                    value: diff.hipsCm!,
                    unit: 'cm',
                    inverseColors: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip que muestra la diferencia de una medida
class _DiffChip extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final bool inverseColors;

  const _DiffChip({
    required this.label,
    required this.value,
    required this.unit,
    this.inverseColors = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = value > 0;
    final isNegative = value < 0;
    final isGood = inverseColors ? isNegative : isPositive;

    final color = isGood 
        ? AppColors.success 
        : isPositive || isNegative 
            ? AppColors.error 
            : Colors.grey;

    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$sign${value.toStringAsFixed(1)} $unit',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card individual de una medida
class _MeasurementCard extends StatelessWidget {
  final BodyMeasurementModel measurement;
  final BodyMeasurementDiff? diff;

  const _MeasurementCard({
    required this.measurement,
    this.diff,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dateStr = DateFormat('d MMM yyyy', 'es').format(measurement.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: colors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              dateStr,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (diff?.weightKg != null) ...[
              const Spacer(),
              _buildDiffBadge(diff!.weightKg!, 'kg', colors, inverse: true),
            ],
          ],
        ),
        subtitle: measurement.notes != null && measurement.notes!.isNotEmpty
            ? Text(
                measurement.notes!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Grid de medidas
                _buildMeasurementsGrid(),
              ],
            ),
          ),
        ],
      ),
    ),);
  }

  Widget _buildDiffBadge(double value, String unit, ColorScheme colors, {bool inverse = false}) {
    final isPositive = value > 0;
    final isGood = inverse ? !isPositive : isPositive;
    final color = isGood ? AppColors.success : AppColors.error;
    final sign = value > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$sign${value.toStringAsFixed(1)} $unit',
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMeasurementsGrid() {
    final measurements = <Map<String, dynamic>>[];

    if (measurement.weightKg != null) {
      measurements.add({
        'icon': Icons.monitor_weight,
        'label': 'Peso',
        'value': '${measurement.weightKg!.toStringAsFixed(1)} kg',
      });
    }
    if (measurement.waistCm != null) {
      measurements.add({
        'icon': Icons.accessibility,
        'label': 'Cintura',
        'value': '${measurement.waistCm!.toStringAsFixed(1)} cm',
      });
    }
    if (measurement.chestCm != null) {
      measurements.add({
        'icon': Icons.accessibility_new,
        'label': 'Pecho',
        'value': '${measurement.chestCm!.toStringAsFixed(1)} cm',
      });
    }
    if (measurement.hipsCm != null) {
      measurements.add({
        'icon': Icons.accessibility,
        'label': 'Cadera',
        'value': '${measurement.hipsCm!.toStringAsFixed(1)} cm',
      });
    }
    if (measurement.avgArmCm != null) {
      measurements.add({
        'icon': Icons.fitness_center,
        'label': 'Brazo',
        'value': '${measurement.avgArmCm!.toStringAsFixed(1)} cm',
      });
    }
    if (measurement.avgThighCm != null) {
      measurements.add({
        'icon': Icons.fitness_center,
        'label': 'Muslo',
        'value': '${measurement.avgThighCm!.toStringAsFixed(1)} cm',
      });
    }
    if (measurement.bodyFatPercentage != null) {
      measurements.add({
        'icon': Icons.percent,
        'label': '% Grasa',
        'value': '${measurement.bodyFatPercentage!.toStringAsFixed(1)}%',
      });
    }

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: measurements.map((m) => _buildMeasurementItem(m)).toList(),
    );
  }

  Widget _buildMeasurementItem(Map<String, dynamic> data) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data['icon'] as IconData, size: 20),
          const SizedBox(height: 4),
          Text(
            data['label'] as String,
            style: AppTypography.labelSmall,
          ),
          const SizedBox(height: 2),
          Text(
            data['value'] as String,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TAB: FOTOS
// ============================================================================

class _PhotosTab extends ConsumerWidget {
  const _PhotosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(progressPhotosStreamProvider);
    final selectedCategory = ref.watch(selectedPhotoCategoryProvider);

    return Column(
      children: [
        // Filtro de categorías
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'Todas',
                  isSelected: selectedCategory == null,
                  onTap: () => ref.read(selectedPhotoCategoryProvider.notifier).select(null),
                ),
                ...PhotoCategory.values.map((cat) => _CategoryChip(
                  label: '${cat.icon} ${cat.displayName}',
                  isSelected: selectedCategory == cat,
                  onTap: () => ref.read(selectedPhotoCategoryProvider.notifier).select(cat),
                )),
              ],
            ),
          ),
        ),

        // Grid de fotos
        Expanded(
          child: photosAsync.when(
            data: (photos) {
              final filteredPhotos = selectedCategory != null
                  ? photos.where((p) => p.category == selectedCategory).toList()
                  : photos;

              if (filteredPhotos.isEmpty) {
                return const AppEmpty(
                  icon: Icons.photo_library,
                  title: 'Sin fotos',
                  subtitle: 'Añade tu primera foto de progreso',
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                ),
                itemCount: filteredPhotos.length,
                itemBuilder: (context, index) {
                  final photo = filteredPhotos[index];
                  return _PhotoCard(photo: photo);
                },
              );
            },
            loading: () => const AppLoading(),
            error: (_, _) => AppError(
              message: 'Error al cargar fotos',
              onRetry: () => ref.invalidate(progressPhotosStreamProvider),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) => onTap(),
        selectedColor: colors.primaryContainer,
        checkmarkColor: colors.primary,
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final ProgressPhotoModel photo;

  const _PhotoCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy', 'es').format(photo.date);

    return GestureDetector(
      onTap: () => _showPhotoDetail(context),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md),
                ),
                child: Image.file(
                  File(photo.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${photo.category.icon} ${photo.category.displayName}',
                    style: AppTypography.labelSmall,
                  ),
                  Text(
                    dateStr,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(photo.category.displayName),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Flexible(
              child: Image.file(
                File(photo.imagePath),
                fit: BoxFit.contain,
              ),
            ),
            if (photo.notes != null && photo.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(photo.notes!),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SHEETS PARA AÑADIR
// ============================================================================

class _AddMeasurementSheet extends ConsumerStatefulWidget {
  const _AddMeasurementSheet();

  @override
  ConsumerState<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends ConsumerState<_AddMeasurementSheet> {
  DateTime selectedDate = DateTime.now();
  final _weightController = TextEditingController();
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _hipsController = TextEditingController();
  final _leftArmController = TextEditingController();
  final _rightArmController = TextEditingController();
  final _leftThighController = TextEditingController();
  final _rightThighController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    _hipsController.dispose();
    _leftArmController.dispose();
    _rightArmController.dispose();
    _leftThighController.dispose();
    _rightThighController.dispose();
    _bodyFatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Text(
                        'Nuevas Medidas',
                        style: AppTypography.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Form
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      // Fecha
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Fecha'),
                        subtitle: Text(
                          DateFormat('d MMMM yyyy', 'es').format(selectedDate),
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Medidas principales
                      Text('Medidas Principales', style: AppTypography.titleSmall),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberField(
                              controller: _weightController,
                              label: 'Peso (kg)',
                              icon: Icons.monitor_weight,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildNumberField(
                              controller: _waistController,
                              label: 'Cintura (cm)',
                              icon: Icons.accessibility,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberField(
                              controller: _chestController,
                              label: 'Pecho (cm)',
                              icon: Icons.accessibility_new,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildNumberField(
                              controller: _hipsController,
                              label: 'Cadera (cm)',
                              icon: Icons.accessibility,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),
                      Text('Extremidades', style: AppTypography.titleSmall),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberField(
                              controller: _leftArmController,
                              label: 'Brazo Izq (cm)',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildNumberField(
                              controller: _rightArmController,
                              label: 'Brazo Der (cm)',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberField(
                              controller: _leftThighController,
                              label: 'Muslo Izq (cm)',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildNumberField(
                              controller: _rightThighController,
                              label: 'Muslo Der (cm)',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),
                      _buildNumberField(
                        controller: _bodyFatController,
                        label: '% Grasa Corporal (opcional)',
                        icon: Icons.percent,
                      ),

                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas (opcional)',
                          hintText: 'Ej: Medición tomada por la mañana',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),

                // Botón guardar
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton(
                    onPressed: _save,
                    label: 'GUARDAR MEDIDAS',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  void _save() {
    HapticFeedback.mediumImpact();

    final notifier = ref.read(bodyMeasurementsNotifierProvider.notifier);
    
    notifier.addMeasurement(
      date: selectedDate,
      weightKg: _parseDouble(_weightController.text),
      waistCm: _parseDouble(_waistController.text),
      chestCm: _parseDouble(_chestController.text),
      hipsCm: _parseDouble(_hipsController.text),
      leftArmCm: _parseDouble(_leftArmController.text),
      rightArmCm: _parseDouble(_rightArmController.text),
      leftThighCm: _parseDouble(_leftThighController.text),
      rightThighCm: _parseDouble(_rightThighController.text),
      bodyFatPercentage: _parseDouble(_bodyFatController.text),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    Navigator.pop(context);
    
    AppSnackbar.show(
      context,
      message: 'Medidas guardadas correctamente',
    );
  }

  double? _parseDouble(String text) {
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }
}

class _AddPhotoSheet extends ConsumerStatefulWidget {
  const _AddPhotoSheet();

  @override
  ConsumerState<_AddPhotoSheet> createState() => _AddPhotoSheetState();
}

class _AddPhotoSheetState extends ConsumerState<_AddPhotoSheet> {
  DateTime selectedDate = DateTime.now();
  PhotoCategory selectedCategory = PhotoCategory.front;
  String? imagePath;
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Añadir Foto de Progreso', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.lg),

          // Selector de fecha
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Fecha'),
            subtitle: Text(
              DateFormat('d MMMM yyyy', 'es').format(selectedDate),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => selectedDate = date);
              }
            },
          ),

          // Selector de categoría
          const SizedBox(height: AppSpacing.md),
          Text('Vista', style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: PhotoCategory.values.map((cat) {
              return ChoiceChip(
                selected: selectedCategory == cat,
                onSelected: (_) => setState(() => selectedCategory = cat),
                label: Text('${cat.icon} ${cat.displayName}'),
              );
            }).toList(),
          ),

          // Preview de imagen
          const SizedBox(height: AppSpacing.lg),
          if (imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.file(
                File(imagePath!),
                height: 200,
                fit: BoxFit.cover,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar Foto o Elegir de Galería'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(AppSpacing.lg),
              ),
            ),

          // Notas
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              border: OutlineInputBorder(),
            ),
          ),

          // Botón guardar
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            onPressed: imagePath != null ? _save : null,
            label: 'GUARDAR FOTO',
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() => imagePath = picked.path);
      }
    }
  }

  void _save() {
    if (imagePath == null) return;

    HapticFeedback.mediumImpact();

    final notifier = ref.read(progressPhotosNotifierProvider.notifier);
    
    notifier.addPhoto(
      date: selectedDate,
      imagePath: imagePath!,
      category: selectedCategory,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    Navigator.pop(context);
    
    AppSnackbar.show(
      context,
      message: 'Foto guardada correctamente',
    );
  }
}
