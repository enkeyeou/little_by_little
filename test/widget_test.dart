import 'package:flutter_test/flutter_test.dart';
import 'package:little_by_little/app/app.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const LittleByLittleApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Small steps still count.'), findsOneWidget);
  });
}