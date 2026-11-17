
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:auspify_todo/main.dart';

void main() {
  testWidgets('To-Do List screen displays correctly', (tester) async {
    await tester.pumpWidget(const TodoApp());

    expect(find.text('My To-Do List'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
