import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';
import '../../../core/security/encryption_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _scaleAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // Capture state/navigator before any asynchronous gaps
    final navigator = Navigator.of(context);
    final appState = AppScope.of(context);

    // Moved here to prevent blocking runApp in main.dart
    await EncryptionService.initialize();
    await appState.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    if (!appState.seenOnboarding) {
      navigator.pushReplacementNamed(AppRouter.onboarding);
      return;
    }
    if (!appState.isLoggedIn) {
      navigator.pushReplacementNamed(AppRouter.login);
      return;
    }
    if (appState.role == UserRole.doctor) {
      navigator.pushReplacementNamed(AppRouter.doctorShell);
      return;
    }
    if (!appState.profileCompleted) {
      navigator.pushReplacementNamed(AppRouter.profileSetup);
      return;
    }
    navigator.pushReplacementNamed(AppRouter.patientShell);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[AppTheme.accentBlue, Color(0xFF1A4BC4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const Spacer(flex: 3),
              // Animated logo
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) => FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(scale: _scaleAnim, child: child),
                ),
                child: Column(
                  children: <Widget>[
                    // Logo circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppTheme.space2),
                      child: ClipOval(
                        child: Image.asset(
                          AppAssets.appLogo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.local_hospital_rounded,
                            color: AppTheme.accentBlue,
                            size: 52,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Qurexa',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your Health, On Time',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              // Loading indicator
              Column(
                children: <Widget>[
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Loading your health profile...',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Page dots (decorative — fixed at 3)
              const PageDotIndicator(count: 3, current: 0),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
