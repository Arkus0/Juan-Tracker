import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/training_provider.dart';
import '../services/haptics_controller.dart';
import '../../core/design_system/design_system.dart';
import '../widgets/session/focus_mode_widgets.dart';

/// Notifier para saber si estamos en modo Focus
class FocusModeNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void set(bool value) => state = value;
}

final focusModeProvider = NotifierProvider<FocusModeNotifier, bool>(FocusModeNotifier.new);

/// Notifier para el set actualmente seleccionado
class SelectedSetNotifier extends Notifier<({int exerciseIndex, int setIndex})?> {
  @override
  ({int exerciseIndex, int setIndex})? build() => null;
  void set(({int exerciseIndex, int setIndex})? value) => state = value;
}

final selectedSetProvider = NotifierProvider<SelectedSetNotifier, ({int exerciseIndex, int setIndex})?>(SelectedSetNotifier.new);

/// SessionScreen optimizado para modo Focus en gimnasio
class FocusSessionScreen extends ConsumerStatefulWidget {
  const FocusSessionScreen({super.key});

  @override
  ConsumerState<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends ConsumerState<FocusSessionScreen> {
  final PageController _pageController = PageController();
  int _currentExerciseIndex = 0;

  // Controllers para inputs
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _rpeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    HapticsController.instance.initialize();
    
    // Seleccionar automáticamente el primer set incompleto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSelectNextSet();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    _rpeController.dispose();
    super.dispose();
  }

  void _autoSelectNextSet() {
    final session = ref.read(trainingSessionProvider);
    final nextSet = session.nextIncompleteSet;
    
    if (nextSet != null) {
      ref.read(selectedSetProvider.notifier).set(nextSet);
      _currentExerciseIndex = nextSet.exerciseIndex;
      
      // Cargar valores actuales
      _loadSetValues(nextSet.exerciseIndex, nextSet.setIndex);
    }
  }

  void _loadSetValues(int exerciseIndex, int setIndex) {
    final session = ref.read(trainingSessionProvider);
    if (exerciseIndex >= session.exercises.length) return;
    
    final exercise = session.exercises[exerciseIndex];
    if (setIndex >= exercise.logs.length) return;
    
    final log = exercise.logs[setIndex];
    
    setState(() {
      _weightController.text = log.peso > 0 ? log.peso.toStringAsFixed(1) : '';
      _repsController.text = log.reps > 0 ? log.reps.toString() : '';
      _rpeController.text = log.rpe?.toStringAsFixed(1) ?? '';
    });
  }

  void _saveCurrentSet() {
    final selected = ref.read(selectedSetProvider);
    if (selected == null) return;

    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final reps = int.tryParse(_repsController.text);
    final rpe = int.tryParse(_rpeController.text);

    ref.read(trainingSessionProvider.notifier).updateLog(
      selected.exerciseIndex,
      selected.setIndex,
      peso: weight,
      reps: reps,
      rpe: rpe,
    );

    // Marcar como completado
    ref.read(trainingSessionProvider.notifier).updateLog(
      selected.exerciseIndex,
      selected.setIndex,
      completed: true,
    );

    HapticsController.instance.onSetCompleted();

    // Avanzar al siguiente set
    _moveToNextSet();
  }

  void _moveToNextSet() {
    final session = ref.read(trainingSessionProvider);
    final selected = ref.read(selectedSetProvider);
    
    if (selected == null) {
      _autoSelectNextSet();
      return;
    }

    // Buscar siguiente set en el mismo ejercicio
    final exercise = session.exercises[selected.exerciseIndex];
    if (selected.setIndex + 1 < exercise.logs.length) {
      final next = (
        exerciseIndex: selected.exerciseIndex,
        setIndex: selected.setIndex + 1,
      );
      ref.read(selectedSetProvider.notifier).set(next);
      _loadSetValues(next.exerciseIndex, next.setIndex);
      return;
    }

    // Pasar al siguiente ejercicio
    if (selected.exerciseIndex + 1 < session.exercises.length) {
      final next = (
        exerciseIndex: selected.exerciseIndex + 1,
        setIndex: 0,
      );
      ref.read(selectedSetProvider.notifier).set(next);
      _currentExerciseIndex = next.exerciseIndex;
      _loadSetValues(next.exerciseIndex, next.setIndex);
      
      // Animar al siguiente ejercicio
      _pageController.animateToPage(
        _currentExerciseIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Sesión completada
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¡Sesión Completada!', style: AppTypography.titleLarge),
        content: Text(
          'Has completado todos los sets de esta sesión.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CONTINUAR', style: AppTypography.labelLarge),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _finishSession();
            },
            child: Text('TERMINAR', style: AppTypography.labelLarge.copyWith(
              color: Theme.of(context).colorScheme.primary,
            )),
          ),
        ],
      ),
    );
  }

  void _finishSession() async {
    final notifier = ref.read(trainingSessionProvider.notifier);
    await notifier.finishSession();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('¡Sesión guardada!', style: AppTypography.labelSmall),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(trainingSessionProvider);
    final selected = ref.watch(selectedSetProvider);
    final restTimer = session.restTimer;

    // Timer info
    final timerRemaining = restTimer.remainingSeconds;
    final isTimerRunning = restTimer.isActive && !restTimer.isPaused;
    final isTimerPaused = restTimer.isPaused;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header con navegación de ejercicios
            _ExerciseHeader(
              exerciseName: selected != null && selected.exerciseIndex < session.exercises.length
                  ? session.exercises[selected.exerciseIndex].nombre
                  : 'Entrenamiento',
              exerciseIndex: _currentExerciseIndex,
              totalExercises: session.exercises.length,
              onPrevious: _currentExerciseIndex > 0
                  ? () {
                      setState(() => _currentExerciseIndex--);
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
              onNext: _currentExerciseIndex < session.exercises.length - 1
                  ? () {
                      setState(() => _currentExerciseIndex++);
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
            ),

            // Progress indicator
            _SessionProgressBar(session: session),

            // Timer siempre visible (sticky)
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.all(16),
              child: FocusTimerWidget(
                remainingSeconds: timerRemaining.toInt(),
                isRunning: isTimerRunning,
                isPaused: isTimerPaused,
                onToggle: () {
                  if (restTimer.isActive) {
                    if (restTimer.isPaused) {
                      ref.read(trainingSessionProvider.notifier).resumeRest();
                    } else {
                      ref.read(trainingSessionProvider.notifier).pauseRest();
                    }
                  } else {
                    ref.read(trainingSessionProvider.notifier).startRest();
                  }
                },
                onAddTime: () => ref.read(trainingSessionProvider.notifier).addRestTime(30),
                onSkip: () => ref.read(trainingSessionProvider.notifier).stopRest(),
              ),
            ),

            // PageView de ejercicios
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentExerciseIndex = index);
                  // Actualizar set seleccionado al cambiar de ejercicio
                  final newSelected = (
                    exerciseIndex: index,
                    setIndex: 0,
                  );
                  ref.read(selectedSetProvider.notifier).set(newSelected);
                  _loadSetValues(index, 0);
                },
                itemCount: session.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = session.exercises[index];
                  return _ExerciseFocusView(
                    exercise: exercise,
                    exerciseIndex: index,
                    selectedSet: selected,
                    onSetSelected: (setIndex) {
                      ref.read(selectedSetProvider.notifier).set((
                        exerciseIndex: index,
                        setIndex: setIndex,
                      ));
                      _loadSetValues(index, setIndex);
                      HapticsController.instance.trigger(HapticEvent.focusChanged);
                    },
                  );
                },
              ),
            ),

            // Panel de inputs (si hay set seleccionado)
            if (selected != null)
              _InputPanel(
                weightController: _weightController,
                repsController: _repsController,
                rpeController: _rpeController,
                onSave: _saveCurrentSet,
                isLastSet: _isLastSet(session, selected),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _finishSession,
        backgroundColor: AppColors.success,
        icon: const Icon(Icons.check),
        label: Text('TERMINAR', style: AppTypography.labelSmall),
      ),
    );
  }

  bool _isLastSet(dynamic session, ({int exerciseIndex, int setIndex}) selected) {
    final isLastExercise = selected.exerciseIndex == session.exercises.length - 1;
    if (!isLastExercise) return false;
    
    final exercise = session.exercises[selected.exerciseIndex];
    return selected.setIndex == exercise.logs.length - 1;
  }
}

/// Header de ejercicio con navegación
class _ExerciseHeader extends StatelessWidget {
  final String exerciseName;
  final int exerciseIndex;
  final int totalExercises;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _ExerciseHeader({
    required this.exerciseName,
    required this.exerciseIndex,
    required this.totalExercises,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: colors.outline.withAlpha(50)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios, color: colors.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    exerciseName.toUpperCase(),
                    style: AppTypography.titleLarge.copyWith(
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ejercicio ${exerciseIndex + 1} de $totalExercises',
                    style: AppTypography.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: onPrevious != null ? colors.onSurface : colors.outline),
                  onPressed: onPrevious,
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: onNext != null ? colors.onSurface : colors.outline),
                  onPressed: onNext,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra de progreso de la sesión
class _SessionProgressBar extends StatelessWidget {
  final dynamic session;

  const _SessionProgressBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    int totalSets = 0;
    int completedSets = 0;
    
    for (final exercise in session.exercises) {
      totalSets += exercise.logs.length as int;
      completedSets += exercise.logs.where((log) => log.completed).length as int;
    }
    
    final progress = totalSets > 0 ? completedSets / totalSets : 0.0;

    return Container(
      height: 4,
      color: colors.surfaceContainerLow,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(color: colors.primary),
      ),
    );
  }
}

/// Vista de ejercicio en modo Focus
class _ExerciseFocusView extends StatelessWidget {
  final dynamic exercise;
  final int exerciseIndex;
  final ({int exerciseIndex, int setIndex})? selectedSet;
  final ValueChanged<int> onSetSelected;

  const _ExerciseFocusView({
    required this.exercise,
    required this.exerciseIndex,
    required this.selectedSet,
    required this.onSetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exercise.logs.length,
      itemBuilder: (context, index) {
        final log = exercise.logs[index];
        final isSelected = selectedSet?.exerciseIndex == exerciseIndex &&
                          selectedSet?.setIndex == index;

        return _SelectableFocusSetCard(
          setNumber: index + 1,
          weight: log.peso,
          reps: log.reps,
          rpe: log.rpe,
          isCompleted: log.completado,
          isSelected: isSelected,
          onTap: () => onSetSelected(index),
        );
      },
    );
  }
}

/// Panel de inputs grande
class _InputPanel extends StatelessWidget {
  final TextEditingController weightController;
  final TextEditingController repsController;
  final TextEditingController rpeController;
  final VoidCallback onSave;
  final bool isLastSet;

  const _InputPanel({
    required this.weightController,
    required this.repsController,
    required this.rpeController,
    required this.onSave,
    required this.isLastSet,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de arrastre
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            
            // Inputs
            Row(
              children: [
                Expanded(
                  child: FocusNumberInput(
                    label: 'PESO',
                    initialValue: double.tryParse(weightController.text),
                    onChanged: (value) {
                      weightController.text = value.toStringAsFixed(1);
                    },
                    suffix: 'kg',
                    decimalPlaces: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FocusNumberInput(
                    label: 'REPS',
                    initialValue: double.tryParse(repsController.text),
                    onChanged: (value) {
                      repsController.text = value.toInt().toString();
                    },
                    min: 0,
                    max: 999,
                    decimalPlaces: 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FocusNumberInput(
                    label: 'RPE',
                    initialValue: double.tryParse(rpeController.text),
                    onChanged: (value) {
                      rpeController.text = value.toStringAsFixed(1);
                    },
                    min: 1,
                    max: 10,
                    decimalPlaces: 1,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botón guardar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: onSave,
                icon: Icon(isLastSet ? Icons.check_circle : Icons.arrow_forward),
                label: Text(
                  isLastSet ? 'COMPLETAR SESIÓN' : 'GUARDAR Y CONTINUAR',
                  style: AppTypography.labelSmall.copyWith(
                    color: colors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension del FocusSetCard con selección
class _SelectableFocusSetCard extends StatelessWidget {
  final int setNumber;
  final double? weight;
  final int? reps;
  final double? rpe;
  final bool isCompleted;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SelectableFocusSetCard({
    required this.setNumber,
    this.weight,
    this.reps,
    this.rpe,
    this.isCompleted = false,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected 
            ? colors.primaryContainer 
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? colors.primary 
              : isCompleted 
                  ? AppColors.success 
                  : colors.outline,
          width: isSelected || isCompleted ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Número de serie con estado
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? AppColors.success 
                      : isSelected 
                          ? colors.primary 
                          : colors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 28)
                      : Text(
                          setNumber.toString(),
                          style: AppTypography.titleLarge.copyWith(
                            color: isSelected ? colors.onPrimary : colors.onSurface,
                            fontSize: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Datos del set
              Expanded(
                child: Row(
                  children: [
                    _DataItem(
                      label: 'PESO',
                      value: weight != null ? weight!.toStringAsFixed(1) : '--',
                      unit: 'kg',
                      isSelected: isSelected,
                    ),
                    const SizedBox(width: 24),
                    _DataItem(
                      label: 'REPS',
                      value: reps?.toString() ?? '--',
                      isSelected: isSelected,
                    ),
                    if (rpe != null) ...[
                      const SizedBox(width: 24),
                      _DataItem(
                        label: 'RPE',
                        value: rpe!.toStringAsFixed(1),
                        isSelected: isSelected,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item de datos mejorado
class _DataItem extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final bool isSelected;

  const _DataItem({
    required this.label,
    required this.value,
    this.unit,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTypography.dataLarge.copyWith(
                color: isSelected ? colors.onPrimaryContainer : colors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2),
              Text(
                unit!,
                style: AppTypography.caption.copyWith(
                  color: isSelected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
