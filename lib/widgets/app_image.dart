import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.path,
    this.radius = AppTheme.radiusCard,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
  });

  final String path;
  final double radius;
  final BoxFit fit;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        path,
        fit: fit,
        height: height,
        width: width,
        errorBuilder: (_, _, _) {
          return Container(
            height: height,
            width: width,
            color: AppTheme.lightTint,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_outlined,
              color: AppTheme.hint,
              size: 28,
            ),
          );
        },
      ),
    );
  }
}
