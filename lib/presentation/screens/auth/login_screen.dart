import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../../domain/entities/role_mismatch_exception.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/role_mismatch_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.patient;
  bool _isSubmitting = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter your email and password.');
      return;
    }

    setState(() => _isSubmitting = true);
    final appState = AppScope.of(context);
    appState.completeOnboarding();
    try {
      await appState.login(
        selectedRole: _selectedRole,
        email: email,
        password: password,
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack('Sign in failed: $error');
      setState(() => _isSubmitting = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (appState.role == UserRole.admin) {
      Navigator.of(context).pushReplacementNamed(AppRouter.adminShell);
      return;
    }
    if (appState.role == UserRole.doctor) {
      Navigator.of(context).pushReplacementNamed(AppRouter.doctorShell);
      return;
    }
    if (!appState.profileCompleted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.profileSetup);
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRouter.patientShell);
  }

  Future<void> _loginWithGoogle() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final appState = AppScope.of(context);
    appState.completeOnboarding();
    try {
      await appState.loginWithGoogle(selectedRole: _selectedRole);

      if (!mounted) return;
      if (appState.isLoggedIn) {
        if (appState.role == UserRole.admin) {
          Navigator.of(context).pushReplacementNamed(AppRouter.adminShell);
          return;
        }
        if (appState.role == UserRole.doctor) {
          Navigator.of(context).pushReplacementNamed(AppRouter.doctorShell);
          return;
        }
        if (!appState.profileCompleted) {
          Navigator.of(context).pushReplacementNamed(AppRouter.profileSetup);
          return;
        }
        Navigator.of(context).pushReplacementNamed(AppRouter.patientShell);
      }
    } on RoleMismatchException catch (e) {
      // ── Hard auth failure: role mismatch ─────────────────────────────────
      // 1. Sign out safely — failure must never crash the flow.
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      if (!mounted) return;

      // 2. Show the non-dismissible dialog and handle the user's choice.
      await showRoleMismatchDialog(
        context: context,
        exception: e,
        onGoBack: () {
          // User wants to sign in with their registered role — update the
          // selector and return to the login screen (no auto-retry).
          setState(() => _selectedRole = e.registeredRole);
        },
        onSignUp: () {
          // User wants to use a different Google account — send them to signup
          // with a contextual pre-selected role and warning message.
          Navigator.of(context).pushNamed(
            AppRouter.signup,
            arguments: <String, dynamic>{
              'preselectedRole': e.selectedRole,
              'message':
                  'Your previous Google account is registered as a '
                  '${e.registeredRole == UserRole.doctor ? 'Doctor' : 'Patient'}. '
                  'Please register a new account for the '
                  '${e.selectedRole == UserRole.doctor ? 'Doctor' : 'Patient'} role.',
            },
          );
        },
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack('Google sign in failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ─── Brand header ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space6,
                AppTheme.space6,
                AppTheme.space6,
                AppTheme.space5,
              ),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppTheme.radiusXl),
                  bottomRight: Radius.circular(AppTheme.radiusXl),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: AppTheme.accentBlue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Qurexa',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to manage your health preferences',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // ─── Form ─────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Role toggle
                    const Text(
                      'Login as',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RoleToggle(
                      selected: _selectedRole,
                      onChanged: (role) =>
                          setState(() => _selectedRole = role),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    _FieldLabel('Email'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'you@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password
                    _FieldLabel('Password'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: _hidePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showSnack(
                          'Forgot password flow coming soon.',
                        ),
                        child: const Text('Forgot Password?'),
                      ),
                    ),

                    // Sign in button
                    PrimaryActionButton(
                      label: 'Sign In',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _login,
                    ),
                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: <Widget>[
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Google button
                    SecondaryActionButton(
                      label: 'Continue with Google',
                      customIcon: Image.asset(
                        'assets/images/branding/google_logo.png',
                        width: 20,
                        height: 20,
                      ),
                      onPressed: _isSubmitting ? null : _loginWithGoogle,
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRouter.signup),
                        child: const Text('New User? Create Account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Role Toggle Widget ────────────────────────────────────────────────────────

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.selected, required this.onChanged});

  final UserRole selected;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: <Widget>[
          _RoleOption(
            label: 'Patient',
            icon: Icons.person_rounded,
            isSelected: selected == UserRole.patient,
            onTap: () => onChanged(UserRole.patient),
          ),
          _RoleOption(
            label: 'Doctor',
            icon: Icons.medical_services_rounded,
            isSelected: selected == UserRole.doctor,
            onTap: () => onChanged(UserRole.doctor),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
