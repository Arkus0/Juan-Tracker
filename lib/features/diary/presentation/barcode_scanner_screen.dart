import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Pantalla para escanear códigos de barras usando la cámara
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _hasScanned = false;
  bool _isFlashOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code != null && code.isNotEmpty) {
      setState(() => _hasScanned = true);
      
      // Pequeño delay para mostrar el éxito antes de volver
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.of(context).pop(code);
        }
      });
    }
  }

  void _toggleFlash() async {
    await _controller.toggleTorch();
    setState(() => _isFlashOn = !_isFlashOn);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código de barras'),
        centerTitle: true,
        actions: [
          // Botón de flash
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
          ),
          // Botón de cambiar cámara
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Vista de la cámara
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al acceder a la cámara',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.errorDetails?.message ?? 'Error desconocido',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('VOLVER'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Overlay con el recuadro de escaneo
          CustomPaint(
            size: Size.infinite,
            painter: _ScannerOverlay(
              borderColor: _hasScanned ? Colors.green : colorScheme.primary,
            ),
          ),

          // Indicador de escaneo exitoso
          if (_hasScanned)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '¡Código detectado!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Instrucciones en la parte inferior
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Centra el código de barras en el recuadro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botón para entrada manual
                  ElevatedButton.icon(
                    onPressed: () {
                      _controller.stop();
                      _showManualInputDialog();
                    },
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Introducir manualmente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();

    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Código de barras'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Número del código',
            hintText: 'Ej: 8410000000000',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.isNotEmpty) {
                Navigator.of(ctx).pop(code);
              }
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    ).then((code) {
      controller.dispose();
      if (code != null && mounted) {
        Navigator.of(context).pop(code);
      } else {
        // Reanudar el scanner si canceló
        _controller.start();
        setState(() => _hasScanned = false);
      }
    });
  }
}

/// Pintor personalizado para el overlay del scanner
class _ScannerOverlay extends CustomPainter {
  final Color borderColor;

  _ScannerOverlay({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanAreaSize = size.width * 0.7;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = size.height * 0.3;
    final scanAreaRect = Rect.fromLTWH(
      scanAreaLeft,
      scanAreaTop,
      scanAreaSize,
      scanAreaSize * 0.6,
    );

    // Dibujar el fondo oscuro con el hueco del scanner
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scanAreaRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Dibujar el borde del recuadro
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Esquinas del recuadro
    const cornerLength = 30.0;
    
    // Esquina superior izquierda
    canvas.drawLine(
      Offset(scanAreaRect.left, scanAreaRect.top + cornerLength),
      Offset(scanAreaRect.left, scanAreaRect.top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRect.left, scanAreaRect.top),
      Offset(scanAreaRect.left + cornerLength, scanAreaRect.top),
      borderPaint,
    );

    // Esquina superior derecha
    canvas.drawLine(
      Offset(scanAreaRect.right - cornerLength, scanAreaRect.top),
      Offset(scanAreaRect.right, scanAreaRect.top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRect.right, scanAreaRect.top),
      Offset(scanAreaRect.right, scanAreaRect.top + cornerLength),
      borderPaint,
    );

    // Esquina inferior izquierda
    canvas.drawLine(
      Offset(scanAreaRect.left, scanAreaRect.bottom - cornerLength),
      Offset(scanAreaRect.left, scanAreaRect.bottom),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRect.left, scanAreaRect.bottom),
      Offset(scanAreaRect.left + cornerLength, scanAreaRect.bottom),
      borderPaint,
    );

    // Esquina inferior derecha
    canvas.drawLine(
      Offset(scanAreaRect.right - cornerLength, scanAreaRect.bottom),
      Offset(scanAreaRect.right, scanAreaRect.bottom),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanAreaRect.right, scanAreaRect.bottom),
      Offset(scanAreaRect.right, scanAreaRect.bottom - cornerLength),
      borderPaint,
    );

    // Línea de scan animada (simplificada)
    final scanLinePaint = Paint()
      ..color = borderColor.withAlpha(128)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(scanAreaRect.left, scanAreaRect.center.dy),
      Offset(scanAreaRect.right, scanAreaRect.center.dy),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlay oldDelegate) {
    return oldDelegate.borderColor != borderColor;
  }
}
