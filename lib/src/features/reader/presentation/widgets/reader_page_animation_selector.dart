import 'package:flutter/material.dart';
import 'package:lumina/src/features/reader/domain/reader_settings.dart';

/// A segmented chip-row for choosing the page-turning animation style.
///
/// Currently supports two options: None and Slide.  The selected chip is
/// highlighted with `primaryContainer` colours.
class ReaderPageAnimationSelector extends StatelessWidget {
  const ReaderPageAnimationSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.noneLabel,
    required this.slideLabel,
  });

  final ReaderPageAnimation value;
  final ValueChanged<ReaderPageAnimation> onChanged;
  final String noneLabel;
  final String slideLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget chip(ReaderPageAnimation option, IconData icon, String label) {
      final selected = value == option;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(option),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
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

    return Row(
      children: [
        chip(
          ReaderPageAnimation.none,
          Icons.not_interested_outlined,
          noneLabel,
        ),
        const SizedBox(width: 8),
        chip(ReaderPageAnimation.slide, Icons.swipe_outlined, slideLabel),
      ],
    );
  }
}
