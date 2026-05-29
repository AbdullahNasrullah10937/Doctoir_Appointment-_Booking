import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_booking_system/presentation/screens/screens.dart';
import 'package:doctor_booking_system/presentation/state/app_scope.dart';
import 'package:doctor_booking_system/presentation/state/app_state.dart';

void main() {
  testWidgets('Login screen renders expected controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      AppScope(
        state: AppState(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
