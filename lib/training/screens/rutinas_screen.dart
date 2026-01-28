import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/rutina.dart';
import '../providers/training_provider.dart';
import '../utils/design_system.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/routine_import_preview_dialog.dart';
import 'create_edit_routine_screen.dart';

class RutinasScreen extends ConsumerWidget {
  const RutinasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutinasAsync = ref.watch(rutinasStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MIS RUTINAS'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'import') {
                _showImportFlow(context, ref);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Importar Rutina'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: rutinasAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Cargando rutinas...'),
        error: (err, stack) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(rutinasStreamProvider),
        ),
        data: (rutinas) {
          if (rutinas.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.fitness_center,
              title: 'NO HAY RUTINAS',
              subtitle: 'Crea tu primera rutina para empezar',
              actionLabel: 'CREAR RUTINA',
              onAction: () => _navigateToCreate(context),
            );
          }

          return ListView.builder(
            itemCount: rutinas.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final rutina = rutinas[index];
              return Dismissible(
                key: ValueKey(rutina.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  color: Theme.of(context).colorScheme.error,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteRutina(context, ref, rutina),
                child: _RutinaTile(
                  rutina: rutina,
                  onTap: () => _navigateToEdit(context, rutina),
                  onDuplicate: () => _duplicateRutina(context, ref, rutina),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_rutina_fab',
        onPressed: () => _navigateToCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('NUEVA RUTINA'),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    final theme = Theme.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Theme(
          data: theme,
          child: const CreateEditRoutineScreen(),
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context, dynamic rutina) {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
    final theme = Theme.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Theme(
          data: theme,
          child: CreateEditRoutineScreen(rutina: rutina),
        ),
      ),
    );
  }

  void _deleteRutina(BuildContext context, WidgetRef ref, Rutina rutina) {
    ref.read(trainingRepositoryProvider).deleteRutina(rutina.id);
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('RUTINA ELIMINADA', style: AppTypography.button),
        // 🎯 REDISEÑO: Fondo del sistema
        backgroundColor: Theme.of(context).colorScheme.surface,
        action: SnackBarAction(
          label: 'DESHACER',
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: () {
            ref.read(trainingRepositoryProvider).saveRutina(rutina);
            try {
              HapticFeedback.lightImpact();
            } catch (_) {}
          },
        ),
      ),
    );
  }

  /// 🆕 Duplicar rutina completa
  Future<void> _duplicateRutina(
    BuildContext context,
    WidgetRef ref,
    Rutina rutina,
  ) async {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}

    const uuid = Uuid();

    // Crear copia con nuevo ID y nombre modificado
    final newRutina = Rutina(
      id: uuid.v4(),
      nombre: '${rutina.nombre} (copia)',
      creada: DateTime.now(),
      dias: rutina.dias
          .map(
            (dia) => dia.copyWith(
              ejercicios: dia.ejercicios
                  .map(
                    (ej) => ej.copyWith(
                      instanceId: uuid
                          .v4(), // Nuevo ID único para cada ejercicio
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );

    await ref.read(trainingRepositoryProvider).saveRutina(newRutina);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'RUTINA DUPLICADA: ${newRutina.nombre.toUpperCase()}',
            style: AppTypography.button,
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2000),
        ),
      );
    }
  }

  Future<void> _showImportFlow(BuildContext context, WidgetRef ref) async {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}

    // Step 1: Show JSON input dialog
    final parsedRutina = await showDialog<Rutina>(
      context: context,
      builder: (ctx) => const RoutineImportInputDialog(),
    );

    if (parsedRutina == null || !context.mounted) return;

    // Step 2: Show preview dialog
    final confirmedRutina = await showDialog<Rutina>(
      context: context,
      builder: (ctx) => RoutineImportPreviewDialog(
        rutina: parsedRutina,
        onConfirm: () {
          // This callback is called when user confirms import
        },
      ),
    );

    if (confirmedRutina == null || !context.mounted) return;

    // Step 3: Save the routine to database
    try {
      final repository = ref.read(trainingRepositoryProvider);
      await repository.saveRutina(confirmedRutina);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'RUTINA IMPORTADA: ${confirmedRutina.nombre.toUpperCase()}',
              style: AppTypography.button,
            ),
            // 🎯 REDISEÑO: Verde para éxito
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 2000),
          ),
        );
        try {
          HapticFeedback.vibrate();
        } catch (_) {}
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar: ${e.toString()}',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        try {
          HapticFeedback.vibrate();
        } catch (_) {}
      }
    }
  }
}

/// Extracted widget for better performance - only rebuilds when its rutina changes
class _RutinaTile extends StatelessWidget {
  final dynamic rutina;
  final VoidCallback onTap;
  final VoidCallback onDuplicate; // 🆕

  const _RutinaTile({
    required this.rutina,
    required this.onTap,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final totalExercises = rutina.dias.fold(
      0,
      (sum, day) => sum + day.ejercicios.length,
    );

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.grey[900],
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      rutina.nombre.toUpperCase(),
                      style: AppTypography.sectionTitle,
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.copy, color: Colors.blue[400]),
                    title: const Text(
                      'Duplicar rutina',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Crear una copia para modificar',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onDuplicate();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.edit, color: Colors.orange[400]),
                    title: const Text(
                      'Editar rutina',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onTap();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.share, color: Colors.green[400]),
                    title: const Text(
                      'Compartir rutina',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Exportar rutina en texto',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _shareRoutine(context, rutina);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      rutina.nombre.toUpperCase(),
                      // 🎯 REDISEÑO: Usar tipografía del sistema
                      style: AppTypography.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 🎯 REDISEÑO: Icono más sutil
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: '${rutina.dias.length} DÍAS',
                  ),
                  const SizedBox(width: 16),
                  _InfoChip(
                    icon: Icons.fitness_center,
                    label: '$totalExercises EJERCICIOS',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compartir rutina en texto (web-safe)
  Future<void> _shareRoutine(BuildContext context, dynamic rutina) async {
    final buffer = StringBuffer();
    buffer.writeln('Rutina: ${rutina.nombre}');
    buffer.writeln(
      '${rutina.dias.length} días • ${rutina.dias.fold(0, (sum, d) => sum + d.ejercicios.length)} ejercicios',
    );
    buffer.writeln('');
    for (final dia in rutina.dias) {
      buffer.writeln('${dia.nombre}:');
      for (final ej in dia.ejercicios) {
        buffer.writeln('- ${ej.nombre} ${ej.series}x${ej.repsRange}');
      }
      buffer.writeln('');
    }

    try {
      await SharePlus.instance.share(ShareParams(text: buffer.toString()));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al compartir: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

/// Reusable info chip for consistent styling
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.label),
      ],
    );
  }
}
