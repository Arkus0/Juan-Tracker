import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/deload_alerts_provider.dart';

/// 🎯 MED-005: Widget de alertas de deload/sobreentrenamiento
/// 
/// Muestra alertas cuando el usuario está estancado o en riesgo de sobreentrenamiento
class DeloadAlertsWidget extends ConsumerWidget {
  const DeloadAlertsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(deloadAlertsProvider);
    
    if (alerts.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'ALERTAS DE ENTRENAMIENTO',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...alerts.map((alert) => _AlertCard(alert: alert)),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final DeloadAlert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    
    final (icon, color) = switch (alert.severity) {
      AlertSeverity.critical => (Icons.warning_rounded, Colors.red),
      AlertSeverity.warning => (Icons.trending_flat, Colors.orange),
      AlertSeverity.info => (Icons.info_outline, Colors.blue),
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: color.withAlpha((0.1 * 255).round()),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.exerciseName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    alert.message,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.recommendation,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
