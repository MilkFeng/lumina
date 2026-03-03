import 'package:flutter/material.dart';
import 'package:lumina/src/core/widgets/segmented_option_chip.dart';

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
    final cs = Theme.of(context).colorScheme;
    return SegmentedOptionChip(
      icon: icon,
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      selectedBackgroundColor: cs.secondary,
      onSelectedColor: cs.onSecondary,
      selectedBorderColor: cs.primary.withValues(alpha: 0.5),
      unselectedBorderColor: cs.secondary.withValues(alpha: 0.3),
    );
  }
}
