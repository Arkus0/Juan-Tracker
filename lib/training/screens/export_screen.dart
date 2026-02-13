// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/sesion.dart';
import '../providers/training_provider.dart';
import '../services/backup_service.dart';
import '../services/csv_export_service.dart';
import '../utils/design_system.dart';
import '../../core/widgets/home_button.dart';

/// Pantalla de exportación de datos con filtros
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  // Estado
  ExportType _type = ExportType.training;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  final List<String> _selectedExercises = [];
  bool _allExercisesSelected = true;
  final List<String> _selectedColumns = [
    'date',
    'exercise',
    'weight',
    'reps',
    'rpe',
    'volume',
  ];

  bool _isLoading = false;
  List<String> _availableExercises = [];

  // Search para ejercicios
  final TextEditingController _exerciseSearchController =
      TextEditingController();
  String _exerciseSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAvailableExercises();
  }

  @override
  void dispose() {
    _exerciseSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableExercises() async {
    final repo = ref.read(trainingRepositoryProvider);
    final sessions = await repo.getExerciseNames();
    if (mounted) {
      setState(() {
        _availableExercises = sessions..sort();
      });
    }
  }

  Future<void> _selectDateRange() async {
    HapticFeedback.selectionClick();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: Theme.of(context).appBarTheme.copyWith(
                  backgroundColor: AppColors.bgElevated,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _setQuickDateRange(int days) {
    HapticFeedback.selectionClick();
    setState(() {
      if (days == -1) {
        // Todo
        _dateRange = DateTimeRange(
          start: DateTime(2020),
          end: DateTime.now(),
        );
      } else {
        _dateRange = DateTimeRange(
          start: DateTime.now().subtract(Duration(days: days)),
          end: DateTime.now(),
        );
      }
    });
  }

  Future<List<Sesion>> _loadSessionsForExport() async {
    final repo = ref.read(trainingRepositoryProvider);
    // Obtener todas las sesiones y filtrar por fecha
    final allSessions = await repo.watchSesionesHistory(limit: 10000).first;

    return allSessions.where((session) {
      final sessionDate = DateTime(
        session.fecha.year,
        session.fecha.month,
        session.fecha.day,
      );
      final start = DateTime(
        _dateRange.start.year,
        _dateRange.start.month,
        _dateRange.start.day,
      );
      final end = DateTime(
        _dateRange.end.year,
        _dateRange.end.month,
        _dateRange.end.day,
      );
      return !sessionDate.isBefore(start) && !sessionDate.isAfter(end);
    }).toList();
  }

  Future<String> _generateCSV() async {
    final sessions = await _loadSessionsForExport();
    final exportData = CsvExportService.convertSessionsToExportData(
      sessions,
      exerciseFilter: _allExercisesSelected ? null : _selectedExercises,
    );

    return CsvExportService.generateTrainingCSV(
      sessions: exportData,
      columns: _selectedColumns,
    );
  }

  Future<void> _exportAndShare() async {
    if (_selectedColumns.isEmpty) {
      _showError('Selecciona al menos una columna');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final csv = await _generateCSV();
      final tempDir = await getTemporaryDirectory();
      final fileName = CsvExportService.generateFileName(_type);
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csv, encoding: utf8);

      if (!context.mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Export Juan Tracker - ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError('Error al exportar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToDownloads() async {
    if (_selectedColumns.isEmpty) {
      _showError('Selecciona al menos una columna');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final csv = await _generateCSV();

      if (kIsWeb) {
        // En web no hay carpeta de descargas directa
        _showError('En web usa "Exportar y Compartir"');
        return;
      }

      // Intentar obtener directorio de descargas
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        // Use async exists() to avoid blocking the UI thread
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null) {
        _showError('No se pudo acceder a la carpeta de descargas');
        return;
      }

      final fileName = CsvExportService.generateFileName(_type);
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsString(csv, encoding: utf8);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guardado en Descargas: $fileName',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: AppColors.completedGreen,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat()),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.montserrat()),
        backgroundColor: AppColors.completedGreen,
      ),
    );
  }

  String _buildImportSummary(ImportResult result) {
    final parts = <String>[];
    if (result.routinesImported > 0) {
      parts.add('${result.routinesImported} rutina(s)');
    }
    if (result.sessionsImported > 0) {
      parts.add('${result.sessionsImported} sesión(es)');
    }
    if (result.setsImported > 0) {
      parts.add('${result.setsImported} serie(s)');
    }
    if (parts.isEmpty) {
      parts.add('sin cambios');
    }
    final source = result.source != null ? ' (${result.source})' : '';
    return 'Importación completada$source: ${parts.join(', ')}';
  }

  Future<String?> _pickFileContent({
    required List<String> allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) {
        _showError('No se pudo leer el archivo');
        return null;
      }
      return utf8.decode(bytes, allowMalformed: true);
    }

    final path = file.path;
    if (path == null) {
      _showError('No se pudo acceder al archivo');
      return null;
    }
    return File(path).readAsString(encoding: utf8);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: HomeButton(),
        ),
        title: Text(
          'EXPORTAR DATOS',
          style: AppTypography.sectionTitle.copyWith(
            letterSpacing: 2,
            color: scheme.onSurface,
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tipo de exportación
          _buildSectionTitle('TIPO DE EXPORTACIÓN'),
          const SizedBox(height: 12),
          _buildTypeSelector(),
          const SizedBox(height: 24),

          // Rango de fechas
          _buildSectionTitle('RANGO DE FECHAS'),
          const SizedBox(height: 12),
          _buildDateRangeSelector(),
          const SizedBox(height: 12),
          _buildQuickDateButtons(),
          const SizedBox(height: 24),

          // Ejercicios (solo para training)
          if (_type != ExportType.diet) ...[
            _buildSectionTitle('EJERCICIOS'),
            const SizedBox(height: 12),
            _buildExerciseSelector(),
            const SizedBox(height: 24),
          ],

          // Columnas
          _buildSectionTitle('COLUMNAS A INCLUIR'),
          const SizedBox(height: 12),
          _buildColumnSelector(),
          const SizedBox(height: 24),

          // Preview
          _buildSectionTitle('VISTA PREVIA'),
          const SizedBox(height: 12),
          _buildPreview(),
          const SizedBox(height: 32),

          // Botones de acción
          _buildActionButtons(),

          const SizedBox(height: 40),

          // Divider
          Divider(color: scheme.outline),
          const SizedBox(height: 24),

          // 🆕 BACKUP COMPLETO JSON
          _buildSectionTitle('BACKUP COMPLETO'),
          const SizedBox(height: 12),
          _buildBackupSection(scheme),

          const SizedBox(height: 24),

          // 🆕 IMPORTAR
          _buildSectionTitle('IMPORTAR DATOS'),
          const SizedBox(height: 12),
          _buildImportSection(scheme),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTypeSelector() {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTypeOption(
            label: 'Entrenamiento',
            icon: Icons.fitness_center,
            isSelected: _type == ExportType.training,
            onTap: () => setState(() => _type = ExportType.training),
          ),
          _buildTypeOption(
            label: 'Dieta',
            icon: Icons.restaurant,
            isSelected: _type == ExportType.diet,
            onTap: () => setState(() => _type = ExportType.diet),
          ),
          _buildTypeOption(
            label: 'Ambos',
            icon: Icons.all_inclusive,
            isSelected: _type == ExportType.both,
            onTap: () => setState(() => _type = ExportType.both),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primary.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: isSelected
                ? Border.all(color: scheme.primary.withValues(alpha: 0.5))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    final scheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return InkWell(
      onTap: _selectDateRange,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, color: scheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Desde: ${dateFormat.format(_dateRange.start)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hasta: ${dateFormat.format(_dateRange.end)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateButtons() {
    final buttons = [
      ('Última semana', 7),
      ('Último mes', 30),
      ('3 meses', 90),
      ('Todo', -1),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: buttons.map((btn) {
        final label = btn.$1;
        final days = btn.$2;
        return ActionChip(
          label: Text(
            label,
            style: GoogleFonts.montserrat(fontSize: 11),
          ),
          onPressed: () => _setQuickDateRange(days),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        );
      }).toList(),
    );
  }

  Widget _buildExerciseSelector() {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle todos/seleccionar
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: scheme.outline),
          ),
          child: Column(
            children: [
              RadioListTile<bool>(
                title: Text(
                  'Todos los ejercicios',
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                value: true,
                groupValue: _allExercisesSelected,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _allExercisesSelected = value!);
                },
                activeColor: scheme.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                dense: true,
              ),
              const Divider(height: 1),
              RadioListTile<bool>(
                title: Text(
                  'Seleccionar ejercicios específicos',
                  style: GoogleFonts.montserrat(fontSize: 14),
                ),
                value: false,
                groupValue: _allExercisesSelected,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() => _allExercisesSelected = value!);
                },
                activeColor: scheme.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                dense: true,
              ),
            ],
          ),
        ),

        // Selector de ejercicios específicos
        if (!_allExercisesSelected) ...[
          const SizedBox(height: 12),
          // Buscador
          TextField(
            controller: _exerciseSearchController,
            onChanged: (value) => setState(() => _exerciseSearchQuery = value),
            style: GoogleFonts.montserrat(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar ejercicio...',
              hintStyle: GoogleFonts.montserrat(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
              ),
              prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
              suffixIcon: _exerciseSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _exerciseSearchController.clear();
                        setState(() => _exerciseSearchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: scheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: scheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: scheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: scheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(height: 8),

          // Contador seleccionados
          if (_selectedExercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${_selectedExercises.length} ejercicio(s) seleccionado(s)',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Lista de ejercicios
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: scheme.outline),
            ),
            child: _availableExercises.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableExercises.where((e) {
                      if (_exerciseSearchQuery.isEmpty) return true;
                      return e
                          .toLowerCase()
                          .contains(_exerciseSearchQuery.toLowerCase());
                    }).length,
                    itemBuilder: (context, index) {
                      final filtered = _availableExercises.where((e) {
                        if (_exerciseSearchQuery.isEmpty) return true;
                        return e
                            .toLowerCase()
                            .contains(_exerciseSearchQuery.toLowerCase());
                      }).toList();
                      final exercise = filtered[index];
                      final isSelected = _selectedExercises.contains(exercise);

                      return CheckboxListTile(
                        title: Text(
                          exercise,
                          style: GoogleFonts.montserrat(fontSize: 13),
                        ),
                        value: isSelected,
                        onChanged: (value) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (value!) {
                              _selectedExercises.add(exercise);
                            } else {
                              _selectedExercises.remove(exercise);
                            }
                          });
                        },
                        activeColor: scheme.primary,
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildColumnSelector() {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: CsvExportService.availableColumns.map((column) {
        final isSelected = _selectedColumns.contains(column.key);
        return FilterChip(
          label: Text(
            column.label,
            style: GoogleFonts.montserrat(fontSize: 12),
          ),
          selected: isSelected,
          onSelected: (selected) {
            HapticFeedback.selectionClick();
            setState(() {
              if (selected) {
                _selectedColumns.add(column.key);
              } else if (_selectedColumns.length > 1) {
                _selectedColumns.remove(column.key);
              }
            });
          },
          selectedColor: scheme.primary.withValues(alpha: 0.2),
          checkmarkColor: scheme.primary,
          side: BorderSide(
            color: isSelected ? scheme.primary : scheme.outline,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreview() {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<List<String>>>(
      future: _buildPreviewData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: scheme.outline),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: scheme.outline),
            ),
            child: Text(
              'No hay datos para mostrar en el rango seleccionado',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final headers = data.first;
        final rows = data.skip(1).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: scheme.outline),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      scheme.surface.withValues(alpha: 0.5),
                    ),
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 40,
                    horizontalMargin: 12,
                    columnSpacing: 16,
                    columns: headers
                        .map((h) => DataColumn(
                              label: Text(
                                h,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ))
                        .toList(),
                    rows: rows
                        .map((row) => DataRow(
                              cells: row
                                  .map((cell) => DataCell(
                                        Text(
                                          cell,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<int>(
              future: _getTotalRowCount(),
              builder: (context, countSnapshot) {
                final count = countSnapshot.data ?? 0;
                return Text(
                  rows.length < count
                      ? 'Mostrando ${rows.length} de $count filas'
                      : 'Total: $count filas',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<List<String>>> _buildPreviewData() async {
    try {
      final sessions = await _loadSessionsForExport();
      final exportData = CsvExportService.convertSessionsToExportData(
        sessions,
        exerciseFilter: _allExercisesSelected ? null : _selectedExercises,
      );

      if (exportData.isEmpty) return [];

      return CsvExportService.generatePreview(
        sessions: exportData,
        columns: _selectedColumns,
        maxRows: 5,
      );
    } catch (e) {
      return [];
    }
  }

  Future<int> _getTotalRowCount() async {
    try {
      final sessions = await _loadSessionsForExport();
      final exportData = CsvExportService.convertSessionsToExportData(
        sessions,
        exerciseFilter: _allExercisesSelected ? null : _selectedExercises,
      );
      return CsvExportService.countTotalRows(exportData);
    } catch (e) {
      return 0;
    }
  }

  Widget _buildActionButtons() {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _exportAndShare,
            icon: const Icon(Icons.share),
            label: Text(
              'EXPORTAR Y COMPARTIR',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _saveToDownloads,
            icon: const Icon(Icons.download),
            label: Text(
              'GUARDAR EN DESCARGAS',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: scheme.onSurface,
              side: BorderSide(color: scheme.outline),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🆕 BACKUP JSON COMPLETO
  Widget _buildBackupSection(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.backup, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup JSON Completo',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      'Incluye: rutinas, sesiones, notas, perfiles',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _exportFullBackup,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('GENERAR Y COMPARTIR BACKUP'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportFullBackup() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(trainingRepositoryProvider);
      final backupService = BackupService(repo);
      await backupService.shareBackup();
    } catch (e) {
      _showError('Error al generar backup: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🆕 IMPORTAR DATOS
  Widget _buildImportSection(ColorScheme scheme) {
    return Column(
      children: [
        // Importar desde JSON
        _buildImportCard(
          scheme: scheme,
          icon: Icons.restore,
          title: 'Restaurar desde Backup',
          subtitle: 'Importar archivo JSON de Juan Tracker',
          color: scheme.secondary,
          onTap: _importFromJson,
        ),
        const SizedBox(height: 12),
        // Importar desde Strong.app
        _buildImportCard(
          scheme: scheme,
          icon: Icons.fitness_center,
          title: 'Importar de Strong.app',
          subtitle: 'Importar CSV exportado de Strong',
          color: Colors.orange,
          onTap: _importFromStrong,
        ),
      ],
    );
  }

  Widget _buildImportCard({
    required ColorScheme scheme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromJson() async {
    HapticFeedback.selectionClick();
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final content = await _pickFileContent(allowedExtensions: ['json']);
      if (content == null) return;

      final repo = ref.read(trainingRepositoryProvider);
      final backupService = BackupService(repo);
      final result = await backupService.importFromJson(content);

      if (!context.mounted) return;

      if (result.success) {
        _showSuccess(_buildImportSummary(result));
        await _loadAvailableExercises();
      } else {
        _showError('Error al importar: ${result.error}');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showError('Error al importar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importFromStrong() async {
    HapticFeedback.selectionClick();
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final content = await _pickFileContent(allowedExtensions: ['csv']);
      if (content == null) return;

      final repo = ref.read(trainingRepositoryProvider);
      final backupService = BackupService(repo);
      final result = await backupService.importFromStrongApp(content);

      if (!context.mounted) return;

      if (result.success) {
        _showSuccess(_buildImportSummary(result));
        await _loadAvailableExercises();
      } else {
        _showError('Error al importar: ${result.error}');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showError('Error al importar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}


