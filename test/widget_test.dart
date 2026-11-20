import 'package:flutter_test/flutter_test.dart';
import 'package:little_by_little/app/app.dart';
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

  testWidgets('Home displays today progress and habits sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LittleByLittleApp());
    await tester.pumpAndSettle();

    expect(find.text("Today's Progress"), findsOneWidget);
    expect(find.text('Your habits'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Monthly calendar fits a compact screen without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LittleByLittleApp());
    await tester.pumpAndSettle();

    expect(find.text("Today's Progress"), findsOneWidget);

    // Expand the calendar from its month selector.
    await tester.tap(find.textContaining(DateTime.now().year.toString()).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
