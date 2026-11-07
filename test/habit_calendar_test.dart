import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_by_little/core/utils/calendar_dates.dart';
import 'package:little_by_little/features/habits/presentation/widgets/habit_calendar.dart';
import 'package:little_by_little/features/habits/presentation/widgets/habit_day_status.dart';
import 'package:little_by_little/features/habits/presentation/widgets/habit_week_progress.dart';

void main() {
  testWidgets('Habit calendar shows Sunday-first dates and month navigation', (
    WidgetTester tester,
  ) async {
    final today = DateTime.now();
    var visibleMonth = DateTime(today.year, today.month);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  HabitWeekProgress(
                    weekStart: CalendarDates.startOfWeek(today),
                    today: today,
                    statusForDate: (_) => HabitDayStatus.notScheduled,
                    countForDate: (_) => null,
                    counterUnit: 'pages',
                    isCounter: false,
                  ),
                  HabitCalendar(
                    visibleMonth: visibleMonth,
                    selectedDate: today,
                    statusForDate: (_) => HabitDayStatus.notScheduled,
                    countForDate: (_) => null,
                    counterUnit: 'pages',
                    isCounter: false,
                    selectedDateDetails: const SizedBox.shrink(),
                    onDateSelected: (_) {},
                    onMonthChanged: (offset) {
                      setState(() {
                        visibleMonth = DateTime(
                          visibleMonth.year,
                          visibleMonth.month + offset,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SUN'), findsOneWidget);
    expect(find.text('Completion History'), findsOneWidget);
    expect(find.text(CalendarDates.monthYearLabel(today)), findsOneWidget);

    final previousMonth = DateTime(today.year, today.month - 1);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(
      find.text(CalendarDates.monthYearLabel(previousMonth)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
