import 'package:docscan/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class TagPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const TagPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.surfaceHighlight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
