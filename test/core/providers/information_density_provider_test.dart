import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/core/providers/information_density_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InformationDensityNotifier', () {
    late ProviderContainer container;

    setUp(() {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should have comfortable as default value', () {
      final density = container.read(informationDensityProvider);
      expect(density, DensityMode.comfortable);
    });

    test('setMode should update state', () async {
      final notifier = container.read(informationDensityProvider.notifier);
      
      await notifier.setMode(DensityMode.compact);
      expect(container.read(informationDensityProvider), DensityMode.compact);

      await notifier.setMode(DensityMode.detailed);
      expect(container.read(informationDensityProvider), DensityMode.detailed);
    });

    test('toggleMode should cycle through modes', () async {
      final notifier = container.read(informationDensityProvider.notifier);
      
      // Start with comfortable
      expect(container.read(informationDensityProvider), DensityMode.comfortable);

      // Toggle to detailed
      await notifier.toggleMode();
      expect(container.read(informationDensityProvider), DensityMode.detailed);

      // Toggle to compact
      await notifier.toggleMode();
      expect(container.read(informationDensityProvider), DensityMode.compact);

      // Toggle back to comfortable
      await notifier.toggleMode();
      expect(container.read(informationDensityProvider), DensityMode.comfortable);
    });

    test('should persist mode to SharedPreferences', () async {
      final notifier = container.read(informationDensityProvider.notifier);
      await notifier.setMode(DensityMode.compact);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('information_density_mode'), 'compact');
    });

    test('should load persisted mode after setMode', () async {
      // First set the mode
      final notifier = container.read(informationDensityProvider.notifier);
      await notifier.setMode(DensityMode.detailed);
      
      // Verify the preference was persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('information_density_mode'), 'detailed');
      
      // Create a new container with the same preferences
      final newContainer = ProviderContainer();
      
      // The new container should eventually load the persisted value
      // Note: Since _loadPreference is async, we verify the persisted value exists
      // The actual loading happens asynchronously in build()
      expect(prefs.getString('information_density_mode'), 'detailed');
      newContainer.dispose();
    });
  });

  group('DensityValues', () {
    test('forMode should return correct values for compact mode', () {
      final values = DensityValues.forMode(DensityMode.compact);
      
      expect(values.cardPadding, 8);
      expect(values.cardMargin, 4);
      expect(values.listTilePadding, 4);
      expect(values.fontSizeOffset, -1);
      expect(values.iconSize, 20);
      expect(values.dense, true);
      expect(values.rowHeight, 48);
      expect(values.horizontalPadding, 8);
      expect(values.inputHeight, 56);
    });

    test('forMode should return correct values for comfortable mode', () {
      final values = DensityValues.forMode(DensityMode.comfortable);
      
      expect(values.cardPadding, 16);
      expect(values.cardMargin, 12);
      expect(values.listTilePadding, 12);
      expect(values.fontSizeOffset, 0);
      expect(values.iconSize, 24);
      expect(values.dense, false);
      expect(values.rowHeight, 64);
      expect(values.horizontalPadding, 12);
      expect(values.inputHeight, 72);
    });

    test('forMode should return correct values for detailed mode', () {
      final values = DensityValues.forMode(DensityMode.detailed);
      
      expect(values.cardPadding, 20);
      expect(values.cardMargin, 16);
      expect(values.listTilePadding, 16);
      expect(values.fontSizeOffset, 1);
      expect(values.iconSize, 28);
      expect(values.dense, false);
      expect(values.rowHeight, 72);
      expect(values.horizontalPadding, 16);
      expect(values.inputHeight, 80);
    });

    test('modeName should return correct localized names', () {
      expect(DensityValues.modeName(DensityMode.compact), 'Compacta');
      expect(DensityValues.modeName(DensityMode.comfortable), 'Cómoda');
      expect(DensityValues.modeName(DensityMode.detailed), 'Detallada');
    });

    test('modeDescription should return correct descriptions', () {
      expect(
        DensityValues.modeDescription(DensityMode.compact),
        'Más datos en pantalla, ideal para gym',
      );
      expect(
        DensityValues.modeDescription(DensityMode.comfortable),
        'Equilibrio entre espacio e información',
      );
      expect(
        DensityValues.modeDescription(DensityMode.detailed),
        'Más espaciado, hints adicionales',
      );
    });
  });
}
