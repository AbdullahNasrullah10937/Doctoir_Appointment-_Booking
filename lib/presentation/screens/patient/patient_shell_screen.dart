import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/screen_helpers.dart';

class PatientShellScreen extends StatefulWidget {
  const PatientShellScreen({super.key});

  @override
  State<PatientShellScreen> createState() => _PatientShellScreenState();
}

class _PatientShellScreenState extends State<PatientShellScreen> {
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
      _PatientHomeTab(),
      _PatientAppointmentsTab(),
      _PatientRecordsTab(),
      _PatientSettingsTab(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: pages[appState.patientTabIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appState.patientTabIndex,
        onDestinationSelected: appState.setPatientTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_rounded), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Appointments'),
          NavigationDestination(icon: Icon(Icons.folder_open_outlined), selectedIcon: Icon(Icons.folder_open_rounded), label: 'Records'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

// ─── HOME TAB ─────────────────────────────────────────────────────────────────

class _PatientHomeTab extends StatelessWidget {
  const _PatientHomeTab();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final profile = appState.profile;
    final upcoming = appState.nextUpcomingAppointment;
    final doctors = appState.doctors.take(6).toList();

    return Column(
      key: const ValueKey<String>('home'),
      children: <Widget>[
        // ─── Gradient Header ────────────────────────────────────────────────
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
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Hello, ${profile?.fullName.split(' ').first ?? 'Patient'} 👋',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        const Text('How are you feeling today?', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed(AppRouter.notifications),
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                          child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                      if (appState.unreadNotificationCount > 0)
                        Positioned(
                          top: 0, right: 0,
                          child: Container(
                            width: 16, height: 16,
                            decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(
                              '${appState.unreadNotificationCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed(AppRouter.profileSetup),
                    child: AssetCircleAvatar(
                      imageAsset: AppAssets.patientAhmed,
                      initials: buildInitials(profile?.fullName ?? 'PT'),
                      radius: 20,
                      borderColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Search bar
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed(AppRouter.doctorSearch),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: const Row(
                    children: <Widget>[
                      Icon(Icons.search_rounded, color: AppTheme.textMuted),
                      SizedBox(width: 10),
                      Text('Search doctor, specialty...', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // ─── Content ────────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.space4),
            children: <Widget>[
              // Quick actions
              const SectionHeading(title: 'Quick Actions'),
              Row(
                children: <Widget>[
                  Expanded(
                    child: QuickActionTile(
                      icon: Icons.search_rounded, label: 'Find\nDoctor',
                      color: AppTheme.accentBlue,
                      onTap: () => Navigator.of(context).pushNamed(AppRouter.doctorSearch),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: QuickActionTile(
                      icon: Icons.health_and_safety_rounded, label: 'AI\nCheck',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.of(context).pushNamed(AppRouter.aiSymptomChecker),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: QuickActionTile(
                      icon: Icons.call_rounded, label: 'Emergency',
                      color: AppTheme.danger,
                      onTap: () => Navigator.of(context).pushNamed(AppRouter.emergency),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: QuickActionTile(
                      icon: Icons.alarm_rounded, label: 'Reminders',
                      color: AppTheme.success,
                      onTap: () => Navigator.of(context).pushNamed(AppRouter.medicationReminders),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Upcoming appointment
              const SectionHeading(title: 'Upcoming Appointment'),
              if (upcoming == null)
                MediQCard(
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.calendar_today_rounded, color: AppTheme.textMuted, size: 36),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('No upcoming appointments', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed(AppRouter.doctorSearch),
                            child: const Text('Book one now →', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                MediQCard(
                  onTap: () => Navigator.of(context).pushNamed(AppRouter.queueTracker, arguments: upcoming),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          AssetCircleAvatar(imageAsset: upcoming.doctor.imageAsset, initials: buildInitials(upcoming.doctor.name, fallback: 'DR'), radius: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(upcoming.doctor.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(upcoming.doctor.specialty, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          StatusBadge(label: _statusLabel(upcoming.status), color: _statusColor(upcoming.status)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 5),
                          Text(formatDate(upcoming.dateTime), style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 5),
                          Text(formatTime(upcoming.dateTime), style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              // Nearby doctors
              const SizedBox(height: 4),
              SectionHeading(
                title: 'Top Doctors',
                trailing: TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRouter.doctorSearch),
                  child: const Text('See All'),
                ),
              ),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: doctors.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final doc = doctors[index];
                    return GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed(AppRouter.doctorProfile, arguments: doc),
                      child: Container(
                        width: 140,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            AssetCircleAvatar(imageAsset: doc.imageAsset, initials: buildInitials(doc.name, fallback: 'DR'), radius: 28),
                            const SizedBox(height: 8),
                            Text(doc.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            Text(doc.specialty, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Icon(Icons.star_rounded, color: AppTheme.warning, size: 13),
                                const SizedBox(width: 3),
                                Text(doc.rating.toStringAsFixed(1), style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w700, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.upcoming: return 'Upcoming';
      case AppointmentStatus.pending: return 'Pending';
      case AppointmentStatus.completed: return 'Completed';
      case AppointmentStatus.cancelled: return 'Cancelled';
    }
  }

  Color _statusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.upcoming: return AppTheme.success;
      case AppointmentStatus.pending: return AppTheme.warning;
      case AppointmentStatus.completed: return AppTheme.accentBlue;
      case AppointmentStatus.cancelled: return AppTheme.danger;
    }
  }
}

// ─── APPOINTMENTS TAB ─────────────────────────────────────────────────────────

class _PatientAppointmentsTab extends StatefulWidget {
  const _PatientAppointmentsTab();

  @override
  State<_PatientAppointmentsTab> createState() => _PatientAppointmentsTabState();
}

class _PatientAppointmentsTabState extends State<_PatientAppointmentsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final upcoming = appState.upcomingAppointments;
    final past = appState.pastAppointments;

    return Column(
      key: const ValueKey<String>('appointments'),
      children: <Widget>[
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space4, AppTheme.space4, 0),
          color: AppTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Appointments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                tabs: const <Tab>[Tab(text: 'Upcoming'), Tab(text: 'Past')],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              // Upcoming
              upcoming.isEmpty
                  ? const EmptyStateView(title: 'No upcoming appointments', message: 'Book a doctor to get started.', icon: Icons.calendar_today_rounded)
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.space4),
                      itemCount: upcoming.length,
                      itemBuilder: (_, i) => _AppointmentCard(appointment: upcoming[i]),
                    ),
              // Past
              past.isEmpty
                  ? const EmptyStateView(title: 'No past appointments', message: 'Your consultation history will appear here.', icon: Icons.history_rounded)
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.space4),
                      itemCount: past.length,
                      itemBuilder: (_, i) => _AppointmentCard(appointment: past[i], isPast: true),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, this.isPast = false});
  final Appointment appointment;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    return MediQCard(
      onTap: isPast
          ? null
          : () => Navigator.of(context).pushNamed(AppRouter.queueTracker, arguments: appointment),
      child: Row(
        children: <Widget>[
          AssetCircleAvatar(imageAsset: appointment.doctor.imageAsset, initials: buildInitials(appointment.doctor.name, fallback: 'DR'), radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(appointment.doctor.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(appointment.doctor.specialty, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 3),
                Text('${formatDate(appointment.dateTime)} • ${formatTime(appointment.dateTime)}',
                  style: const TextStyle(color: AppTheme.accentBlue, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              StatusBadge(label: _labelFor(appointment.status), color: _colorFor(appointment.status)),
              if (!isPast) ...<Widget>[
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _labelFor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.upcoming: return 'Upcoming';
      case AppointmentStatus.pending: return 'Pending';
      case AppointmentStatus.completed: return 'Completed';
      case AppointmentStatus.cancelled: return 'Cancelled';
    }
  }

  Color _colorFor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.upcoming: return AppTheme.success;
      case AppointmentStatus.pending: return AppTheme.warning;
      case AppointmentStatus.completed: return AppTheme.accentBlue;
      case AppointmentStatus.cancelled: return AppTheme.danger;
    }
  }
}

// ─── RECORDS TAB ─────────────────────────────────────────────────────────────

class _PatientRecordsTab extends StatefulWidget {
  const _PatientRecordsTab();

  @override
  State<_PatientRecordsTab> createState() => _PatientRecordsTabState();
}

class _PatientRecordsTabState extends State<_PatientRecordsTab> {
  int _category = 0;
  static const List<String> _categories = <String>['All', 'Prescriptions', 'Lab', 'Reports'];

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final records = appState.records;

    return Column(
      key: const ValueKey<String>('records'),
      children: <Widget>[
        // Header
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space4, AppTheme.space4, AppTheme.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Health Records', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final selected = _category == i;
                    return GestureDetector(
                      onTap: () => setState(() => _category = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.accentBlue : AppTheme.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                          border: Border.all(color: selected ? AppTheme.accentBlue : AppTheme.border),
                        ),
                        child: Text(
                          _categories[i],
                          style: TextStyle(
                            color: selected ? Colors.white : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600, fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: records.isEmpty
              ? const EmptyStateView(title: 'No Records Yet', message: 'Your prescriptions and health records will appear here after consultations.', icon: Icons.folder_open_rounded)
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  itemCount: records.length,
                  itemBuilder: (_, i) {
                    final rec = records[i];
                    return MediQCard(
                      onTap: () => Navigator.of(context).pushNamed(AppRouter.digitalPrescription, arguments: rec),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                            child: const Icon(Icons.description_rounded, color: AppTheme.accentBlue, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(rec.issue, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text(rec.doctorName, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                Text(formatDate(rec.date), style: const TextStyle(color: AppTheme.accentBlue, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── SETTINGS TAB ─────────────────────────────────────────────────────────────

class _PatientSettingsTab extends StatelessWidget {
  const _PatientSettingsTab();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final profile = appState.profile;

    return Column(
      key: const ValueKey<String>('settings'),
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
              Stack(
                children: <Widget>[
                  AssetCircleAvatar(
                    imageAsset: AppAssets.patientAhmed,
                    initials: buildInitials(profile?.fullName ?? 'PT'),
                    radius: 36,
                    borderColor: Colors.white,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed(AppRouter.profileSetup),
                      child: Container(
                        width: 26, height: 26,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded, size: 14, color: AppTheme.accentBlue),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(profile?.fullName ?? 'Patient', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              if (profile != null) ...<Widget>[
                const SizedBox(height: 3),
                Text('${profile.age} yrs • ${profile.gender} • ${profile.bloodGroup ?? 'N/A'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.space4),
            children: <Widget>[
              const SectionHeading(title: 'Account'),
              _SettingsTile(icon: Icons.person_rounded, title: 'Edit Profile', onTap: () => Navigator.of(context).pushNamed(AppRouter.profileSetup)),
              _SettingsTile(icon: Icons.notifications_rounded, title: 'Notifications', onTap: () => Navigator.of(context).pushNamed(AppRouter.notifications)),
              _SettingsTile(icon: Icons.alarm_rounded, title: 'Medication Reminders', onTap: () => Navigator.of(context).pushNamed(AppRouter.medicationReminders)),
              const SizedBox(height: 8),
              const SectionHeading(title: 'Support'),
              _SettingsTile(icon: Icons.help_rounded, title: 'Help & Support', onTap: () => Navigator.of(context).pushNamed(AppRouter.helpSupport)),
              _SettingsTile(icon: Icons.call_rounded, title: 'Emergency Numbers', onTap: () => Navigator.of(context).pushNamed(AppRouter.emergency)),
              const SizedBox(height: 8),
              const SectionHeading(title: 'Account'),
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
