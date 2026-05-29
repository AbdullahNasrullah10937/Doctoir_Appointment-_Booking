import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionPressed,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: AppTheme.h2)),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionPressed,
            child: Text(
              actionLabel!,
              style: AppTheme.caption.copyWith(color: AppTheme.primaryBlue),
            ),
          ),
      ],
    );
  }
}
