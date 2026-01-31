import 'package:flutter/material.dart';

/// Estado vacío de búsqueda con opciones alternativas
/// 
/// Muestra mensaje motivacional y botones para:
/// - Añadir manual
/// - Dictar con voz
/// - Escanear etiqueta
/// - Escanear barcode
class SearchEmptyState extends StatelessWidget {
  final String? query;
  final VoidCallback onManualAdd;
  final VoidCallback onVoiceInput;
  final VoidCallback onOcrScan;
  final VoidCallback onBarcodeScan;

  const SearchEmptyState({
    super.key,
    this.query,
    required this.onManualAdd,
    required this.onVoiceInput,
    required this.onOcrScan,
    required this.onBarcodeScan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = query != null && query!.isNotEmpty;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono
            Icon(
              hasQuery ? Icons.search_off : Icons.restaurant_menu,
              size: 80,
              color: theme.colorScheme.primary.withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: 24),
            
            // Título
            Text(
              hasQuery ? 'No hay coincidencias locales' : 'Busca tus alimentos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Subtítulo
            Text(
              hasQuery
                  ? 'Prueba con voz, cámara o escanea el código de barras'
                  : 'Escribe el nombre, usa la voz, escanea una etiqueta o el código de barras',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            if (hasQuery) ...[
              const SizedBox(height: 8),
              Text(
                '"$query"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Botones de acción
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _ActionButton(
                  icon: Icons.mic,
                  label: 'Voz',
                  color: Colors.orange,
                  onTap: onVoiceInput,
                ),
                _ActionButton(
                  icon: Icons.document_scanner,
                  label: 'Cámara',
                  color: Colors.green,
                  onTap: onOcrScan,
                ),
                _ActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Barcode',
                  color: Colors.blue,
                  onTap: onBarcodeScan,
                ),
                _ActionButton(
                  icon: Icons.edit,
                  label: 'Manual',
                  color: Colors.purple,
                  onTap: onManualAdd,
                ),
              ],
            ),
            
            if (hasQuery) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onManualAdd,
                icon: const Icon(Icons.add_circle_outline),
                label: Text('Añadir "$query" manualmente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha((0.1 * 255).round()),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
