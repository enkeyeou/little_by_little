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

  testWidgets('Home progress card exposes its three pages in order', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LittleByLittleApp());
    await tester.pumpAndSettle();

    expect(find.text("Today's Progress"), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('progress-page-indicator-1')));
    await tester.pumpAndSettle();
    expect(find.text('Weekly Progress'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('progress-page-indicator-2')));
    await tester.pumpAndSettle();
    expect(find.text('Monthly Activity'), findsOneWidget);
  });
}
