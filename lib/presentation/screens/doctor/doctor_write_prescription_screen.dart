import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/screen_helpers.dart';

class DoctorWritePrescriptionScreen extends StatefulWidget {
  const DoctorWritePrescriptionScreen({super.key, required this.patientCase});
  final PatientCase patientCase;

  @override
  State<DoctorWritePrescriptionScreen> createState() => _DoctorWritePrescriptionScreenState();
}

class _DoctorWritePrescriptionScreenState extends State<DoctorWritePrescriptionScreen> {
  final List<MedicineInputRow> _rows = <MedicineInputRow>[
    MedicineInputRow(
      medicineController: TextEditingController(text: 'Paracetamol'),
      doseController: TextEditingController(text: '500mg'),
      frequencyController: TextEditingController(text: '3x daily'),
      durationController: TextEditingController(text: '5 days'),
    ),
  ];
  final TextEditingController _diagnosisController = TextEditingController(text: 'Viral Fever');
  final TextEditingController _notesController = TextEditingController(
    text: 'Rest for 3 days. Drink fluids. Follow-up if no improvement in 5 days.',
  );

  @override
  void dispose() {
    for (final row in _rows) { row.dispose(); }
    _diagnosisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(MedicineInputRow(
        medicineController: TextEditingController(),
        doseController: TextEditingController(),
        frequencyController: TextEditingController(),
        durationController: TextEditingController(),
      ));
    });
  }

  void _removeRow(int index) {
    _rows[index].dispose();
    setState(() => _rows.removeAt(index));
  }

  void _sendPrescription() {
    final medicines = _rows
        .where((r) => r.medicineController.text.trim().isNotEmpty)
        .map((r) => PrescriptionMedicine(
          name: r.medicineController.text.trim(),
          dose: r.doseController.text.trim().isEmpty ? 'N/A' : r.doseController.text.trim(),
          frequency: r.frequencyController.text.trim().isEmpty ? 'N/A' : r.frequencyController.text.trim(),
          duration: r.durationController.text.trim().isEmpty ? 'N/A' : r.durationController.text.trim(),
        ))
        .toList();

    if (medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one medicine.')));
      return;
    }

    AppScope.of(context).sendDoctorPrescription(
      patientCase: widget.patientCase,
      medicines: medicines,
      notes: _notesController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prescription sent to patient successfully.')),
    );
    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.doctorShell, (_) => false);
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Write Prescription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('${widget.patientCase.patientName} • Token #${widget.patientCase.token}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Text('Rx', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.space4),
                children: <Widget>[
                  // Diagnosis
                  const _FieldLabel('Diagnosis'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _diagnosisController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Viral Fever',
                      prefixIcon: Icon(Icons.biotech_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Medicines header
                  Row(
                    children: <Widget>[
                      const Text('Medications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _addRow,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySoft,
                            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                            border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.add_rounded, size: 16, color: AppTheme.accentBlue),
                              SizedBox(width: 4),
                              Text('Add Medicine', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Medicine rows
                  ...List<Widget>.generate(_rows.length, (index) {
                    final row = _rows[index];
                    return MediQCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(color: AppTheme.primarySoft, shape: BoxShape.circle),
                                child: Center(child: Text('${index + 1}', style: const TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700, fontSize: 13))),
                              ),
                              const SizedBox(width: 8),
                              const Text('Medicine', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const Spacer(),
                              if (_rows.length > 1)
                                GestureDetector(
                                  onTap: () => _removeRow(index),
                                  child: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.danger, size: 20),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: row.medicineController,
                            decoration: const InputDecoration(hintText: 'Medicine name', prefixIcon: Icon(Icons.medication_rounded)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Expanded(child: TextField(controller: row.doseController, decoration: const InputDecoration(labelText: 'Dose', hintText: '500mg'))),
                              const SizedBox(width: 8),
                              Expanded(child: TextField(controller: row.frequencyController, decoration: const InputDecoration(labelText: 'Frequency', hintText: '3x daily'))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: row.durationController,
                            decoration: const InputDecoration(labelText: 'Duration', hintText: '5 days', prefixIcon: Icon(Icons.calendar_today_rounded)),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Notes
                  const _FieldLabel('Doctor Notes'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Instructions, follow-up advice...'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Bottom CTA
            Container(
              padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space3, AppTheme.space4, AppTheme.space4),
              decoration: const BoxDecoration(color: AppTheme.surface, border: Border(top: BorderSide(color: AppTheme.border))),
              child: PrimaryActionButton(
                label: 'Send Prescription to Patient',
                icon: Icons.send_rounded,
                onPressed: _sendPrescription,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary));
  }
}
