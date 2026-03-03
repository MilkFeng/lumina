import 'package:flutter/material.dart';
import 'package:lumina/src/core/widgets/segmented_option_chip.dart';
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
    return Row(
      children: [
        SegmentedOptionChip(
          icon: Icons.help_outline,
          label: askLabel,
          isSelected: value == ReaderLinkHandling.ask,
          onTap: () => onChanged(ReaderLinkHandling.ask),
        ),
        const SizedBox(width: 8),
        SegmentedOptionChip(
          icon: Icons.open_in_new_outlined,
          label: alwaysLabel,
          isSelected: value == ReaderLinkHandling.always,
          onTap: () => onChanged(ReaderLinkHandling.always),
        ),
        const SizedBox(width: 8),
        SegmentedOptionChip(
          icon: Icons.link_off_outlined,
          label: neverLabel,
          isSelected: value == ReaderLinkHandling.never,
          onTap: () => onChanged(ReaderLinkHandling.never),
        ),
      ],
    );
  }
}
