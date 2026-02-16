import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/design_system.dart';

/// Tipo de captura para entrada de datos.
enum CaptureType { voice, ocr, text, manual }

extension CaptureTypeExtension on CaptureType {
  IconData get icon {
    switch (this) {
      case CaptureType.voice: return Icons.mic;
      case CaptureType.ocr: return Icons.photo_camera;
      case CaptureType.text: return Icons.keyboard;
      case CaptureType.manual: return Icons.touch_app;
    }
  }

  String get label {
    switch (this) {
      case CaptureType.voice: return 'Voz';
      case CaptureType.ocr: return 'Escanear';
      case CaptureType.text: return 'Texto';
      case CaptureType.manual: return 'Manual';
    }
  }

  Color get color {
    switch (this) {
      case CaptureType.voice: return AppColors.error;
      case CaptureType.ocr: return Colors.blue;
      case CaptureType.text: return Colors.purple;
      case CaptureType.manual: return Colors.green;
    }
  }
}

/// Botón híbrido de captura que permite elegir entre Voz, OCR, Texto o Manual.
///
/// Un solo tap para cambiar método, mantener pulsado para iniciar captura.
/// Diseñado para minimizar fricción en contexto de gimnasio.
class UnifiedCaptureButton extends StatefulWidget {
  final Function(CaptureType) onCapture;
  final CaptureType initialType;
  final bool showLabels;
  final double size;
  final bool disabled;

  const UnifiedCaptureButton({
    super.key,
    required this.onCapture,
    this.initialType = CaptureType.voice,
    this.showLabels = true,
    this.size = 60,
    this.disabled = false,
  });

  @override
  State<UnifiedCaptureButton> createState() => _UnifiedCaptureButtonState();
}

class _UnifiedCaptureButtonState extends State<UnifiedCaptureButton>
    with SingleTickerProviderStateMixin {
  late CaptureType _currentType;
  late AnimationController _expandController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    _expandController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) { _expandController.forward(); } else { _expandController.reverse(); }
    });
    try { HapticFeedback.selectionClick(); } catch (_) {}
  }

  void _selectType(CaptureType type) {
    setState(() { _currentType = type; _isExpanded = false; });
    _expandController.reverse();
    try { HapticFeedback.mediumImpact(); } catch (_) {}
    widget.onCapture(type);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    if (widget.disabled) {
      return _buildDisabledButton(onSurface);
    }

    return AnimatedBuilder(
      animation: _expandController,
      builder: (context, child) => _isExpanded ? _buildExpandedView(onSurface) : _buildCollapsedButton(onSurface),
    );
  }

  Widget _buildDisabledButton(Color onSurface) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.bgDeep, border: Border.all(color: AppColors.border)),
      child: Icon(_currentType.icon, color: onSurface.withAlpha(97), size: widget.size * 0.4),
    );
  }

  Widget _buildCollapsedButton(Color onSurface) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleExpand,
          onLongPress: () => widget.onCapture(_currentType),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _currentType.color.withValues(alpha: 0.15), border: Border.all(color: _currentType.color.withValues(alpha: 0.5))),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(_currentType.icon, color: _currentType.color, size: widget.size * 0.45),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.bgDeep, border: Border.all(color: _currentType.color, width: 1.5)),
                    child: Icon(Icons.expand_more, size: 10, color: _currentType.color),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.showLabels) ...[
          const SizedBox(height: 6),
          Text(_currentType.label, style: AppTypography.labelSmall.copyWith(color: _currentType.color)),
        ],
      ],
    );
  }

  Widget _buildExpandedView(Color onSurface) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: CaptureType.values.map((type) {
              final isSelected = type == _currentType;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => _selectType(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: widget.size * 0.9,
                    height: widget.size * 0.9,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? type.color.withValues(alpha: 0.3) : AppColors.bgDeep, border: Border.all(color: isSelected ? type.color : AppColors.border, width: isSelected ? 2 : 1)),
                    child: Icon(type.icon, color: isSelected ? type.color : onSurface.withAlpha(138), size: widget.size * 0.4),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _toggleExpand,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.bgDeep, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 12, color: onSurface.withAlpha(138)),
                  const SizedBox(width: 4),
                  Text('Cerrar', style: AppTypography.labelSmall.copyWith(color: onSurface.withAlpha(138))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector horizontal de método de captura.
///
/// Muestra todas las opciones en una fila para selección rápida.
class CaptureMethodSelector extends StatelessWidget {
  final CaptureType? selected;
  final Function(CaptureType) onSelect;
  final bool compact;

  const CaptureMethodSelector({
    super.key,
    this.selected,
    required this.onSelect,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: CaptureType.values.map((type) {
        final isSelected = type == selected;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
          child: GestureDetector(
            onTap: () {
              try { HapticFeedback.selectionClick(); } catch (_) {}
              onSelect(type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: compact ? 8 : 12),
              decoration: BoxDecoration(
                color: isSelected ? type.color.withValues(alpha: 0.2) : AppColors.bgDeep,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? type.color.withValues(alpha: 0.6) : AppColors.border, width: isSelected ? 2 : 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(type.icon, color: isSelected ? type.color : onSurface.withAlpha(138), size: compact ? 20 : 24),
                  if (!compact) ...[
                    const SizedBox(height: 4),
                    Text(type.label, style: AppTypography.labelSmall.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? type.color : onSurface.withAlpha(138))),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// FAB flotante para añadir con múltiples métodos.
class MultiCaptureFloatingButton extends StatefulWidget {
  final Function(CaptureType) onCapture;
  final CaptureType defaultType;

  const MultiCaptureFloatingButton({
    super.key,
    required this.onCapture,
    this.defaultType = CaptureType.voice,
  });

  @override
  State<MultiCaptureFloatingButton> createState() => _MultiCaptureFloatingButtonState();
}

class _MultiCaptureFloatingButtonState extends State<MultiCaptureFloatingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) { _controller.forward(); } else { _controller.reverse(); }
    });
    try { HapticFeedback.selectionClick(); } catch (_) {}
  }

  void _select(CaptureType type) {
    _toggle();
    widget.onCapture(type);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: CaptureType.values.reversed.map((type) {
              if (type == widget.defaultType) return const SizedBox.shrink();
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
                child: FadeTransition(
                  opacity: _controller,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(8)),
                          child: Text(type.label, style: AppTypography.bodyMedium.copyWith(color: onSurface.withAlpha(178))),
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton.small(
                          heroTag: 'fab_${type.name}',
                          backgroundColor: type.color,
                          onPressed: () => _select(type),
                          child: Icon(type.icon, color: onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        FloatingActionButton(
          heroTag: 'fab_main_capture',
          backgroundColor: _isExpanded ? AppColors.bgElevated : widget.defaultType.color,
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_isExpanded ? Icons.close : widget.defaultType.icon, color: onSurface),
          ),
        ),
      ],
    );
  }
}
