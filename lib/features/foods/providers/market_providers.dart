import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mercados soportados
enum FoodMarket {
  spain('España', 'spain_subset.jsonl.gz', '🇪🇸'),
  usa('Estados Unidos', 'usa_subset.jsonl.gz', '🇺🇸');

  final String displayName;
  final String filename;
  final String flag;

  const FoodMarket(this.displayName, this.filename, this.flag);

  static FoodMarket? fromString(String? value) {
    if (value == null) return null;
    try {
      return FoodMarket.values.firstWhere((m) => m.name == value);
    } catch (_) {
      return null;
    }
  }
}

/// Provider del mercado seleccionado
class SelectedMarketNotifier extends Notifier<FoodMarket?> {
  static const String _prefsKey = 'selected_food_market';

  @override
  FoodMarket? build() => null;

  Future<void> loadSavedMarket() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    state = FoodMarket.fromString(saved) ?? FoodMarket.spain;
  }

  Future<void> setMarket(FoodMarket market) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, market.name);
    state = market;
  }

  Future<bool> hasMarketSelected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_prefsKey);
  }
}

final selectedMarketProvider = NotifierProvider<SelectedMarketNotifier, FoodMarket?>(
  SelectedMarketNotifier.new,
);

/// Provider para verificar si hay un mercado seleccionado
final hasMarketSelectedProvider = FutureProvider<bool>((ref) async {
  final notifier = ref.read(selectedMarketProvider.notifier);
  return notifier.hasMarketSelected();
});
