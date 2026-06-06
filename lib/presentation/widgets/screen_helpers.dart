import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/app_entities.dart';

// ─── String helpers ───────────────────────────────────────────────────────────

/// Returns 1–2 uppercase initials from a display name.
String buildInitials(String value, {String fallback = 'PT'}) {
  final parts = value.trim().split(' ');
  if (parts.isEmpty) return fallback;
  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
  final initials = '$first$second'.toUpperCase();
  return initials.isEmpty ? fallback : initials;
}

// ─── Widget helpers ───────────────────────────────────────────────────────────



/// Settings list-tile row used inside the patient settings tab.
Widget buildSettingsTile(
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

/// Emergency contact card row used in the emergency numbers screen.
Widget buildEmergencyCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String number,
  required String description,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: AppTheme.space3),
    padding: const EdgeInsets.all(AppTheme.space3),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      border: Border.all(color: AppTheme.border),
      boxShadow: AppTheme.cardShadow,
    ),
    child: Row(
      children: <Widget>[
        CircleAvatar(
          backgroundColor: AppTheme.dangerLight,
          child: Icon(icon, color: AppTheme.danger),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                number,
                style: const TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                description,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final uri = Uri(scheme: 'tel', path: number);
            try {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                throw 'Could not launch dialer';
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not open phone dialer: $e'),
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          child: const Text('Call'),
        ),
      ],
    ),
  );
}

/// Circular video control button for the video consultation screen.
Widget buildVideoControl(IconData icon) {
  return CircleAvatar(
    radius: 24,
    backgroundColor: AppTheme.surfaceAlt,
    child: Icon(icon, color: AppTheme.textPrimary),
  );
}

/// Maps a [NotificationType] to its icon.
IconData notificationIcon(NotificationType type) {
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

// ─── Data classes ─────────────────────────────────────────────────────────────

/// One slide in the onboarding page-view.
class OnboardingItem {
  const OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String asset;
  final IconData icon;
}

/// A single chat message for the AI health assistant chat UI.
class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

/// A single medicine input row in the doctor prescription writer.
class MedicineInputRow {
  MedicineInputRow({
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
