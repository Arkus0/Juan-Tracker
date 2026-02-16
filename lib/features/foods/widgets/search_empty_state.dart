import 'package:flutter/material.dart';

/// Estado vacio de busqueda con alternativas de entrada.
class SearchEmptyState extends StatelessWidget {
  final String? query;
  final VoidCallback onManualAdd;
  final VoidCallback onVoiceInput;
  final VoidCallback onOcrScan;
  final VoidCallback onBarcodeScan;
  final VoidCallback? onSearchOnline;
  final bool isBusy;

  const SearchEmptyState({
    super.key,
    this.query,
    required this.onManualAdd,
    required this.onVoiceInput,
    required this.onOcrScan,
    required this.onBarcodeScan,
    this.onSearchOnline,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasQuery = query != null && query!.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasQuery ? Icons.search_off : Icons.restaurant_menu,
              size: 80,
              color: colors.primary.withAlpha((0.35 * 255).round()),
            ),
            const SizedBox(height: 24),
            Text(
              hasQuery ? 'No hay coincidencias locales' : 'Busca tus alimentos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasQuery
                  ? 'Puedes buscar en internet o usar otros metodos.'
                  : 'Escribe el nombre, usa voz, camara o codigo de barras.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasQuery) ...[
              const SizedBox(height: 8),
              Text(
                '"$query"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (hasQuery && onSearchOnline != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: isBusy ? null : onSearchOnline,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Buscar en Open Food Facts'),
                style: FilledButton.styleFrom(minimumSize: const Size(220, 48)),
              ),
              const SizedBox(height: 8),
              Text(
                'Requiere conexion a internet',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (hasQuery)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: colors.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'o usa otros metodos',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: colors.outlineVariant)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _ActionButton(
                  icon: Icons.mic,
                  label: 'Voz',
                  bgColor: colors.errorContainer,
                  fgColor: colors.onErrorContainer,
                  onTap: onVoiceInput,
                  enabled: !isBusy,
                ),
                _ActionButton(
                  icon: Icons.document_scanner,
                  label: 'Camara',
                  bgColor: colors.tertiaryContainer,
                  fgColor: colors.onTertiaryContainer,
                  onTap: onOcrScan,
                  enabled: !isBusy,
                ),
                _ActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Barcode',
                  bgColor: colors.secondaryContainer,
                  fgColor: colors.onSecondaryContainer,
                  onTap: onBarcodeScan,
                  enabled: !isBusy,
                ),
                _ActionButton(
                  icon: Icons.edit,
                  label: 'Manual',
                  bgColor: colors.primaryContainer,
                  fgColor: colors.onPrimaryContainer,
                  onTap: onManualAdd,
                  enabled: !isBusy,
                ),
              ],
            ),
            if (isBusy) ...[
              const SizedBox(height: 16),
              Text(
                'Procesando accion actual...',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
            if (hasQuery) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: isBusy ? null : onManualAdd,
                icon: const Icon(Icons.add_circle_outline),
                label: Text('Anadir "$query" manualmente'),
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
  final Color bgColor;
  final Color fgColor;
  final VoidCallback onTap;
  final bool enabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: bgColor.withAlpha((0.65 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: fgColor, size: 28),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
