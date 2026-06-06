import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/doctor_application.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';

class DoctorRejectedScreen extends StatelessWidget {
  const DoctorRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final app = appState.currentDoctorApplication;
    final reason = app?.rejectionReason ?? 'Please contact support for details.';

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: <Widget>[
              const Spacer(),

              // ── Icon ─────────────────────────────────────────────────────
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.danger.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.cancel_outlined,
                  color: AppTheme.danger,
                  size: 56,
                ),
              ),
              const SizedBox(height: 32),

              // ── Title ────────────────────────────────────────────────────
              Text(
                'Verification Rejected',
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Your verification request was rejected.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // ── Reason card ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(
                    color: AppTheme.danger.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.info_outline_rounded,
                            color: AppTheme.danger, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Reason',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      reason,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── Resubmit button ──────────────────────────────────────────
              if (app != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _resubmit(context, appState, app),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Resubmit Verification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.qPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // ── Logout ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    appState.logout();
                    Navigator.of(context)
                        .pushReplacementNamed(AppRouter.login);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resubmit(
    BuildContext context,
    dynamic appState,
    DoctorApplication current,
  ) async {
    // Navigate to doctor signup in "resubmit" mode — step 4 only
    Navigator.of(context).pushNamed(
      AppRouter.doctorSignup,
      arguments: <String, dynamic>{'resubmit': true, 'application': current},
    );
  }
}
