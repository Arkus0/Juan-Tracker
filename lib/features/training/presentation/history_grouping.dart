import '../../../core/models/training_sesion.dart';

class HistoryGroup {
  final String label;
  final List<Sesion> sesiones;

  HistoryGroup({required this.label, required this.sesiones});
}

List<HistoryGroup> groupSessionsByPeriod(List<Sesion> sesiones, DateTime now) {
  if (sesiones.isEmpty) return const [];

  final sorted = sesiones.toList()..sort((a, b) => b.fecha.compareTo(a.fecha));
  final startOfWeek = _startOfWeek(now);
  final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));

  final Map<String, List<Sesion>> groups = {};

  for (final sesion in sorted) {
    final label = _labelForDate(
      sesion.fecha,
      now,
      startOfWeek,
      startOfLastWeek,
    );
    groups.putIfAbsent(label, () => []).add(sesion);
  }

  return groups.entries
      .map((e) => HistoryGroup(label: e.key, sesiones: e.value))
      .toList();
}

String _labelForDate(
  DateTime date,
  DateTime now,
  DateTime startOfWeek,
  DateTime startOfLastWeek,
) {
  if (!date.isBefore(startOfWeek)) return 'ESTA SEMANA';
  if (!date.isBefore(startOfLastWeek)) return 'SEMANA PASADA';
  if (date.year == now.year && date.month == now.month) return 'ESTE MES';
  return '${_monthName(date.month)} ${date.year}';
}

DateTime _startOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final delta = normalized.weekday - DateTime.monday;
  return normalized.subtract(Duration(days: delta));
}

String _monthName(int month) {
  const months = [
    'ENERO',
    'FEBRERO',
    'MARZO',
    'ABRIL',
    'MAYO',
    'JUNIO',
    'JULIO',
    'AGOSTO',
    'SEPTIEMBRE',
    'OCTUBRE',
    'NOVIEMBRE',
    'DICIEMBRE',
  ];
  if (month < 1 || month > 12) return 'MES';
  return months[month - 1];
}
