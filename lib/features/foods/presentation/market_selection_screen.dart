import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/market_providers.dart';

/// Pantalla de selección de mercado para el onboarding
/// 
/// Permite al usuario elegir entre diferentes mercados (España, USA, etc.)
/// para cargar la base de datos de alimentos correspondiente.
class MarketSelectionScreen extends ConsumerWidget {
  final VoidCallback onMarketSelected;

  const MarketSelectionScreen({
    super.key,
    required this.onMarketSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono/Ilustración
              Icon(
                Icons.public,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 32),

              // Título
              Text(
                'Elige tu región',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtítulo
              Text(
                'Selecciona tu mercado para cargar los productos más relevantes para tu zona.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Opciones de mercado
              _MarketCard(
                market: FoodMarket.spain,
                description: 'Productos de supermercados españoles y europeos',
                productCount: '~600,000',
                onTap: () => _selectMarket(ref, FoodMarket.spain),
              ),
              const SizedBox(height: 16),
              _MarketCard(
                market: FoodMarket.usa,
                description: 'Productos de supermercados estadounidenses',
                productCount: '~500,000',
                onTap: () => _selectMarket(ref, FoodMarket.usa),
              ),

              const SizedBox(height: 32),

              // Nota informativa
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Puedes cambiar esto más tarde en Ajustes. La descarga se realiza una sola vez.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectMarket(WidgetRef ref, FoodMarket market) async {
    await ref.read(selectedMarketProvider.notifier).setMarket(market);
    onMarketSelected();
  }
}

class _MarketCard extends StatelessWidget {
  final FoodMarket market;
  final String description;
  final String productCount;
  final VoidCallback onTap;

  const _MarketCard({
    required this.market,
    required this.description,
    required this.productCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Flag
              Text(
                market.flag,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      market.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        productCount,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
