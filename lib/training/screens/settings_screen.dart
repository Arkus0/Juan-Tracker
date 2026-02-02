import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design_system/design_system.dart' as core show AppTypography, AppSpacing, AppRadius;
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/home_button.dart';
import '../../core/providers/information_density_provider.dart';
import '../providers/settings_provider.dart';
import '../services/media_control_service.dart';
import '../services/timer_notification_service.dart';
import '../utils/design_system.dart';
import 'export_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: HomeButton(),
        ),
        title: Text(
          'AJUSTES',
          style: core.AppTypography.headlineMedium,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(core.AppSpacing.lg),
        children: [
          // Sección Timer
          const _SectionHeader(title: 'TIMER DE DESCANSO'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.vibration,
            title: 'Vibración',
            subtitle: 'Vibrar en los últimos 10 segundos',
            trailing: Switch(
              value: settings.timerVibrationEnabled,
              onChanged: (value) =>
                  notifier.setTimerVibrationEnabled(value: value),
              activeThumbColor: AppColors.bloodRed,
            ),
          ),

          _SettingsTile(
            icon: Icons.volume_up,
            title: 'Sonido',
            subtitle: 'Beep en los últimos 3 segundos',
            trailing: Switch(
              value: settings.timerSoundEnabled,
              onChanged: (value) => notifier.setTimerSoundEnabled(value: value),
              activeThumbColor: AppColors.bloodRed,
            ),
          ),

          // 🎯 P1: Timer siempre auto-inicia - setting eliminado para reducir fricción
          _LockScreenTimerTile(
            isEnabled: settings.lockScreenTimerEnabled,
            onChanged: ({required bool value}) =>
                notifier.setLockScreenTimerEnabled(value: value),
          ),

          _SettingsTile(
            icon: Icons.timer,
            title: 'Descanso por defecto',
            subtitle: '${settings.defaultRestSeconds} segundos',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: settings.defaultRestSeconds > 10
                      ? () => notifier.setDefaultRestSeconds(
                          settings.defaultRestSeconds - 10,
                        )
                      : null,
                  color: AppColors.metalGray,
                ),
                Text(
                  '${settings.defaultRestSeconds}s',
                  style: core.AppTypography.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => notifier.setDefaultRestSeconds(
                    settings.defaultRestSeconds + 10,
                  ),
                  color: AppColors.bloodRed,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sección Control de Música
          const _SectionHeader(title: 'CONTROL DE MÚSICA'),
          const SizedBox(height: 8),

          const _MusicControlTile(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Controla la música de Spotify u otras apps sin salir del entrenamiento. '
              'Requiere permiso de acceso a notificaciones.',
              style: core.AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sección Entrada de Datos
          const _SectionHeader(title: 'ENTRADA DE DATOS'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.touch_app,
            title: 'Modo entrada rápida',
            subtitle: 'Modal numpad grande al tocar KG/REPS',
            trailing: Switch(
              value: settings.useFocusedInputMode,
              onChanged: (value) =>
                  notifier.setUseFocusedInputMode(value: value),
              activeThumbColor: AppColors.completedGreen,
            ),
          ),

          _SettingsTile(
            icon: Icons.center_focus_strong,
            title: 'Autofocus',
            subtitle: 'Enfocar automáticamente el input de peso/reps',
            trailing: Switch(
              value: settings.autofocusEnabled,
              onChanged: (value) =>
                  notifier.setAutofocusEnabled(value: value),
              activeThumbColor: AppColors.completedGreen,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Optimizado para gimnasio: botones grandes, contexto visible, auto-completado. Desactiva autofocus si prefieres control manual.',
              style: core.AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sección Visualización
          const _SectionHeader(title: 'VISUALIZACIÓN'),
          const SizedBox(height: 8),

          const _DensityModeTile(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Modo compacto: más ejercicios visibles en pantalla. Ideal para gimnasio con poca luz.',
              style: core.AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sección Superseries
          const _SectionHeader(title: 'SUPERSERIES'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.link,
            title: 'Indicador de superset',
            subtitle: 'Mostrar badge cuando ejercicio está en superset',
            trailing: Switch(
              value: settings.showSupersetIndicator,
              onChanged: (value) =>
                  notifier.setShowSupersetIndicator(value: value),
              activeThumbColor: AppColors.bloodRed,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'En superseries, el timer solo inicia después del último ejercicio del grupo.',
              style: core.AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sección Rendimiento
          const _SectionHeader(title: 'RENDIMIENTO'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.speed,
            title: 'Modo máximo rendimiento',
            subtitle: 'Reduce animaciones y vibraciones',
            trailing: Switch(
              value: settings.performanceModeEnabled,
              onChanged: (value) =>
                  notifier.setPerformanceModeEnabled(value: value),
              activeThumbColor: AppColors.completedGreen,
            ),
          ),

          if (!settings.performanceModeEnabled) ...[
            _SettingsTile(
              icon: Icons.animation,
              title: 'Reducir animaciones',
              subtitle: 'Desactiva sombras y transiciones',
              trailing: Switch(
                value: settings.reduceAnimations,
                onChanged: (value) =>
                    notifier.setReduceAnimations(value: value),
                activeThumbColor: AppColors.bloodRed,
              ),
            ),
            _SettingsTile(
              icon: Icons.vibration,
              title: 'Reducir vibraciones',
              subtitle: 'Solo vibraciones esenciales',
              trailing: Switch(
                value: settings.reduceVibrations,
                onChanged: (value) =>
                    notifier.setReduceVibrations(value: value),
                activeThumbColor: AppColors.bloodRed,
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'El modo debug de VS Code es ~10x más lento que release. '
              'Para probar rendimiento real: flutter run --release',
              style: core.AppTypography.bodySmall.copyWith(
                color: AppColors.copperOrange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sección Almacenamiento
          const _SectionHeader(title: 'ALMACENAMIENTO'),
          const SizedBox(height: 8),

          _StorageTile(),

          const SizedBox(height: 24),

          // Sección Datos
          const _SectionHeader(title: 'DATOS'),
          const SizedBox(height: 8),

          _SettingsTile(
            icon: Icons.download_rounded,
            title: 'Exportar datos',
            subtitle: 'Exporta tu historial a CSV',
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 18),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExportScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Sección Guías / Ayuda
          const _SectionHeader(title: 'CÓMO FUNCIONA'),
          const SizedBox(height: 8),

          _GuideTile(
            icon: Icons.mic,
            title: 'Entrada por voz',
            subtitle: 'Dicta ejercicios, series y pesos',
            onTap: () => _showGuideDialog(
              context,
              icon: Icons.mic,
              title: 'Entrada por voz',
              bullets: [
                'Di el nombre del ejercicio y se buscará automáticamente',
                'Puedes dictar peso y repeticiones: "80 kilos, 10 reps"',
                'Si no entiende bien, te pedirá confirmar',
                'Funciona mejor en entornos sin mucho ruido',
                'Mantén pulsado el botón de micrófono para hablar',
              ],
            ),
          ),

          _GuideTile(
            icon: Icons.document_scanner,
            title: 'Importar con cámara (OCR)',
            subtitle: 'Escanea rutinas escritas o impresas',
            onTap: () => _showGuideDialog(
              context,
              icon: Icons.document_scanner,
              title: 'Importar con cámara',
              bullets: [
                'Toma foto de una rutina escrita o impresa',
                'La app intentará reconocer ejercicios y series',
                'Siempre te mostrará una previsualización para revisar',
                'Puedes editar cualquier error antes de guardar',
                'Funciona mejor con texto claro y bien iluminado',
              ],
            ),
          ),

          _GuideTile(
            icon: Icons.help_outline,
            title: 'Por qué pide confirmar',
            subtitle: 'Entendiendo las confirmaciones',
            onTap: () => _showGuideDialog(
              context,
              icon: Icons.help_outline,
              title: 'Por qué pide confirmar',
              bullets: [
                'La voz y el OCR no son 100% precisos',
                'Cuando la app no está segura, te pide confirmar',
                'Esto evita errores silenciosos en tu registro',
                'Es mejor confirmar que arreglar después',
                'Con el tiempo, la app aprende de tus ejercicios',
              ],
            ),
          ),

          _GuideTile(
            icon: Icons.trending_up,
            title: 'Progresión automática',
            subtitle: 'Cómo aumenta el peso automáticamente',
            onTap: () => _showGuideDialog(
              context,
              icon: Icons.trending_up,
              title: 'Progresión automática',
              bullets: [
                'Puedes configurar progresión por ejercicio',
                'Cuando completas todas las series, sube el peso',
                'Tipos: lineal (+2.5kg), doble progresión, % 1RM',
                'La progresión se aplica en la siguiente sesión',
                'Puedes desactivarla en cualquier momento',
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Info de la app
          const _SectionHeader(title: 'INFORMACIÓN'),
          const SizedBox(height: 8),

          const _SettingsTile(
            icon: Icons.info_outline,
            title: 'Juan Training',
            subtitle: 'Versión 1.0.0',
            trailing: null,
          ),

          const SizedBox(height: 40),

          // Créditos
          Center(
            child: Text(
              '💪 Hecho para el gym',
              style: core.AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8),
      child: Text(
        title,
        style: core.AppTypography.labelLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(core.AppRadius.md),
      ),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.onSurface.withAlpha(178)),
        title: Text(
          title,
          style: core.AppTypography.titleLarge.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: core.AppTypography.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

/// Widget para mostrar y gestionar almacenamiento
class _StorageTile extends StatefulWidget {
  @override
  State<_StorageTile> createState() => _StorageTileState();
}

class _StorageTileState extends State<_StorageTile> {
  String _storageInfo = 'No disponible';

  @override
  void initState() {
    super.initState();
    _storageInfo = kIsWeb
        ? 'No disponible en web'
        : 'Gestión de caché pendiente';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(core.AppRadius.md),
      ),
      child: ListTile(
        leading: Icon(Icons.storage, color: colorScheme.onSurface.withAlpha(178)),
        title: Text(
          'Caché de imágenes',
          style: core.AppTypography.titleLarge.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          _storageInfo,
          style: core.AppTypography.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: TextButton(
          onPressed: null,
          child: Text(
            'Limpiar',
            style: core.AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

/// Tile para timer en lock screen con solicitud de permisos
class _LockScreenTimerTile extends StatefulWidget {
  final bool isEnabled;
  final Future<void> Function({required bool value}) onChanged;

  const _LockScreenTimerTile({
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  State<_LockScreenTimerTile> createState() => _LockScreenTimerTileState();
}

class _LockScreenTimerTileState extends State<_LockScreenTimerTile> {
  bool _hasPermission = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() => _isChecking = true);
    try {
      final hasPermission = await TimerNotificationService.instance
          .areNotificationsEnabled();
      if (mounted) {
        setState(() {
          _hasPermission = hasPermission;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _handleToggle({required bool value}) async {
    if (value && !_hasPermission) {
      // Solicitar permiso primero
      HapticFeedback.mediumImpact();
      final granted = await TimerNotificationService.instance
          .requestPermissions();
      if (!mounted) return;

      if (!granted) {
        _showPermissionDeniedDialog();
        return;
      }

      setState(() => _hasPermission = true);
    }

    await widget.onChanged(value: value);
  }

  void _showPermissionDeniedDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHighest,
        title: Row(
          children: [
            Icon(Icons.notifications_off, color: Colors.orange[400]),
            const SizedBox(width: 12),
            Text(
              'Permiso necesario',
              style: core.AppTypography.titleLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Para ver el timer en la pantalla de bloqueo, la app necesita permiso para mostrar notificaciones.\n\n'
          'Ve a Ajustes del sistema > Apps > Juan Training > Notificaciones y actívalas.',
          style: core.AppTypography.bodyMedium.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Entendido',
              style: core.AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(core.AppRadius.md),
        border: !_hasPermission && widget.isEnabled
            ? Border.all(color: Colors.orange.withAlpha(128))
            : null,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.lock_clock,
              color: !_hasPermission && widget.isEnabled
                  ? Colors.orange[400]
                  : colorScheme.onSurface.withAlpha(178),
            ),
            title: Text(
              'Mostrar en pantalla de bloqueo',
              style: core.AppTypography.titleLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              _hasPermission || !widget.isEnabled
                  ? 'Ver y controlar el timer sin desbloquear'
                  : '⚠️ Permiso de notificaciones requerido',
              style: core.AppTypography.bodySmall.copyWith(
                color: !_hasPermission && widget.isEnabled
                    ? Colors.orange[400]
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: _isChecking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(
                    value: widget.isEnabled,
                    onChanged: (value) => _handleToggle(value: value),
                    activeThumbColor: Theme.of(context).colorScheme.primary,
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          ),
          // Botón para reintentar si no tiene permiso
          if (!_hasPermission && widget.isEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final granted = await TimerNotificationService.instance
                        .requestPermissions();
                    if (!context.mounted) return;
                    if (granted) {
                      setState(() => _hasPermission = true);
                      if (mounted) {
                        AppSnackbar.show(
                          context,
                          message: '✓ Notificaciones activadas',
                        );
                      }
                    } else {
                      _showPermissionDeniedDialog();
                    }
                  },
                  icon: const Icon(Icons.notifications_active, size: 18),
                  label: Text(
                    'Activar notificaciones',
                    style: core.AppTypography.labelLarge,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[400],
                    side: BorderSide(color: Colors.orange[400]!),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tile para configuración de control de música
class _MusicControlTile extends StatefulWidget {
  const _MusicControlTile();

  @override
  State<_MusicControlTile> createState() => _MusicControlTileState();
}

class _MusicControlTileState extends State<_MusicControlTile> {
  bool _isChecking = false;
  bool _hasAccess = false;
  bool _isMusicActive = false;

  @override
  void initState() {
    super.initState();
    _checkMusicAccess();
  }

  Future<void> _checkMusicAccess() async {
    setState(() => _isChecking = true);
    try {
      final service = MediaControlService.instance;
      await service.initialize();

      // Verificar si puede detectar música
      final session = await service.getActiveSession();
      final isMusicActive = await service.isMusicActive();

      if (mounted) {
        setState(() {
          // Si puede obtener la sesión, tiene acceso completo
          _hasAccess = session.packageName != null || session.title != null;
          _isMusicActive = isMusicActive;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _showInstructionsDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHighest,
        title: Row(
          children: [
            Icon(Icons.music_note, color: Colors.cyan[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Habilitar control de música',
                style: core.AppTypography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Para controlar la música desde la app:',
              style: core.AppTypography.labelLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            const _InstructionStep(
              number: '1',
              text: 'Abre Ajustes del teléfono',
            ),
            const _InstructionStep(
              number: '2',
              text: 'Ve a Apps > Acceso especial',
            ),
            const _InstructionStep(
              number: '3',
              text: 'Toca "Acceso a notificaciones"',
            ),
            const _InstructionStep(number: '4', text: 'Activa "Juan Training"'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyan.withAlpha(26),
                borderRadius: BorderRadius.circular(core.AppRadius.sm),
                border: Border.all(color: Colors.cyan.withAlpha(77)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.cyan[400], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esto permite ver qué canción suena y controlala.',
                      style: core.AppTypography.bodySmall.copyWith(
                        color: Colors.cyan[300],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Entendido',
              style: core.AppTypography.labelLarge.copyWith(
                color: Colors.cyan[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(core.AppRadius.md),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              _hasAccess ? Icons.music_note : Icons.music_off,
              color: _hasAccess ? Colors.cyan[400] : colorScheme.onSurface.withAlpha(150),
            ),
            title: Text(
              'Control de música',
              style: core.AppTypography.titleLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              _isChecking
                  ? 'Verificando...'
                  : _hasAccess
                  ? '✓ Acceso habilitado${_isMusicActive ? " • Música detectada" : ""}'
                  : 'Acceso no configurado',
              style: core.AppTypography.bodySmall.copyWith(
                color: _hasAccess ? Colors.cyan[400] : colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: _isChecking
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _hasAccess ? Icons.check_circle : Icons.warning_amber,
                    color: _hasAccess ? Colors.cyan[400] : Colors.orange[400],
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          ),
          if (!_hasAccess && !_isChecking)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showInstructionsDialog,
                  icon: const Icon(Icons.settings, size: 18),
                  label: Text(
                    'Ver instrucciones',
                    style: core.AppTypography.labelLarge,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyan[400],
                    side: BorderSide(color: Colors.cyan[400]!),
                  ),
                ),
              ),
            ),
          if (_hasAccess && !_isChecking)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _checkMusicAccess,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(
                        'Actualizar',
                        style: core.AppTypography.bodySmall,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        await MediaControlService.instance.openSpotify();
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(
                        'Abrir Spotify',
                        style: core.AppTypography.bodySmall,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Paso de instrucción numerado
class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: core.AppTypography.labelLarge.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: core.AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECCIÓN DE GUÍAS / AYUDA
// ============================================================================

/// Tile para guías explicativas - abre un diálogo al tocar
class _GuideTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GuideTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(core.AppRadius.md),
      ),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.onSurface.withAlpha(178)),
        title: Text(
          title,
          style: core.AppTypography.titleLarge.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: core.AppTypography.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurface.withAlpha(150)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
      ),
    );
  }
}

/// Tile para seleccionar modo de densidad de información
class _DensityModeTile extends ConsumerWidget {
  const _DensityModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = ref.watch(informationDensityProvider);
    final notifier = ref.read(informationDensityProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(core.AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.view_compact,
                  color: colorScheme.onSurface.withAlpha(178),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Densidad de información',
                        style: core.AppTypography.titleLarge.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${DensityValues.modeName(density)}: ${DensityValues.modeDescription(density)}',
                        style: core.AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SegmentedButton<DensityMode>(
              segments: [
                ButtonSegment<DensityMode>(
                  value: DensityMode.compact,
                  label: Text(
                    'Compacta',
                    style: core.AppTypography.bodySmall,
                  ),
                  icon: Icon(Icons.view_compact, size: 18),
                ),
                ButtonSegment<DensityMode>(
                  value: DensityMode.comfortable,
                  label: Text(
                    'Cómoda',
                    style: core.AppTypography.bodySmall,
                  ),
                  icon: Icon(Icons.view_comfy, size: 18),
                ),
                ButtonSegment<DensityMode>(
                  value: DensityMode.detailed,
                  label: Text(
                    'Detallada',
                    style: core.AppTypography.bodySmall,
                  ),
                  icon: Icon(Icons.view_agenda, size: 18),
                ),
              ],
              selected: {density},
              onSelectionChanged: (Set<DensityMode> newSelection) {
                notifier.setMode(newSelection.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.bloodRed;
                    }
                    return Colors.transparent;
                  },
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                  (states) {
                    if (states.contains(WidgetState.selected)) {
                      return colorScheme.onSurface;
                    }
                    return colorScheme.onSurfaceVariant;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Muestra un diálogo de guía con icono, título y bullets
void _showGuideDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required List<String> bullets,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(core.AppRadius.lg)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bloodRed.withAlpha(38),
              borderRadius: BorderRadius.circular(core.AppRadius.sm),
            ),
            child: Icon(icon, color: AppColors.bloodRed, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: core.AppTypography.headlineSmall.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: bullets
            .map(
              (bullet) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.bloodRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bullet,
                        style: core.AppTypography.bodyMedium.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'ENTENDIDO',
            style: core.AppTypography.labelLarge.copyWith(
              color: AppColors.bloodRed,
            ),
          ),
        ),
      ],
    ),
  );
}
