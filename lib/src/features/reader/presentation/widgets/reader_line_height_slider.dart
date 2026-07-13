import 'package:flutter/material.dart';

/// Changed by hawah on 26/Jul/13:
/// A horizontal lineHeight slider with small/large "≡↕" tap targets on either side.
///
/// The slider range is fixed to [1.2, 2.5] with 0.1 increments.
/// Tapping the letter glyphs nudges the value by 0.1 in the respective
/// Holding the letter glyphs nudges the value to max/min value
/// direction; the glyph is greyed-out when the limit is reached.
class ReaderLineHeightSlider extends StatelessWidget {
  const ReaderLineHeightSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  static const double _min = 1.2;
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
          onLongPress: value > _min
              ? () => onChanged(_min)
              : null,
          child: Text(
            '≡↕',
            style: TextStyle(
              fontSize: 18,
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
          onLongPress: value < _max
              ? () => onChanged(_max)
              : null,
          child: Text(
            '≡↕',
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
