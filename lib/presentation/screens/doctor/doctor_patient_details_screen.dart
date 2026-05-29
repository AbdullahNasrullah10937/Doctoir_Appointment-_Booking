import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/screen_helpers.dart';

class DoctorPatientDetailsScreen extends StatelessWidget {
  const DoctorPatientDetailsScreen({super.key, required this.patientCase});
  final PatientCase patientCase;

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
                        Text('Patient Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Current consultation', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.space4),
                children: <Widget>[
                  // Patient identity card
                  MediQCard(
                    child: Row(
                      children: <Widget>[
                        AssetCircleAvatar(
                          imageAsset: patientCase.patientImageAsset,
                          initials: buildInitials(patientCase.patientName, fallback: 'PT'),
                          radius: 32,
                          borderColor: AppTheme.accentBlue,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(patientCase.patientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                              const SizedBox(height: 3),
                              Text(
                                '${patientCase.age} yrs • ${patientCase.gender}',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primarySoft,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Text(
                            'Token #${patientCase.token}',
                            style: const TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Vital metrics
                  MediQCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SectionHeading(title: 'Vitals'),
                        Row(
                          children: <Widget>[
                            _VitalBox(icon: Icons.thermostat_rounded, label: 'Temp', value: '98.6°F', color: AppTheme.warning),
                            const SizedBox(width: 8),
                            _VitalBox(icon: Icons.favorite_rounded, label: 'Heart Rate', value: '72 bpm', color: AppTheme.danger),
                            const SizedBox(width: 8),
                            _VitalBox(icon: Icons.monitor_heart_rounded, label: 'BP', value: '120/80', color: AppTheme.accentBlue),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Chief complaint
                  MediQCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SectionHeading(title: 'Chief Complaint'),
                        Text(patientCase.symptoms, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                      ],
                    ),
                  ),
                  // Known conditions
                  MediQCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SectionHeading(title: 'Known Conditions'),
                        if (patientCase.conditions.isEmpty)
                          const Text('None reported', style: TextStyle(color: AppTheme.textMuted))
                        else
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: patientCase.conditions.map((c) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.warningLight,
                                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                              ),
                              child: Text(c, style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w600, fontSize: 13)),
                            )).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom CTA
            Container(
              padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space3, AppTheme.space4, AppTheme.space4),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: PrimaryActionButton(
                label: 'Start Consultation & Write Prescription',
                icon: Icons.edit_document,
                onPressed: () => Navigator.of(context).pushNamed(AppRouter.doctorWritePrescription, arguments: patientCase),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalBox extends StatelessWidget {
  const _VitalBox({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
