import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/screen_helpers.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final notifications = appState.notifications;
    final unread = notifications.where((n) => n.isUnread).length;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 12),
              color: AppTheme.surface,
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                        if (unread > 0)
                          Text('$unread unread', style: const TextStyle(color: AppTheme.accentBlue, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (unread > 0)
                    TextButton(
                      onPressed: appState.markAllNotificationsAsRead,
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? const EmptyStateView(
                      title: 'All caught up!',
                      message: 'No new notifications at the moment.',
                      icon: Icons.notifications_none_rounded,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.space4),
                      itemCount: notifications.length,
                      itemBuilder: (ctx, index) {
                        final item = notifications[index];
                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.startToEnd,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                            ),
                            child: const Row(
                              children: <Widget>[
                                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (_) {
                            final deleted = item;
                            appState.deleteNotification(item.id);
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                backgroundColor: AppTheme.textPrimary,
                                content: const Text(
                                  'Notification deleted',
                                  style: TextStyle(color: Colors.white, fontSize: 13),
                                ),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  textColor: AppTheme.qAccent,
                                  onPressed: () => appState.insertNotification(deleted),
                                ),
                              ),
                            );
                          },
                          child: _NotificationCard(
                            notification: item,
                            onTap: () {
                              switch (item.type) {
                                case NotificationType.queue:
                                  final upcoming = appState.nextUpcomingAppointment;
                                  if (upcoming != null) Navigator.of(context).pushNamed(AppRouter.queueTracker, arguments: upcoming);
                                case NotificationType.medication:
                                  Navigator.of(context).pushNamed(AppRouter.medicationReminders);
                                case NotificationType.appointment:
                                  appState.setPatientTab(1);
                                  Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.patientShell, (_) => false);
                                case NotificationType.ai:
                                  Navigator.of(context).pushNamed(AppRouter.aiAssistant);
                                case NotificationType.system:
                                  break;
                              }
                            },
                          ),
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});
  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor;
    switch (notification.type) {
      case NotificationType.queue:
        iconColor = AppTheme.accentBlue;
      case NotificationType.medication:
        iconColor = AppTheme.success;
      case NotificationType.appointment:
        iconColor = AppTheme.warning;
      case NotificationType.ai:
        iconColor = const Color(0xFF8B5CF6);
      case NotificationType.system:
        iconColor = AppTheme.textMuted;
    }

    return MediQCard(
      onTap: onTap,
      color: notification.isUnread ? AppTheme.primarySoft.withValues(alpha: 0.5) : null,
      borderColor: notification.isUnread ? AppTheme.accentBlue.withValues(alpha: 0.2) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(notificationIcon(notification.type), color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isUnread ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (notification.isUnread)
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.accentBlue, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(notification.message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
                const SizedBox(height: 4),
                Text(notification.timeLabel, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
