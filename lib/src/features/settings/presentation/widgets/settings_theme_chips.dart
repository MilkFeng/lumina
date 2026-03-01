import 'package:flutter/material.dart';

/// Chip for selecting the app-wide theme mode (system / light / dark).
/// Expands to fill available width, shows icon + label, fills background
/// with [ColorScheme.secondary] when selected.
class AppThemeModeChip extends StatelessWidget {
  const AppThemeModeChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.secondary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : colorScheme.secondary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? colorScheme.onSecondary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? colorScheme.onSecondary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip for selecting a theme color-scheme variant.
/// 56×56, previews color-scheme colors, shows [Icons.check_outlined] when
/// selected.
class AppThemeVariantChip extends StatelessWidget {
  const AppThemeVariantChip({
    super.key,
    required this.colorScheme,
    required this.isSelected,
    required this.onTap,
  });

  final ColorScheme colorScheme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          isSelected ? Icons.check_outlined : Icons.text_format_outlined,
          size: 32,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
