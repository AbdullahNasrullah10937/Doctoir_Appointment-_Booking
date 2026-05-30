import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';

class DigitalPrescriptionScreen extends StatefulWidget {
  const DigitalPrescriptionScreen({super.key, this.record});
  final HealthRecord? record;

  @override
  State<DigitalPrescriptionScreen> createState() => _DigitalPrescriptionScreenState();
}

class _DigitalPrescriptionScreenState extends State<DigitalPrescriptionScreen> {
  Future<Prescription>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future != null) return;
    final appState = AppScope.of(context);
    final record = widget.record ?? (appState.records.isEmpty ? null : appState.records.first);
    if (record != null) _future = appState.getPrescriptionForRecord(record);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 14),
              decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Digital Prescription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('View & manage your prescriptions', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _future == null
                  ? const EmptyStateView(
                      title: 'No prescription found',
                      message: 'No prescription record is available.',
                      icon: Icons.description_rounded,
                    )
                  : FutureBuilder<Prescription>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final rx = snapshot.data!;
                        return ListView(
                          padding: const EdgeInsets.all(AppTheme.space4),
                          children: <Widget>[
                            // Rx header card
                            MediQCard(
                              gradient: AppTheme.primaryGradient,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      const Text(
                                        'Rx',
                                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, fontStyle: FontStyle.italic),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            const Text('Qurexa Digital Prescription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                            Text(formatDate(rx.date), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _RxRow(label: 'Doctor', value: rx.doctorName),
                                  _RxRow(label: 'Patient', value: rx.patientName),
                                  _RxRow(label: 'Diagnosis', value: rx.diagnosis),
                                ],
                              ),
                            ),
                            // Medicines
                            const SectionHeading(title: 'Medications'),
                            ...rx.medicines.map((med) => MediQCard(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primarySoft,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    ),
                                    child: const Icon(Icons.medication_rounded, color: AppTheme.accentBlue, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(med.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                        Text('${med.dose} • ${med.frequency} • ${med.duration}',
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            // Notes
                            if (rx.notes.isNotEmpty) ...<Widget>[
                              const SectionHeading(title: 'Doctor Notes'),
                              MediQCard(
                                child: Text(rx.notes, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                              ),
                            ],
                            const SizedBox(height: 8),
                            PrimaryActionButton(
                              label: 'Set Medicine Reminders',
                              icon: Icons.alarm_rounded,
                              onPressed: () => Navigator.of(context).pushNamed(AppRouter.medicationReminders),
                            ),
                            const SizedBox(height: 10),
                            SecondaryActionButton(
                              label: 'Download PDF',
                              icon: Icons.download_rounded,
                              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Prescription PDF downloaded (mock).')),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RxRow extends StatelessWidget {
  const _RxRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Text('$label: ', style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))),
        ],
      ),
    );
  }
}
