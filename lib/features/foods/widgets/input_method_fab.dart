import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// FAB expandible con metodos de entrada de alimentos.
class InputMethodFab extends StatefulWidget {
  final VoidCallback onManualAdd;
  final VoidCallback onVoiceInput;
  final VoidCallback onOcrScan;
  final VoidCallback onBarcodeScan;
  final bool isBusy;

  const InputMethodFab({
    super.key,
    required this.onManualAdd,
    required this.onVoiceInput,
    required this.onOcrScan,
    required this.onBarcodeScan,
    this.isBusy = false,
  });

  @override
  State<InputMethodFab> createState() => _InputMethodFabState();
}

class _InputMethodFabState extends State<InputMethodFab>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.isBusy) return;

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
        HapticFeedback.lightImpact();
      } else {
        _controller.reverse();
      }
    });
  }

  void _collapse() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEnabled = !widget.isBusy;

    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        if (_isExpanded)
          GestureDetector(
            onTap: _collapse,
            child: Container(
              color: colors.scrim.withAlpha((0.04 * 255).round()),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

        Positioned(
          bottom: 72,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildOption(
                label: 'Escanear barcode',
                icon: Icons.qr_code_scanner,
                containerColor: colors.secondaryContainer,
                foregroundColor: colors.onSecondaryContainer,
                onTap: () {
                  _collapse();
                  widget.onBarcodeScan();
                },
                delay: 0,
                enabled: isEnabled,
              ),
              _buildOption(
                label: 'Escanear etiqueta',
                icon: Icons.document_scanner,
                containerColor: colors.tertiaryContainer,
                foregroundColor: colors.onTertiaryContainer,
                onTap: () {
                  _collapse();
                  widget.onOcrScan();
                },
                delay: 1,
                enabled: isEnabled,
              ),
              _buildOption(
                label: 'Dictar con voz',
                icon: Icons.mic,
                containerColor: colors.errorContainer,
                foregroundColor: colors.onErrorContainer,
                onTap: () {
                  _collapse();
                  widget.onVoiceInput();
                },
                delay: 2,
                enabled: isEnabled,
              ),
              _buildOption(
                label: 'Anadir manual',
                icon: Icons.edit,
                containerColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                onTap: () {
                  _collapse();
                  widget.onManualAdd();
                },
                delay: 3,
                enabled: isEnabled,
              ),
            ],
          ),
        ),

        Tooltip(
          message: widget.isBusy
              ? 'Espera a que termine la accion actual'
              : (_isExpanded ? 'Cerrar acciones' : 'Abrir acciones rapidas'),
          child: FloatingActionButton(
            onPressed: isEnabled ? _toggle : null,
            elevation: _isExpanded ? 8 : 4,
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animation.value * 0.785,
                  child: Icon(_isExpanded ? Icons.close : Icons.add),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required String label,
    required IconData icon,
    required Color containerColor,
    required Color foregroundColor,
    required VoidCallback onTap,
    required int delay,
    required bool enabled,
  }) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final offset = (1 - _animation.value) * (delay * 10 + 20);
        final opacity = _animation.value;

        return Transform.translate(
          offset: Offset(0, offset),
          child: Opacity(
            opacity: opacity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: label,
                    child: Material(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(12),
                      elevation: enabled ? 4 : 1,
                      child: InkWell(
                        onTap: enabled ? onTap : null,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(icon, color: foregroundColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
