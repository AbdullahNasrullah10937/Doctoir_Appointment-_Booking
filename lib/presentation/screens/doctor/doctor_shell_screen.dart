import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/screen_helpers.dart';

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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.qCard,
          border: Border(top: BorderSide(color: AppTheme.qBorder)),
        ),
        child: NavigationBar(
          height: 64,
          selectedIndex: appState.doctorTabIndex,
          onDestinationSelected: appState.setDoctorTab,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule_rounded), label: 'Schedule'),
            NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt_rounded), label: 'Queue'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
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
    final app = appState.currentDoctorApplication;

    String name = app?.fullName ?? 'Dr. Sara Ali';
    if (app != null && !name.toLowerCase().startsWith('dr')) {
      name = 'Dr. $name';
    }
    final initials = buildInitials(name, fallback: 'DR');
    final image = app?.profileImageUrl ?? AppAssets.doctorSara;
    final specialty = app != null
        ? '${app.specialization} • ${app.qualification}'
        : 'General Physician • MBBS, FCPS';

    return Column(
      key: const ValueKey<String>('doc-dashboard'),
      children: <Widget>[
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space4, AppTheme.space4, AppTheme.space5),
          decoration: const BoxDecoration(
            gradient: AppTheme.qHeaderGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  AssetCircleAvatar(imageAsset: image, initials: initials, radius: 22, borderColor: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(specialty, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                onPressed: () async {
                  final newSchedule = await showModalBottomSheet<DoctorSchedule>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _EditScheduleSheet(initialSchedule: slots),
                  );
                  if (newSchedule != null) {
                    await appState.updateDoctorSchedule(newSchedule);
                  }
                },
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
    final app = appState.currentDoctorApplication;

    String name = app?.fullName ?? 'Dr. Sara Ali';
    if (app != null && !name.toLowerCase().startsWith('dr')) {
      name = 'Dr. $name';
    }
    final initials = buildInitials(name, fallback: 'DR');
    final image = app?.profileImageUrl ?? AppAssets.doctorSara;
    final specialty = app != null
        ? '${app.specialization} • ${app.qualification}'
        : 'General Physician • FCPS';

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
              AssetCircleAvatar(imageAsset: image, initials: initials, radius: 36, borderColor: Colors.white),
              const SizedBox(height: 10),
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 3),
              Text(specialty, style: const TextStyle(color: Colors.white70, fontSize: 13)),
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

class _EditScheduleSheet extends StatefulWidget {
  const _EditScheduleSheet({required this.initialSchedule});
  final DoctorSchedule initialSchedule;

  @override
  State<_EditScheduleSheet> createState() => _EditScheduleSheetState();
}

class _EditScheduleSheetState extends State<_EditScheduleSheet> {
  late List<String> _workingDays;
  late TimeOfDay _morningStart;
  late TimeOfDay _morningEnd;
  late TimeOfDay _eveningStart;
  late TimeOfDay _eveningEnd;

  final List<String> _allDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _workingDays = List<String>.from(widget.initialSchedule.workingDays);
    _morningStart = _parseTimeString(widget.initialSchedule.morningStart);
    _morningEnd = _parseTimeString(widget.initialSchedule.morningEnd);
    _eveningStart = _parseTimeString(widget.initialSchedule.eveningStart);
    _eveningEnd = _parseTimeString(widget.initialSchedule.eveningEnd);
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final clean = timeStr.trim().replaceAll(RegExp(r'\s+'), ' ');
      final parts = clean.split(' ');
      if (parts.length != 2) return const TimeOfDay(hour: 9, minute: 0);
      final ampm = parts[1].toUpperCase();
      final timeParts = parts[0].split(':');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      if (ampm == 'PM' && hour < 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour;
    final minute = tod.minute;
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $ampm';
  }

  int _toMinutes(TimeOfDay tod) => tod.hour * 60 + tod.minute;

  void _save() {
    final morningStartMins = _toMinutes(_morningStart);
    final morningEndMins = _toMinutes(_morningEnd);
    final eveningStartMins = _toMinutes(_eveningStart);
    final eveningEndMins = _toMinutes(_eveningEnd);

    if (_workingDays.isEmpty) {
      _showError('Please select at least one working day.');
      return;
    }
    if (morningStartMins >= morningEndMins) {
      _showError('Morning start time must be before morning end time.');
      return;
    }
    if (eveningStartMins >= eveningEndMins) {
      _showError('Evening start time must be before evening end time.');
      return;
    }
    if (morningEndMins >= eveningStartMins) {
      _showError('Morning shift must end before the evening shift starts.');
      return;
    }

    final newSchedule = DoctorSchedule(
      workingDays: _workingDays,
      morningStart: _formatTimeOfDay(_morningStart),
      morningEnd: _formatTimeOfDay(_morningEnd),
      eveningStart: _formatTimeOfDay(_eveningStart),
      eveningEnd: _formatTimeOfDay(_eveningEnd),
      blockedDates: widget.initialSchedule.blockedDates,
    );

    Navigator.of(context).pop(newSchedule);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  Widget _buildTimeTile({
    required String label,
    required TimeOfDay value,
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  Text(_formatTimeOfDay(value), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.access_time_rounded, color: AppTheme.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppTheme.space4,
        AppTheme.space4,
        AppTheme.space4,
        AppTheme.space4 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Work Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),

            // Working Days
            const Text(
              'Select Working Days',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allDays.map((day) {
                final isSelected = _workingDays.contains(day);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _workingDays.remove(day);
                      } else {
                        _workingDays.add(day);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.accentBlue : AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                      border: Border.all(
                        color: isSelected ? AppTheme.accentBlue : AppTheme.border,
                      ),
                    ),
                    child: Text(
                      day.substring(0, 3),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Morning Timing
            const Text(
              'Morning Shift (Start & End)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTimeTile(
                    label: 'Start Time',
                    value: _morningStart,
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: _morningStart);
                      if (time != null) setState(() => _morningStart = time);
                    },
                    icon: Icons.wb_sunny_rounded,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeTile(
                    label: 'End Time',
                    value: _morningEnd,
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: _morningEnd);
                      if (time != null) setState(() => _morningEnd = time);
                    },
                    icon: Icons.wb_sunny_rounded,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Evening Timing
            const Text(
              'Evening Shift (Start & End)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTimeTile(
                    label: 'Start Time',
                    value: _eveningStart,
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: _eveningStart);
                      if (time != null) setState(() => _eveningStart = time);
                    },
                    icon: Icons.nights_stay_rounded,
                    color: AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeTile(
                    label: 'End Time',
                    value: _eveningEnd,
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: _eveningEnd);
                      if (time != null) setState(() => _eveningEnd = time);
                    },
                    icon: Icons.nights_stay_rounded,
                    color: AppTheme.accentBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Action buttons
            PrimaryActionButton(
              label: 'Save Schedule',
              onPressed: _save,
            ),
            const SizedBox(height: 8),
            SecondaryActionButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
