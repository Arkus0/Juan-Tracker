import 'package:logger/logger.dart';

/// Lightweight Telemetry helper to track events and breadcrumbs.
///
/// This intentionally keeps the surface minimal so it can be wired to
/// Sentry/Firebase later.
class TelemetryService {
  TelemetryService._();
  static final TelemetryService instance = TelemetryService._();

  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  /// Track a named event with optional properties
  void trackEvent(String name, [Map<String, dynamic>? props]) {
    _logger.i('Telemetry event: $name ${props ?? {}}');
    // TODO: Integrate with Sentry/Firebase here if configured
  }

  /// Log a breadcrumb (detailed diagnostic message)
  void breadcrumb(String message, [Map<String, dynamic>? data]) {
    _logger.d('Breadcrumb: $message ${data ?? {}}');
  }

  /// Log an error occurrence
  void error(String message, [Object? error, StackTrace? st]) {
    final details = (error != null ? ' | error: $error' : '') + (st != null ? '\n$st' : '');
    _logger.e('Telemetry error: $message$details');
  }
}
