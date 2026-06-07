import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../../domain/entities/role_mismatch_exception.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/role_mismatch_dialog.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  UserRole _selectedRole = UserRole.patient;
  bool _agreeTerms = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _isSubmitting = false;

  // Populated when navigated from a role-mismatch rejection on the login page.
  String? _redirectMessage;
  bool get _hasRedirectMessage => _redirectMessage != null;

  // Use didChangeDependencies (not initState) so that inherited widgets and
  // ModalRoute — which relies on InheritedWidget — are available.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_redirectMessage != null) return; // already initialised

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final role = args['preselectedRole'];
      final msg  = args['message'];
      if (role is UserRole) {
        setState(() => _selectedRole = role);
      }
      if (msg is String && msg.isNotEmpty) {
        // Use a sentinel empty-string so the banner shows even without a msg.
        setState(() => _redirectMessage = msg);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to terms and conditions.'),
        ),
      );
      return;
    }

    // Doctors go through the dedicated multi-step verification signup flow.
    if (_selectedRole == UserRole.doctor) {
      Navigator.of(context).pushNamed(AppRouter.doctorSignup);
      return;
    }

    setState(() => _isSubmitting = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final appState = AppScope.of(context);

    try {
      await appState.register(
        email: email,
        password: password,
        roleOverride: _selectedRole,
      );
      if (!mounted) return;
      appState.completeOnboarding();
      Navigator.of(context).pushReplacementNamed(AppRouter.profileSetup);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $error')),
      );
    }
  }

  Future<void> _signupWithGoogle() async {
    if (_isSubmitting) return;

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to terms and conditions.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // ── Doctor Role: Google OAuth prefill path ─────────────────────────────
    // For doctors, we intercept the Google OAuth flow BEFORE signing into
    // Firebase. We collect the Google account's name/email as prefill data,
    // then hand it to DoctorSignupScreen to complete the 4-step registration.
    // The Firebase Auth sign-in using the Google credential happens inside
    // DoctorSignupScreen._submit() at the very end, after all form data is
    // collected and validated.
    if (_selectedRole == UserRole.doctor) {
      try {
        final googleSignIn = GoogleSignIn();
        // Force the account picker to appear (prevents silent re-use of a
        // previously signed-in Google account).
        await googleSignIn.signOut().catchError((_) => null);
        final googleUser = await googleSignIn.signIn();
        if (!mounted) return;
        if (googleUser == null) {
          // User cancelled the picker — abort silently.
          setState(() => _isSubmitting = false);
          return;
        }
        // Navigate to the 4-step doctor signup form with the Google account
        // object passed as an argument for credential use at submission.
        setState(() => _isSubmitting = false);
        await Navigator.of(context).pushNamed(
          AppRouter.doctorSignup,
          arguments: googleUser,
        );
      } catch (error) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in failed. Please try again.')),
        );
      }
      return;
    }

    // ── Patient Role: standard Google sign-in path ─────────────────────────
    final appState = AppScope.of(context);
    appState.completeOnboarding();
    try {
      await appState.loginWithGoogle(selectedRole: _selectedRole);

      if (!mounted) return;
      if (appState.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed(AppRouter.profileSetup);
      }
    } on RoleMismatchException catch (e) {
      // Safe sign-out — must never crash the flow.
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      if (!mounted) return;

      await showRoleMismatchDialog(
        context: context,
        exception: e,
        onGoBack: () {
          // Return to the login screen.
          Navigator.of(context).pushReplacementNamed(AppRouter.login);
        },
        onSignUp: () {
          // Stay on the signup page. Show a generic prompt that does not
          // reveal which role is registered on this account.
          setState(() {
            _selectedRole = e.selectedRole;
            _redirectMessage =
                'This Google account is already registered. '
                'Please use a different account or sign in instead.';
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-up failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ─── Header ───────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space6,
                AppTheme.space5,
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
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Join Qurexa',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Your health records, one tap away',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Form ─────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.space6),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // ── Redirect warning banner ──────────────────────
                      if (_hasRedirectMessage) ...<Widget>[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(
                              color: const Color(0xFFFF9800),
                              width: 0.9,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFFE65100),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _redirectMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFE65100),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Role selector
                      const Text(
                        'Register as',
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

                      // Full Name
                      _FieldLabel('Full Name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Ahmed Raza',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) => (value == null ||
                                value.trim().isEmpty)
                            ? 'Full name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Email
                      _FieldLabel('Email'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'you@email.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) => (value == null ||
                                value.trim().isEmpty)
                            ? 'Email is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Password
                      _FieldLabel('Password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          hintText: 'Min. 6 characters',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _hidePassword = !_hidePassword,
                            ),
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                        validator: (value) => (value == null ||
                                value.length < 6)
                            ? 'Minimum 6 characters required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password
                      _FieldLabel('Confirm Password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _hideConfirm,
                        decoration: InputDecoration(
                          hintText: 'Re-enter password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _hideConfirm = !_hideConfirm,
                            ),
                            icon: Icon(
                              _hideConfirm
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value != _passwordController.text
                                ? 'Passwords do not match'
                                : null,
                      ),
                      const SizedBox(height: 18),

                      // Terms checkbox
                      GestureDetector(
                        onTap: () =>
                            setState(() => _agreeTerms = !_agreeTerms),
                        child: Row(
                          children: <Widget>[
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _agreeTerms
                                    ? AppTheme.accentBlue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _agreeTerms
                                      ? AppTheme.accentBlue
                                      : AppTheme.border,
                                ),
                              ),
                              child: _agreeTerms
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'I agree to Terms & Conditions and Privacy Policy',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      PrimaryActionButton(
                        label: 'Create Account',
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _submit,
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
                        onPressed: _isSubmitting ? null : _signupWithGoogle,
                      ),
                      const SizedBox(height: 14),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Already have an account? Sign In',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Role Toggle ──────────────────────────────────────────────────────────────

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
          _Option(
            label: 'Patient',
            icon: Icons.person_rounded,
            isSelected: selected == UserRole.patient,
            onTap: () => onChanged(UserRole.patient),
          ),
          _Option(
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

class _Option extends StatelessWidget {
  const _Option({
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
            color:
                isSelected ? AppTheme.accentBlue : Colors.transparent,
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
