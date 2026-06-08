import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:doctor_booking_system/presentation/screens/screens.dart';
import 'package:doctor_booking_system/presentation/state/app_scope.dart';
import 'package:doctor_booking_system/presentation/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    dotenv.testLoad(
      fileInput: 'OPENAI_API_KEY=mock_openai_key\nGROQ_API_KEY=mock_groq_key',
    );
    await Firebase.initializeApp();
  });

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
