// ============================================================================
// BLOCK EDIT SCREEN - Modo Pro
// Pantalla para crear/editar un bloque de entrenamiento
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:juan_tracker/core/design_system/app_theme.dart';
import 'package:uuid/uuid.dart';
import '../models/training_block.dart';

/// Pantalla para crear/editar un bloque de entrenamiento
class BlockEditScreen extends StatefulWidget {
  final TrainingBlock? block; // null = crear nuevo
  final DateTime? defaultStartDate;
  final List<TrainingBlock> existingBlocks; // Para validar solapamientos

  const BlockEditScreen({
    super.key,
    this.block,
    this.defaultStartDate,
    this.existingBlocks = const [],
  });

  @override
  State<BlockEditScreen> createState() => _BlockEditScreenState();
}

class _BlockEditScreenState extends State<BlockEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late BlockType _type;
  late DateTime _startDate;
  late DateTime _endDate;
  late final List<String> _goals;
  final List<TextEditingController> _goalControllers = [];

  bool get _isEditing => widget.block != null;

  int get _durationWeeks => _endDate.difference(_startDate).inDays ~/ 7;

  @override
  void initState() {
    super.initState();
    final block = widget.block;
    _nameController = TextEditingController(text: block?.name ?? '');
    _notesController = TextEditingController(text: block?.notes ?? '');
    _type = block?.type ?? BlockType.accumulation;
    _startDate = block?.startDate ?? widget.defaultStartDate ?? DateTime.now();
    _endDate = block?.endDate ?? _startDate.add(const Duration(days: 28));
    _goals = List<String>.from(block?.goals ?? []);

    // Crear controllers para objetivos existentes
    for (final goal in _goals) {
      _goalControllers.add(TextEditingController(text: goal));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    for (final controller in _goalControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Valida si las fechas se solapan con bloques existentes
  String? _validateDates() {
    if (_startDate.isAfter(_endDate)) {
      return 'La fecha de inicio debe ser anterior a la fecha de fin';
    }

    // Verificar solapamientos con otros bloques (excluyendo el actual si estamos editando)
    for (final existing in widget.existingBlocks) {
      if (_isEditing && existing.id == widget.block!.id) continue;

      // Un bloque se solapa si:
      // - El inicio del nuevo está dentro del existente, O
      // - El fin del nuevo está dentro del existente, O
      // - El nuevo abarca completamente al existente
      final newStartInExisting = _startDate.isAfter(existing.startDate.subtract(const Duration(days: 1))) &&
          _startDate.isBefore(existing.endDate.add(const Duration(days: 1)));
      final newEndInExisting = _endDate.isAfter(existing.startDate.subtract(const Duration(days: 1))) &&
          _endDate.isBefore(existing.endDate.add(const Duration(days: 1)));
      final newEncompassesExisting = _startDate.isBefore(existing.startDate) &&
          _endDate.isAfter(existing.endDate);

      if (newStartInExisting || newEndInExisting || newEncompassesExisting) {
        return 'Las fechas se solapan con el bloque "${existing.name}"';
      }
    }

    return null;
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('El nombre del bloque es obligatorio');
      return;
    }

    // Validar fechas
    final dateError = _validateDates();
    if (dateError != null) {
      _showError(dateError);
      return;
    }

    // Recopilar objetivos no vacíos
    final validGoals = _goalControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final block = TrainingBlock(
      id: widget.block?.id ?? const Uuid().v4(),
      name: name,
      type: _type,
      startDate: _startDate,
      endDate: _endDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      goals: validGoals,
    );

    Navigator.pop(context, block);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addGoal() {
    setState(() {
      _goals.add('');
      _goalControllers.add(TextEditingController());
    });
  }

  void _removeGoal(int index) {
    setState(() {
      _goalControllers[index].dispose();
      _goalControllers.removeAt(index);
      _goals.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final firstDate = isStart
        ? DateTime.now().subtract(const Duration(days: 365))
        : _startDate.add(const Duration(days: 1));
    final lastDate = isStart
        ? DateTime.now().add(const Duration(days: 730))
        : _startDate.add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.ironRed,
              onPrimary: Colors.white,
              surface: AppColors.darkSurface,
              onSurface: AppColors.darkTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Si la nueva fecha de inicio es posterior a la de fin, ajustar
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 28));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          _isEditing ? 'EDITAR BLOQUE' : 'NUEVO BLOQUE',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'GUARDAR',
              style: GoogleFonts.montserrat(
                color: AppColors.ironRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Nombre del bloque
          _SectionTitle('Nombre del bloque'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: GoogleFonts.montserrat(
              color: AppColors.darkTextPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'ej. Volumen Hipertrófia',
              hintStyle: GoogleFonts.montserrat(
                color: AppColors.darkTextTertiary,
              ),
              filled: true,
              fillColor: AppColors.darkSurfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.ironRed, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Tipo de bloque
          _SectionTitle('Tipo de bloque'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BlockType.values.map((type) {
              final isSelected = _type == type;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type.icon,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.darkTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(type.label),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _type = type);
                },
                backgroundColor: AppColors.darkSurfaceVariant,
                selectedColor: AppColors.ironRed,
                labelStyle: GoogleFonts.montserrat(
                  color: isSelected ? Colors.white : AppColors.darkTextPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: BorderSide(
                    color: isSelected ? AppColors.ironRed : AppColors.darkBorder,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Fechas
          _SectionTitle('Duración'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'Inicio',
                  date: _startDate,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DatePickerField(
                  label: 'Fin',
                  date: _endDate,
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Duración calculada
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.ironRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppColors.ironRed,
                ),
                const SizedBox(width: 8),
                Text(
                  '$_durationWeeks semanas',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ironRed,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Objetivos
          _SectionTitle('Objetivos del bloque'),
          const SizedBox(height: 12),
          ..._buildGoalFields(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addGoal,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Añadir objetivo'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ironRed,
              textStyle: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Notas
          _SectionTitle('Notas adicionales'),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            style: GoogleFonts.montserrat(
              color: AppColors.darkTextPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Notas sobre el bloque, progresión planificada, etc...',
              hintStyle: GoogleFonts.montserrat(
                color: AppColors.darkTextTertiary,
              ),
              filled: true,
              fillColor: AppColors.darkSurfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.ironRed, width: 2),
              ),
            ),
            maxLines: 4,
          ),

          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ironRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text(
              _isEditing ? 'GUARDAR CAMBIOS' : 'CREAR BLOQUE',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGoalFields() {
    return _goalControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              Icons.flag,
              size: 18,
              color: AppColors.ironRed.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                style: GoogleFonts.montserrat(
                  color: AppColors.darkTextPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Objetivo ${index + 1}',
                  hintStyle: GoogleFonts.montserrat(
                    color: AppColors.darkTextTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.darkSurfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _removeGoal(index),
              icon: Icon(
                Icons.delete_outline,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

/// Título de sección
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.darkTextSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Campo de selección de fecha
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  String get _formattedDate {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            color: AppColors.darkTextTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: AppColors.darkSurfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: AppColors.darkTextSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _formattedDate,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
