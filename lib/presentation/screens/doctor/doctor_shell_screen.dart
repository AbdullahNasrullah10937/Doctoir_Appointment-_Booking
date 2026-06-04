import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';

class DoctorShellScreen extends StatefulWidget {
  const DoctorShellScreen({super.key});

  @override
  State<DoctorShellScreen> createState() => _DoctorShellScreenState();
}

class _DoctorShellScreenState extends State<DoctorShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.of(context).loadAppData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    const pages = <Widget>[
      _DoctorDashboardTab(),
      _DoctorScheduleTab(),
      _DoctorQueueTab(),
      _DoctorSettingsTab(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: pages[appState.doctorTabIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appState.doctorTabIndex,
        onDestinationSelected: appState.setDoctorTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule_rounded), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt_rounded), label: 'Queue'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

// ─── DASHBOARD TAB ─────────────────────────────────────────────────────────────

class _DoctorDashboardTab extends StatelessWidget {
  const _DoctorDashboardTab();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final queue = appState.doctorQueue;

    return Column(
      key: const ValueKey<String>('doc-dashboard'),
      children: <Widget>[
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space4, AppTheme.space4, AppTheme.space5),
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
                  AssetCircleAvatar(imageAsset: AppAssets.doctorSara, initials: 'SA', radius: 22, borderColor: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Dr. Sara Ali', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        Text('General Physician • MBBS, FCPS', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        const Text('Available', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats row
              Row(
                children: <Widget>[
                  _WhiteStat(value: '${queue.length}', label: 'Today\'s Patients'),
                  const SizedBox(width: 10),
                  const _WhiteStat(value: '1.2K', label: 'Total Patients'),
                  const SizedBox(width: 10),
                  const _WhiteStat(value: '4.8 ★', label: 'Rating'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.space4),
            children: <Widget>[
              const SectionHeading(title: 'Today\'s Overview'),
              Row(
                children: <Widget>[
                  Expanded(child: _DashCard(icon: Icons.pending_actions_rounded, label: 'Pending', value: '${queue.length}', color: AppTheme.warning)),
                  const SizedBox(width: 10),
                  Expanded(child: _DashCard(icon: Icons.check_circle_rounded, label: 'Done', value: '0', color: AppTheme.success)),
                  const SizedBox(width: 10),
                  Expanded(child: _DashCard(icon: Icons.access_time_rounded, label: 'Wait (avg)', value: '12m', color: AppTheme.accentBlue)),
                ],
              ),
              const SizedBox(height: 4),
              // Next patient
              SectionHeading(
                title: 'Patient Queue',
                trailing: TextButton(onPressed: () => appState.setDoctorTab(2), child: const Text('View All')),
              ),
              if (queue.isEmpty)
                const EmptyStateView(title: 'No patients queued', message: 'New bookings will appear here.', icon: Icons.people_alt_rounded)
              else
                ...queue.take(3).map((p) => _PatientQueueCard(patient: p)),
            ],
          ),
        ),
      ],
    );
  }
}

class _WhiteStat extends StatelessWidget {
  const _WhiteStat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: <Widget>[
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  const _DashCard({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── SCHEDULE TAB ─────────────────────────────────────────────────────────────

class _DoctorScheduleTab extends StatelessWidget {
  const _DoctorScheduleTab();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final slots = appState.doctorSchedule;

    return Column(
      key: const ValueKey<String>('doc-schedule'),
      children: <Widget>[
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space4, AppTheme.space4, AppTheme.space3),
          child: Row(
            children: <Widget>[
              const Expanded(child: Text('Manage Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(AppTheme.radiusChip)),
                child: const Text('Add Slot', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.space4),
            children: <Widget>[
              // Working days
              MediQCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeading(title: 'Working Days'),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: slots.workingDays.map((day) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySoft,
                          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                          border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.3)),
                        ),
                        child: Text(day, style: const TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700)),
                      )).toList(),
                    ),
                    const SizedBox(height: 14),
                    const SectionHeading(title: 'Timing'),
                    _TimeRow(icon: Icons.wb_sunny_rounded, label: 'Morning', value: '${slots.morningStart} – ${slots.morningEnd}', color: AppTheme.warning),
                    const SizedBox(height: 8),
                    _TimeRow(icon: Icons.nights_stay_rounded, label: 'Evening', value: '${slots.eveningStart} – ${slots.eveningEnd}', color: AppTheme.accentBlue),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SecondaryActionButton(
                label: 'Edit Schedule',
                icon: Icons.edit_calendar_rounded,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── QUEUE TAB ─────────────────────────────────────────────────────────────────

class _DoctorQueueTab extends StatelessWidget {
  const _DoctorQueueTab();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final queue = appState.doctorQueue;

    return Column(
      key: const ValueKey<String>('doc-queue'),
      children: <Widget>[
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space4, AppTheme.space4, AppTheme.space3),
          child: Row(
            children: <Widget>[
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Patient Queue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('${queue.length} patients today', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ],
              )),
              StatusBadge(label: 'Live', color: AppTheme.success),
            ],
          ),
        ),
        Expanded(
          child: queue.isEmpty
              ? const EmptyStateView(title: 'Queue is empty', message: 'Patients will appear here once they book an appointment.', icon: Icons.people_alt_rounded)
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  itemCount: queue.length,
                  itemBuilder: (_, i) => _PatientQueueCard(patient: queue[i]),
                ),
        ),
      ],
    );
  }
}

class _PatientQueueCard extends StatelessWidget {
  const _PatientQueueCard({required this.patient});
  final PatientCase patient;

  @override
  Widget build(BuildContext context) {
    return MediQCard(
      onTap: () => Navigator.of(context).pushNamed(AppRouter.doctorPatientDetails, arguments: patient),
      child: Row(
        children: <Widget>[
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppTheme.primarySoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('${patient.token}', style: const TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(patient.patientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text('${patient.age} yrs • ${patient.gender}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                if (patient.symptoms.isNotEmpty)
                  Text(patient.symptoms, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(
            label: patient.token <= 5 ? 'Next' : 'Waiting',
            color: patient.token <= 5 ? AppTheme.warning : AppTheme.textMuted,
          ),
        ],
      ),
    );
  }
}

// ─── SETTINGS TAB ─────────────────────────────────────────────────────────────

class _DoctorSettingsTab extends StatelessWidget {
  const _DoctorSettingsTab();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    return Column(
      key: const ValueKey<String>('doc-settings'),
      children: <Widget>[
        // Profile banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space5, AppTheme.space4, AppTheme.space5),
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(AppTheme.radiusXl),
              bottomRight: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          child: Column(
            children: <Widget>[
              AssetCircleAvatar(imageAsset: AppAssets.doctorSara, initials: 'SA', radius: 36, borderColor: Colors.white),
              const SizedBox(height: 10),
              const Text('Dr. Sara Ali', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 3),
              const Text('General Physician • FCPS', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.space4),
            children: <Widget>[
              const SectionHeading(title: 'Clinic'),
              _SettingsTile(icon: Icons.schedule_rounded, title: 'Manage Schedule', onTap: () => appState.setDoctorTab(1)),
              _SettingsTile(icon: Icons.people_alt_rounded, title: 'View Patient Queue', onTap: () => appState.setDoctorTab(2)),
              const SizedBox(height: 8),
              const SectionHeading(title: 'Support'),
              _SettingsTile(icon: Icons.help_rounded, title: 'Help & Support', onTap: () => Navigator.of(context).pushNamed(AppRouter.helpSupport)),
              _SettingsTile(icon: Icons.call_rounded, title: 'Emergency Numbers', onTap: () => Navigator.of(context).pushNamed(AppRouter.emergency)),
              const SizedBox(height: 8),
              MediQCard(
                onTap: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: <Widget>[
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            appState.logout();
                            Navigator.of(context).pushReplacementNamed(AppRouter.login);
                          },
                          child: const Text('Sign Out', style: TextStyle(color: AppTheme.danger)),
                        ),
                      ],
                    ),
                  );
                },
                borderColor: AppTheme.dangerLight,
                child: const Row(
                  children: <Widget>[
                    Icon(Icons.logout_rounded, color: AppTheme.danger, size: 20),
                    SizedBox(width: 12),
                    Text('Sign Out', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MediQCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppTheme.accentBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}
