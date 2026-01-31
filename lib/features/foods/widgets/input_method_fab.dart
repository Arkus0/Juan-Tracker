import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// FAB expandible con métodos de entrada de alimentos
/// 
/// Muestra opciones:
/// - Añadir manual
/// - Dictar con voz
/// - Escanear etiqueta
/// - Escanear barcode
class InputMethodFab extends StatefulWidget {
  final VoidCallback onManualAdd;
  final VoidCallback onVoiceInput;
  final VoidCallback onOcrScan;
  final VoidCallback onBarcodeScan;

  const InputMethodFab({
    super.key,
    required this.onManualAdd,
    required this.onVoiceInput,
    required this.onOcrScan,
    required this.onBarcodeScan,
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
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
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
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop para cerrar al tocar fuera
        if (_isExpanded)
          GestureDetector(
            onTap: _collapse,
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        
        // Opciones expandibles
        Padding(
          padding: const EdgeInsets.only(bottom: 80, right: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildOption(
                label: 'Escanear barcode',
                icon: Icons.qr_code_scanner,
                color: Colors.blue,
                onTap: () {
                  _collapse();
                  widget.onBarcodeScan();
                },
                delay: 0,
              ),
              _buildOption(
                label: 'Escanear etiqueta',
                icon: Icons.document_scanner,
                color: Colors.green,
                onTap: () {
                  _collapse();
                  widget.onOcrScan();
                },
                delay: 1,
              ),
              _buildOption(
                label: 'Dictar con voz',
                icon: Icons.mic,
                color: Colors.orange,
                onTap: () {
                  _collapse();
                  widget.onVoiceInput();
                },
                delay: 2,
              ),
              _buildOption(
                label: 'Añadir manual',
                icon: Icons.edit,
                color: Colors.purple,
                onTap: () {
                  _collapse();
                  widget.onManualAdd();
                },
                delay: 3,
              ),
            ],
          ),
        ),
        
        // FAB principal
        Padding(
          padding: const EdgeInsets.only(bottom: 16, right: 16),
          child: FloatingActionButton(
            onPressed: _toggle,
            elevation: _isExpanded ? 8 : 4,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animation.value * 0.785, // 45 grados
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
    required Color color,
    required VoidCallback onTap,
    required int delay,
  }) {
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
                  // Label
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).round()),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  
                  // Button
                  Material(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 4,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white),
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
