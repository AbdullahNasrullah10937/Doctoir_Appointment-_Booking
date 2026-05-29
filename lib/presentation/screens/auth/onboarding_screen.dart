import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/screen_helpers.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  final List<OnboardingItem> _items = const <OnboardingItem>[
    OnboardingItem(
      title: 'Book Doctors Easily',
      subtitle:
          'Find specialists near you and book your appointment in under 30 seconds.',
      asset: AppAssets.onboardingBook,
      icon: Icons.calendar_month_rounded,
    ),
    OnboardingItem(
      title: 'Track Your Queue Live',
      subtitle:
          'Watch real-time token updates and arrive at exactly the right time — never wait again.',
      asset: AppAssets.onboardingQueue,
      icon: Icons.stacked_line_chart_rounded,
    ),
    OnboardingItem(
      title: 'Keep Records Simple',
      subtitle:
          'Store prescriptions, diagnoses, and medication reminders all in one place.',
      asset: AppAssets.onboardingRecords,
      icon: Icons.folder_open_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_pageIndex < _items.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _finish();
  }

  void _finish() {
    AppScope.of(context).completeOnboarding();
    Navigator.of(context).pushReplacementNamed(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ─── Skip button ─────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: AppTheme.space4,
                  top: AppTheme.space2,
                ),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),

            // ─── Page view (fills remaining space) ───────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemBuilder: (_, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space6,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Illustration box — bounded to avoid overflow
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 260,
                              maxHeight: 220,
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXl,
                                  ),
                                  gradient: AppTheme.primaryGradient,
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: AppTheme.accentBlue.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusXl,
                                  ),
                                  child: Image.asset(
                                    item.asset,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Icon(
                                      item.icon,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontSize: 22, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            height: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ─── Dot indicators ──────────────────────────────────────────────
            PageDotIndicator(count: _items.length, current: _pageIndex),
            const SizedBox(height: 28),

            // ─── Action buttons ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space6),
              child: Column(
                children: <Widget>[
                  PrimaryActionButton(
                    label: _pageIndex == _items.length - 1
                        ? 'Get Started'
                        : 'Next',
                    icon: _pageIndex == _items.length - 1
                        ? Icons.arrow_forward_rounded
                        : null,
                    onPressed: _onContinue,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Already have an account? Sign In'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
