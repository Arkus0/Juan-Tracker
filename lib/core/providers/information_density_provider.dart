import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modos de densidad de información para la UI
enum DensityMode { compact, comfortable, detailed }

/// Provider global de densidad de información
final informationDensityProvider = NotifierProvider<InformationDensityNotifier, DensityMode>(
  InformationDensityNotifier.new,
);

/// Notifier que maneja el modo de densidad con persistencia
class InformationDensityNotifier extends Notifier<DensityMode> {
  static const _key = 'information_density_mode';

  @override
   DensityMode build() {
    _loadPreference();
    return DensityMode.comfortable;
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      try {
        state = DensityMode.values.byName(value);
      } catch (_) {
        state = DensityMode.comfortable;
      }
    }
  }

  Future<void> setMode(DensityMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  /// Toggle al siguiente modo (compact -> comfortable -> detailed -> compact)
  Future<void> toggleMode() async {
    final nextMode = switch (state) {
      DensityMode.compact => DensityMode.comfortable,
      DensityMode.comfortable => DensityMode.detailed,
      DensityMode.detailed => DensityMode.compact,
    };
    await setMode(nextMode);
  }
}

/// Valores de diseño según el modo de densidad
class DensityValues {
  final double cardPadding;
  final double cardMargin;
  final double listTilePadding;
  final double fontSizeOffset;
  final double iconSize;
  final bool dense;
  final double rowHeight;
  final double horizontalPadding;
  final double inputHeight;

  const DensityValues({
    required this.cardPadding,
    required this.cardMargin,
    required this.listTilePadding,
    required this.fontSizeOffset,
    required this.iconSize,
    required this.dense,
    required this.rowHeight,
    required this.horizontalPadding,
    required this.inputHeight,
  });

  factory DensityValues.forMode(DensityMode mode) {
    return switch (mode) {
      DensityMode.compact => const DensityValues(
          cardPadding: 8,
          cardMargin: 4,
          listTilePadding: 4,
          fontSizeOffset: -1,
          iconSize: 20,
          dense: true,
          rowHeight: 48,
          horizontalPadding: 8,
          inputHeight: 56,
        ),
      DensityMode.comfortable => const DensityValues(
          cardPadding: 16,
          cardMargin: 12,
          listTilePadding: 12,
          fontSizeOffset: 0,
          iconSize: 24,
          dense: false,
          rowHeight: 64,
          horizontalPadding: 12,
          inputHeight: 72,
        ),
      DensityMode.detailed => const DensityValues(
          cardPadding: 20,
          cardMargin: 16,
          listTilePadding: 16,
          fontSizeOffset: 1,
          iconSize: 28,
          dense: false,
          rowHeight: 72,
          horizontalPadding: 16,
          inputHeight: 80,
        ),
    };
  }

  /// Obtiene el nombre localizado del modo
  static String modeName(DensityMode mode) => switch (mode) {
        DensityMode.compact => 'Compacta',
        DensityMode.comfortable => 'Cómoda',
        DensityMode.detailed => 'Detallada',
      };

  /// Obtiene la descripción localizada del modo
  static String modeDescription(DensityMode mode) => switch (mode) {
        DensityMode.compact => 'Más datos en pantalla, ideal para gym',
        DensityMode.comfortable => 'Equilibrio entre espacio e información',
        DensityMode.detailed => 'Más espaciado, hints adicionales',
      };

  /// Obtiene el icono del modo
  static String modeIcon(DensityMode mode) => switch (mode) {
        DensityMode.compact => 'view_compact',
        DensityMode.comfortable => 'view_comfy',
        DensityMode.detailed => 'view_agenda',
      };
}
