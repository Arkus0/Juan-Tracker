# QUICK_WINS_UX.md - Mejoras de Alto Impacto / Bajo Esfuerzo

> **Criterio de selección**: Cada item debe ser implementable en <2 horas
> **Objetivo**: Máximo impacto en percepción de usuario con mínimo esfuerzo de desarrollo

---

## Resumen de Quick Wins

| # | Nombre | Tiempo Est. | Impacto | Archivo Principal |
|---|--------|-------------|---------|-------------------|
| QW-01 | Conectar smartSuggestionProvider | 45 min | 🔴 Critical | entry_screen.dart |
| QW-02 | Invertir consumido→restante | 30 min | 🔴 Critical | diary_screen.dart |
| QW-03 | Snackbar duration consistency | 20 min | 🟡 Medium | Múltiples |
| QW-04 | Añadir "Última vez: X días" | 45 min | 🟠 High | train_selection_screen.dart |
| QW-05 | Progress ring en lugar de números | 1h | 🟠 High | entry_screen.dart |
| QW-06 | Copiar días semánticos | 30 min | 🟡 Medium | create_edit_routine_screen.dart |
| QW-07 | Empty state educativo | 45 min | 🟡 Medium | diary_screen.dart |
| QW-08 | Thumb zone reorganization | 1h | 🟡 Medium | entry_screen.dart |
| QW-09 | Welcome back toast | 30 min | 🟠 High | training_session_screen.dart |
| QW-10 | Color contrast fix macros | 20 min | 🟢 Low | diary_screen.dart |

---

## QW-01: Conectar smartSuggestionProvider a Entry Screen

**Tiempo**: 45 minutos
**Impacto**: 🔴 CRITICAL - Soluciona el issue más visible
**Archivo**: `lib/features/home/presentation/entry_screen.dart`

### Problema Actual
```dart
// entry_screen.dart:593-604
final stats = rutinasAsync.when(
  data: (rutinas) {
    // Siempre muestra hardcoded, incluso con rutinas
    return [
      const _Stat(icon: Icons.calendar_today, value: '—', label: 'Hoy'),
      const _Stat(icon: Icons.timer, value: '--', label: 'min'),
    ];
  },
```

### Solución
```dart
class _TrainingModeCard extends ConsumerWidget {
  final VoidCallback onTap;

  const _TrainingModeCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // CAMBIO: Usar smartSuggestionProvider en lugar de solo rutinasAsync
    final suggestionAsync = ref.watch(smartSuggestionProvider);

    final stats = suggestionAsync.when(
      data: (suggestion) {
        if (suggestion == null) {
          return [
            const _Stat(icon: Icons.calendar_today, value: 'Sin rutina', label: 'Config'),
            const _Stat(icon: Icons.timer, value: '--', label: 'min'),
          ];
        }
        return [
          _Stat(
            icon: Icons.fitness_center,
            value: suggestion.dayName,  // "Pecho" en lugar de "—"
            label: 'Hoy',
          ),
          _Stat(
            icon: Icons.history,
            value: _formatTimeSince(suggestion.timeSinceLastSession),
            label: 'última',
          ),
        ];
      },
      loading: () => [
        const _Stat(icon: Icons.calendar_today, value: '...', label: 'Hoy'),
        const _Stat(icon: Icons.timer, value: '--', label: 'min'),
      ],
      error: (e, _) => [
        const _Stat(icon: Icons.calendar_today, value: '—', label: 'Hoy'),
        const _Stat(icon: Icons.timer, value: '--', label: 'min'),
      ],
    );

    return _ModeCard(
      title: 'Entrenamiento',
      subtitle: stats[0].value != 'Sin rutina'
          ? 'Toca ${stats[0].value} hoy'  // Subtítulo dinámico
          : 'Sesiones, rutinas, análisis y progreso',
      // ... resto igual
    );
  }

  String _formatTimeSince(Duration? duration) {
    if (duration == null) return 'nuevo';
    final days = duration.inDays;
    if (days == 0) return 'hoy';
    if (days == 1) return 'ayer';
    return '${days}d';
  }
}
```

### Dependencia
Requiere que `SmartWorkoutSuggestion` incluya `timeSinceLastSession` (ver QW-04).

---

## QW-02: Invertir Consumido → Restante

**Tiempo**: 30 minutos
**Impacto**: 🔴 CRITICAL - Cambia el modelo mental de retrospectivo a prospectivo
**Archivo**: `lib/features/diary/presentation/diary_screen.dart`

### Problema Actual
```dart
// diary_screen.dart:449-454
Text(
  '${summary.consumed.kcal}',  // Muestra LO QUE COMIÓ
  style: AppTypography.dataLarge.copyWith(
    color: colors.primary,
  ),
),
```

### Solución
```dart
// Reemplazar sección de calorías en _DailySummaryCard
Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Te quedan',  // CAMBIO: Label prospectivo
            style: AppTypography.labelMedium.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                // CAMBIO: Mostrar restante como dato principal
                '${summary.progress.kcalRemaining ?? (summary.targets?.kcalTarget ?? 0) - summary.consumed.kcal}',
                style: AppTypography.dataLarge.copyWith(
                  color: _getRemainingColor(summary, colors),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kcal',
                style: AppTypography.dataSmall.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // CAMBIO: Mostrar consumido como secundario
          if (summary.hasTargets)
            Text(
              'Consumido: ${summary.consumed.kcal} / ${summary.targets!.kcalTarget}',
              style: AppTypography.labelSmall.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    ),
    // ... MacroDonut igual
  ],
),

// Helper para color según estado
Color _getRemainingColor(DaySummary summary, ColorScheme colors) {
  final remaining = summary.progress.kcalRemaining ?? 0;
  if (remaining < 0) return AppColors.error;  // Pasado
  if (remaining < 200) return AppColors.warning;  // Poco margen
  return colors.primary;  // OK
}
```

---

## QW-03: Snackbar Duration Consistency

**Tiempo**: 20 minutos
**Impacto**: 🟡 MEDIUM - Mejora percepción de consistencia
**Archivos**: Múltiples (buscar `showSnackBar`)

### Solución
Crear helper y reemplazar todas las instancias:

```dart
// En lib/core/widgets/app_snackbar.dart (nuevo archivo)

/// Snackbar consistente con duración y estilo unificado
class AppSnackbar {
  static const Duration defaultDuration = Duration(seconds: 3);
  static const Duration longDuration = Duration(seconds: 5);

  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = defaultDuration,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isError)
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
            if (!isError)
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
              )
            : null,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Snackbar con undo action
  static void showWithUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
  }) {
    show(
      context,
      message: message,
      actionLabel: 'DESHACER',
      onAction: onUndo,
      duration: longDuration,  // Más tiempo para undo
    );
  }
}
```

### Uso
```dart
// Antes
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Peso registrado')),
);

// Después
AppSnackbar.show(context, message: 'Peso registrado');
```

---

## QW-04: Añadir "Última vez: X días" a Sugerencia

**Tiempo**: 45 minutos
**Impacto**: 🟠 HIGH - Contexto crítico para decisión
**Archivo**: `lib/training/providers/training_provider.dart`

### Cambios en Modelo
```dart
// Extender SmartWorkoutSuggestion
class SmartWorkoutSuggestion {
  final Rutina rutina;
  final int dayIndex;
  final String dayName;
  final String reason;

  // NUEVOS CAMPOS
  final Duration? timeSinceLastSession;
  final DateTime? lastSessionDate;
  final bool isRestDay;

  const SmartWorkoutSuggestion({
    required this.rutina,
    required this.dayIndex,
    required this.dayName,
    required this.reason,
    this.timeSinceLastSession,
    this.lastSessionDate,
    this.isRestDay = false,
  });
}
```

### Cambios en Provider
```dart
final smartSuggestionProvider = FutureProvider<SmartWorkoutSuggestion?>((ref) async {
  // ... código existente ...

  if (lastSession != null && lastUsedRutina.dias.isNotEmpty) {
    final lastDayIndex = lastSession.dayIndex ?? -1;
    final totalDays = lastUsedRutina.dias.length;

    var nextDayIndex = (lastDayIndex + 1) % totalDays;
    // ... saltar días vacíos ...

    final nextDay = lastUsedRutina.dias[nextDayIndex];

    // NUEVO: Calcular tiempo desde última sesión
    final timeSince = DateTime.now().difference(lastSession.fecha);

    // NUEVO: Construir reason con contexto temporal
    String reason;
    if (timeSince.inDays == 0) {
      reason = 'Continúa tu rutina';
    } else if (timeSince.inDays == 1) {
      reason = 'Última sesión: ayer';
    } else if (timeSince.inDays <= 7) {
      reason = 'Última sesión: hace ${timeSince.inDays} días';
    } else {
      reason = '¡Retoma tu rutina! (${timeSince.inDays} días)';
    }

    return SmartWorkoutSuggestion(
      rutina: lastUsedRutina,
      dayIndex: nextDayIndex,
      dayName: nextDay.nombre,
      reason: reason,
      timeSinceLastSession: timeSince,  // NUEVO
      lastSessionDate: lastSession.fecha,  // NUEVO
    );
  }

  return null;
});
```

---

## QW-05: Progress Ring en Entry Screen

**Tiempo**: 1 hora
**Impacto**: 🟠 HIGH - Visualización inmediata del estado
**Archivo**: `lib/features/home/presentation/entry_screen.dart`

### Implementación
```dart
// Añadir widget de progress ring a _NutritionModeCard

class _NutritionModeCard extends ConsumerWidget {
  final VoidCallback onTap;

  const _NutritionModeCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(daySummaryProvider);
    final latestAsync = ref.watch(latestWeighInProvider);

    return summaryAsync.when(
      data: (summary) {
        final progress = summary.progress.kcalPercent ?? 0;

        return _ModeCard(
          title: 'Nutrición',
          subtitle: _getContextualSubtitle(summary),
          icon: Icons.restaurant_menu_rounded,
          gradientColors: [AppColors.primary, AppColors.primaryLight],
          // NUEVO: Progress indicator visual
          trailing: _MiniProgressRing(
            progress: progress,
            remaining: summary.progress.kcalRemaining ?? 0,
          ),
          stats: [
            _Stat(
              icon: Icons.local_fire_department,
              value: '${summary.progress.kcalRemaining ?? 0}',
              label: 'restantes',
            ),
            _Stat(
              icon: Icons.egg_alt,
              value: '${(summary.targets?.proteinTarget ?? 0) - summary.consumed.protein ~/ 1}g',
              label: 'proteína',
            ),
          ],
          onTap: onTap,
        );
      },
      loading: () => _buildLoadingCard(),
      error: (_, _) => _buildErrorCard(),
    );
  }

  String _getContextualSubtitle(DaySummary summary) {
    final remaining = summary.progress.kcalRemaining ?? 0;
    if (remaining < 0) return '¡Pasaste tu objetivo!';
    if (remaining < 200) return 'Casi llegas a tu objetivo';
    return 'Te quedan $remaining kcal';
  }
}

// Mini progress ring widget
class _MiniProgressRing extends StatelessWidget {
  final double progress;
  final int remaining;

  const _MiniProgressRing({
    required this.progress,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0, 1),
            strokeWidth: 4,
            backgroundColor: Colors.white.withAlpha(50),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 1 ? Colors.red : Colors.white,
            ),
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## QW-06: Sugerir Nombres Semánticos para Días

**Tiempo**: 30 minutos
**Impacto**: 🟡 MEDIUM - Guía al usuario hacia mejor nomenclatura
**Archivo**: `lib/training/screens/create_edit_routine_screen.dart`

### Implementación
Añadir sugerencias cuando el usuario crea un día:

```dart
// Sugerencias de nombres semánticos
const List<String> _suggestedDayNames = [
  'Pecho',
  'Espalda',
  'Pierna',
  'Hombros',
  'Brazos',
  'Full Body',
  'Upper',
  'Lower',
  'Push',
  'Pull',
  'Pecho & Tríceps',
  'Espalda & Bíceps',
  'Cuádriceps & Glúteos',
  'Isquios & Pantorrillas',
];

// En el diálogo de crear día
Widget _buildAddDayDialog(BuildContext context) {
  return AlertDialog(
    title: const Text('Nuevo Día'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _dayNameController,
          decoration: const InputDecoration(
            labelText: 'Nombre del día',
            hintText: 'Ej: Pecho & Tríceps',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Sugerencias:',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestedDayNames.take(8).map((name) {
            return ActionChip(
              label: Text(name),
              onPressed: () {
                _dayNameController.text = name;
              },
            );
          }).toList(),
        ),
      ],
    ),
    // ... actions
  );
}
```

---

## QW-07: Empty State Educativo

**Tiempo**: 45 minutos
**Impacto**: 🟡 MEDIUM - Mejora onboarding
**Archivo**: `lib/features/diary/presentation/diary_screen.dart`

### Antes
```dart
AppEmpty(
  icon: Icons.restaurant_menu_outlined,
  title: 'Sin entradas hoy',
  subtitle: 'Añade tu primera comida para empezar a trackear',
  actionLabel: 'AÑADIR COMIDA',
  onAction: () => _showAddEntry(context, ref, MealType.breakfast),
),
```

### Después
```dart
AppEmpty(
  icon: Icons.restaurant_menu_outlined,
  title: 'Registra tu primera comida',
  subtitle: 'Trackear lo que comes te ayuda a:\n'
      '• Alcanzar tus objetivos de proteína\n'
      '• Mantener tu déficit/superávit\n'
      '• Identificar patrones alimenticios',
  actionLabel: 'AÑADIR DESAYUNO',  // Más específico
  secondaryActionLabel: 'CONFIGURAR OBJETIVOS',  // Guía adicional
  onAction: () => _showAddEntry(context, ref, MealType.breakfast),
  onSecondaryAction: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TargetsScreen()),
  ),
),
```

---

## QW-08: Thumb Zone Reorganization

**Tiempo**: 1 hora
**Impacto**: 🟡 MEDIUM - Mejora ergonomía en uso con una mano
**Archivo**: `lib/features/home/presentation/entry_screen.dart`

### Cambio de Layout
Mover "Accesos Rápidos" al bottom de la pantalla:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          // Header con saludo (compacto)
          _buildHeader(),

          // Contenido principal con scroll
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Cards de modo
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _NutritionModeCard(onTap: () => _navigateToNutrition(context)),
                      const SizedBox(height: 16),
                      _TrainingModeCard(onTap: () => _navigateToTraining(context)),
                    ]),
                  ),
                ),
                // Streak counter
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const StreakCounter(),
                  ),
                ),
              ],
            ),
          ),

          // CAMBIO: Quick Actions fijos en bottom (thumb zone)
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: const _QuickActionsRow(),
          ),
        ],
      ),
    ),
  );
}
```

---

## QW-09: Welcome Back Toast para Sesión Activa

**Tiempo**: 30 minutos
**Impacto**: 🟠 HIGH - Recuperación de contexto
**Archivo**: `lib/training/screens/training_session_screen.dart`

### Implementación
```dart
class _TrainingSessionScreenState extends ConsumerState<TrainingSessionScreen> {
  @override
  void initState() {
    super.initState();

    // Mostrar toast de bienvenida si hay sesión restaurada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeBackIfNeeded();
    });
  }

  void _showWelcomeBackIfNeeded() {
    final session = ref.read(trainingSessionProvider);

    // Si la sesión empezó hace más de 5 minutos, mostrar contexto
    if (session.startTime != null) {
      final elapsed = DateTime.now().difference(session.startTime!);
      if (elapsed.inMinutes > 5) {
        _showWelcomeBackBanner(session, elapsed);
      }
    }
  }

  void _showWelcomeBackBanner(TrainingState session, Duration elapsed) {
    final completedSets = session.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.logs.where((l) => l.completed).length,
    );
    final totalSets = session.exercises.fold<int>(
      0,
      (sum, ex) => sum + ex.logs.length,
    );

    final nextSet = session.nextIncompleteSet;
    final currentExercise = nextSet != null
        ? session.exercises[nextSet.exerciseIndex].nombre
        : 'terminado';

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¡Bienvenido de vuelta!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Llevas ${elapsed.inMinutes} min | $completedSets/$totalSets series',
            ),
            if (nextSet != null)
              Text('Siguiente: $currentExercise (Serie ${nextSet.setIndex + 1})'),
          ],
        ),
        leading: const Icon(Icons.fitness_center, color: Colors.green),
        backgroundColor: Colors.green.withAlpha(30),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text('CONTINUAR'),
          ),
        ],
      ),
    );

    // Auto-dismiss después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }
}
```

---

## QW-10: Color Contrast Fix en Macros

**Tiempo**: 20 minutos
**Impacto**: 🟢 LOW - Accesibilidad
**Archivo**: `lib/features/diary/presentation/diary_screen.dart`

### Problema
Los colores de macros (rojo, amarillo, azul) pueden tener bajo contraste en modo claro.

### Solución
```dart
// En _MacroItem, usar colores con mejor contraste
class _MacroItem extends StatelessWidget {
  // ...

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    // CAMBIO: Colores adaptados al tema
    final adaptedColor = brightness == Brightness.light
        ? color.withAlpha(230)  // Más oscuro en light mode
        : color;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: adaptedColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ...
          ],
        ),
        // ...
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (progress ?? 0).clamp(0.0, 1.0),
            minHeight: 4,
            // CAMBIO: Background más visible
            backgroundColor: brightness == Brightness.light
                ? color.withAlpha(40)
                : color.withAlpha(50),
            valueColor: AlwaysStoppedAnimation<Color>(adaptedColor),
          ),
        ),
      ],
    );
  }
}
```

---

## Orden de Implementación Recomendado

```
Día 1 (2-3 horas):
├── QW-01: Conectar smartSuggestionProvider ⭐ Mayor impacto
├── QW-02: Invertir consumido→restante ⭐ Mayor impacto
└── QW-03: Snackbar consistency

Día 2 (2-3 horas):
├── QW-04: Añadir "Última vez: X días"
├── QW-09: Welcome back toast
└── QW-10: Color contrast fix

Día 3 (2-3 horas):
├── QW-05: Progress ring
├── QW-06: Sugerir nombres semánticos
└── QW-07: Empty state educativo

Día 4 (1-2 horas):
└── QW-08: Thumb zone reorganization
```

**Total estimado**: 8-11 horas para todos los quick wins.
**Impacto**: Resolución de 2 issues CRITICAL + 3 HIGH + mejoras de polish.

---

*Documento creado como parte de la auditoría UX - Enero 2026*
