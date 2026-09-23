import 'package:flutter/material.dart';
import 'package:lumina/src/core/widgets/segmented_option_chip.dart';
import 'package:lumina/src/features/reader/domain/reader_settings.dart';

/// A segmented chip-row for choosing how a chapter is laid out: discrete pages
/// or one continuously scrolling column.
///
/// The row is rendered disabled when the book cannot support scrolling — a
/// right-to-left or vertical-writing book always paginates — so the option
/// stays discoverable instead of silently disappearing.
class ReaderScrollModeSelector extends StatelessWidget {
  const ReaderScrollModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.paginatedLabel,
    required this.scrollingLabel,
    this.enabled = true,
  });

  final ReaderScrollMode value;
  final ValueChanged<ReaderScrollMode> onChanged;
  final String paginatedLabel;
  final String scrollingLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SegmentedOptionChip(
          icon: Icons.auto_stories_outlined,
          label: paginatedLabel,
          isSelected: value == ReaderScrollMode.paginated,
          enabled: enabled,
          onTap: () => onChanged(ReaderScrollMode.paginated),
        ),
        const SizedBox(width: 8),
        SegmentedOptionChip(
          icon: Icons.swap_vert_outlined,
          label: scrollingLabel,
          isSelected: value == ReaderScrollMode.scrolling,
          enabled: enabled,
          onTap: () => onChanged(ReaderScrollMode.scrolling),
        ),
      ],
    );
  }
}
