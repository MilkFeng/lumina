import 'package:flutter/material.dart';

/// A square chip that represents a single reader colour theme option.
///
/// Shows a [Icons.check_outlined] icon when [isSelected] is `true`, otherwise
/// shows [Icons.text_format_outlined].  The chip's surface and icon colours are
/// driven entirely by the supplied [colorScheme] so it accurately previews the
/// theme it represents.
class ReaderThemeOptionChip extends StatelessWidget {
  const ReaderThemeOptionChip({
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
