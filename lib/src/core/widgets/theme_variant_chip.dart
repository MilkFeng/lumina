import 'package:flutter/material.dart';

/// A square 56×56 chip that previews a [ColorScheme] and indicates selection.
///
/// Shows [Icons.check_outlined] with a scale+fade animation when [isSelected]
/// is `true`, otherwise shows [Icons.text_format_outlined].  The border color
/// also animates between selected / unselected states.
class ThemeVariantChip extends StatelessWidget {
  const ThemeVariantChip({
    super.key,
    required this.colorScheme,
    required this.isSelected,
    required this.onTap,
  });

  /// Colour scheme of the theme preset this chip represents.
  final ColorScheme colorScheme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appColorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? appColorScheme.primary.withValues(alpha: 0.5)
                : appColorScheme.secondary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            isSelected ? Icons.check_outlined : Icons.text_format_outlined,
            key: ValueKey(isSelected),
            size: 32,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
