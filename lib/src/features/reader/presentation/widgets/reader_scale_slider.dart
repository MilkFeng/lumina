import 'package:flutter/material.dart';

/// A horizontal scale slider with small/large "A" tap targets on either side.
///
/// The slider range is fixed to [0.5, 2.5] with 0.1 increments.
/// Tapping the letter glyphs nudges the value by 0.1 in the respective
/// direction; the glyph is greyed-out when the limit is reached.
class ReaderScaleSlider extends StatelessWidget {
  const ReaderScaleSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  static const double _min = 0.5;
  static const double _max = 2.5;
  static const double _nudge = 0.1;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    final disabledColor = Theme.of(context).colorScheme.outline;

    return Row(
      children: [
        GestureDetector(
          onTap: value > _min
              ? () => onChanged((value - _nudge).clamp(_min, _max))
              : null,
          child: Text(
            'A',
            style: TextStyle(
              fontSize: 12,
              color: value > _min ? color : disabledColor,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: _min,
            max: _max,
            divisions: 20,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ),
        GestureDetector(
          onTap: value < _max
              ? () => onChanged((value + _nudge).clamp(_min, _max))
              : null,
          child: Text(
            'A',
            style: TextStyle(
              fontSize: 22,
              color: value < _max ? color : disabledColor,
            ),
          ),
        ),
      ],
    );
  }
}
