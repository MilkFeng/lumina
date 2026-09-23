import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

/// One badge of the strips the reader keeps along the top and bottom of the
/// page.
///
/// Small, dimmed text: it reports where the reader is without ever pulling
/// attention away from the page itself.
class ReaderStatusBadge extends StatelessWidget {
  const ReaderStatusBadge({
    super.key,
    required this.content,
    this.tabular = false,
    this.overflow = TextOverflow.clip,
  });

  final String content;

  /// Whether the digits get fixed-width columns, so a badge whose value changes
  /// — a page counter, a clock — does not shift sideways as it does.
  final bool tabular;

  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      content,
      overflow: overflow,
      style: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        fontSize: 10,
        fontWeight: FontWeight.w500,
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
        shadows: [
          Shadow(
            color: colorScheme.surface.withValues(alpha: 0.5),
            blurRadius: 1.0,
            offset: Offset.zero,
          ),
        ],
      ),
    );
  }
}

/// The clock and battery the reader draws where the system status bar would
/// have been, while that bar is hidden.
///
/// It keeps its own timer and its own battery reading rather than leaning on
/// the renderer's rebuilds: the renderer drives a WebView, which has no business
/// being rebuilt once a minute for two labels, and the strip is all that
/// changes.
class ReaderStatusBarReadout extends StatefulWidget {
  const ReaderStatusBarReadout({super.key});

  @override
  State<ReaderStatusBarReadout> createState() => _ReaderStatusBarReadoutState();
}

class _ReaderStatusBarReadoutState extends State<ReaderStatusBarReadout>
    with WidgetsBindingObserver {
  final Battery _battery = Battery();

  Timer? _tick;
  DateTime _now = DateTime.now();
  int? _batteryLevel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshBattery());
    _scheduleTick();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    super.dispose();
  }

  /// Refreshes on the way back from a pause: a reader that spent an hour in the
  /// background would otherwise come back to a clock an hour behind, and the
  /// next minute boundary is up to a minute away.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    setState(() => _now = DateTime.now());
    unawaited(_refreshBattery());
  }

  /// Wakes at the next minute boundary rather than a minute from now: the clock
  /// then turns over with the system one instead of up to a minute late.
  void _scheduleTick() {
    _tick?.cancel();
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));
    _tick = Timer(nextMinute.difference(now), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      unawaited(_refreshBattery());
      _scheduleTick();
    });
  }

  /// Re-reads the battery level.
  ///
  /// A platform with no battery to report leaves the readout showing the clock
  /// alone, which is why the level stays null rather than defaulting to a
  /// number.
  Future<void> _refreshBattery() async {
    int? level;
    try {
      level = await _battery.batteryLevel;
    } catch (_) {
      level = null;
    }
    if (!mounted || level == _batteryLevel) return;
    setState(() => _batteryLevel = level);
  }

  /// The time the way the system status bar writes it: `21:41` on a 24-hour
  /// clock, `9:41` on a 12-hour one.
  String _formatTime(DateTime now) {
    final minute = now.minute.toString().padLeft(2, '0');
    if (MediaQuery.alwaysUse24HourFormatOf(context)) {
      return '${now.hour.toString().padLeft(2, '0')}:$minute';
    }
    return '${now.hour % 12 == 0 ? 12 : now.hour % 12}:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final batteryLevel = _batteryLevel;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ReaderStatusBadge(content: _formatTime(_now), tabular: true),
        if (batteryLevel != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BatteryGlyph(level: batteryLevel),
              const SizedBox(width: 4),
              ReaderStatusBadge(content: '$batteryLevel%', tabular: true),
            ],
          ),
      ],
    );
  }
}

/// The battery, drawn as the cell the system status bar draws.
///
/// The charge is the fill, in proportion to the level rather than in steps, so
/// the glyph says as much as the number beside it does.
class _BatteryGlyph extends StatelessWidget {
  const _BatteryGlyph({required this.level});

  /// Charge in percent, 0-100.
  final int level;

  /// Sized to the badges it stands next to: the strip is 24 px of usable
  /// height, and the number is set in 10 px type.
  static const double _width = 21;
  static const double _height = 10;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: _width,
      height: _height,
      child: CustomPaint(
        painter: _BatteryPainter(
          level: level,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          // The shadow the badges carry, at the lightest it can be while still
          // doing its job: the glyph is thin where the text is solid, and its
          // halo starts to swallow it long before theirs does.
          shadowColor: colorScheme.surface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  const _BatteryPainter({
    required this.level,
    required this.color,
    required this.shadowColor,
  });

  final int level;
  final Color color;
  final Color shadowColor;

  static const double _strokeWidth = 1.0;

  /// The terminal on the right of the cell, and the gap that separates it.
  static const double _terminalWidth = 2.0;
  static const double _terminalHeight = 5.0;
  static const double _terminalGap = 1.0;

  /// How far the charge is held off the cell's own outline.
  static const double _chargeInset = 1.5;

  /// The blur of the glyph's own shadow — the floor a [MaskFilter] can be given
  /// without being no blur at all, since `Shadow.blurRadius: 0` is itself a
  /// sigma of 0.5.
  ///
  /// The badge text blurs its shadow with `1.0 * 0.57735 + 0.5`, which a 1 px
  /// outline cannot carry: it spreads over the whole shape and leaves a smudge.
  static const double _shadowSigma = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    // Shadow pass first, under everything: the page's ink runs right up to the
    // strip, and this is what keeps the glyph readable where it does.
    _paintGlyph(
      canvas,
      size,
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _shadowSigma),
    );
    _paintGlyph(canvas, size, Paint()..color = color);
  }

  void _paintGlyph(Canvas canvas, Size size, Paint paint) {
    final cellWidth = size.width - _terminalWidth - _terminalGap;
    final cell = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      cellWidth - _strokeWidth,
      size.height - _strokeWidth,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(cell, const Radius.circular(2.5)),
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth,
    );

    final charge = cell.deflate(_chargeInset);
    final chargedWidth = charge.width * (level.clamp(0, 100) / 100);
    if (chargedWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(charge.left, charge.top, chargedWidth, charge.height),
          const Radius.circular(1),
        ),
        paint..style = PaintingStyle.fill,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cellWidth + _terminalGap,
          (size.height - _terminalHeight) / 2,
          _terminalWidth,
          _terminalHeight,
        ),
        const Radius.circular(1),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BatteryPainter oldDelegate) =>
      oldDelegate.level != level ||
      oldDelegate.color != color ||
      oldDelegate.shadowColor != shadowColor;
}
