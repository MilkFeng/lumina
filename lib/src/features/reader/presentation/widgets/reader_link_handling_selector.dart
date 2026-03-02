import 'package:flutter/material.dart';
import 'package:lumina/src/features/reader/domain/reader_settings.dart';

/// A segmented chip-row for choosing how external hyperlinks are handled.
///
/// The three options — Ask, Always, Never — are represented as equal-width
/// chips.  The currently selected chip is highlighted with
/// `primaryContainer` colours.
class ReaderLinkHandlingSelector extends StatelessWidget {
  const ReaderLinkHandlingSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.askLabel,
    required this.alwaysLabel,
    required this.neverLabel,
  });

  final ReaderLinkHandling value;
  final ValueChanged<ReaderLinkHandling> onChanged;
  final String askLabel;
  final String alwaysLabel;
  final String neverLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget chip(ReaderLinkHandling option, IconData icon, String label) {
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
        chip(ReaderLinkHandling.ask, Icons.help_outline, askLabel),
        const SizedBox(width: 8),
        chip(
          ReaderLinkHandling.always,
          Icons.open_in_new_outlined,
          alwaysLabel,
        ),
        const SizedBox(width: 8),
        chip(ReaderLinkHandling.never, Icons.link_off_outlined, neverLabel),
      ],
    );
  }
}
