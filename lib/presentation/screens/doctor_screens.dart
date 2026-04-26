import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/app_entities.dart';
import '../routes/app_router.dart';
import '../state/app_scope.dart';
import '../widgets/common_widgets.dart';

class DoctorShellScreen extends StatelessWidget {
  const DoctorShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    final pages = <Widget>[
      const _DoctorDashboardTab(),
      const _DoctorScheduleTab(),
      const _DoctorQueueTab(),
      const _DoctorSettingsTab(),
    ];

    final titles = <String>[
      'Doctor Dashboard',
      'Manage Schedule',
      'Patient Queue',
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
                    Text(
                      titles[appState.doctorTabIndex],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    AssetCircleAvatar(initials: 'SA', radius: 16),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: pages[appState.doctorTabIndex],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appState.doctorTabIndex,
        onDestinationSelected: appState.setDoctorTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_rounded),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Queue',
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

class _DoctorDashboardTab extends StatelessWidget {
  const _DoctorDashboardTab();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final queue = appState.doctorQueue;

    return ListView(
      key: const ValueKey<String>('doctor-dashboard-tab'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF20407A), Color(0xFF162A4E)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Dr. Sara Ali',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Today\'s consultation summary',
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: MetricTile(
                      label: 'Patients Today',
                      value: '${queue.length + 7}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: MetricTile(
                      label: 'Completed',
                      value: '7',
                      valueColor: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: MetricTile(
                      label: 'In Queue',
                      value: '2',
                      valueColor: AppTheme.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeading(title: 'Current Queue'),
        ...queue.map(
          (caseItem) => MediQCard(
            onTap: () {
              Navigator.of(
                context,
              ).pushNamed(AppRouter.doctorPatientDetails, arguments: caseItem);
            },
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: AppTheme.accentBlue,
                  child: Text('${caseItem.token}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        caseItem.patientName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${caseItem.age} ${caseItem.gender} • ${caseItem.symptoms}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textMuted),
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

class _DoctorScheduleTab extends StatefulWidget {
  const _DoctorScheduleTab();

  @override
  State<_DoctorScheduleTab> createState() => _DoctorScheduleTabState();
}

class _DoctorScheduleTabState extends State<_DoctorScheduleTab> {
  late List<String> _workingDays;
  late TextEditingController _morningStartController;
  late TextEditingController _morningEndController;
  late TextEditingController _eveningStartController;
  late TextEditingController _eveningEndController;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }

    final schedule = AppScope.of(context).doctorSchedule;

    _workingDays = List<String>.from(schedule.workingDays);
    _morningStartController = TextEditingController(
      text: schedule.morningStart,
    );
    _morningEndController = TextEditingController(text: schedule.morningEnd);
    _eveningStartController = TextEditingController(
      text: schedule.eveningStart,
    );
    _eveningEndController = TextEditingController(text: schedule.eveningEnd);

    _loaded = true;
  }

  @override
  void dispose() {
    _morningStartController.dispose();
    _morningEndController.dispose();
    _eveningStartController.dispose();
    _eveningEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dayLabels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return ListView(
      key: const ValueKey<String>('doctor-schedule-tab'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: <Widget>[
        MediQCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SectionHeading(title: 'Working Days'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: dayLabels.map((day) {
                  final selected = _workingDays.contains(day);
                  return FilterChip(
                    selected: selected,
                    label: Text(day),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _workingDays.add(day);
                        } else {
                          _workingDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const SectionHeading(title: 'Morning Slot'),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _morningStartController,
                      decoration: const InputDecoration(labelText: 'Start'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _morningEndController,
                      decoration: const InputDecoration(labelText: 'End'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SectionHeading(title: 'Evening Slot'),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _eveningStartController,
                      decoration: const InputDecoration(labelText: 'Start'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _eveningEndController,
                      decoration: const InputDecoration(labelText: 'End'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PrimaryActionButton(
                label: 'Save Schedule',
                onPressed: () {
                  final appState = AppScope.of(context);
                  final updated = DoctorSchedule(
                    workingDays: _workingDays,
                    morningStart: _morningStartController.text.trim(),
                    morningEnd: _morningEndController.text.trim(),
                    eveningStart: _eveningStartController.text.trim(),
                    eveningEnd: _eveningEndController.text.trim(),
                  );
                  appState.updateDoctorSchedule(updated);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Schedule updated successfully.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              SecondaryActionButton(
                label: 'Mark Holiday',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Holiday marked (mock).')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoctorQueueTab extends StatelessWidget {
  const _DoctorQueueTab();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    return ListView(
      key: const ValueKey<String>('doctor-queue-tab'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: <Widget>[
        ...appState.doctorQueue.map(
          (caseItem) => MediQCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: AppTheme.accentBlue,
                      child: Text('${caseItem.token}'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            caseItem.patientName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${caseItem.age} years • ${caseItem.gender}',
                            style: const TextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(caseItem.symptoms),
                const SizedBox(height: 8),
                PrimaryActionButton(
                  label: 'View Patient Details',
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRouter.doctorPatientDetails,
                      arguments: caseItem,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DoctorSettingsTab extends StatelessWidget {
  const _DoctorSettingsTab();

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);

    return ListView(
      key: const ValueKey<String>('doctor-settings-tab'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: <Widget>[
        MediQCard(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.notifications_rounded),
                title: const Text('Notification Preferences'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: const Text('Language'),
                subtitle: const Text('English'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_rounded),
                title: const Text('Privacy Settings'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
            ],
          ),
        ),
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

class DoctorPatientDetailsScreen extends StatelessWidget {
  const DoctorPatientDetailsScreen({super.key, required this.patientCase});

  final PatientCase patientCase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Details')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              MediQCard(
                child: Row(
                  children: <Widget>[
                    AssetCircleAvatar(
                      imageAsset: patientCase.patientImageAsset,
                      initials: _initials(patientCase.patientName),
                      radius: 30,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            patientCase.patientName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${patientCase.age} years • ${patientCase.gender} • Token #${patientCase.token}',
                            style: const TextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              MediQCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SectionHeading(title: 'Chief Complaint'),
                    Text(patientCase.symptoms),
                    const SizedBox(height: 10),
                    const SectionHeading(title: 'Known Conditions'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: patientCase.conditions
                          .map((item) => Chip(label: Text(item)))
                          .toList(),
                    ),
                  ],
                ),
              ),
              PrimaryActionButton(
                label: 'Start Consultation & Write Prescription',
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRouter.doctorWritePrescription,
                    arguments: patientCase,
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

class DoctorWritePrescriptionScreen extends StatefulWidget {
  const DoctorWritePrescriptionScreen({super.key, required this.patientCase});

  final PatientCase patientCase;

  @override
  State<DoctorWritePrescriptionScreen> createState() =>
      _DoctorWritePrescriptionScreenState();
}

class _DoctorWritePrescriptionScreenState
    extends State<DoctorWritePrescriptionScreen> {
  final List<_MedicineInputRow> _rows = <_MedicineInputRow>[
    _MedicineInputRow(
      medicineController: TextEditingController(text: 'Paracetamol'),
      doseController: TextEditingController(text: '500mg'),
      frequencyController: TextEditingController(text: '3x daily'),
      durationController: TextEditingController(text: '5 days'),
    ),
  ];

  final TextEditingController _notesController = TextEditingController(
    text:
        'Rest for 3 days. Drink fluids. Follow-up if no improvement in 5 days.',
  );

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(
        _MedicineInputRow(
          medicineController: TextEditingController(),
          doseController: TextEditingController(),
          frequencyController: TextEditingController(),
          durationController: TextEditingController(),
        ),
      );
    });
  }

  void _sendPrescription() {
    final medicines = _rows
        .where((row) => row.medicineController.text.trim().isNotEmpty)
        .map(
          (row) => PrescriptionMedicine(
            name: row.medicineController.text.trim(),
            dose: row.doseController.text.trim().isEmpty
                ? 'N/A'
                : row.doseController.text.trim(),
            frequency: row.frequencyController.text.trim().isEmpty
                ? 'N/A'
                : row.frequencyController.text.trim(),
            duration: row.durationController.text.trim().isEmpty
                ? 'N/A'
                : row.durationController.text.trim(),
          ),
        )
        .toList();

    if (medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one medicine.')),
      );
      return;
    }

    final appState = AppScope.of(context);
    appState.sendDoctorPrescription(
      patientCase: widget.patientCase,
      medicines: medicines,
      notes: _notesController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prescription sent to patient successfully.'),
      ),
    );

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.doctorShell, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Write Prescription')),
      body: MediQGradientBackground(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: SafeArea(
          child: ListView(
            children: <Widget>[
              MediQCard(
                child: Text(
                  '${widget.patientCase.patientName} • Token #${widget.patientCase.token}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ..._rows.map(
                (row) => MediQCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: row.medicineController,
                        decoration: const InputDecoration(
                          labelText: 'Medicine',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: row.doseController,
                              decoration: const InputDecoration(
                                labelText: 'Dose',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: row.frequencyController,
                              decoration: const InputDecoration(
                                labelText: 'Frequency',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: row.durationController,
                        decoration: const InputDecoration(
                          labelText: 'Duration',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SecondaryActionButton(
                label: '+ Add Medicine',
                onPressed: _addRow,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Doctor Notes'),
              ),
              const SizedBox(height: 12),
              PrimaryActionButton(
                label: 'Send Prescription',
                onPressed: _sendPrescription,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _initials(String value) {
  final parts = value.trim().split(' ');
  if (parts.isEmpty) {
    return 'PT';
  }

  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
  final initials = '$first$second'.toUpperCase();
  return initials.isEmpty ? 'PT' : initials;
}

class _MedicineInputRow {
  _MedicineInputRow({
    required this.medicineController,
    required this.doseController,
    required this.frequencyController,
    required this.durationController,
  });

  final TextEditingController medicineController;
  final TextEditingController doseController;
  final TextEditingController frequencyController;
  final TextEditingController durationController;

  void dispose() {
    medicineController.dispose();
    doseController.dispose();
    frequencyController.dispose();
    durationController.dispose();
  }
}
