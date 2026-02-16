import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

/// IDs de notificación para recordatorios de dieta
class _ReminderIds {
  static const int breakfast = 2001;
  static const int lunch = 2002;
  static const int dinner = 2003;
  static const int snack = 2004;
  static const int weighIn = 2005;
  static const int weeklyCheckIn = 2006;
  static const int water = 2007;
}

/// Canal de notificaciones para recordatorios
const String _channelId = 'diet_reminders_channel';
const String _channelName = 'Recordatorios de Dieta';
const String _channelDescription =
    'Recordatorios para registrar comidas, peso y agua';

/// Servicio singleton para gestionar recordatorios de dieta.
///
/// Usa `flutter_local_notifications` con `zonedSchedule()` para
/// programar notificaciones diarias a horas configurables.
class DietReminderService {
  static final DietReminderService instance = DietReminderService._();
  DietReminderService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Inicializa el servicio: timezone, canal de notificación, plugin.
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    // Inicializar zonas horarias
    tzdata.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('[DietReminder] No se pudo obtener timezone: $e');
      // Fallback: intentar deducir por offset
      _setTimezoneByOffset();
    }

    // Inicializar plugin de notificaciones
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(settings: initSettings);

    // Crear canal Android
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
      }
    }

    _isInitialized = true;
    debugPrint('[DietReminder] Servicio inicializado');
  }

  /// Fallback: deduce timezone por offset del dispositivo
  void _setTimezoneByOffset() {
    final offset = DateTime.now().timeZoneOffset;
    final locations = tz.timeZoneDatabase.locations;
    for (final entry in locations.entries) {
      final loc = entry.value;
      final locOffset = Duration(milliseconds: loc.currentTimeZone.offset);
      if (locOffset == offset) {
        tz.setLocalLocation(loc);
        debugPrint('[DietReminder] Timezone por offset: ${entry.key}');
        return;
      }
    }
    debugPrint('[DietReminder] No se encontró timezone, usando UTC');
  }

  // ─────────────────────────────────────────────────────────────────
  // Programación de recordatorios
  // ─────────────────────────────────────────────────────────────────

  /// Programa un recordatorio diario de desayuno
  Future<void> scheduleBreakfast(int hour, int minute) =>
      _scheduleDailyReminder(
        id: _ReminderIds.breakfast,
        hour: hour,
        minute: minute,
        title: '🍳 Hora del desayuno',
        body: '¿Ya registraste tu desayuno? Ábrelo para loguearlo rápido.',
      );

  /// Programa un recordatorio diario de almuerzo
  Future<void> scheduleLunch(int hour, int minute) =>
      _scheduleDailyReminder(
        id: _ReminderIds.lunch,
        hour: hour,
        minute: minute,
        title: '🥗 Hora del almuerzo',
        body: 'No olvides registrar tu almuerzo para mantener el tracking.',
      );

  /// Programa un recordatorio diario de cena
  Future<void> scheduleDinner(int hour, int minute) =>
      _scheduleDailyReminder(
        id: _ReminderIds.dinner,
        hour: hour,
        minute: minute,
        title: '🍽️ Hora de la cena',
        body: 'Registra tu cena antes de terminar el día.',
      );

  /// Programa un recordatorio diario de merienda/snack
  Future<void> scheduleSnack(int hour, int minute) =>
      _scheduleDailyReminder(
        id: _ReminderIds.snack,
        hour: hour,
        minute: minute,
        title: '🍎 Merienda',
        body: '¿Comiste algo entre horas? Registra tu snack.',
      );

  /// Programa un recordatorio diario de pesaje
  Future<void> scheduleWeighIn(int hour, int minute) =>
      _scheduleDailyReminder(
        id: _ReminderIds.weighIn,
        hour: hour,
        minute: minute,
        title: '⚖️ Hora de pesarse',
        body: 'Registra tu peso matutino para mantener la tendencia actualizada.',
      );

  /// Programa un recordatorio de hidratación (tarde)
  Future<void> scheduleWater(int hour, int minute) =>
      _scheduleDailyReminder(
        id: _ReminderIds.water,
        hour: hour,
        minute: minute,
        title: '💧 Recordatorio de agua',
        body: '¿Has bebido suficiente agua hoy? Revisa tu progreso.',
      );

  /// Programa un recordatorio semanal de check-in (lunes)
  Future<void> scheduleWeeklyCheckIn(int hour, int minute) async {
    if (!_isInitialized || kIsWeb) return;

    await _notifications.cancel(id: _ReminderIds.weeklyCheckIn);

    final scheduledDate = _nextInstanceOfWeekday(
      DateTime.monday,
      hour,
      minute,
    );

    await _notifications.zonedSchedule(
      id: _ReminderIds.weeklyCheckIn,
      title: '📊 Check-in semanal',
      body: 'Es hora de tu revisión semanal. Revisa tu progreso y ajusta objetivos.',
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    debugPrint('[DietReminder] Weekly check-in programado: lunes $hour:$minute');
  }

  // ─────────────────────────────────────────────────────────────────
  // Cancelación
  // ─────────────────────────────────────────────────────────────────

  /// Cancela un recordatorio específico
  Future<void> cancelBreakfast() => _notifications.cancel(id: _ReminderIds.breakfast);
  Future<void> cancelLunch() => _notifications.cancel(id: _ReminderIds.lunch);
  Future<void> cancelDinner() => _notifications.cancel(id: _ReminderIds.dinner);
  Future<void> cancelSnack() => _notifications.cancel(id: _ReminderIds.snack);
  Future<void> cancelWeighIn() => _notifications.cancel(id: _ReminderIds.weighIn);
  Future<void> cancelWater() => _notifications.cancel(id: _ReminderIds.water);
  Future<void> cancelWeeklyCheckIn() =>
      _notifications.cancel(id: _ReminderIds.weeklyCheckIn);

  /// Cancela todos los recordatorios de dieta
  Future<void> cancelAll() async {
    await cancelBreakfast();
    await cancelLunch();
    await cancelDinner();
    await cancelSnack();
    await cancelWeighIn();
    await cancelWater();
    await cancelWeeklyCheckIn();
  }

  /// Solicitar permiso de notificaciones (Android 13+)
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────

  Future<void> _scheduleDailyReminder({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized || kIsWeb) return;

    // Cancelar la anterior si existe
    await _notifications.cancel(id: id);

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('[DietReminder] Recordatorio $id programado: $hour:$minute');
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Calcula la próxima instancia de una hora específica
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Calcula la próxima instancia de un día de la semana + hora
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
