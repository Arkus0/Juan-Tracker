import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';

final providerPatterns = [
  RegExp(
    r"\b(StateNotifierProvider|StateProvider|StreamProvider|FutureProvider|Provider<|ChangeNotifierProvider|NotifierProvider)\b",
  ),
  RegExp(r"\bautoDispose\b"),
];

final _logger = Logger('extract_providers');

void main(List<String> args) {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln(
      'No se encontró la carpeta `lib`. Ejecuta desde la raíz del proyecto.',
    );
    exit(1);
  }

  final results = <String, List<String>>{};

  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((rec) {
    stderr.writeln(
      '${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}',
    );
  });

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      final matches = <String>{};
      for (final pat in providerPatterns) {
        for (final m in pat.allMatches(content)) {
          final line = _lineForOffset(content, m.start);
          matches.add(line.trim());
        }
      }
      if (matches.isNotEmpty) {
        results[entity.path] = matches.toList();
      }
    }
  }

  printJson(results);
}

String _lineForOffset(String content, int offset) {
  final lastNewLineIndex = (offset - 1) >= 0
      ? content.lastIndexOf('\n', offset - 1)
      : -1;
  final nextNewLineIndex = content.indexOf('\n', offset);
  final s = lastNewLineIndex == -1 ? 0 : lastNewLineIndex + 1;
  final e = nextNewLineIndex == -1 ? content.length : nextNewLineIndex;
  return content.substring(s, e);
}

void printJson(Map<String, List<String>> results) {
  final encoder = JsonEncoder.withIndent('  ');
  _logger.info(encoder.convert(results));
}
