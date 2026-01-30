// ============================================================================
// BLOCK TIMELINE WIDGET - Modo Pro
// Muestra la línea de tiempo de bloques de entrenamiento
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:juan_tracker/core/design_system/app_theme.dart';
import '../../models/training_block.dart';

/// Widget que muestra la línea de tiempo de bloques de entrenamiento
class BlockTimelineWidget extends StatelessWidget {
  final List<TrainingBlock> blocks;
  final TrainingBlock? activeBlock;
  final VoidCallback? onAddBlock;
  final Function(TrainingBlock)? onEditBlock;
  final Function(TrainingBlock)? onDeleteBlock;
  final bool isEditing;

  const BlockTimelineWidget({
    super.key,
    required this.blocks,
    this.activeBlock,
    this.onAddBlock,
    this.onEditBlock,
    this.onDeleteBlock,
    this.isEditing = true,
  });

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty && !isEditing) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: activeBlock != null
              ? AppColors.ironRed.withAlpha((0.3 * 255).round())
              : AppColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.science,
                color: activeBlock != null ? AppColors.ironRed : AppColors.darkTextSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PERIODIZACIÓN POR BLOQUES',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: activeBlock != null
                        ? AppColors.ironRed
                        : AppColors.darkTextSecondary,
                  ),
                ),
              ),
              if (isEditing && onAddBlock != null)
                _AddBlockButton(onTap: onAddBlock!),
            ],
          ),

          const SizedBox(height: 12),
          Divider(
            color: AppColors.darkDivider,
            height: 1,
          ),
          const SizedBox(height: 16),

          // Timeline
          if (blocks.isEmpty)
            _EmptyBlocksMessage(onAddBlock: isEditing ? onAddBlock : null)
          else
            _BlockTimeline(
              blocks: blocks.sortedByStartDate(),
              activeBlock: activeBlock,
              onEditBlock: onEditBlock,
              onDeleteBlock: onDeleteBlock,
              isEditing: isEditing,
            ),

          // Bloque activo info
          if (activeBlock != null) ...[
            const SizedBox(height: 16),
            _ActiveBlockInfo(block: activeBlock!),
          ],
        ],
      ),
    );
  }
}

/// Botón para añadir bloque
class _AddBlockButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddBlockButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ironRed.withAlpha((0.15 * 255).round()),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                color: AppColors.ironRed,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'AÑADIR BLOQUE',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ironRed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensaje cuando no hay bloques
class _EmptyBlocksMessage extends StatelessWidget {
  final VoidCallback? onAddBlock;

  const _EmptyBlocksMessage({this.onAddBlock});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.calendar_view_month_outlined,
            color: AppColors.darkTextTertiary,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin bloques configurados',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: AppColors.darkTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Añade bloques para periodizar tu entrenamiento',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.darkTextTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAddBlock != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddBlock,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('CREAR PRIMER BLOQUE'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ironRed,
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Timeline de bloques
class _BlockTimeline extends StatelessWidget {
  final List<TrainingBlock> blocks;
  final TrainingBlock? activeBlock;
  final Function(TrainingBlock)? onEditBlock;
  final Function(TrainingBlock)? onDeleteBlock;
  final bool isEditing;

  const _BlockTimeline({
    required this.blocks,
    this.activeBlock,
    this.onEditBlock,
    this.onDeleteBlock,
    this.isEditing = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: blocks.asMap().entries.map((entry) {
          final index = entry.key;
          final block = entry.value;
          final isActive = block.id == activeBlock?.id;
          final isFirst = index == 0;
          final isLast = index == blocks.length - 1;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Línea conectora izquierda
              if (!isFirst)
                Container(
                  width: 20,
                  height: 2,
                  color: isActive || blocks[index - 1].isCompleted
                      ? AppColors.ironRed
                      : AppColors.darkBorder,
                ),

              // Bloque
              _BlockCard(
                block: block,
                isActive: isActive,
                onTap: isEditing && onEditBlock != null
                    ? () => onEditBlock!(block)
                    : null,
                onLongPress: isEditing && onDeleteBlock != null
                    ? () => _showDeleteDialog(context, block)
                    : null,
              ),

              // Línea conectora derecha
              if (!isLast)
                Container(
                  width: 20,
                  height: 2,
                  color: isActive
                      ? AppColors.ironRed
                      : AppColors.darkBorder,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TrainingBlock block) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          '¿Eliminar bloque?',
          style: GoogleFonts.montserrat(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar el bloque "${block.name}"?',
          style: GoogleFonts.montserrat(
            color: AppColors.darkTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCELAR',
              style: GoogleFonts.montserrat(
                color: AppColors.darkTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDeleteBlock?.call(block);
            },
            child: Text(
              'ELIMINAR',
              style: GoogleFonts.montserrat(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card individual de bloque
class _BlockCard extends StatelessWidget {
  final TrainingBlock block;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _BlockCard({
    required this.block,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
  });

  Color get _backgroundColor {
    if (isActive) return AppColors.ironRed.withAlpha((0.2 * 255).round());
    if (block.isCompleted) return AppColors.ironRed.withAlpha((0.1 * 255).round());
    if (block.isPending) return AppColors.darkSurfaceContainer;
    return AppColors.darkSurfaceContainer;
  }

  Color get _borderColor {
    if (isActive) return AppColors.ironRed;
    if (block.isCompleted) return AppColors.ironRed.withAlpha((0.5 * 255).round());
    return AppColors.darkBorder;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: _borderColor, width: isActive ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono y duración
              Row(
                children: [
                  Icon(
                    block.type.icon,
                    color: isActive ? AppColors.ironRed : AppColors.darkTextSecondary,
                    size: 16,
                  ),
                  const Spacer(),
                  Text(
                    '${block.durationWeeks} sem',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: AppColors.darkTextTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Nombre
              Text(
                block.name,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.darkTextPrimary : AppColors.darkTextSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Tipo
              Text(
                block.type.label,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: AppColors.darkTextTertiary,
                ),
              ),

              // Progreso si está activo
              if (isActive) ...[
                const SizedBox(height: 8),
                _ProgressBar(progress: block.progress),
              ],

              // Badge completado
              if (block.isCompleted && !isActive) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.ironRed,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'COMPLETADO',
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ironRed,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de progreso
class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.darkBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ironRed),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).round()}%',
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.ironRed,
          ),
        ),
      ],
    );
  }
}

/// Información del bloque activo
class _ActiveBlockInfo extends StatelessWidget {
  final TrainingBlock block;

  const _ActiveBlockInfo({required this.block});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ironRed.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.ironRed.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_filled,
                color: AppColors.ironRed,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'BLOQUE ACTIVO',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ironRed,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            block.name,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Semana ${block.currentWeek} de ${block.durationWeeks} • ${block.type.label}',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.darkTextSecondary,
            ),
          ),
          if (block.goals.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: block.goals.map((goal) {
                return Chip(
                  label: Text(
                    goal,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  backgroundColor: AppColors.darkSurface,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
