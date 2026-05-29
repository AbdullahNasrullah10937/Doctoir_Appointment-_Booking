import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/common_widgets.dart';

class QueueTrackerScreen extends StatefulWidget {
  const QueueTrackerScreen({super.key, required this.appointment});
  final Appointment appointment;

  @override
  State<QueueTrackerScreen> createState() => _QueueTrackerScreenState();
}

class _QueueTrackerScreenState extends State<QueueTrackerScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) AppScope.of(context).tickQueue();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final queue = appState.queueSnapshot;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // AppBar
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
              color: AppTheme.surface,
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Live Queue Tracker',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                  ),
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.success, shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Live', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
            ),

            Expanded(
              child: queue == null
                  ? const EmptyStateView(
                      title: 'Queue not available',
                      message: 'Queue details appear once booking is confirmed.',
                      icon: Icons.queue_rounded,
                    )
                  : ListView(
                      padding: const EdgeInsets.all(AppTheme.space4),
                      children: <Widget>[
                        // Doctor info
                        MediQCard(
                          child: Column(
                            children: <Widget>[
                              Text(
                                queue.doctorName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                queue.clinicLocation,
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 18),
                              // Token circle
                              ScaleTransition(
                                scale: _pulseAnim,
                                child: Container(
                                  width: 120, height: 120,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primarySoft,
                                    border: Border.all(color: AppTheme.accentBlue, width: 4),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: AppTheme.accentBlue.withValues(alpha: 0.25),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        '${queue.yourToken}',
                                        style: const TextStyle(
                                          fontSize: 38, fontWeight: FontWeight.w800, color: AppTheme.accentBlue,
                                        ),
                                      ),
                                      const Text(
                                        'Your Token',
                                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Metrics
                              Row(
                                children: <Widget>[
                                  Expanded(child: _StatBox(label: 'Current', value: '${queue.currentToken}', color: AppTheme.accentBlue)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _StatBox(label: 'Ahead', value: '${queue.patientsAhead}', color: AppTheme.warning)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _StatBox(label: 'Wait', value: '${queue.estimatedWaitMinutes}m', color: AppTheme.success)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Alerts card
                        MediQCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    width: 8, height: 8,
                                    decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Auto Alerts', style: TextStyle(fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _AlertRow(icon: Icons.people_rounded, text: '${queue.patientsAhead} patients ahead of you'),
                              _AlertRow(icon: Icons.location_on_rounded, text: 'Please make your way to the clinic'),
                              if (widget.appointment.isVideoConsultation) ...<Widget>[
                                const SizedBox(height: 10),
                                PrimaryActionButton(
                                  label: 'Join Video Consultation',
                                  icon: Icons.videocam_rounded,
                                  onPressed: () => Navigator.of(context).pushNamed(
                                    AppRouter.videoConsultation, arguments: widget.appointment.doctor,
                                  ),
                                ),
                              ],
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
                label: 'Mark Consultation Completed',
                icon: Icons.check_circle_rounded,
                onPressed: () {
                  AppScope.of(context).completeAppointment(widget.appointment.id);
                  Navigator.of(context).pushNamed(AppRouter.rateReview, arguments: widget.appointment.doctor);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: <Widget>[
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: AppTheme.accentBlue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }
}
