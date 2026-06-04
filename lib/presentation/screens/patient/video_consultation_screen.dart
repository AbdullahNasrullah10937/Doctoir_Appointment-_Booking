import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/app_entities.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/screen_helpers.dart';

class VideoConsultationScreen extends StatelessWidget {
  const VideoConsultationScreen({super.key, this.doctor});
  final Doctor? doctor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white60),
                  ),
                  const Expanded(
                    child: Text(
                      'Video Consultation',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                        const Text('Live', style: TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Video area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppTheme.space3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2128),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    AssetCircleAvatar(
                      imageAsset: doctor?.imageAsset,
                      initials: buildInitials(doctor?.name ?? 'DR', fallback: 'DR'),
                      radius: 52,
                      borderColor: AppTheme.accentBlue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      doctor?.name ?? 'Doctor',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    if (doctor != null)
                      Text(doctor!.specialty, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                    const SizedBox(height: 12),
                    const RepaintBoundary(child: _PulseDot()),
                    const SizedBox(height: 6),
                    const Text('Connected', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.fromLTRB(AppTheme.space6, AppTheme.space4, AppTheme.space6, AppTheme.space5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _ControlButton(icon: Icons.mic_rounded, label: 'Mute'),
                  _ControlButton(icon: Icons.videocam_rounded, label: 'Camera'),
                  _ControlButton(icon: Icons.volume_up_rounded, label: 'Speaker'),
                  _EndCallButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _a,
      child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

class _EndCallButton extends StatelessWidget {
  const _EndCallButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppTheme.danger,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(color: AppTheme.danger.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 6),
        const Text('End', style: TextStyle(color: AppTheme.danger, fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
