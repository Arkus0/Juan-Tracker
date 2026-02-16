import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juan_tracker/diet/services/recipe_url_importer.dart';

typedef _FetchHandler = Future<ResponseBody> Function(RequestOptions options);

class _FakeHttpAdapter implements HttpClientAdapter {
  final _FetchHandler handler;

  _FakeHttpAdapter(this.handler);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }
}

Dio _buildDio(_FetchHandler handler) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeHttpAdapter(handler);
  return dio;
}

ResponseBody _htmlResponse(
  String body, {
  int statusCode = 200,
  String contentType = 'text/html; charset=utf-8',
  Map<String, List<String>> extraHeaders = const {},
}) {
  return ResponseBody.fromString(
    body,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [contentType],
      ...extraHeaders,
    },
  );
}

void main() {
  group('RecipeUrlImporter', () {
    test('throws invalidUrl for malformed URL', () async {
      final importer = RecipeUrlImporter(
        dio: _buildDio((_) async => _htmlResponse('')),
      );

      await expectLater(
        () => importer.importFromUrl('notaurl'),
        throwsA(
          isA<RecipeImportException>().having(
            (e) => e.code,
            'code',
            RecipeImportErrorCode.invalidUrl,
          ),
        ),
      );
    });

    test('blocks localhost URLs for security', () async {
      final importer = RecipeUrlImporter(
        dio: _buildDio((_) async => _htmlResponse('')),
      );

      await expectLater(
        () => importer.importFromUrl('http://localhost:8080/recipe'),
        throwsA(
          isA<RecipeImportException>().having(
            (e) => e.code,
            'code',
            RecipeImportErrorCode.blockedHost,
          ),
        ),
      );
    });

    test(
      'parses JSON-LD recipe including comma decimals and nested steps',
      () async {
        const html = '''
<!doctype html>
<html>
<head>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Recipe",
  "name": "Tortilla simple",
  "recipeYield": "2 porciones",
  "recipeIngredient": ["2 huevos", "100 g patata"],
  "recipeInstructions": [
    {
      "@type": "HowToSection",
      "name": "Preparacion",
      "itemListElement": [
        {"@type": "HowToStep", "text": "Batir huevos"},
        {"@type": "HowToStep", "text": "Freir patata"}
      ]
    }
  ],
  "nutrition": {
    "@type": "NutritionInformation",
    "calories": "450 kcal",
    "proteinContent": "12,5 g",
    "carbohydrateContent": "30,2 g",
    "fatContent": "20,1 g"
  }
}
</script>
</head>
<body></body>
</html>
''';

        final importer = RecipeUrlImporter(
          dio: _buildDio((_) async => _htmlResponse(html)),
        );

        final parsed = await importer.importFromUrl(
          'https://ejemplo.com/tortilla',
        );

        expect(parsed.name, 'Tortilla simple');
        expect(parsed.servings, 2);
        expect(parsed.ingredients, ['2 huevos', '100 g patata']);
        expect(parsed.instructions, isNotNull);
        expect(parsed.instructions!, contains('Preparacion'));
        expect(parsed.instructions!, contains('Batir huevos'));
        expect(parsed.instructions!, contains('Freir patata'));
        expect(parsed.totalKcal, 450);
        expect(parsed.totalProtein, closeTo(12.5, 0.001));
        expect(parsed.totalCarbs, closeTo(30.2, 0.001));
        expect(parsed.totalFat, closeTo(20.1, 0.001));
        expect(parsed.sourceUrl, 'https://ejemplo.com/tortilla');
      },
    );

    test('maps timeout errors to timeout domain error', () async {
      final importer = RecipeUrlImporter(
        dio: _buildDio((options) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          );
        }),
      );

      await expectLater(
        () => importer.importFromUrl('https://ejemplo.com/receta'),
        throwsA(
          isA<RecipeImportException>().having(
            (e) => e.code,
            'code',
            RecipeImportErrorCode.timeout,
          ),
        ),
      );
    });

    test('rejects unsupported content types', () async {
      final importer = RecipeUrlImporter(
        dio: _buildDio(
          (_) async =>
              _htmlResponse('<html></html>', contentType: 'application/json'),
        ),
      );

      await expectLater(
        () => importer.importFromUrl('https://ejemplo.com/api'),
        throwsA(
          isA<RecipeImportException>().having(
            (e) => e.code,
            'code',
            RecipeImportErrorCode.unsupportedContent,
          ),
        ),
      );
    });

    test('rejects oversized response based on content-length', () async {
      final importer = RecipeUrlImporter(
        dio: _buildDio(
          (_) async => _htmlResponse(
            '<html><head><title>Receta</title></head><body></body></html>',
            extraHeaders: {
              Headers.contentLengthHeader: ['2097153'],
            },
          ),
        ),
      );

      await expectLater(
        () => importer.importFromUrl('https://ejemplo.com/receta-grande'),
        throwsA(
          isA<RecipeImportException>().having(
            (e) => e.code,
            'code',
            RecipeImportErrorCode.responseTooLarge,
          ),
        ),
      );
    });
  });
}
