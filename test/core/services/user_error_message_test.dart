import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/core/services/user_error_message.dart';

void main() {
  group('userErrorMessage', () {
    test('elimina prefijos tecnicos comunes', () {
      final message = userErrorMessage(Exception('Bad state: fallo de prueba'));
      expect(message, 'fallo de prueba');
    });

    test('mapea timeout a mensaje amigable', () {
      final message = userErrorMessage(TimeoutException('network timeout'));
      expect(
        message,
        'La operación tardó demasiado. Reintenta en unos segundos.',
      );
    });

    test('usa fallback con detalles internos largos', () {
      final longInternal =
          'package:juan_tracker/${List.filled(220, 'x').join()}';
      final message = userErrorMessage(
        longInternal,
        fallback: 'Fallo controlado',
      );
      expect(message, 'Fallo controlado');
    });
  });
}
