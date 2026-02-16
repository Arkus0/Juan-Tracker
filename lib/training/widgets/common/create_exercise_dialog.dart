import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/library_exercise.dart';
import '../../services/exercise_library_service.dart';
import '../../services/exercise_image_storage_service.dart';
import '../../../core/design_system/design_system.dart';

/// Diálogo para crear un ejercicio personalizado
class CreateExerciseDialog extends StatefulWidget {
  /// Si se proporciona, edita el ejercicio existente en lugar de crear uno nuevo
  final LibraryExercise? exerciseToEdit;

  const CreateExerciseDialog({super.key, this.exerciseToEdit});

  /// Muestra el diálogo y retorna el ejercicio creado/editado o null si se cancela
  static Future<LibraryExercise?> show(
    BuildContext context, {
    LibraryExercise? exerciseToEdit,
  }) {
    return showDialog<LibraryExercise>(
      context: context,
      builder: (context) =>
          CreateExerciseDialog(exerciseToEdit: exerciseToEdit),
    );
  }

  @override
  State<CreateExerciseDialog> createState() => _CreateExerciseDialogState();
}

class _CreateExerciseDialogState extends State<CreateExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedMuscleGroup = 'Pecho';
  String _selectedEquipment = 'Barra';
  List<String> _selectedMuscles = [];

  String? _existingImagePath;
  String? _pendingImagePath;
  bool _removeImage = false;
  bool _isPickingImage = false;

  bool _isLoading = false;

  bool get _isEditing => widget.exerciseToEdit != null;

  static const List<String> _muscleGroups = [
    'Pecho',
    'Espalda',
    'Hombros',
    'Bíceps',
    'Tríceps',
    'Piernas',
    'Glúteos',
    'Core',
    'Cardio',
    'Full Body',
  ];

  static const List<String> _equipmentOptions = [
    'Barra',
    'Mancuernas',
    'Máquina',
    'Cable',
    'Peso corporal',
    'Kettlebell',
    'Banda elástica',
    'Barra dominadas',
    'TRX',
    'Otro',
  ];

  static const Map<String, List<String>> _musclesByGroup = {
    'Pecho': ['Pectoral mayor', 'Pectoral menor'],
    'Espalda': ['Dorsal ancho', 'Trapecio', 'Romboides', 'Erectores'],
    'Hombros': [
      'Deltoides anterior',
      'Deltoides lateral',
      'Deltoides posterior',
    ],
    'Bíceps': ['Bíceps braquial', 'Braquial'],
    'Tríceps': ['Tríceps braquial'],
    'Piernas': [
      'Cuádriceps',
      'Isquiotibiales',
      'Gemelos',
      'Aductores',
      'Abductores',
    ],
    'Glúteos': ['Glúteo mayor', 'Glúteo medio', 'Glúteo menor'],
    'Core': ['Recto abdominal', 'Oblicuos', 'Transverso'],
    'Cardio': [],
    'Full Body': [],
  };

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final ex = widget.exerciseToEdit!;
      _nameController.text = ex.name;
      _descriptionController.text = ex.description ?? '';
      _selectedMuscleGroup = _muscleGroups.contains(ex.muscleGroup)
          ? ex.muscleGroup
          : 'Pecho';
      _selectedEquipment = _equipmentOptions.contains(ex.equipment)
          ? ex.equipment
          : 'Otro';
      _selectedMuscles = List.from(ex.muscles);
      _existingImagePath = ex.localImagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final library = ExerciseLibraryService.instance;
      final imageService = ExerciseImageStorageService.instance;
      LibraryExercise result;

      if (_isEditing) {
        await library.updateCustomExercise(
          exerciseId: widget.exerciseToEdit!.id,
          name: _nameController.text.trim(),
          muscleGroup: _selectedMuscleGroup,
          equipment: _selectedEquipment,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          muscles: _selectedMuscles,
        );
        final exerciseId = widget.exerciseToEdit!.id;

        if (_removeImage) {
          await imageService.deleteImageIfExists(_existingImagePath);
          await library.setExerciseImage(
            exerciseId: exerciseId,
            localImagePath: null,
          );
        } else if (_pendingImagePath != null) {
          final savedPath = await imageService.persistImage(
            sourcePath: _pendingImagePath!,
            exerciseId: exerciseId,
          );
          await imageService.deleteImageIfExists(_existingImagePath);
          await library.setExerciseImage(
            exerciseId: exerciseId,
            localImagePath: savedPath,
          );
        }

        result = library.getExerciseById(exerciseId)!;
      } else {
        result = await library.addCustomExercise(
          name: _nameController.text.trim(),
          muscleGroup: _selectedMuscleGroup,
          equipment: _selectedEquipment,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          muscles: _selectedMuscles,
        );

        if (_pendingImagePath != null) {
          final savedPath = await imageService.persistImage(
            sourcePath: _pendingImagePath!,
            exerciseId: result.id,
          );
          await library.setExerciseImage(
            exerciseId: result.id,
            localImagePath: savedPath,
          );
          result = library.getExerciseById(result.id)!;
        }
      }

      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.actionPrimary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? get _previewImagePath {
    if (_pendingImagePath != null) return _pendingImagePath;
    if (_removeImage) return null;
    return _existingImagePath;
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

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
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _pendingImagePath = picked.path;
          _removeImage = false;
        });
      }
    }

    if (mounted) setState(() => _isPickingImage = false);
  }

  void _clearImage() {
    setState(() {
      _pendingImagePath = null;
      _removeImage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: AppColors.bgElevated,
      title: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit : Icons.add_circle,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            _isEditing ? 'EDITAR EJERCICIO' : 'NUEVO EJERCICIO',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del ejercicio
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre del ejercicio *',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.fitness_center,
                      color: Colors.grey,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un nombre';
                    }
                    if (value.trim().length < 3) {
                      return 'Mínimo 3 caracteres';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 16),

                // Grupo muscular
                DropdownButtonFormField<String>(
                  initialValue: _selectedMuscleGroup,
                  dropdownColor: AppColors.bgElevated,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Grupo muscular',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.category, color: Colors.grey),
                  ),
                  items: _muscleGroups.map((group) {
                    return DropdownMenuItem(value: group, child: Text(group));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMuscleGroup = value;
                        _selectedMuscles =
                            []; // Reset muscles when group changes
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Equipamiento
                DropdownButtonFormField<String>(
                  initialValue: _selectedEquipment,
                  dropdownColor: AppColors.bgElevated,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Equipamiento',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.build, color: Colors.grey),
                  ),
                  items: _equipmentOptions.map((eq) {
                    return DropdownMenuItem(value: eq, child: Text(eq));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedEquipment = value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Músculos específicos (opcional)
                if (_musclesByGroup[_selectedMuscleGroup]?.isNotEmpty ==
                    true) ...[
                  const Text(
                    'Músculos trabajados (opcional)',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _musclesByGroup[_selectedMuscleGroup]!.map((
                      muscle,
                    ) {
                      final isSelected = _selectedMuscles.contains(muscle);
                      return FilterChip(
                        label: Text(
                          muscle,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedMuscles.add(muscle);
                            } else {
                              _selectedMuscles.remove(muscle);
                            }
                          });
                        },
                        selectedColor: AppColors.actionPrimary,
                        backgroundColor: AppColors.bgInteractive,
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Descripción (opcional)
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.bgElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.notes, color: Colors.grey),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 16),

                // Foto (opcional)
                Text(
                  'Foto (opcional)',
                  style: AppTypography.labelMedium.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                if (_previewImagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_previewImagePath!),
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 140,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: scheme.onSurfaceVariant,
                      size: 40,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPickingImage ? null : _pickImage,
                        icon: const Icon(Icons.photo_camera),
                        label: Text(
                          _previewImagePath == null
                              ? 'Elegir foto'
                              : 'Cambiar foto',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_previewImagePath != null)
                      OutlinedButton(
                        onPressed: _clearImage,
                        child: const Text('Quitar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'CANCELAR',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.actionPrimary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isEditing ? 'GUARDAR' : 'CREAR',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }
}
