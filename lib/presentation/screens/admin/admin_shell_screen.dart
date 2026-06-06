import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/doctor_application.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../state/app_state.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.of(context).loadAdminData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final apps = appState.doctorApplications;
    final pending = apps.where((a) => a.status.name == 'pending').length;
    final approved = apps.where((a) => a.status.name == 'approved').length;
    final rejected = apps.where((a) => a.status.name == 'rejected').length;

    final pages = <Widget>[
      // ── Dashboard ─────────────────────────────────────────────────────────
      SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 8),
            Text('Admin Dashboard',
                style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text('Qurexa Health Platform',
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppTheme.textMuted)),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                _StatCard('Pending', '$pending', AppTheme.qAccent,
                    Icons.pending_rounded),
                const SizedBox(width: 12),
                _StatCard('Approved', '$approved', AppTheme.success,
                    Icons.check_circle_rounded),
                const SizedBox(width: 12),
                _StatCard('Rejected', '$rejected', AppTheme.danger,
                    Icons.cancel_rounded),
              ],
            ),
            const SizedBox(height: 28),
            if (pending > 0) ...<Widget>[
              Text('Requires Attention',
                  style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.qAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(
                      color: AppTheme.qAccent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.notifications_active_rounded,
                        color: AppTheme.qAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$pending doctor verification request${pending > 1 ? 's' : ''} waiting for review.',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _tab = 1),
                      child: const Text('Review'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),

      // ── Verifications ─────────────────────────────────────────────────────
      const AdminDoctorVerificationTab(),

      // ── Settings ──────────────────────────────────────────────────────────
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.admin_panel_settings_rounded,
                  size: 64, color: AppTheme.textMuted),
              const SizedBox(height: 20),
              Text('Admin Account',
                  style: GoogleFonts.dmSans(
                      fontSize: 20, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 32),
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
                    foregroundColor: AppTheme.danger,
                    side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: pages[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.qPrimary,
        unselectedItemColor: AppTheme.textMuted,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.verified_user_rounded), label: 'Verifications'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.count, this.color, this.icon);
  final String label, count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(count,
                style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Verification Tab (embedded) ──────────────────────────────────────────────

class AdminDoctorVerificationTab extends StatefulWidget {
  const AdminDoctorVerificationTab({super.key});

  @override
  State<AdminDoctorVerificationTab> createState() =>
      _AdminDoctorVerificationTabState();
}

class _AdminDoctorVerificationTabState
    extends State<AdminDoctorVerificationTab>
    with SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final all = appState.doctorApplications;
    final pending = all.where((a) => a.status.name == 'pending').toList();
    final approved = all.where((a) => a.status.name == 'approved').toList();
    final rejected = all.where((a) => a.status.name == 'rejected').toList();

    return Column(
      children: <Widget>[
        Container(
          color: AppTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text('Doctor Verifications',
                    style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
              ),
              TabBar(
                controller: _tc,
                labelColor: AppTheme.qPrimary,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: AppTheme.qPrimary,
                tabs: <Tab>[
                  Tab(text: 'Pending (${pending.length})'),
                  Tab(text: 'Approved (${approved.length})'),
                  Tab(text: 'Rejected (${rejected.length})'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tc,
            children: <Widget>[
              _AppList(apps: pending, showActions: true),
              _AppList(apps: approved, showActions: false),
              _AppList(apps: rejected, showActions: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppList extends StatelessWidget {
  const _AppList({required this.apps, required this.showActions});
  final List<DoctorApplication> apps;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.inbox_rounded, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text('No applications',
                style: GoogleFonts.dmSans(
                    color: AppTheme.textMuted, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: apps.length,
      itemBuilder: (ctx, i) =>
          _DoctorCard(app: apps[i], showActions: showActions),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.app, required this.showActions});
  final DoctorApplication app;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final statusColor = app.status == DoctorVerificationStatus.approved
        ? AppTheme.success
        : app.status == DoctorVerificationStatus.rejected
            ? AppTheme.danger
            : AppTheme.qAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.qPrimary.withValues(alpha: 0.12),
                  backgroundImage: _getProfileImageProvider(app.profileImageUrl),
                  child: _getProfileImageProvider(app.profileImageUrl) == null
                      ? Text(
                          app.fullName.isNotEmpty
                              ? app.fullName[0].toUpperCase()
                              : 'D',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: AppTheme.qPrimary),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(app.fullName,
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppTheme.textPrimary)),
                      Text(app.specialization,
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: AppTheme.textSecondary)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (app.status.name).toUpperCase(),
                          style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Details ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                _infoChip(Icons.badge_rounded, 'PMDC: ${app.pmdcNumber}'),
                _infoChip(Icons.school_rounded, app.qualification),
                _infoChip(Icons.work_rounded, '${app.experienceYears} yrs exp'),
                _infoChip(Icons.local_hospital_rounded, app.clinicName),
                _infoChip(Icons.location_on_rounded, app.city),
                _infoChip(Icons.attach_money_rounded,
                    'PKR ${app.consultationFee}'),
              ],
            ),
          ),

          // ── Documents ─────────────────────────────────────────────────
          if (app.pmdcCertificateUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: <Widget>[
                  _docThumb('PMDC', app.pmdcCertificateUrl!, context),
                  if (app.qualificationCertUrl != null) ...<Widget>[
                    const SizedBox(width: 10),
                    _docThumb('Degree',
                        app.qualificationCertUrl!, context),
                  ],
                ],
              ),
            ),

          if (app.rejectionReason != null && app.rejectionReason != '')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Reason: ${app.rejectionReason}',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppTheme.danger)),
              ),
            ),

          // ── Actions ───────────────────────────────────────────────────
          if (showActions)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _approve(context, appState, app.uid),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _reject(context, appState, app.uid),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        side: BorderSide(
                            color: AppTheme.danger.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _approve(
      BuildContext context, AppState appState, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve Doctor'),
        content: const Text(
            'This doctor will be visible to patients immediately.'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Approve',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await appState.approveDoctorApplication(uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor approved successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _reject(
      BuildContext context, AppState appState, String uid) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Doctor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Invalid PMDC number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final reason = reasonCtrl.text.trim().isEmpty
        ? 'Application did not meet our requirements.'
        : reasonCtrl.text.trim();
    try {
      await appState.rejectDoctorApplication(uid, reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor rejected.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

Widget _infoChip(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 12, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppTheme.textSecondary)),
      ],
    ),
  );
}

ImageProvider? _getProfileImageProvider(String? imageAsset) {
  if (imageAsset == null || imageAsset.isEmpty) return null;
  if (imageAsset.startsWith('http://') || imageAsset.startsWith('https://')) {
    return NetworkImage(imageAsset);
  }
  if (imageAsset.startsWith('assets/')) {
    return AssetImage(imageAsset);
  }
  try {
    final bytes = base64Decode(imageAsset);
    return MemoryImage(bytes);
  } catch (_) {
    return null;
  }
}

Widget _docThumb(String label, String url, BuildContext context) {
  final provider = _getProfileImageProvider(url);
  return GestureDetector(
    onTap: () => showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: provider != null
              ? Image(image: provider)
              : const SizedBox(
                  width: 200,
                  height: 200,
                  child: Icon(Icons.broken_image_rounded, size: 48),
                ),
        ),
      ),
    ),
    child: Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: provider != null
              ? Image(
                  image: provider,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context2, error, stack) =>
                      Container(width: 80, height: 80, color: AppTheme.surfaceAlt,
                          child: const Icon(Icons.broken_image_rounded)),
                )
              : Container(width: 80, height: 80, color: AppTheme.surfaceAlt,
                  child: const Icon(Icons.broken_image_rounded)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 10, color: AppTheme.textMuted)),
      ],
    ),
  );
}
