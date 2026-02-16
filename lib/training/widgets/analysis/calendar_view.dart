import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/design_system/design_system.dart' show AppTypography;
import '../../providers/analysis_provider.dart';
import 'daily_snapshot_card.dart';

/// TableCalendar wrapper with training day markers
class AnalysisCalendarView extends ConsumerStatefulWidget {
  const AnalysisCalendarView({super.key});

  @override
  ConsumerState<AnalysisCalendarView> createState() =>
      _AnalysisCalendarViewState();
}

class _AnalysisCalendarViewState extends ConsumerState<AnalysisCalendarView> {
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final trainingDatesAsync = ref.watch(trainingDatesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Calendar
        trainingDatesAsync.when(
          data: (trainingDates) =>
              _buildCalendar(scheme, trainingDates, selectedDate),
          loading: () => _buildCalendarLoading(scheme),
          error: (_, _) => _buildCalendar(scheme, {}, selectedDate),
        ),

        // Daily snapshot when date selected
        if (selectedDate != null) ...[
          const SizedBox(height: 16),
          const DailySnapshotCard(),
        ],
      ],
    );
  }

  Widget _buildCalendar(
    ColorScheme scheme,
    Set<DateTime> trainingDates,
    DateTime? selectedDate,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          HapticFeedback.selectionClick();
          ref.read(selectedCalendarDateProvider.notifier).setDate(selectedDay);
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          // Update year provider for heatmap sync
          ref.read(selectedYearProvider.notifier).setYear(focusedDay.year);
        },
        // Spanish locale
        locale: 'es_ES',
        startingDayOfWeek: StartingDayOfWeek.monday,
        // Custom builders
        calendarBuilders: CalendarBuilders(
          // Training day marker
          markerBuilder: (context, day, events) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            if (trainingDates.contains(normalizedDay)) {
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
          // Default cell
          defaultBuilder: (context, day, focusedDay) {
            return _buildDayCell(
              scheme,
              day,
              isSelected: false,
              isToday: false,
            );
          },
          // Today cell
          todayBuilder: (context, day, focusedDay) {
            return _buildDayCell(scheme, day, isSelected: false, isToday: true);
          },
          // Selected cell
          selectedBuilder: (context, day, focusedDay) {
            return _buildDayCell(
              scheme,
              day,
              isSelected: true,
              isToday: isSameDay(day, DateTime.now()),
            );
          },
          // Outside cell (other months)
          outsideBuilder: (context, day, focusedDay) {
            return Center(
              child: Text(
                '${day.day}',
                style: AppTypography.bodyMedium.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
        // Styling
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            border: Border.all(color: scheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          formatButtonTextStyle: AppTypography.bodySmall.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          titleTextStyle: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: scheme.onSurfaceVariant,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: scheme.onSurfaceVariant,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: AppTypography.labelMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          weekendStyle: AppTypography.labelMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        calendarStyle: CalendarStyle(
          cellMargin: const EdgeInsets.all(4),
          // Default
          defaultTextStyle: AppTypography.bodyMedium.copyWith(
            color: scheme.onSurface,
          ),
          // Weekend
          weekendTextStyle: AppTypography.bodyMedium.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          // Today
          todayDecoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
          ),
          todayTextStyle: AppTypography.titleMedium.copyWith(
            color: scheme.onSurface,
          ),
          // Selected
          selectedDecoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(
    ColorScheme scheme,
    DateTime day, {
    required bool isSelected,
    required bool isToday,
  }) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected
            ? scheme.primary
            : isToday
            ? scheme.surface
            : null,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: AppTypography.bodyMedium.copyWith(
            color: isSelected
                ? scheme.onSurface
                : isToday
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: isSelected || isToday
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarLoading(ColorScheme scheme) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CircularProgressIndicator(color: scheme.primary, strokeWidth: 2),
      ),
    );
  }
}
