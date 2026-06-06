import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../../domain/entities/doctor_application.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    
    // Logo entrance animation (smooth easeOutCubic, typical of premium systems)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnim = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    ));

    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    ));

    // Sliding indicator animation (looping)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _logoController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final navigator = Navigator.of(context);
    final appState = AppScope.of(context);

    // Run app state initialization concurrently with the minimum splash screen delay
    // to establish premium branding/trust without adding any extra load times.
    await Future.wait([
      appState.initialize(),
      Future<void>.delayed(const Duration(milliseconds: 2000)),
    ]);

    if (!mounted) return;

    if (!appState.seenOnboarding) {
      navigator.pushReplacementNamed(AppRouter.onboarding);
      return;
    }
    if (!appState.isLoggedIn) {
      navigator.pushReplacementNamed(AppRouter.login);
      return;
    }
    if (appState.role == UserRole.admin) {
      navigator.pushReplacementNamed(AppRouter.adminShell);
      return;
    }
    if (appState.role == UserRole.doctor) {
      switch (appState.doctorVerificationStatus) {
        case DoctorVerificationStatus.pending:
          navigator.pushReplacementNamed(AppRouter.doctorPending);
          return;
        case DoctorVerificationStatus.rejected:
          navigator.pushReplacementNamed(AppRouter.doctorRejected);
          return;
        case DoctorVerificationStatus.approved:
          navigator.pushReplacementNamed(AppRouter.doctorShell);
          return;
      }
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
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // 1. Subtle premium radial glow background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: <Color>[
                    Color(0xFF0F1C2E), // Primary dark theme base
                    Color(0xFF070B14), // Pure deep slate black
                  ],
                  stops: <double>[0.0, 1.0],
                ),
              ),
            ),
          ),
          
          // 2. Main Centered Branding Mark
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (_, child) => FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(scale: _scaleAnim, child: child),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Neumorphic/Glassmorphic squircle enclosing the logo
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C1422),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.accentBlue.withValues(alpha: 0.20),
                        width: 1.5,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppTheme.accentBlue.withValues(alpha: 0.08),
                          blurRadius: 40,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      AppAssets.appLogo,
                      width: 52,
                      height: 52,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.local_hospital_rounded,
                        color: AppTheme.accentBlue,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Sleek, spaced corporate typography
                  const Text(
                    'QUREXA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 6.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CLINICAL PORTAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Minimal sliding progress indicator at the bottom (Netflix/Uber system style)
          Positioned(
            bottom: 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(1.5),
                  child: Container(
                    width: 120,
                    height: 2.5,
                    color: Colors.white.withValues(alpha: 0.06),
                    child: Stack(
                      children: <Widget>[
                        AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) {
                            final progress = _progressController.value;
                            return Positioned(
                              left: -120 + (progress * 240),
                              width: 120,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      AppTheme.accentBlue.withValues(alpha: 0.0),
                                      AppTheme.accentBlue,
                                      AppTheme.accentBlue.withValues(alpha: 0.0),
                                    ],
                                    stops: const <double>[0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'INITIALIZING SYSTEM',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.25),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
