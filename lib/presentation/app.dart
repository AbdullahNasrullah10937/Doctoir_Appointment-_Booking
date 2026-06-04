import 'package:flutter/material.dart';

import '../core/ads/ad_service.dart';
import '../core/notifications/notification_service.dart';
import '../core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';

/// Global navigator key — used by [NotificationService] for deep-link
/// navigation from terminated and background notification states.
final GlobalKey<NavigatorState> qurexaNavigatorKey = GlobalKey<NavigatorState>();

class QurexaApp extends StatefulWidget {
  const QurexaApp({super.key});

  @override
  State<QurexaApp> createState() => _QurexaAppState();
}

class _QurexaAppState extends State<QurexaApp> {
  late final AppState _state;
  final AdService _adService = AdService();

  @override
  void initState() {
    super.initState();
    _state = AppState();

    // Initialize Ads and Notifications concurrently in a microtask after initial frame render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.microtask(() async {
        if (!mounted) return;
        await Future.wait([
          NotificationService.instance.initialize(qurexaNavigatorKey),
          _adService.initialize(),
        ]);
      });
    });
  }

  @override
  void dispose() {
    _state.dispose();
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdServiceProvider(
      adService: _adService,
      child: AppScope(
        state: _state,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Qurexa',
          theme: AppTheme.light,
          navigatorKey: qurexaNavigatorKey,
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: AppRouter.splash,
        ),
      ),
    );
  }
}

// ─── AdService provider ───────────────────────────────────────────────────────

/// Makes [AdService] accessible anywhere in the widget tree without
/// rebuilding on ad state changes (pure InheritedWidget, no notifier).
class AdServiceProvider extends InheritedWidget {
  const AdServiceProvider({
    super.key,
    required this.adService,
    required super.child,
  });

  final AdService adService;

  static AdService of(BuildContext context) {
    final provider = context.getElementForInheritedWidgetOfExactType<AdServiceProvider>();
    assert(provider != null, 'AdServiceProvider not found in widget tree.');
    return (provider!.widget as AdServiceProvider).adService;
  }

  @override
  bool updateShouldNotify(AdServiceProvider oldWidget) => false;
}
