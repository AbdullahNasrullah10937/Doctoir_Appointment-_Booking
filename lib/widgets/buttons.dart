import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon = Icons.arrow_forward_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label, style: AppTheme.button)),
            Icon(trailingIcon, color: AppTheme.white),
          ],
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
        ),
        child: Row(
          children: <Widget>[
            ?leading,
            if (leading != null) const SizedBox(width: AppTheme.space1),
            Expanded(
              child: Text(
                label,
                style: AppTheme.button.copyWith(color: AppTheme.darkText),
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: AppTheme.darkText),
          ],
        ),
      ),
    );
  }
}
