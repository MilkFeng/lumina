import 'package:flutter/material.dart';

/// A single option chip used inside a segmented chip-row.
///
/// Renders an [icon] above a [label] inside a rounded tile that expands to
/// fill its share of the parent [Row].  The tile's background and border
/// colour change when [isSelected] is `true`.
///
/// Color defaults match the `primaryContainer` style used by the reader
/// settings selectors.  Pass explicit overrides for the `secondary` style used
/// by [AppThemeModeChip] or any other palette.
class SegmentedOptionChip extends StatelessWidget {
  const SegmentedOptionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedBackgroundColor,
    this.onSelectedColor,
    this.selectedBorderColor,
    this.unselectedBorderColor,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// Background colour when selected.
  /// Defaults to [ColorScheme.primaryContainer].
  final Color? selectedBackgroundColor;

  /// Foreground (icon + text) colour when selected.
  /// Defaults to [ColorScheme.onPrimaryContainer].
  final Color? onSelectedColor;

  /// Border colour when selected.
  /// Defaults to [ColorScheme.primary].
  final Color? selectedBorderColor;

  /// Border colour when unselected.
  /// Defaults to [ColorScheme.outlineVariant].
  final Color? unselectedBorderColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final effectiveSelectedBg = selectedBackgroundColor ?? cs.primaryContainer;
    final effectiveOnSelected = onSelectedColor ?? cs.onPrimaryContainer;
    final effectiveSelectedBorder = selectedBorderColor ?? cs.primary;
    final effectiveUnselectedBorder =
        unselectedBorderColor ?? cs.outlineVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveSelectedBg
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? effectiveSelectedBorder
                  : effectiveUnselectedBorder,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? effectiveOnSelected : cs.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? effectiveOnSelected : cs.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
