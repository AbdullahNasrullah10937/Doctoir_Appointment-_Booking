import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';

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
    final profile = AppScope.of(context).profile;
    if (profile != null) {
      _nameController.text = profile.fullName;
      _ageController.text = profile.age.toString();
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
    _bloodController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final appState = AppScope.of(context);
    final profile = UserProfile(
      fullName: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      gender: _gender,
      bloodGroup: _bloodController.text.trim(),
      chronicConditions: _conditionController.text.trim(),
    );

    appState.completeProfile(profile);
    Navigator.of(context).pushReplacementNamed(AppRouter.patientShell);
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
                  const Text(
                    'Complete Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Step 1 of 1 — Doctors need this info before your consultation',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  // Step progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 5,
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
                      // Avatar
                      Center(
                        child: Stack(
                          children: <Widget>[
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.primarySoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.accentBlue,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppTheme.accentBlue,
                                size: 40,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Full Name
                      _FieldLabel('Full Name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Your full name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) => (value == null ||
                                value.trim().isEmpty)
                            ? 'Full name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Age + Gender row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _FieldLabel('Age'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '25',
                                    prefixIcon: Icon(Icons.cake_outlined),
                                  ),
                                  validator: (value) {
                                    final parsed = int.tryParse(value ?? '');
                                    if (parsed == null || parsed <= 0) {
                                      return 'Enter valid age';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _FieldLabel('Gender'),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _gender,
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.wc_rounded),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                  items: const <String>['Male', 'Female', 'Other']
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: item,
                                          child: Text(item),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      setState(() => _gender = value ?? 'Male'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Blood Group
                      _FieldLabel('Blood Group'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _bloodController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. O+, B-',
                          prefixIcon: Icon(Icons.bloodtype_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Chronic Conditions
                      _FieldLabel('Chronic Conditions (Optional)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _conditionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Diabetes, Hypertension',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Icon(
                              Icons.medical_information_outlined,
                            ),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 28),

                      PrimaryActionButton(
                        label: 'Save & Continue',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: _saveProfile,
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
