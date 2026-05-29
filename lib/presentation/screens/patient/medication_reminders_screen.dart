import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';

class MedicationRemindersScreen extends StatelessWidget {
  const MedicationRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final reminders = appState.reminders;
    final enabled = reminders.where((r) => r.isEnabled).length;
    final total = reminders.length;

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
                        Text('Medication Reminders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        Text('Never miss a dose', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.alarm_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: <Widget>[
                  // Summary card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.space4, AppTheme.space4, AppTheme.space4, 0),
                    child: MediQCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(Icons.analytics_rounded, color: AppTheme.accentBlue, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "Today's Status: $enabled/$total active",
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: total == 0 ? 0 : enabled / total,
                              minHeight: 8,
                              backgroundColor: AppTheme.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            total == 0 ? 'No reminders set' : '$enabled of $total medicines active',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // List
                  Expanded(
                    child: reminders.isEmpty
                        ? const EmptyStateView(
                            title: 'No Reminders Set',
                            message: 'Add medication reminders from your prescription.',
                            icon: Icons.alarm_off_rounded,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppTheme.space4),
                            itemCount: reminders.length,
                            itemBuilder: (_, index) {
                              final reminder = reminders[index];
                              return MediQCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Container(
                                          width: 42, height: 42,
                                          decoration: BoxDecoration(
                                            color: reminder.isEnabled
                                                ? AppTheme.primarySoft
                                                : AppTheme.surfaceAlt,
                                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                          ),
                                          child: Icon(
                                            Icons.medication_rounded,
                                            color: reminder.isEnabled ? AppTheme.accentBlue : AppTheme.textMuted,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(reminder.medicineName,
                                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                              Text(
                                                '${reminder.remainingDays} days remaining',
                                                style: TextStyle(
                                                  color: reminder.remainingDays <= 2 ? AppTheme.danger : AppTheme.textMuted,
                                                  fontSize: 12,
                                                  fontWeight: reminder.remainingDays <= 2 ? FontWeight.w700 : FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: reminder.isEnabled,
                                          onChanged: (_) => appState.toggleReminder(reminder.id),
                                        ),
                                      ],
                                    ),
                                    if (reminder.times.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 10),
                                      const Divider(height: 1),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8, runSpacing: 8,
                                        children: reminder.times.map((time) => Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: reminder.isEnabled ? AppTheme.primarySoft : AppTheme.surfaceAlt,
                                            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                                            border: Border.all(color: AppTheme.border),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Icon(Icons.access_time_rounded, size: 12,
                                                color: reminder.isEnabled ? AppTheme.accentBlue : AppTheme.textMuted),
                                              const SizedBox(width: 4),
                                              Text(time, style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: reminder.isEnabled ? AppTheme.accentBlue : AppTheme.textMuted,
                                              )),
                                            ],
                                          ),
                                        )).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
