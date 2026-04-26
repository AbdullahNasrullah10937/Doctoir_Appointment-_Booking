import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/app_entities.dart';
import '../routes/app_router.dart';
import '../state/app_scope.dart';
import '../widgets/common_widgets.dart';

class PatientShellScreen extends StatefulWidget {
  const PatientShellScreen({super.key});

  @override
  State<PatientShellScreen> createState() => _PatientShellScreenState();
}

class _PatientShellScreenState extends State<PatientShellScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    final pages = <Widget>[
      const _PatientHomeTab(),
      const _PatientAppointmentsTab(),
      const _PatientRecordsTab(),
      const _PatientSettingsTab(),
    ];

    final titles = <String>[
      'Home',
      'Appointments',
      'Health Records',
      'Settings',
    ];

    return Scaffold(
      body: MediQGradientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          titles[appState.patientTabIndex],
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appState.patientTabIndex == 0
                              ? 'Good to see you, ${appState.profile?.fullName ?? 'Patient'}'
                              : 'MediQ keeps everything in one flow',
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        IconButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRouter.notifications);
                          },
                          icon: const Icon(Icons.notifications_none_rounded),
                        ),
                        if (appState.unreadNotificationCount > 0)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: pages[appState.patientTabIndex],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appState.patientTabIndex,
        onDestinationSelected: appState.setPatientTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_open_rounded),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _PatientHomeTab extends StatelessWidget {
  const _PatientHomeTab();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final upcoming = appState.nextUpcomingAppointment;

    return ListView(
      key: const ValueKey<String>('home-tab'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      children: <Widget>[
        GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(AppRouter.doctorSearch);
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: const Row(
              children: <Widget>[
                Icon(Icons.search_rounded, color: AppTheme.textMuted),
                SizedBox(width: 8),
                Text(
                  'Search doctor, specialty, hospital...',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeading(title: 'Upcoming Appointment'),
        if (upcoming != null)
          MediQCard(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    AssetCircleAvatar(
                      imageAsset: upcoming.doctor.imageAsset,
                      initials: _initials(upcoming.doctor.name),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            upcoming.doctor.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatDate(upcoming.dateTime)} • ${formatTime(upcoming.dateTime)}',
                            style: const TextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Token #${upcoming.tokenNumber}',
                        style: const TextStyle(
                          color: AppTheme.accentBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: PrimaryActionButton(
                        label: 'Track Queue',
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRouter.queueTracker,
                            arguments: upcoming,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          EmptyStateView(
            title: 'No appointment booked yet',
            message: 'Find a doctor and book your first appointment.',
            actionLabel: 'Find Doctor',
            onAction: () =>
                Navigator.of(context).pushNamed(AppRouter.doctorSearch),
          ),
        const SizedBox(height: 14),
        const SectionHeading(title: 'Quick Actions'),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.65,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            QuickActionTile(
              icon: Icons.manage_search_rounded,
              label: 'Find Doctor',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.doctorSearch),
            ),
            QuickActionTile(
              icon: Icons.calendar_month_rounded,
              label: 'My Appointments',
              onTap: () {
                appState.setPatientTab(1);
              },
            ),
            QuickActionTile(
              icon: Icons.folder_copy_rounded,
              label: 'Health Records',
              onTap: () {
                appState.setPatientTab(2);
              },
            ),
            QuickActionTile(
              icon: Icons.psychology_rounded,
              label: 'Symptom Checker',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRouter.aiSymptomChecker),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const SectionHeading(title: 'Nearby Doctors'),
        ...appState.doctors
            .take(3)
            .map(
              (doctor) => MediQCard(
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushNamed(AppRouter.doctorProfile, arguments: doctor);
                },
                child: Row(
                  children: <Widget>[
                    AssetCircleAvatar(
                      imageAsset: doctor.imageAsset,
                      initials: _initials(doctor.name),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            doctor.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${doctor.specialty} • ${doctor.distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '⭐ ${doctor.rating.toStringAsFixed(1)}',
                            style: const TextStyle(color: AppTheme.warning),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _PatientAppointmentsTab extends StatefulWidget {
  const _PatientAppointmentsTab();

  @override
  State<_PatientAppointmentsTab> createState() =>
      _PatientAppointmentsTabState();
}

class _PatientAppointmentsTabState extends State<_PatientAppointmentsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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

    return Column(
      key: const ValueKey<String>('appointments-tab'),
      children: <Widget>[
        TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  if (appState.upcomingAppointments.isEmpty)
                    EmptyStateView(
                      title: 'No upcoming appointments',
                      message: 'Your future bookings will appear here.',
                      actionLabel: 'Book Appointment',
                      onAction: () {
                        Navigator.of(context).pushNamed(AppRouter.doctorSearch);
                      },
                    )
                  else
                    ...appState.upcomingAppointments.map(
                      (appointment) => MediQCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    appointment.doctor.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _statusBadge('Confirmed', AppTheme.success),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${appointment.doctor.specialty} • ${formatDate(appointment.dateTime)} ${formatTime(appointment.dateTime)}',
                              style: const TextStyle(color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Text('Token #${appointment.tokenNumber}'),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(
                                        AppRouter.queueTracker,
                                        arguments: appointment,
                                      );
                                    },
                                    child: const Text('Track Queue'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      appState.cancelAppointment(
                                        appointment.id,
                                      );
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ],
                            ),
                            if (appointment.isVideoConsultation)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: PrimaryActionButton(
                                  label: 'Join Video Consultation',
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                      AppRouter.videoConsultation,
                                      arguments: appointment.doctor,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  if (appState.pastAppointments.isEmpty)
                    const EmptyStateView(
                      title: 'No past appointments',
                      message:
                          'Completed appointments will appear in this tab.',
                    )
                  else
                    ...appState.pastAppointments.map(
                      (appointment) => MediQCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    appointment.doctor.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _statusBadge('Completed', AppTheme.accentBlue),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${appointment.doctor.specialty} • ${formatDate(appointment.dateTime)}',
                              style: const TextStyle(color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      final record = appState.records.isEmpty
                                          ? null
                                          : appState.records.first;
                                      Navigator.of(context).pushNamed(
                                        AppRouter.digitalPrescription,
                                        arguments: record,
                                      );
                                    },
                                    child: const Text('View Prescription'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(
                                        AppRouter.rateReview,
                                        arguments: appointment.doctor,
                                      );
                                    },
                                    child: const Text('Rate Doctor'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PatientRecordsTab extends StatelessWidget {
  const _PatientRecordsTab();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    return ListView(
      key: const ValueKey<String>('records-tab'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: <Widget>[
        const SectionHeading(title: 'My Health Records'),
        ...appState.records.map(
          (record) => MediQCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  record.doctorName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatDate(record.date)} • ${record.issue}',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 6),
                Text('Diagnosis: ${record.diagnosisNotes}'),
                const SizedBox(height: 4),
                Text('Prescription: ${record.prescriptionSummary}'),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRouter.digitalPrescription,
                            arguments: record,
                          );
                        },
                        child: const Text('View Rx'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'System share sheet opened (mock).',
                              ),
                            ),
                          );
                        },
                        child: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PatientSettingsTab extends StatelessWidget {
  const _PatientSettingsTab();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    return ListView(
      key: const ValueKey<String>('settings-tab'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: <Widget>[
        MediQCard(
          child: Row(
            children: <Widget>[
              AssetCircleAvatar(
                initials: _initials(appState.profile?.fullName ?? 'User'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      appState.profile?.fullName ?? 'Patient',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      appState.profile?.phone ?? '+92 300 0000000',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.profileSetup);
                },
                child: const Text('Edit'),
              ),
            ],
          ),
        ),
        MediQCard(
          child: Column(
            children: <Widget>[
              _settingsTile(
                context,
                icon: Icons.notifications_rounded,
                title: 'Notifications Center',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRouter.notifications),
              ),
              _settingsTile(
                context,
                icon: Icons.psychology_alt_rounded,
                title: 'AI Symptom Checker',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRouter.aiSymptomChecker),
              ),
              _settingsTile(
                context,
                icon: Icons.help_center_rounded,
                title: 'Help & Support',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRouter.helpSupport),
              ),
              _settingsTile(
                context,
                icon: Icons.emergency_rounded,
                title: 'Emergency Numbers',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRouter.emergency),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        PrimaryActionButton(
          label: 'Sign Out',
          onPressed: () {
            appState.logout();
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
          },
        ),
      ],
    );
  }
}

Widget _settingsTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return ListTile(
    onTap: onTap,
    leading: Icon(icon, color: AppTheme.accentBlue),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key, this.initialSpecialty});

  final String? initialSpecialty;

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  String _specialty = 'All';
  String _gender = 'All';
  bool _todayOnly = false;

  @override
  void initState() {
    super.initState();
    _specialty = widget.initialSpecialty ?? 'All';
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final specialties = <String>{
      'All',
      ...appState.doctors.map((d) => d.specialty),
    };

    final doctors = appState.filterDoctors(
      query: _queryController.text,
      specialty: _specialty,
      gender: _gender,
      availableTodayOnly: _todayOnly,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Find Doctor')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              TextField(
                controller: _queryController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search by doctor name or specialty',
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: specialties.map((specialty) {
                    final selected = _specialty == specialty;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: selected,
                        label: Text(specialty),
                        onSelected: (_) {
                          setState(() {
                            _specialty = specialty;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const <String>['All', 'Male', 'Female']
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _gender = value ?? 'All';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _todayOnly,
                    onSelected: (value) {
                      setState(() {
                        _todayOnly = value;
                      });
                    },
                    label: const Text('Available Today'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: doctors.isEmpty
                    ? const EmptyStateView(
                        title: 'No matching doctor found',
                        message: 'Try changing your filters or search terms.',
                      )
                    : ListView.builder(
                        itemCount: doctors.length,
                        itemBuilder: (_, index) {
                          final doctor = doctors[index];
                          return MediQCard(
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRouter.doctorProfile,
                                arguments: doctor,
                              );
                            },
                            child: Row(
                              children: <Widget>[
                                AssetCircleAvatar(
                                  imageAsset: doctor.imageAsset,
                                  initials: _initials(doctor.name),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        doctor.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        doctor.specialty,
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                      Text(
                                        '⭐ ${doctor.rating.toStringAsFixed(1)} • Rs ${doctor.consultationFee}',
                                        style: const TextStyle(
                                          color: AppTheme.warning,
                                        ),
                                      ),
                                      Text(
                                        'Next: ${doctor.nextAvailableSlot}',
                                        style: const TextStyle(
                                          color: AppTheme.accentBlue,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key, required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              MediQCard(
                child: Column(
                  children: <Widget>[
                    AssetCircleAvatar(
                      imageAsset: doctor.imageAsset,
                      initials: _initials(doctor.name),
                      radius: 38,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      doctor.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text('⭐ ${doctor.rating.toStringAsFixed(1)}'),
                    const SizedBox(height: 8),
                    Text(
                      '${doctor.qualifications} • ${doctor.experienceYears}+ years',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              MediQCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeading(title: 'Consultation Details'),
                    Text('Hospital: ${doctor.hospital}'),
                    const SizedBox(height: 4),
                    Text('Location: ${doctor.location}'),
                    const SizedBox(height: 4),
                    Text('Fee: Rs ${doctor.consultationFee}'),
                    const SizedBox(height: 4),
                    Text('Next slot: ${doctor.nextAvailableSlot}'),
                  ],
                ),
              ),
              MediQCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeading(title: 'Patient Reviews'),
                    if (doctor.reviews.isEmpty)
                      const Text('No reviews yet')
                    else
                      ...doctor.reviews.map(
                        (review) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            '"${review.comment}" • ${review.userName} (${review.rating.toStringAsFixed(1)}★)',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PrimaryActionButton(
                label: 'Book Appointment',
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed(AppRouter.bookAppointment, arguments: doctor);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key, required this.doctor});

  final Doctor doctor;

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  int _slotIndex = 1;
  bool _isVideo = false;

  final TextEditingController _reasonController = TextEditingController(
    text: 'Headache and fever for 2 days',
  );

  List<DateTime> get _slots {
    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return <DateTime>[
      DateTime(date.year, date.month, date.day, 10, 0),
      DateTime(date.year, date.month, date.day, 10, 15),
      DateTime(date.year, date.month, date.day, 10, 30),
      DateTime(date.year, date.month, date.day, 11, 0),
      DateTime(date.year, date.month, date.day, 11, 30),
      DateTime(date.year, date.month, date.day, 12, 0),
    ];
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _continueToPayment() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add visit reason.')));
      return;
    }

    final draft = AppointmentDraft(
      doctor: widget.doctor,
      slotDateTime: _slots[_slotIndex],
      visitReason: reason,
      isVideoConsultation: _isVideo,
    );

    Navigator.of(context).pushNamed(AppRouter.payment, arguments: draft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              MediQCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeading(title: 'Select Date'),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, index) {
                          final day = DateTime.now().add(Duration(days: index));
                          final selected =
                              day.day == _selectedDate.day &&
                              day.month == _selectedDate.month;
                          return ChoiceChip(
                            selected: selected,
                            label: Text(formatShortDate(day)),
                            onSelected: (_) {
                              setState(() {
                                _selectedDate = day;
                                _slotIndex = 0;
                              });
                            },
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemCount: 7,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const SectionHeading(title: 'Select Time Slot'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List<Widget>.generate(_slots.length, (index) {
                        final selected = index == _slotIndex;
                        return ChoiceChip(
                          selected: selected,
                          label: Text(formatTime(_slots[index])),
                          onSelected: (_) {
                            setState(() {
                              _slotIndex = index;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Visit Reason',
                        hintText: 'Describe symptoms briefly',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Video consultation (optional)'),
                      subtitle: const Text(
                        'You can consult remotely if needed',
                      ),
                      value: _isVideo,
                      onChanged: (value) {
                        setState(() {
                          _isVideo = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              PrimaryActionButton(
                label: 'Confirm & Continue To Payment',
                onPressed: _continueToPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.draft});

  final AppointmentDraft draft;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'Card';
  bool _paying = false;

  Future<void> _pay() async {
    setState(() {
      _paying = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (!mounted) {
      return;
    }

    final appState = AppScope.of(context);
    final appointment = appState.bookAppointment(draft: widget.draft);

    setState(() {
      _paying = false;
    });

    Navigator.of(
      context,
    ).pushReplacementNamed(AppRouter.queueTracker, arguments: appointment);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              MediQCard(
                child: Column(
                  children: <Widget>[
                    const Text(
                      'Consultation Fee',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${draft.doctor.consultationFee}',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${draft.doctor.name} • ${formatDate(draft.slotDateTime)} ${formatTime(draft.slotDateTime)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              MediQCard(
                child: Column(
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <String>['Card', 'JazzCash', 'EasyPaisa']
                          .map(
                            (method) => ChoiceChip(
                              selected: _method == method,
                              label: Text(method),
                              onSelected: (_) {
                                setState(() {
                                  _method = method;
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              PrimaryActionButton(
                label: _paying
                    ? 'Processing Payment...'
                    : 'Pay Rs ${draft.doctor.consultationFee}',
                onPressed: _paying ? null : _pay,
              ),
              const SizedBox(height: 8),
              const Text(
                'Secured payment (frontend mock mode)',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QueueTrackerScreen extends StatefulWidget {
  const QueueTrackerScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  State<QueueTrackerScreen> createState() => _QueueTrackerScreenState();
}

class _QueueTrackerScreenState extends State<QueueTrackerScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) {
        return;
      }
      AppScope.of(context).tickQueue();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final queue = appState.queueSnapshot;

    return Scaffold(
      appBar: AppBar(title: const Text('Live Queue Tracker')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              if (queue == null)
                const EmptyStateView(
                  title: 'Queue not available',
                  message:
                      'Queue details will appear once booking is confirmed.',
                )
              else ...<Widget>[
                MediQCard(
                  child: Column(
                    children: <Widget>[
                      Text(
                        queue.doctorName,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        queue.clinicLocation,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 110,
                        height: 110,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.accentBlue,
                            width: 4,
                          ),
                          color: AppTheme.accentBlue.withValues(alpha: 0.16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '${queue.yourToken}',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text('Your Token'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: MetricTile(
                              label: 'Current Token',
                              value: '${queue.currentToken}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MetricTile(
                              label: 'Patients Ahead',
                              value: '${queue.patientsAhead}',
                              valueColor: AppTheme.warning,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MetricTile(
                              label: 'Estimated Wait',
                              value: '${queue.estimatedWaitMinutes}m',
                              valueColor: AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                MediQCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Auto alerts',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text('• 2 patients ahead of you'),
                      const Text('• Please arrive at clinic'),
                      const SizedBox(height: 10),
                      if (widget.appointment.isVideoConsultation)
                        PrimaryActionButton(
                          label: 'Join Video Consultation',
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRouter.videoConsultation,
                              arguments: widget.appointment.doctor,
                            );
                          },
                        ),
                    ],
                  ),
                ),
                PrimaryActionButton(
                  label: 'Mark Consultation Completed',
                  onPressed: () {
                    appState.completeAppointment(widget.appointment.id);
                    Navigator.of(context).pushNamed(
                      AppRouter.rateReview,
                      arguments: widget.appointment.doctor,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AiSymptomCheckerScreen extends StatefulWidget {
  const AiSymptomCheckerScreen({super.key});

  @override
  State<AiSymptomCheckerScreen> createState() => _AiSymptomCheckerScreenState();
}

class _AiSymptomCheckerScreenState extends State<AiSymptomCheckerScreen> {
  final TextEditingController _symptomController = TextEditingController(
    text: 'Fever, sore throat, headache for 2 days',
  );

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Symptom Checker')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              MediQCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Describe your symptoms',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _symptomController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type symptoms with duration',
                      ),
                    ),
                    const SizedBox(height: 10),
                    PrimaryActionButton(
                      label: 'Analyse Symptoms',
                      onPressed: () {
                        appState.runSymptomChecker(_symptomController.text);
                      },
                    ),
                  ],
                ),
              ),
              if (appState.latestAiSuggestions.isNotEmpty)
                MediQCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'AI Suggested Specialists',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: appState.latestAiSuggestions
                            .map((suggestion) => Chip(label: Text(suggestion)))
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      PrimaryActionButton(
                        label: 'Find Doctors',
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRouter.doctorSearch,
                            arguments: appState.latestAiSuggestions.first,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              const MediQCard(
                child: Text(
                  'AI provides general guidance only. It does not replace medical diagnosis by a licensed doctor.',
                  style: TextStyle(color: AppTheme.warning),
                ),
              ),
              SecondaryActionButton(
                label: 'Open AI Health Assistant Chat',
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.aiAssistant);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AiHealthAssistantScreen extends StatefulWidget {
  const AiHealthAssistantScreen({super.key});

  @override
  State<AiHealthAssistantScreen> createState() =>
      _AiHealthAssistantScreenState();
}

class _AiHealthAssistantScreenState extends State<AiHealthAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      text: 'How can I help you today? Ask any health question.',
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _messages.add(
        _ChatMessage(
          text:
              'Possible causes include stress, dehydration, and sleep changes. If symptoms are severe, consult a doctor. Tap below to find specialists.',
          isUser: false,
        ),
      );
      _inputController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Health Assistant')),
      body: MediQGradientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: MediQCard(
                  margin: EdgeInsets.zero,
                  child: Text(
                    'AI provides general guidance, not medical diagnosis.',
                    style: TextStyle(color: AppTheme.warning),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, index) {
                    final message = _messages[index];
                    return Align(
                      alignment: message.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 290),
                        decoration: BoxDecoration(
                          color: message.isUser
                              ? AppTheme.accentBlue
                              : AppTheme.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(message.text),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        decoration: const InputDecoration(
                          hintText: 'Ask a health question...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: PrimaryActionButton(
                  label: 'Find Related Doctors',
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.doctorSearch,
                      arguments: 'General Physician',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DigitalPrescriptionScreen extends StatefulWidget {
  const DigitalPrescriptionScreen({super.key, this.record});

  final HealthRecord? record;

  @override
  State<DigitalPrescriptionScreen> createState() =>
      _DigitalPrescriptionScreenState();
}

class _DigitalPrescriptionScreenState extends State<DigitalPrescriptionScreen> {
  Future<Prescription>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future != null) {
      return;
    }

    final appState = AppScope.of(context);
    final record =
        widget.record ??
        (appState.records.isEmpty ? null : appState.records.first);

    if (record != null) {
      _future = appState.getPrescriptionForRecord(record);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Digital Prescription')),
        body: const MediQGradientBackground(
          child: EmptyStateView(
            title: 'Prescription not found',
            message: 'No prescription record is available.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Digital Prescription')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: FutureBuilder<Prescription>(
            future: _future,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final prescription = snapshot.data!;

              return ListView(
                children: <Widget>[
                  MediQCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'MediQ Digital Prescription',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${formatDate(prescription.date)} • ${prescription.doctorName}',
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 10),
                        Text('Patient: ${prescription.patientName}'),
                        Text('Diagnosis: ${prescription.diagnosis}'),
                        const SizedBox(height: 12),
                        const SectionHeading(title: 'Medicines'),
                        ...prescription.medicines.map(
                          (medicine) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '• ${medicine.name} ${medicine.dose} • ${medicine.frequency} • ${medicine.duration}',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Notes: ${prescription.notes}'),
                      ],
                    ),
                  ),
                  PrimaryActionButton(
                    label: 'Set Medicine Reminders',
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamed(AppRouter.medicationReminders);
                    },
                  ),
                  const SizedBox(height: 8),
                  SecondaryActionButton(
                    label: 'Download PDF',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Prescription PDF downloaded (mock).'),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class MedicationRemindersScreen extends StatelessWidget {
  const MedicationRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    final enabledCount = appState.reminders
        .where((item) => item.isEnabled)
        .length;
    final totalCount = appState.reminders.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Medication Reminders')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              MediQCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Today\'s reminder status: $enabledCount/$totalCount active',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: totalCount == 0 ? 0 : enabledCount / totalCount,
                    ),
                  ],
                ),
              ),
              ...appState.reminders.map(
                (reminder) => MediQCard(
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  reminder.medicineName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${reminder.remainingDays} days remaining',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: reminder.isEnabled,
                            onChanged: (_) {
                              appState.toggleReminder(reminder.id);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: reminder.times
                            .map((time) => Chip(label: Text(time)))
                            .toList(),
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

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: <Widget>[
          TextButton(
            onPressed: appState.markAllNotificationsAsRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              ...appState.notifications.map(
                (item) => MediQCard(
                  onTap: () {
                    switch (item.type) {
                      case NotificationType.queue:
                        final upcoming = appState.nextUpcomingAppointment;
                        if (upcoming != null) {
                          Navigator.of(context).pushNamed(
                            AppRouter.queueTracker,
                            arguments: upcoming,
                          );
                        }
                      case NotificationType.medication:
                        Navigator.of(
                          context,
                        ).pushNamed(AppRouter.medicationReminders);
                      case NotificationType.appointment:
                        appState.setPatientTab(1);
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRouter.patientShell,
                          (route) => false,
                        );
                      case NotificationType.ai:
                        Navigator.of(context).pushNamed(AppRouter.aiAssistant);
                      case NotificationType.system:
                        break;
                    }
                  },
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        backgroundColor: AppTheme.accentBlue.withValues(
                          alpha: 0.2,
                        ),
                        child: Icon(
                          _notificationIcon(item.type),
                          color: AppTheme.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(item.message),
                            const SizedBox(height: 2),
                            Text(
                              item.timeLabel,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (item.isUnread)
                        const Icon(
                          Icons.circle,
                          size: 10,
                          color: AppTheme.accentBlue,
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

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              const MediQCard(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search FAQs...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              MediQCard(
                child: Column(
                  children: <Widget>[
                    ExpansionTile(
                      title: const Text('How do I cancel an appointment?'),
                      children: const <Widget>[
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Open Appointments and tap Cancel.'),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      title: const Text('How does live queue tracking work?'),
                      children: const <Widget>[
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Queue updates in real-time and alerts you before your turn.',
                          ),
                        ),
                      ],
                    ),
                    ExpansionTile(
                      title: const Text('How to share my health records?'),
                      children: const <Widget>[
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Use the Share action from Health Records tab.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PrimaryActionButton(
                label: 'Live Chat Support',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Live chat opened (mock).')),
                  );
                },
              ),
              const SizedBox(height: 8),
              SecondaryActionButton(
                label: 'Report Problem',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Issue report form opened (mock).'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmergencyNumbersScreen extends StatelessWidget {
  const EmergencyNumbersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Numbers')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              const MediQCard(
                child: Text(
                  'For life-threatening emergencies, call immediately.',
                  style: TextStyle(color: AppTheme.danger),
                ),
              ),
              _emergencyCard(
                context,
                icon: Icons.local_hospital_rounded,
                title: 'Ambulance',
                subtitle: '1122 • Punjab Emergency',
              ),
              _emergencyCard(
                context,
                icon: Icons.health_and_safety_rounded,
                title: 'Nearest Hospital',
                subtitle: 'City Hospital • 0.8 km',
              ),
              _emergencyCard(
                context,
                icon: Icons.call_rounded,
                title: 'Emergency Helpline',
                subtitle: '115 • Edhi Foundation',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _emergencyCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return MediQCard(
    child: Row(
      children: <Widget>[
        CircleAvatar(
          backgroundColor: AppTheme.danger.withValues(alpha: 0.2),
          child: Icon(icon, color: AppTheme.danger),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(subtitle, style: const TextStyle(color: AppTheme.textMuted)),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Dialing $title (mock)...')));
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          child: const Text('Call'),
        ),
      ],
    ),
  );
}

class RateReviewScreen extends StatefulWidget {
  const RateReviewScreen({super.key, this.doctor});

  final Doctor? doctor;

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  int _rating = 4;
  final TextEditingController _commentController = TextEditingController(
    text: 'Doctor explained the issue clearly and was very patient.',
  );

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted. Thank you!')),
    );

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.patientShell, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;

    return Scaffold(
      appBar: AppBar(title: const Text('Rate & Review')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              MediQCard(
                child: Column(
                  children: <Widget>[
                    AssetCircleAvatar(
                      imageAsset: doctor?.imageAsset,
                      initials: _initials(doctor?.name ?? 'Doctor'),
                      radius: 34,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doctor?.name ?? 'Doctor',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: List<Widget>.generate(5, (index) {
                        final position = index + 1;
                        return IconButton(
                          icon: Icon(
                            position <= _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppTheme.warning,
                          ),
                          onPressed: () {
                            setState(() {
                              _rating = position;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Your review',
                      ),
                    ),
                  ],
                ),
              ),
              PrimaryActionButton(label: 'Submit Review', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoConsultationScreen extends StatelessWidget {
  const VideoConsultationScreen({super.key, this.doctor});

  final Doctor? doctor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(title: const Text('Video Consultation')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFF1E293B),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AssetCircleAvatar(
                        imageAsset: doctor?.imageAsset,
                        initials: _initials(doctor?.name ?? 'DR'),
                        radius: 44,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        doctor?.name ?? 'Doctor',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Connected',
                        style: TextStyle(color: AppTheme.success),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _videoControl(Icons.mic_rounded),
                  _videoControl(Icons.videocam_rounded),
                  _videoControl(Icons.volume_up_rounded),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.danger,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.call_end_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _videoControl(IconData icon) {
  return CircleAvatar(
    radius: 24,
    backgroundColor: const Color(0xFF334155),
    child: Icon(icon, color: Colors.white),
  );
}

Widget _statusBadge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
    ),
  );
}

String _initials(String value) {
  final parts = value.trim().split(' ');
  if (parts.isEmpty) {
    return 'DR';
  }

  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
  final initials = '$first$second'.toUpperCase();
  return initials.isEmpty ? 'DR' : initials;
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

IconData _notificationIcon(NotificationType type) {
  switch (type) {
    case NotificationType.queue:
      return Icons.queue_rounded;
    case NotificationType.medication:
      return Icons.medication_liquid_rounded;
    case NotificationType.appointment:
      return Icons.calendar_month_rounded;
    case NotificationType.ai:
      return Icons.psychology_rounded;
    case NotificationType.system:
      return Icons.info_outline_rounded;
  }
}
