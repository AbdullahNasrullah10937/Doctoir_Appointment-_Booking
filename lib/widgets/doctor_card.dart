import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_image.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({
    super.key,
    required this.imagePath,
    required this.name,
    required this.specialty,
    required this.fee,
    required this.nextSlot,
    required this.isAvailable,
    this.onTap,
  });

  final String imagePath;
  final String name;
  final String specialty;
  final String fee;
  final String nextSlot;
  final bool isAvailable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.space2,
        vertical: AppTheme.space1,
      ),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space2),
          child: Row(
            children: <Widget>[
              AppImage(
                path: imagePath,
                radius: AppTheme.radiusInput,
                height: 90,
                width: 80,
              ),
              const SizedBox(width: AppTheme.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(name, style: AppTheme.h2),
                    const SizedBox(height: AppTheme.space1),
                    Text(specialty, style: AppTheme.subtitleStyle),
                    const SizedBox(height: AppTheme.space1),
                    Text(fee, style: AppTheme.caption),
                    const SizedBox(height: AppTheme.space1),
                    Text(nextSlot, style: AppTheme.caption),
                  ],
                ),
              ),
              _AvailabilityBadge(isAvailable: isAvailable),
            ],
          ),
        ),
      ),
    );
  }
}

class DoctorMiniCard extends StatelessWidget {
  const DoctorMiniCard({
    super.key,
    required this.imagePath,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.distance,
    this.onTap,
  });

  final String imagePath;
  final String name;
  final String specialty;
  final String rating;
  final String distance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: AppTheme.space2),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppImage(
              path: imagePath,
              radius: AppTheme.radiusCard,
              height: 92,
              width: double.infinity,
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.space1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(name, style: AppTheme.label),
                  const SizedBox(height: AppTheme.space1),
                  Text(specialty, style: AppTheme.caption),
                  const SizedBox(height: AppTheme.space1),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.star_rounded,
                        color: AppTheme.warning,
                        size: 16,
                      ),
                      const SizedBox(width: AppTheme.space1),
                      Text(rating, style: AppTheme.caption),
                      const SizedBox(width: AppTheme.space1),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space1,
                          vertical: AppTheme.space1,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTint,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusInput,
                          ),
                        ),
                        child: Text(distance, style: AppTheme.caption),
                      ),
                    ],
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

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final background = isAvailable ? AppTheme.successTint : AppTheme.errorTint;
    final foreground = isAvailable ? AppTheme.success : AppTheme.error;
    final label = isAvailable ? 'Available' : 'Busy';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space1,
        vertical: AppTheme.space1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.circle, color: foreground, size: 8),
          const SizedBox(width: AppTheme.space1),
          Text(label, style: AppTheme.caption.copyWith(color: foreground)),
        ],
      ),
    );
  }
}
