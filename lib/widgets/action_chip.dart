import 'package:flutter/material.dart' hide ActionChip;

import '../core/theme/app_theme.dart';

class ActionChip extends StatelessWidget {
  const ActionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
    this.unselectedColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.radius = AppTheme.radiusChip,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppTheme.space2,
      vertical: AppTheme.space1,
    ),
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? (selectedColor ?? AppTheme.primaryBlue)
        : (unselectedColor ?? AppTheme.lightTint);
    final foreground = selected
        ? (selectedTextColor ?? AppTheme.white)
        : (unselectedTextColor ?? AppTheme.darkText);

    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Text(label, style: AppTheme.caption.copyWith(color: foreground)),
      ),
    );
  }
}
