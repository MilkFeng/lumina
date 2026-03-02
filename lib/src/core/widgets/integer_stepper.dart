import 'package:flutter/material.dart';

/// A compact card-style stepper for an integer value.
///
/// Displays a [label] above a row with decrement/increment icon-buttons and the
/// current [value] in between.  Values are clamped to [[min], [max]] and change
/// by [step] on each tap.
class IntegerStepper extends StatelessWidget {
  const IntegerStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;

  /// Amount added or subtracted on each button press.
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_outlined, size: 16),
                onPressed: value > min ? () => onChanged(value - step) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                visualDensity: VisualDensity.compact,
                color: colorScheme.primary,
                disabledColor: colorScheme.outline,
              ),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_outlined, size: 16),
                onPressed: value < max ? () => onChanged(value + step) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                visualDensity: VisualDensity.compact,
                color: colorScheme.primary,
                disabledColor: colorScheme.outline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
