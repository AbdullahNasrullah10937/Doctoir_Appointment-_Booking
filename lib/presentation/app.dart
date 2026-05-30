import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';

class QurexaApp extends StatefulWidget {
  const QurexaApp({super.key});

  @override
  State<QurexaApp> createState() => _QurexaAppState();
}

class _QurexaAppState extends State<QurexaApp> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Qurexa',
        theme: AppTheme.light,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.splash,
      ),
    );
  }
}
