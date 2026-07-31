import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders a MaterialApp shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Text('Mandi App')),
    ));

    expect(find.text('Mandi App'), findsOneWidget);
  });
}
