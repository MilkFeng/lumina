import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Main button of the library speed dial.
///
/// The open state is drawn by rotating the very same plus glyph by 45 degrees,
/// which is what a cross is, so a second icon never enters the tree and there is
/// nothing to cross fade. `flutter_speed_dial`'s built-in icon handling instead
/// fades `activeIcon` in while `icon` fades out: both glyphs are painted at once
/// (they sit 45 degrees out of phase, because the package pre-rotates the active
/// icon by a visually inert 90 degrees) and that fade keeps running for 60ms
/// after the dial has finished opening - the overlap reads as a flicker. Passing
/// this widget as the speed dial's `dialRoot` replaces all of it with a single
/// rotating icon.
///
/// It renders what the package draws by default: theme FAB colours, stadium
/// shape, elevation 6, no hero tag.
class SpeedDialRootButton extends StatefulWidget {
  const SpeedDialRootButton({
    super.key,
    required this.open,
    required this.onPressed,
  });

  /// Whether the dial is open. Owned by the speed dial.
  final bool open;

  /// Opens or closes the dial.
  final VoidCallback onPressed;

  @override
  State<SpeedDialRootButton> createState() => _SpeedDialRootButtonState();
}

class _SpeedDialRootButtonState extends State<SpeedDialRootButton>
    with SingleTickerProviderStateMixin {
  /// Half of a right angle: the rotation that turns a plus into a cross.
  static const double _morphAngle = math.pi / 4;

  static const double _iconSize = 24;

  /// A little longer than the 150ms the dial spends on its child buttons, so the
  /// icon settles last.
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );

  /// Eased rather than linear: the package drives its rotation with the raw
  /// controller value, which made the icon feel mechanical next to the eased
  /// child buttons.
  late final Animation<double> _turn = _controller.drive(
    CurveTween(curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _controller.value = widget.open ? 1 : 0;
  }

  @override
  void didUpdateWidget(SpeedDialRootButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) {
      if (widget.open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Long press toggles the dial too, which is what the package wires up for
    // the button it renders itself.
    return GestureDetector(
      onLongPress: widget.onPressed,
      child: FloatingActionButton(
        // The dial's child buttons carry no hero tag either; a tagged button
        // here would fly across routes while the shelf is being navigated.
        heroTag: null,
        onPressed: widget.onPressed,
        shape: const StadiumBorder(),
        elevation: 6,
        highlightElevation: 6,
        child: AnimatedBuilder(
          animation: _turn,
          builder: (context, child) =>
              Transform.rotate(angle: _turn.value * _morphAngle, child: child),
          child: const Icon(Icons.add_outlined, size: _iconSize),
        ),
      ),
    );
  }
}
