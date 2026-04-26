import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/app_entities.dart';
import '../routes/app_router.dart';
import '../state/app_scope.dart';
import '../widgets/common_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final appState = AppScope.of(context);
    await appState.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    if (!mounted) {
      return;
    }

    if (!appState.seenOnboarding) {
      Navigator.of(context).pushReplacementNamed(AppRouter.onboarding);
      return;
    }

    if (!appState.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MediQGradientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentBlue.withValues(alpha: 0.22),
                  border: Border.all(color: AppTheme.accentBlue, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  AppAssets.appLogo,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 42,
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Text('MediQ', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              const Text(
                'Doctor Appointment & Queue Management',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  final List<_OnboardingItem> _items = const <_OnboardingItem>[
    _OnboardingItem(
      title: 'Book Doctor Appointments In Seconds',
      subtitle:
          'Find nearby specialists, compare fee and rating, and reserve a slot quickly.',
      asset: AppAssets.onboardingBook,
      icon: Icons.calendar_month_rounded,
    ),
    _OnboardingItem(
      title: 'Track Queue Live',
      subtitle:
          'Watch current token updates and arrive at the right time without waiting for hours.',
      asset: AppAssets.onboardingQueue,
      icon: Icons.stacked_line_chart_rounded,
    ),
    _OnboardingItem(
      title: 'Keep Health Records Simple',
      subtitle:
          'Store consultation notes, prescriptions, and medicine reminders in one place.',
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    final appState = AppScope.of(context);
    appState.completeOnboarding();
    Navigator.of(context).pushReplacementNamed(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MediQGradientBackground(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    AppScope.of(context).completeOnboarding();
                    Navigator.of(context).pushReplacementNamed(AppRouter.login);
                  },
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  onPageChanged: (index) {
                    setState(() {
                      _pageIndex = index;
                    });
                  },
                  itemBuilder: (_, index) {
                    final item = _items[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFF1C365A),
                                Color(0xFF162638),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Image.asset(
                            item.asset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) {
                              return Icon(
                                item.icon,
                                size: 100,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_items.length, (index) {
                  final isActive = _pageIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.accentBlue : AppTheme.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 22),
              PrimaryActionButton(
                label: _pageIndex == _items.length - 1 ? 'Get Started' : 'Next',
                onPressed: _onContinue,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  AppScope.of(context).completeOnboarding();
                  Navigator.of(context).pushReplacementNamed(AppRouter.login);
                },
                child: const Text('Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController(
    text: '+92 300 0000000',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '12345678',
  );

  UserRole _selectedRole = UserRole.patient;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login({required bool useGoogle}) async {
    setState(() {
      _isSubmitting = true;
    });

    final appState = AppScope.of(context);
    appState.completeOnboarding();
    await appState.login(selectedRole: _selectedRole);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (_selectedRole == UserRole.doctor) {
      Navigator.of(context).pushReplacementNamed(AppRouter.doctorShell);
      return;
    }

    if (!appState.profileCompleted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.profileSetup);
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRouter.patientShell);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MediQGradientBackground(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              const SizedBox(height: 12),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue your appointments and queue tracking.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 18),
              MediQCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Login as',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<UserRole>(
                      segments: const <ButtonSegment<UserRole>>[
                        ButtonSegment<UserRole>(
                          value: UserRole.patient,
                          icon: Icon(Icons.person_rounded),
                          label: Text('Patient'),
                        ),
                        ButtonSegment<UserRole>(
                          value: UserRole.doctor,
                          icon: Icon(Icons.medical_services_rounded),
                          label: Text('Doctor'),
                        ),
                      ],
                      selected: <UserRole>{_selectedRole},
                      onSelectionChanged: (value) {
                        setState(() {
                          _selectedRole = value.first;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone or Email',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_rounded),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(AppRouter.otp);
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    PrimaryActionButton(
                      label: _isSubmitting ? 'Signing In...' : 'Sign In',
                      onPressed: _isSubmitting
                          ? null
                          : () => _login(useGoogle: false),
                    ),
                    const SizedBox(height: 10),
                    SecondaryActionButton(
                      label: 'Continue with Google',
                      icon: Icons.g_mobiledata_rounded,
                      onPressed: _isSubmitting
                          ? null
                          : () => _login(useGoogle: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRouter.signup),
                child: const Text('New here? Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController(
    text: 'Ahmed Raza',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '+92 300 0000000',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'ahmed@email.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: '12345678',
  );
  final TextEditingController _confirmController = TextEditingController(
    text: '12345678',
  );

  bool _agreeTerms = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms and conditions.')),
      );
      return;
    }

    Navigator.of(context).pushNamed(AppRouter.otp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              MediQCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 8) {
                            return 'Valid phone is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Minimum 6 characters required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: _agreeTerms,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'I agree to Terms & Conditions and Privacy Policy',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _agreeTerms = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 6),
                      PrimaryActionButton(
                        label: 'Create Account',
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit OTP code.')),
      );
      return;
    }

    final appState = AppScope.of(context);
    appState.completeOnboarding();
    await appState.login(selectedRole: UserRole.patient);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRouter.profileSetup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              MediQCard(
                child: Column(
                  children: <Widget>[
                    const Icon(
                      Icons.sms_rounded,
                      size: 50,
                      color: AppTheme.accentBlue,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Enter the 6-digit code sent to +92 300 ••• 4567',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        letterSpacing: 4,
                      ),
                      decoration: const InputDecoration(
                        hintText: '472913',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryActionButton(
                      label: 'Verify & Continue',
                      onPressed: _verify,
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Resend OTP'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController(
    text: 'Ahmed Raza',
  );
  final TextEditingController _ageController = TextEditingController(
    text: '28',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '+92 300 0000000',
  );
  final TextEditingController _bloodController = TextEditingController(
    text: 'B+',
  );
  final TextEditingController _conditionController = TextEditingController(
    text: 'Diabetes, Hypertension',
  );

  String _gender = 'Male';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = AppScope.of(context);
    final profile = appState.profile;
    if (profile != null) {
      _nameController.text = profile.fullName;
      _ageController.text = profile.age.toString();
      _phoneController.text = profile.phone;
      _bloodController.text = profile.bloodGroup ?? _bloodController.text;
      _conditionController.text =
          profile.chronicConditions ?? _conditionController.text;
      _gender = profile.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _bloodController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appState = AppScope.of(context);
    final profile = UserProfile(
      fullName: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      gender: _gender,
      phone: _phoneController.text.trim(),
      bloodGroup: _bloodController.text.trim(),
      chronicConditions: _conditionController.text.trim(),
    );

    appState.completeProfile(profile);

    Navigator.of(context).pushReplacementNamed(AppRouter.patientShell);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              const Text(
                'Doctors use this profile before consultation.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              MediQCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age'),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Valid age is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: const <String>['Male', 'Female', 'Other']
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _gender = value ?? 'Male';
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _bloodController,
                        decoration: const InputDecoration(
                          labelText: 'Blood Group',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _conditionController,
                        decoration: const InputDecoration(
                          labelText: 'Chronic Conditions (Optional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryActionButton(
                        label: 'Save & Continue',
                        onPressed: _saveProfile,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String asset;
  final IconData icon;
}
