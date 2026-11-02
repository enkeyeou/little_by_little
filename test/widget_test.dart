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
}
