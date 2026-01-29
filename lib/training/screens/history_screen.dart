import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/external_session.dart';
import '../models/rutina.dart';
import '../models/sesion.dart';
import '../providers/training_provider.dart';
import '../utils/design_system.dart';
import '../widgets/common/app_widgets.dart';
import '../widgets/external_session_sheet.dart';
import 'session_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Cargar más cuando el usuario está cerca del final (200px antes)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreIfNeeded();
    }
  }

  Future<void> _loadMoreIfNeeded() async {
    if (_isLoadingMore) return;

    final currentPage = ref.read(historyPaginationProvider);
    final sessionsAsync = ref.read(sesionesHistoryPaginatedProvider(currentPage));

    // Solo cargar más si hay datos y potencialmente más por cargar
    final sessions = sessionsAsync.asData?.value ?? [];
    if (sessions.length >= (currentPage + 1) * 20) {
      setState(() => _isLoadingMore = true);
      ref.read(historyPaginationProvider.notifier).loadMore();
      // Pequeño delay para evitar spam de cargas
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(historyPaginationProvider);
    final sessionsAsync = ref.watch(sesionesHistoryPaginatedProvider(currentPage));
    final rutinasAsync = ref.watch(rutinasStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HISTORIAL'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export_all') {
                final sessions =
                    sessionsAsync.asData?.value ?? const <Sesion>[];
                _exportAllSessions(context, sessions);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'export_all',
                child: Row(
                  children: [
                    Icon(Icons.file_download, size: 20),
                    SizedBox(width: 8),
                    Text('Exportar Todo'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_external_session',
        onPressed: () => _showExternalSessionSheet(context, ref),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add),
        label: Text(
          'SESIÓN EXTERNA',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      body: sessionsAsync.when(
        loading: () =>
            const AppLoadingIndicator(message: 'Cargando historial...'),
        error: (err, stack) => ErrorStateWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(sesionesHistoryPaginatedProvider(currentPage)),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return _buildEmptyStateWithHint(context, ref);
          }

          return rutinasAsync.when(
            loading: () => const AppLoadingIndicator(),
            error: (err, stack) =>
                ErrorStateWidget(message: 'Error cargando rutinas: $err'),
            data: (rutinas) {
              final rutinasMap = {for (final r in rutinas) r.id: r};

              // Agrupar sesiones por semana
              final groupedSessions = _groupSessionsByWeek(sessions);
              final entries = groupedSessions.entries.toList();

              return ListView.builder(
                controller: _scrollController,
                // Performance: número de items + 1 para indicador de carga
                itemCount: entries.length + (_isLoadingMore ? 1 : 0),
                padding: const EdgeInsets.only(top: 16, bottom: 100),
                itemBuilder: (context, index) {
                  // Indicador de carga al final
                  if (index >= entries.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final weekEntry = entries[index];
                  return _WeekSection(
                    weekLabel: weekEntry.key,
                    sessions: weekEntry.value,
                    rutinasMap: rutinasMap,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Map<String, List<Sesion>> _groupSessionsByWeek(List<Sesion> sessions) {
    final grouped = <String, List<Sesion>>{};
    final now = DateTime.now();

    for (final session in sessions) {
      final diff = now.difference(session.fecha).inDays;
      String label;

      if (diff < 7) {
        label = 'ESTA SEMANA';
      } else if (diff < 14) {
        label = 'SEMANA PASADA';
      } else if (diff < 30) {
        label = 'ESTE MES';
      } else {
        final monthLabel = DateFormat(
          'MMMM yyyy',
          'es_ES',
        ).format(session.fecha).toUpperCase();
        label = monthLabel;
      }

      grouped.putIfAbsent(label, () => []).add(session);
    }

    return grouped;
  }

  Future<void> _exportAllSessions(BuildContext context, List<Sesion> sessions) async {
    if (sessions.isEmpty) return;

    final data = sessions.map((s) => _sessionToMap(s)).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    await SharePlus.instance.share(
      ShareParams(text: jsonStr, subject: 'Juan Training - Historial Completo'),
    );
  }

  Map<String, dynamic> _sessionToMap(Sesion session) {
    return {
      'id': session.id,
      'fecha': session.fecha.toIso8601String(),
      'duracionMin': session.durationSeconds != null
          ? (session.durationSeconds! / 60).round()
          : null,
      'volumenTotal': session.totalVolume,
      'seriesCompletadas': session.completedSetsCount,
      'ejercicios': session.ejerciciosCompletados
          .map(
            (e) => {
              'nombre': e.nombre,
              'series': e.logs
                  .map(
                    (l) => {
                      'peso': l.peso,
                      'reps': l.reps,
                      'completado': l.completed,
                      'rpe': l.rpe,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    };
  }

  Widget _buildEmptyStateWithHint(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 24),
            Text(
              'SIN ENTRENAMIENTOS',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Completa tu primer entrenamiento para ver el historial.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.neonCyan,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '¿Entrenaste fuera de la app?',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neonCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Puedes agregar sesiones externas usando voz, escáner, texto o entrada manual.',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showExternalSessionSheet(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('AGREGAR SESIÓN EXTERNA'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neonCyan,
                        side: const BorderSide(color: AppColors.neonCyan),
                      ),
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

  void _showExternalSessionSheet(BuildContext context, WidgetRef ref) async {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}

    final session = await ExternalSessionSheet.show(context);

    if (session != null && context.mounted) {
      // Guardar la sesión externa (placeholder para futura implementación con la base de datos)
      await _saveExternalSession(session, ref);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.neonCyan,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sesión externa guardada (${session.exercises.length} ejercicios)',
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.bgElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          action: SnackBarAction(
            label: 'DESHACER',
            textColor: AppColors.neonCyan,
            onPressed: () async {
              await _undoSaveExternalSession(session, ref);
            },
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  Future<void> _saveExternalSession(
    ExternalSession session,
    WidgetRef ref,
  ) async {
    final repo = ref.read(trainingRepositoryProvider);
    await repo.saveSesion(session.toSesion());
  }

  Future<void> _undoSaveExternalSession(
    ExternalSession session,
    WidgetRef ref,
  ) async {
    final repo = ref.read(trainingRepositoryProvider);
    await repo.deleteSesion(session.id);
  }
}

class _WeekSection extends ConsumerWidget {
  final String weekLabel;
  final List<Sesion> sessions;
  final Map<String, Rutina> rutinasMap;

  const _WeekSection({
    required this.weekLabel,
    required this.sessions,
    required this.rutinasMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calcular estadísticas de la semana
    final totalVolume = sessions.fold(0.0, (sum, s) => sum + s.totalVolume);
    final totalSessions = sessions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                weekLabel,
                style: GoogleFonts.montserrat(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$totalSessions sesiones • ${(totalVolume / 1000).toStringAsFixed(1)}t vol',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        ...sessions.map(
          (session) => _SessionTile(
            key: ValueKey(session.id),
            session: session,
            rutinasMap: rutinasMap,
            onDelete: () => _deleteSession(context, ref, session),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _deleteSession(BuildContext context, WidgetRef ref, Sesion session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '¿ELIMINAR SESIÓN?',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción no se puede deshacer.',
              style: GoogleFonts.montserrat(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgDeep,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.dayName ?? 'Sesión',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(session.fecha),
                    style: GoogleFonts.montserrat(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.completedSetsCount} series • ${(session.totalVolume / 1000).toStringAsFixed(1)}t volumen',
                    style: GoogleFonts.montserrat(
                      color: AppColors.neonCyan,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'CANCELAR',
              style: GoogleFonts.montserrat(color: Colors.white54),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete, size: 18),
            label: Text(
              'ELIMINAR',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(trainingRepositoryProvider);
        await repository.deleteSesion(session.id);
        
        if (context.mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sesión eliminada',
                style: GoogleFonts.montserrat(),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al eliminar: $e',
                style: GoogleFonts.montserrat(),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _SessionTile extends StatefulWidget {
  final Sesion session;
  final Map<String, Rutina> rutinasMap;
  final VoidCallback onDelete;

  const _SessionTile({
    super.key,
    required this.session,
    required this.rutinasMap,
    required this.onDelete,
  });

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final rutina = widget.rutinasMap[widget.session.rutinaId];
    final rutinaName = rutina?.nombre ?? 'RUTINA ELIMINADA';

    final dateStr = DateFormat(
      'd MMM',
      'es_ES',
    ).format(widget.session.fecha).toUpperCase();
    final timeStr = DateFormat('HH:mm').format(widget.session.fecha);

    final durationText = widget.session.durationSeconds != null
        ? '${(widget.session.durationSeconds! / 60).toStringAsFixed(0)} MIN'
        : 'N/A';

    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () {
              try {
                HapticFeedback.selectionClick();
              } catch (_) {}
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            onLongPress: () {
              try {
                HapticFeedback.mediumImpact();
              } catch (_) {}
              final theme = Theme.of(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Theme(
                    data: theme,
                    child: SessionDetailScreen(sesion: widget.session),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 55,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dateStr.split(' ')[0],
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white, height: 1),
                        ),
                        Text(
                          dateStr.split(' ').length > 1
                              ? dateStr.split(' ')[1]
                              : '',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rutinaName.toUpperCase(),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.session.dayName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.session.dayName!,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              durationText,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.fitness_center,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(widget.session.totalVolume / 1000).toStringAsFixed(1)}t',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // Detalle expandible
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey[800]),
          const SizedBox(height: 8),
          // Lista de ejercicios resumida
          ...widget.session.ejerciciosCompletados.take(5).map((ejercicio) {
            final completedSets = ejercicio.logs
                .where((l) => l.completed)
                .length;
            final maxWeight = ejercicio.logs
                .where((l) => l.completed)
                .fold(0.0, (max, l) => l.peso > max ? l.peso : max);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ejercicio.nombre,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$completedSets series',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${maxWeight}kg max',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (widget.session.ejerciciosCompletados.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${widget.session.ejerciciosCompletados.length - 5} ejercicios más',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ),
          const SizedBox(height: 12),
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final theme = Theme.of(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Theme(
                          data: theme,
                          child: SessionDetailScreen(sesion: widget.session),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('VER DETALLE'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _exportSession(context, widget.session),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('EXPORT'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.error,
                tooltip: 'Eliminar sesión',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportSession(BuildContext context, Sesion session) async {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}

    final buffer = StringBuffer();
    buffer.writeln('=== JUAN TRAINING ===');
    buffer.writeln(
      'Fecha: ${DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(session.fecha)}',
    );
    if (session.dayName != null) buffer.writeln('Día: ${session.dayName}');
    buffer.writeln('Duración: ${session.formattedDuration}');
    buffer.writeln(
      'Volumen Total: ${(session.totalVolume / 1000).toStringAsFixed(1)} toneladas',
    );
    buffer.writeln();
    buffer.writeln('--- EJERCICIOS ---');

    for (final ejercicio in session.ejerciciosCompletados) {
      buffer.writeln();
      buffer.writeln('${ejercicio.nombre}:');
      for (var i = 0; i < ejercicio.logs.length; i++) {
        final log = ejercicio.logs[i];
        if (log.completed) {
          final rpeStr = log.rpe != null ? ' RPE:${log.rpe}' : '';
          buffer.writeln(
            '  Serie ${i + 1}: ${log.peso}kg x ${log.reps}$rpeStr',
          );
        }
      }
    }

    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject:
            'Juan Training - Sesión ${DateFormat('dd/MM').format(session.fecha)}',
      ),
    );
  }
}
