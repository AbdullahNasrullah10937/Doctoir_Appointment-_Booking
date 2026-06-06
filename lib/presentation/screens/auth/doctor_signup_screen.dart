import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../../domain/entities/doctor_application.dart';
import '../../../data/firebase/doctor_application_sync.dart';
import '../../../data/firebase/patient_cloud_sync.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';

class DoctorSignupScreen extends StatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final PageController _pageCtrl = PageController();
  int _step = 0;
  bool _isSubmitting = false;

  // Step 1 — Account
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _gender = 'Male';
  bool _hidePass = true;
  bool _hideConfirm = true;
  final _step1Key = GlobalKey<FormState>();

  // Step 2 — Professional
  final _pmdcCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _qualCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _step2Key = GlobalKey<FormState>();

  // Step 3 — Clinic & Availability
  final _clinicCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _startCtrl = TextEditingController(text: '09:00 AM');
  final _endCtrl = TextEditingController(text: '05:00 PM');
  bool _onlineConsult = false;
  final Map<String, bool> _days = {
    'Mon': true, 'Tue': true, 'Wed': true,
    'Thu': true, 'Fri': true, 'Sat': false, 'Sun': false,
  };
  final _step3Key = GlobalKey<FormState>();

  // Step 4 — Documents
  File? _profileImg;
  File? _pmdcImg;
  File? _qualImg;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in [
      _nameCtrl, _emailCtrl, _passCtrl, _confirmCtrl, _phoneCtrl,
      _pmdcCtrl, _specCtrl, _qualCtrl, _expCtrl, _feeCtrl, _bioCtrl,
      _clinicCtrl, _addressCtrl, _cityCtrl, _startCtrl, _endCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  void _next() {
    final keys = [_step1Key, _step2Key, _step3Key];
    if (_step < 3) {
      if (keys[_step].currentState?.validate() != true) return;
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _step++);
    }
  }

  void _prev() {
    if (_step > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _step--);
    }
  }

  Future<void> _pickImage(String field) async {
    final double maxDim = field == 'profile' ? 150.0 : 300.0;
    final int qual = field == 'profile' ? 70 : 45;
    final xf = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxDim,
      maxHeight: maxDim,
      imageQuality: qual,
    );
    if (xf == null) return;
    setState(() {
      if (field == 'profile') _profileImg = File(xf.path);
      if (field == 'pmdc') _pmdcImg = File(xf.path);
      if (field == 'qual') _qualImg = File(xf.path);
    });
  }

  Future<String?> _toBase64(File? file) async {
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _submit() async {
    if (_pmdcImg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PMDC certificate is required.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    UserCredential? cred;
    try {
      // Convert images to base64 first
      final profileUrl = await _toBase64(_profileImg);
      final pmdcUrl = await _toBase64(_pmdcImg);
      final qualUrl = await _toBase64(_qualImg);

      // Create Firebase Auth account
      cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      final uid = cred.user!.uid;

      // Write role meta
      final roleMetaSuccess = await PatientCloudBootstrap.writeRoleMeta(
        firebaseUserId: uid,
        role: UserRole.doctor,
      );
      if (!roleMetaSuccess) {
        throw Exception('Failed to write user role. Please try again.');
      }

      final repo = DoctorApplicationRepository();
      await repo.writePendingMeta(uid);

      final app = DoctorApplication(
        uid: uid,
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        gender: _gender,
        pmdcNumber: _pmdcCtrl.text.trim(),
        specialization: _specCtrl.text.trim(),
        qualification: _qualCtrl.text.trim(),
        experienceYears: int.tryParse(_expCtrl.text.trim()) ?? 0,
        consultationFee: int.tryParse(_feeCtrl.text.trim()) ?? 0,
        bio: _bioCtrl.text.trim(),
        clinicName: _clinicCtrl.text.trim(),
        clinicAddress: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        status: DoctorVerificationStatus.pending,
        createdAt: DateTime.now().toUtc(),
        profileImageUrl: profileUrl,
        pmdcCertificateUrl: pmdcUrl,
        qualificationCertUrl: qualUrl,
        availability: Map<String, bool>.from(_days),
        availabilityStart: _startCtrl.text.trim(),
        availabilityEnd: _endCtrl.text.trim(),
        onlineConsultation: _onlineConsult,
      );

      await repo.submitApplication(app);

      if (!mounted) return;
      final appState = AppScope.of(context);
      appState.setDoctorRegistered(app);

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRouter.doctorPending,
        (_) => false,
      );
    } catch (e) {
      if (cred != null) {
        try {
          await cred.user?.delete();
        } catch (authDeleteError) {
          debugPrint('Failed to delete auth user during rollback: $authDeleteError');
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Account', 'Professional', 'Clinic', 'Documents'];
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF0B6E6E), Color(0xFF0D9B9B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: _step == 0
                            ? () => Navigator.of(context).pop()
                            : _prev,
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                      ),
                      const Text(
                        'Doctor Registration',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress
                  Row(
                    children: List.generate(steps.length, (i) {
                      final done = i <= _step;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            children: <Widget>[
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: done
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                steps[i],
                                style: TextStyle(
                                  color: done
                                      ? Colors.white
                                      : Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: <Widget>[
                  _Step1(
                    formKey: _step1Key,
                    nameCtrl: _nameCtrl,
                    emailCtrl: _emailCtrl,
                    passCtrl: _passCtrl,
                    confirmCtrl: _confirmCtrl,
                    phoneCtrl: _phoneCtrl,
                    gender: _gender,
                    hidePass: _hidePass,
                    hideConfirm: _hideConfirm,
                    onGenderChanged: (v) => setState(() => _gender = v),
                    onTogglePass: () => setState(() => _hidePass = !_hidePass),
                    onToggleConfirm: () =>
                        setState(() => _hideConfirm = !_hideConfirm),
                    onNext: _next,
                  ),
                  _Step2(
                    formKey: _step2Key,
                    pmdcCtrl: _pmdcCtrl,
                    specCtrl: _specCtrl,
                    qualCtrl: _qualCtrl,
                    expCtrl: _expCtrl,
                    feeCtrl: _feeCtrl,
                    bioCtrl: _bioCtrl,
                    onNext: _next,
                  ),
                  _Step3(
                    formKey: _step3Key,
                    clinicCtrl: _clinicCtrl,
                    addressCtrl: _addressCtrl,
                    cityCtrl: _cityCtrl,
                    startCtrl: _startCtrl,
                    endCtrl: _endCtrl,
                    days: _days,
                    onlineConsult: _onlineConsult,
                    onDayChanged: (d, v) => setState(() => _days[d] = v),
                    onOnlineChanged: (v) =>
                        setState(() => _onlineConsult = v),
                    onNext: _next,
                  ),
                  _Step4(
                    profileImg: _profileImg,
                    pmdcImg: _pmdcImg,
                    qualImg: _qualImg,
                    isSubmitting: _isSubmitting,
                    onPickProfile: () => _pickImage('profile'),
                    onPickPmdc: () => _pickImage('pmdc'),
                    onPickQual: () => _pickImage('qual'),
                    onSubmit: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 1: Account ──────────────────────────────────────────────────────────
class _Step1 extends StatelessWidget {
  const _Step1({
    required this.formKey, required this.nameCtrl, required this.emailCtrl,
    required this.passCtrl, required this.confirmCtrl, required this.phoneCtrl,
    required this.gender, required this.hidePass, required this.hideConfirm,
    required this.onGenderChanged, required this.onTogglePass,
    required this.onToggleConfirm, required this.onNext,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, emailCtrl, passCtrl, confirmCtrl, phoneCtrl;
  final String gender;
  final bool hidePass, hideConfirm;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onTogglePass, onToggleConfirm, onNext;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _sectionTitle('Basic Information'),
          _field('Full Name', nameCtrl, icon: Icons.person_outline,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null),
          _field('Email', emailCtrl, icon: Icons.email_outlined,
              type: TextInputType.emailAddress,
              validator: (v) => !v!.contains('@') ? 'Invalid email' : null),
          _passwordField('Password', passCtrl, hidePass, onTogglePass,
              validator: (v) => v!.length < 6 ? 'Min 6 chars' : null),
          _passwordField('Confirm Password', confirmCtrl, hideConfirm,
              onToggleConfirm,
              validator: (v) => v != passCtrl.text ? 'Passwords do not match' : null),
          _field('Phone Number', phoneCtrl, icon: Icons.phone_outlined,
              type: TextInputType.phone,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 8),
          _sectionTitle('Gender'),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              for (final g in ['Male', 'Female', 'Other'])
                Expanded(
                  child: GestureDetector(
                    onTap: () => onGenderChanged(g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: gender == g
                            ? AppTheme.qPrimary
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: gender == g
                              ? AppTheme.qPrimary
                              : AppTheme.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        g,
                        style: TextStyle(
                          color: gender == g ? Colors.white : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          PrimaryActionButton(label: 'Next: Professional Info', onPressed: onNext),
        ],
      ),
    );
  }
}

// ─── Step 2: Professional ─────────────────────────────────────────────────────
class _Step2 extends StatelessWidget {
  const _Step2({
    required this.formKey, required this.pmdcCtrl, required this.specCtrl,
    required this.qualCtrl, required this.expCtrl, required this.feeCtrl,
    required this.bioCtrl, required this.onNext,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController pmdcCtrl, specCtrl, qualCtrl, expCtrl, feeCtrl, bioCtrl;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _sectionTitle('Professional Information'),
          _field('PMDC Registration Number', pmdcCtrl,
              icon: Icons.badge_outlined,
              validator: (v) => v!.trim().isEmpty ? 'PMDC number is required' : null),
          _field('Specialization', specCtrl, icon: Icons.medical_services_outlined,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null),
          _field('Qualification (e.g. MBBS, FCPS)', qualCtrl,
              icon: Icons.school_outlined,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null),
          _field('Years of Experience', expCtrl, icon: Icons.timeline_rounded,
              type: TextInputType.number,
              validator: (v) {
                if (v!.trim().isEmpty) return 'Required';
                if (int.tryParse(v.trim()) == null) return 'Must be a number';
                return null;
              }),
          _field('Consultation Fee (PKR)', feeCtrl,
              icon: Icons.monetization_on_outlined,
              type: TextInputType.number,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null),
          _field('Bio / About', bioCtrl, icon: Icons.notes_rounded,
              maxLines: 4, isRequired: false),
          const SizedBox(height: 24),
          PrimaryActionButton(label: 'Next: Clinic Info', onPressed: onNext),
        ],
      ),
    );
  }
}

// ─── Step 3: Clinic & Availability ───────────────────────────────────────────
class _Step3 extends StatelessWidget {
  const _Step3({
    required this.formKey, required this.clinicCtrl, required this.addressCtrl,
    required this.cityCtrl, required this.startCtrl, required this.endCtrl,
    required this.days, required this.onlineConsult,
    required this.onDayChanged, required this.onOnlineChanged, required this.onNext,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController clinicCtrl, addressCtrl, cityCtrl, startCtrl, endCtrl;
  final Map<String, bool> days;
  final bool onlineConsult;
  final void Function(String, bool) onDayChanged;
  final ValueChanged<bool> onOnlineChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          _sectionTitle('Clinic / Hospital'),
          _field('Clinic / Hospital Name', clinicCtrl,
              icon: Icons.local_hospital_outlined,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null),
          _field('Clinic Address', addressCtrl,
              icon: Icons.location_on_outlined,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null),
          _field('City', cityCtrl, icon: Icons.location_city_outlined,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null),
          _sectionTitle('Availability'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: days.entries.map((e) {
              return FilterChip(
                label: Text(e.key),
                selected: e.value,
                onSelected: (v) => onDayChanged(e.key, v),
                selectedColor: AppTheme.qPrimary.withValues(alpha: 0.15),
                checkmarkColor: AppTheme.qPrimary,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _field('Start Time', startCtrl,
                    icon: Icons.schedule_rounded, isRequired: false),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field('End Time', endCtrl,
                    icon: Icons.schedule_outlined, isRequired: false),
              ),
            ],
          ),
          SwitchListTile(
            value: onlineConsult,
            onChanged: onOnlineChanged,
            title: Text('Online Consultations Available',
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppTheme.textSecondary)),
            activeThumbColor: AppTheme.qPrimary,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          PrimaryActionButton(label: 'Next: Upload Documents', onPressed: onNext),
        ],
      ),
    );
  }
}

// ─── Step 4: Documents ────────────────────────────────────────────────────────
class _Step4 extends StatelessWidget {
  const _Step4({
    required this.profileImg, required this.pmdcImg, required this.qualImg,
    required this.isSubmitting, required this.onPickProfile,
    required this.onPickPmdc, required this.onPickQual, required this.onSubmit,
  });
  final File? profileImg, pmdcImg, qualImg;
  final bool isSubmitting;
  final VoidCallback onPickProfile, onPickPmdc, onPickQual, onSubmit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        _sectionTitle('Verification Documents'),
        const SizedBox(height: 4),
        Text(
          'Upload clear photos of your documents. PMDC certificate is required.',
          style: GoogleFonts.dmSans(
              fontSize: 13, color: AppTheme.textMuted, height: 1.5),
        ),
        const SizedBox(height: 20),
        _DocPicker(
          label: 'Profile Photo',
          file: profileImg,
          icon: Icons.person_rounded,
          required: false,
          onPick: onPickProfile,
        ),
        const SizedBox(height: 12),
        _DocPicker(
          label: 'PMDC Certificate *',
          file: pmdcImg,
          icon: Icons.badge_rounded,
          required: true,
          onPick: onPickPmdc,
        ),
        const SizedBox(height: 12),
        _DocPicker(
          label: 'Degree / Qualification Certificate',
          file: qualImg,
          icon: Icons.school_rounded,
          required: false,
          onPick: onPickQual,
        ),
        const SizedBox(height: 32),
        PrimaryActionButton(
          label: 'Submit Application',
          isLoading: isSubmitting,
          onPressed: isSubmitting ? null : onSubmit,
        ),
      ],
    );
  }
}

class _DocPicker extends StatelessWidget {
  const _DocPicker({
    required this.label, required this.file, required this.icon,
    required this.required, required this.onPick,
  });
  final String label;
  final File? file;
  final IconData icon;
  final bool required;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: file != null
              ? AppTheme.qPrimary.withValues(alpha: 0.06)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: file != null ? AppTheme.qPrimary : AppTheme.border,
          ),
        ),
        child: Row(
          children: <Widget>[
            const SizedBox(width: 16),
            if (file != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(file!,
                    width: 52, height: 52, fit: BoxFit.cover),
              )
            else
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.textMuted, size: 28),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label,
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(
                    file != null ? 'Tap to change' : 'Tap to upload',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Icon(
              file != null
                  ? Icons.check_circle_rounded
                  : Icons.upload_file_rounded,
              color: file != null ? AppTheme.success : AppTheme.textMuted,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _sectionTitle(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );

Widget _field(
  String label,
  TextEditingController ctrl, {
  IconData? icon,
  TextInputType type = TextInputType.text,
  String? Function(String?)? validator,
  int maxLines = 1,
  bool isRequired = true,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      validator: isRequired
          ? (validator ??
              (v) => v!.trim().isEmpty ? '$label is required' : null)
          : validator,
    ),
  );
}

Widget _passwordField(
  String label,
  TextEditingController ctrl,
  bool hide,
  VoidCallback onToggle, {
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      obscureText: hide,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(hide ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppTheme.textMuted),
        ),
      ),
      validator: validator,
    ),
  );
}
