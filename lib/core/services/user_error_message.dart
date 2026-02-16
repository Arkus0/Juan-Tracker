import 'dart:async';

/// Convierte errores tecnicos a mensajes aptos para UI.
String userErrorMessage(
  Object error, {
  String fallback = 'No se pudo completar la acción. Intenta de nuevo.',
}) {
  if (error is StateError) {
    final message = _stripPrefixes(error.message.toString());
    return message.isNotEmpty ? message : fallback;
  }

  if (error is TimeoutException) {
    return 'La operación tardó demasiado. Reintenta en unos segundos.';
  }

  if (error is FormatException) {
    return 'Los datos recibidos no tienen un formato valido.';
  }

  final raw = _stripPrefixes(error.toString());
  if (raw.isEmpty) return fallback;

  // Evitar exponer stacks o detalles internos largos.
  if (raw.length > 180 ||
      raw.contains('dart:') ||
      raw.contains('package:') ||
      raw.contains('StackTrace')) {
    return fallback;
  }

  return raw;
}

String _stripPrefixes(String input) {
  var value = input.trim();
  const prefixes = <String>[
    'Exception:',
    'Bad state:',
    'StateError:',
    'Error:',
  ];

  for (final prefix in prefixes) {
    if (value.startsWith(prefix)) {
      value = value.substring(prefix.length).trim();
    }
  }

  return value;
}
