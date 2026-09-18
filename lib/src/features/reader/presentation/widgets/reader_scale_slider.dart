import 'package:flutter/material.dart';

/// A horizontal scale slider with small/large "A" tap targets on either side.
///
/// The slider range is fixed to [0.5, 2.5] with 0.1 increments.
/// Tapping the letter glyphs nudges the value by 0.1 in the respective
/// direction; the glyph is greyed-out when the limit is reached.
///
/// Changed by hawah on 26/Jul/13:
///   Holding the letter glyphs nudges the value to max/min value
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
          onLongPress: value > _min ? () => onChanged(_min) : null,
          child: Icon(
            Icons.text_decrease_outlined,
            size: 24,
            color: value > _min ? color : disabledColor,
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
          onLongPress: value < _max ? () => onChanged(_max) : null,
          child: Icon(
            Icons.text_increase_outlined,
            size: 24,
            color: value < _max ? color : disabledColor,
          ),
        ),
      ],
    );
  }
}
