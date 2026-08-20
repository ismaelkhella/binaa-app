// Smoke test for the Bina Academy app shell. The app boots into the welcome
// screen via the auth-driven redirect logic, so we look for the brand
// wordmark as a stable anchor.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:binaa_academy/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('boots into the welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BinaAcademyApp()));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Bina Academy'), findsOneWidget);
    expect(find.text('ابدأ الآن'), findsOneWidget);
  });
}
