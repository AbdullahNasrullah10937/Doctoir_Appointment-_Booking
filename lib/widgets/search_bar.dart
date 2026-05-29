import 'package:flutter/material.dart' hide SearchBar;

import '../core/theme/app_theme.dart';

class SearchBar extends StatelessWidget {
  const SearchBar({
    super.key,
    this.hintText = 'Search doctors, specialties...',
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space2),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
          const SizedBox(width: AppTheme.space1),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTap: onTap,
              readOnly: readOnly,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
