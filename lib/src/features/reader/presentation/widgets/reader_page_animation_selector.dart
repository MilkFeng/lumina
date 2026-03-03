import 'package:flutter/material.dart';
import 'package:lumina/src/core/widgets/segmented_option_chip.dart';
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
    return Row(
      children: [
        SegmentedOptionChip(
          icon: Icons.not_interested_outlined,
          label: noneLabel,
          isSelected: value == ReaderPageAnimation.none,
          onTap: () => onChanged(ReaderPageAnimation.none),
        ),
        const SizedBox(width: 8),
        SegmentedOptionChip(
          icon: Icons.swipe_outlined,
          label: slideLabel,
          isSelected: value == ReaderPageAnimation.slide,
          onTap: () => onChanged(ReaderPageAnimation.slide),
        ),
      ],
    );
  }
}
