import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class EmergencyNumbersScreen extends StatelessWidget {
  const EmergencyNumbersScreen({super.key});

  static const List<_Emergency> _entries = <_Emergency>[
    _Emergency(icon: Icons.local_hospital_rounded, title: 'Ambulance', number: '1122', description: 'Punjab Emergency Service', color: AppTheme.danger),
    _Emergency(icon: Icons.local_police_rounded, title: 'Police Helpline', number: '15', description: 'National Police Emergency', color: AppTheme.accentBlue),
    _Emergency(icon: Icons.health_and_safety_rounded, title: 'Hospital Assistance', number: '1234', description: 'Hospital Information Desk', color: AppTheme.success),
    _Emergency(icon: Icons.call_rounded, title: 'Health Support', number: '44488', description: '24/7 Patient Support Line', color: AppTheme.warning),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 14),
              color: AppTheme.danger,
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text('Emergency Numbers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  const Icon(Icons.emergency_rounded, color: Colors.white),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: AppTheme.space4),
              color: AppTheme.dangerLight,
              child: const Text(
                '⚠️  For life-threatening emergencies, call immediately.',
                style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppTheme.space4),
                itemCount: _entries.length,
                itemBuilder: (_, index) => _EmergencyCard(entry: _entries[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.entry});
  final _Emergency entry;

  @override
  Widget build(BuildContext context) {
    return MediQCard(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dialing ${entry.number} — ${entry.title} (mock)...')),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(entry.icon, color: entry.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(entry.number, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: entry.color)),
                Text(entry.description, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: entry.color,
            child: const Icon(Icons.call_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _Emergency {
  const _Emergency({required this.icon, required this.title, required this.number, required this.description, required this.color});
  final IconData icon;
  final String title, number, description;
  final Color color;
}
