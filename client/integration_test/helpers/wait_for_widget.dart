import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> waitForWidget(WidgetTester tester, Finder finder,
    {Duration timeout = const Duration(seconds: 5)}) async {
  final stopwatch = Stopwatch()..start();

  while (stopwatch.elapsed < timeout) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 1));
  }

  throw Exception('Widget ${finder.toString()} not found after $timeout');
}

Future<void> waitForWidgetWithText(
    WidgetTester tester, Finder finder, String text,
    {Duration timeout = const Duration(seconds: 5)}) async {
  final stopwatch = Stopwatch()..start();

  while (stopwatch.elapsed < timeout) {
    if (finder.evaluate().isNotEmpty) {
      final textWidget = tester.widget<Text>(finder);

      if (textWidget.data == text) {
        return;
      }
    }
    await tester.pump(const Duration(milliseconds: 1));
  }

  throw Exception(
    'Widget ${finder.toString()} with "$text" not found after $timeout',
  );
}
