import 'package:flutter_test/flutter_test.dart';
import 'package:little_by_little/app/app.dart';
import 'package:little_by_little/core/utils/calendar_dates.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const LittleByLittleApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Small steps still count.'), findsOneWidget);
  });

  testWidgets('Home progress cards swipe through three pages in order', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LittleByLittleApp());
    await tester.pumpAndSettle();

    expect(find.text("Today's Progress"), findsOneWidget);

    final swipeArea = find.byKey(
      const ValueKey('home-progress-overview-swipe-area'),
    );
    final todayPageHeight = tester.getSize(swipeArea).height;

    await tester.drag(swipeArea, const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Monthly Activity'), findsOneWidget);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('progress-page-indicator-2')),
          )
          .properties
          .selected,
      isTrue,
    );
    expect(tester.getSize(swipeArea).height, greaterThan(todayPageHeight));

    await tester.drag(swipeArea, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text("Today's Progress"), findsOneWidget);

    await tester.drag(swipeArea, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Weekly Progress'), findsOneWidget);
    expect(find.text('SUN'), findsOneWidget);
    expect(find.text('SAT'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);

    await tester.drag(swipeArea, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Monthly Activity'), findsOneWidget);

    await tester.drag(swipeArea, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text("Today's Progress"), findsOneWidget);
    await tester.drag(swipeArea, const Offset(600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Monthly Activity'), findsOneWidget);

    final previousMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month - 1,
    );
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(
      find.text(CalendarDates.monthYearLabel(previousMonth)),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(
      find.text(CalendarDates.monthYearLabel(DateTime.now())),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Monthly activity fits a compact screen without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LittleByLittleApp());
    await tester.pumpAndSettle();

    final swipeArea = find.byKey(
      const ValueKey('home-progress-overview-swipe-area'),
    );
    await tester.drag(swipeArea, const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(find.text('Weekly Progress'), findsOneWidget);
    await tester.drag(swipeArea, const Offset(-250, 0));
    await tester.pumpAndSettle();

    expect(find.text('Monthly Activity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}
