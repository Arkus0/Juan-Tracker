import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';


import '../../../core/widgets/widgets.dart';
import '../../models/rutina.dart';
import '../../models/sesion.dart';
import '../../providers/training_provider.dart';
import '../../screens/session_detail_screen.dart';

/// Session history list grouped by week - refactored from HistoryScreen
class SessionListView extends ConsumerWidget {
  const SessionListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sesionesHistoryStreamProvider);
    final rutinasAsync = ref.watch(rutinasStreamProvider);

    return sessionsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: AppLoading(message: 'Cargando historial...'),
      ),
      error: (err, stack) => SliverToBoxAdapter(
        child: AppError(
          message: 'Error al cargar historial',
          details: err.toString(),
          onRetry: () => ref.invalidate(sesionesHistoryStreamProvider),
        ),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return const SliverToBoxAdapter(
            child: AppEmpty(
              icon: Icons.history_toggle_off,
              title: 'Sin entrenamientos',
              subtitle:
                  'Completa tu primer entrenamiento para ver el historial.',
            ),
          );
        }

        return rutinasAsync.when(
          loading: () => const SliverToBoxAdapter(child: AppLoading()),
          error: (err, stack) => SliverToBoxAdapter(
            child: AppError(
              message: 'Error al cargar rutinas',
              details: err.toString(),
            ),
          ),
          data: (rutinas) {
            final rutinasMap = {for (final r in rutinas) r.id: r};
            final groupedSessions = _groupSessionsByWeek(sessions);

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final weekEntry = groupedSessions.entries.elementAt(index);
                return WeekSection(
                  weekLabel: weekEntry.key,
                  sessions: weekEntry.value,
                  rutinasMap: rutinasMap,
                );
              }, childCount: groupedSessions.length),
            );
          },
        );
      },
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
}

/// Week section header with stats
class WeekSection extends StatelessWidget {
  final String weekLabel;
  final List<Sesion> sessions;
  final Map<String, Rutina> rutinasMap;

  const WeekSection({
    super.key,
    required this.weekLabel,
    required this.sessions,
    required this.rutinasMap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$totalSessions sesiones • ${(totalVolume / 1000).toStringAsFixed(1)}t vol',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
        ),
        ...sessions.map(
          (session) => SessionTile(
            key: ValueKey(session.id),
            session: session,
            rutinasMap: rutinasMap,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Individual session tile with expandable details
class SessionTile extends StatefulWidget {
  final Sesion session;
  final Map<String, Rutina> rutinasMap;

  const SessionTile({
    super.key,
    required this.session,
    required this.rutinasMap,
  });

  @override
  State<SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<SessionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
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
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  // Date badge
                  Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scheme.outline),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dateStr.split(' ')[0],
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                            height: 1,
                          ),
                        ),
                        Text(
                          dateStr.split(' ').length > 1
                              ? dateStr.split(' ')[1]
                              : '',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Session info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rutinaName.toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onSurface,
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
                                  color: scheme.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.session.dayName!,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
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
                              size: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              timeStr,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              durationText,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.fitness_center,
                              size: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${(widget.session.totalVolume / 1000).toStringAsFixed(1)}t',
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: scheme.onSurfaceVariant,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(scheme),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: scheme.outline, height: 1),
          const SizedBox(height: 10),
          // Exercise list
          ...widget.session.ejerciciosCompletados.take(5).map((ejercicio) {
            final completedSets = ejercicio.logs
                .where((l) => l.completed)
                .length;
            final maxWeight = ejercicio.logs
                .where((l) => l.completed)
                .fold(0.0, (max, l) => l.peso > max ? l.peso : max);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ejercicio.nombre,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: scheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$completedSets series',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${maxWeight.toStringAsFixed(1)}kg',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
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
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Action buttons
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
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('DETALLE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onSurface,
                    side: BorderSide(color: scheme.outline),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _exportSession(context, widget.session),
                icon: const Icon(Icons.share, size: 16),
                label: const Text('EXPORT'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(
                    color: scheme.primary.withValues(alpha: 0.4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  textStyle: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _exportSession(BuildContext context, Sesion session) {
    HapticFeedback.selectionClick();

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

    SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject:
            'Juan Training - Sesión ${DateFormat('dd/MM').format(session.fecha)}',
      ),
    );
  }
}

// =============================================================================
// EXPORT UTILITIES
// =============================================================================

/// Export all sessions as JSON
void exportAllSessions(BuildContext context, List<Sesion> sessions) {
  if (sessions.isEmpty) return;

  final data = sessions.map((s) => sessionToMap(s)).toList();
  final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

  SharePlus.instance.share(
    ShareParams(text: jsonStr, subject: 'Juan Training - Historial Completo'),
  );
}

/// Convert session to exportable map
Map<String, dynamic> sessionToMap(Sesion session) {
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
