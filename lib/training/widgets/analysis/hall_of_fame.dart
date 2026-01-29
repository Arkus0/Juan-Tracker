import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/analysis_models.dart';
import '../../providers/analysis_provider.dart';

/// Grid display of personal records for big lifts
class HallOfFame extends ConsumerWidget {
  const HallOfFame({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prsAsync = ref.watch(personalRecordsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: scheme.tertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: scheme.tertiary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'HALL OF FAME',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                'PRs',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.tertiary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Récords personales en ejercicios clave',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          // PR Grid
          prsAsync.when(
            data: (prs) {
              if (prs.isEmpty) {
                return _buildEmptyState(scheme);
              }
              return _buildPRGrid(prs);
            },
            loading: () => _buildLoading(scheme),
            error: (_, _) => _buildEmptyState(scheme),
          ),
        ],
      ),
    );
  }

  Widget _buildPRGrid(List<PersonalRecord> prs) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: prs.length.clamp(0, 6), // Max 6 PRs
      itemBuilder: (context, index) {
        return _PRCard(pr: prs[index], rank: index + 1);
      },
    );
  }

  Widget _buildEmptyState(ColorScheme scheme) {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, color: scheme.outline, size: 40),
          const SizedBox(height: 12),
          Text(
            'Sin récords aún',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Completa entrenamientos para registrar PRs',
            style: GoogleFonts.montserrat(fontSize: 12, color: scheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(ColorScheme scheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }
}

class _PRCard extends StatelessWidget {
  final PersonalRecord pr;
  final int rank;

  const _PRCard({required this.pr, required this.rank});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Gold/Silver/Bronze styling for top 3
    final isTop3 = rank <= 3;
    final gradientColors = _getGradientColors(rank);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showPRDetail(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isTop3
              ? LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isTop3 ? null : scheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: isTop3
              ? Border.all(color: gradientColors.first.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise name & icon
            Row(
              children: [
                Expanded(
                  child: Text(
                    pr.exerciseName,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (rank <= 3)
                  Text(
                    _getTrophyEmoji(rank),
                    style: const TextStyle(fontSize: 14),
                  ),
              ],
            ),

            const Spacer(),

            // Max weight
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  pr.maxWeight.toStringAsFixed(1),
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'kg',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Reps and estimated 1RM
            Row(
              children: [
                Text(
                  'x${pr.repsAtMax}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.tertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '1RM: ${pr.estimated1RM.toStringAsFixed(0)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: scheme.tertiary,
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

  List<Color> _getGradientColors(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFF3D3D1D), const Color(0xFF2D2D15)]; // Gold
      case 2:
        return [const Color(0xFF3D3D3D), const Color(0xFF2D2D2D)]; // Silver
      case 3:
        return [const Color(0xFF3D2D1D), const Color(0xFF2D2015)]; // Bronze
      default:
        return [const Color(0xFF252525), const Color(0xFF1E1E1E)];
    }
  }

  String _getTrophyEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  void _showPRDetail(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // PR display
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.tertiary.withValues(alpha: 0.3),
                          scheme.tertiary.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🏆', style: TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RÉCORD PERSONAL',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: scheme.tertiary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          pr.exerciseName,
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildStatRow(context, 'Peso máximo', pr.formattedWeight),
                    Divider(color: scheme.outline, height: 24),
                    _buildStatRow(
                      context,
                      'Repeticiones',
                      '${pr.repsAtMax} reps',
                    ),
                    Divider(color: scheme.outline, height: 24),
                    _buildStatRow(
                      context,
                      '1RM Estimado',
                      pr.formattedEstimated1RM,
                    ),
                    Divider(color: scheme.outline, height: 24),
                    _buildStatRow(
                      context,
                      'Logrado el',
                      DateFormat('d MMM yyyy', 'es_ES').format(pr.achievedAt),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
