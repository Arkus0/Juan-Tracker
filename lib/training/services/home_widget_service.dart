import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar el widget de home screen de Android
/// Comunica con código nativo via MethodChannel
class HomeWidgetService {
  static const _channel = MethodChannel('com.juantracker/home_widget');
  static const _prefsKey = 'home_widget_data';
  
  static final HomeWidgetService _instance = HomeWidgetService._internal();
  factory HomeWidgetService() => _instance;
  HomeWidgetService._internal();

  /// Inicializa el servicio y configura el handler de llamadas nativas
  void initialize() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Handler para llamadas desde código nativo Android
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getWidgetData':
        return _getWidgetData();
      case 'onWidgetTap':
        // Manejar tap en el widget - navegar a app
        return true;
      default:
        throw MissingPluginException('Method ${call.method} not implemented');
    }
  }

  /// Obtiene los datos para mostrar en el widget
  Future<Map<String, dynamic>> _getWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    
    if (jsonStr == null) {
      return _getDefaultWidgetData();
    }

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return _getDefaultWidgetData();
    }
  }

  /// Datos por defecto cuando no hay rutina activa
  Map<String, dynamic> _getDefaultWidgetData() {
    return {
      'hasWorkout': false,
      'title': 'Juan Tracker',
      'subtitle': 'Sin entreno programado',
      'primaryAction': 'INICIAR',
      'exercises': [],
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// Actualiza los datos del widget cuando hay una rutina programada
  Future<void> updateWidgetData({
    required String routineName,
    required String dayName,
    required List<String> exercises,
    required bool isWorkoutDay,
  }) async {
    final data = {
      'hasWorkout': true,
      'title': routineName,
      'subtitle': dayName,
      'primaryAction': isWorkoutDay ? 'ENTRENAR' : 'VER',
      'exercises': exercises.take(5).toList(), // Máximo 5 ejercicios
      'exerciseCount': exercises.length,
      'isWorkoutDay': isWorkoutDay,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(data));

    // Notificar a Android que actualice el widget
    try {
      await _channel.invokeMethod('updateWidget');
    } catch (e) {
      // Widget puede no estar configurado en Android
      debugPrint('HomeWidget update error: $e');
    }
  }

  /// Limpia los datos del widget (al completar rutina)
  Future<void> clearWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);

    try {
      await _channel.invokeMethod('clearWidget');
    } catch (e) {
      debugPrint('HomeWidget clear error: $e');
    }
  }

  /// Obtiene el estado actual del widget para debug
  Future<Map<String, dynamic>> getDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    
    return {
      'hasData': jsonStr != null,
      'data': jsonStr != null ? jsonDecode(jsonStr) : null,
      'channelAvailable': true,
    };
  }
}

/// Provider para acceder al servicio de widget
final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  return HomeWidgetService();
});

/// Provider que actualiza automáticamente el widget cuando cambia la rutina activa
final homeWidgetUpdaterProvider = Provider<void>((ref) {
  // Escuchar cambios en la rutina activa y actualizar widget
  // Esto se activa cuando hay nuevas rutinas programadas
  
  // Por ahora, es un stub que se implementará cuando tengamos
  // el provider de rutinas programadas
});
