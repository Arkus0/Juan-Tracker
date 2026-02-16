import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/design_system.dart';
import '../../models/ejercicio.dart';
import '../../providers/exercise_history_provider.dart';

/// Widget que muestra el historial de un ejercicio en un bottom sheet.
///
/// Usa [exerciseHistoryProvider] que implementa TTL de 5 minutos,
/// evitando N+1 queries cuando el usuario navega entre ejercicios.
class HistorySheetContent extends ConsumerWidget {
  final String exerciseName;

  const HistorySheetContent({super.key, required this.exerciseName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseName));

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('HISTORIAL', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(
            'Error al cargar: $e',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('HISTORIAL', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text(
                'No hay datos previos.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exerciseName.toUpperCase(),
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'ÚLTIMAS 3 SESIONES',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sessions.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: AppColors.border),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final sessionExercise = session.ejerciciosCompletados
                      .firstWhere(
                        (e) => e.nombre == exerciseName,
                        orElse: () => Ejercicio(
                          id: '',
                          libraryId: 'unknown',
                          nombre: exerciseName,
                          series: 0,
                          reps: 0,
                          logs: const [],
                        ),
                      );

                  final dateLabel =
                      '${session.fecha.day.toString().padLeft(2, '0')}/'
                      '${session.fecha.month.toString().padLeft(2, '0')}/'
                      '${session.fecha.year}';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...sessionExercise.logs.map((log) {
                          final weight =
                              log.peso.truncateToDouble() == log.peso
                                  ? log.peso.toInt().toString()
                                  : log.peso.toStringAsFixed(1);
                          return Text(
                            '• $weight kg × ${log.reps}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Muestra el bottom sheet de historial expandido.
void showExpandedHistorySheet(BuildContext context, Ejercicio exercise) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bgElevated,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: HistorySheetContent(exerciseName: exercise.nombre),
        ),
      );
    },
  );
}
