import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Drives continuous vertical scrolling of the reader WebView from Flutter.
///
/// In scroll mode the WebView receives no touch input at all: Flutter's
/// [GestureDetector] tracks the finger, this session owns the offset and the
/// physics, and the resulting absolute offset is pushed into the page through
/// `window.api.scrollContentTo`.  That keeps the gesture consistent with the
/// rest of the app and avoids running a drag handler inside the page.
///
/// Two details matter for the scroll to feel like a web page rather than a
/// stutter:
///
/// * **Real physics.** The fling reuses Flutter's own
///   [ScrollPhysics.createBallisticSimulation], so the deceleration curve is
///   the platform's, not a hand-rolled approximation.
/// * **Frame coalescing.** Pushing an offset crosses the platform channel, and
///   that round-trip can outlast a frame.  Rather than queueing every frame's
///   offset — which builds a backlog and makes the content lag behind the
///   finger — the session keeps a single pending offset and drops the
///   intermediate ones.
/// Offset changes smaller than this are not worth a platform-channel
/// round-trip.
const double _offsetEpsilon = 0.01;

class WebViewScrollSession {
  WebViewScrollSession({
    required TickerProvider vsync,
    required Future<void> Function(double offset) onPushOffset,
    this.onOffsetChanged,
    this.onSettled,
  }) : _onPushOffset = onPushOffset {
    _ticker = vsync.createTicker(_onTick);
  }

  final Future<void> Function(double offset) _onPushOffset;

  /// Called on every offset change, including each animation frame.
  final VoidCallback? onOffsetChanged;

  /// Called once the scroll comes to rest, after a drag or a fling.
  ///
  /// This is the point at which reading progress is worth persisting; doing it
  /// per frame would write far too often.
  final VoidCallback? onSettled;

  late final Ticker _ticker;

  double _offset = 0;
  double _contentHeight = 0;
  double _viewportHeight = 0;

  /// Kept in sync from the widget tree; [FixedScrollMetrics] requires it.
  double devicePixelRatio = 1.0;

  Simulation? _simulation;
  bool _isDragging = false;

  double? _pendingOffset;
  bool _isFlushing = false;

  /// Current scroll offset in CSS pixels.
  double get offset => _offset;

  /// Largest reachable offset; `0` when the chapter fits on one screen.
  double get maxExtent => max(0.0, _contentHeight - _viewportHeight);

  /// Height of the visible area, in CSS pixels.
  double get viewportHeight => _viewportHeight;

  /// Fraction of the chapter scrolled past, in `[0, 1]`.
  ///
  /// A chapter that fits on one screen is fully read, hence `1`.
  double get ratio => maxExtent <= 0 ? 1.0 : (_offset / maxExtent).clamp(0, 1);

  bool get isAnimating => _ticker.isActive;

  bool get isDragging => _isDragging;

  // ─── Metrics ───────────────────────────────────────────────────────

  /// Applies the extents reported by the page through `onScrollMetrics`.
  ///
  /// The page's own offset is only adopted while the user is not interacting,
  /// so a report that races a drag or a fling cannot yank the content back.
  void applyMetrics({
    required double contentHeight,
    required double viewportHeight,
    required double offset,
  }) {
    _contentHeight = contentHeight;
    _viewportHeight = viewportHeight;
    if (!_isDragging && !isAnimating) {
      _offset = offset.clamp(0.0, maxExtent);
      onOffsetChanged?.call();
    } else {
      _offset = _offset.clamp(0.0, maxExtent);
    }
  }

  /// Resets the offset to the top, for example after a chapter change.
  void reset() {
    stop();
    _offset = 0;
    _contentHeight = 0;
    _pendingOffset = null;
    onOffsetChanged?.call();
  }

  // ─── Gestures ──────────────────────────────────────────────────────

  void beginDrag() {
    stop();
    _isDragging = true;
  }

  /// Moves the content by [primaryDelta] pixels of finger movement.
  ///
  /// Dragging down (a positive delta) reveals earlier content, so the offset
  /// moves the other way.  The offset is clamped instead of overscrolling —
  /// a chapter is a hard boundary in scroll mode.
  void updateDrag(double primaryDelta) {
    if (!_isDragging) return;
    _setOffset(_offset - primaryDelta);
  }

  void endDrag(double primaryVelocity) {
    if (!_isDragging) return;
    _isDragging = false;
    _fling(-primaryVelocity);
  }

  /// Stops any running fling or animation, leaving the content where it is.
  void stop() {
    if (_ticker.isActive) _ticker.stop();
    _simulation = null;
  }

  // ─── Programmatic scrolling ────────────────────────────────────────

  /// Animates the offset by [delta] pixels with a short eased curve.
  ///
  /// Used by the volume keys, which move by roughly one viewport.
  void animateBy(double delta) {
    final target = (_offset + delta).clamp(0.0, maxExtent);
    if ((target - _offset).abs() < _offsetEpsilon) return;
    _start(
      _EasedSimulation(
        start: _offset,
        end: target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _fling(double velocity) {
    final physics = Platform.isIOS
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    final simulation = physics.createBallisticSimulation(
      FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: maxExtent,
        pixels: _offset,
        viewportDimension: _viewportHeight,
        axisDirection: AxisDirection.down,
        devicePixelRatio: devicePixelRatio,
      ),
      velocity,
    );
    if (simulation == null) {
      onSettled?.call();
      return;
    }
    _start(simulation);
  }

  void _start(Simulation simulation) {
    stop();
    _simulation = simulation;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final simulation = _simulation;
    if (simulation == null) {
      stop();
      return;
    }
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final value = simulation.x(seconds);
    _setOffset(value);

    // Stop as soon as the simulation is done, or as soon as it has run into a
    // boundary — an iOS bouncing simulation would otherwise keep ticking
    // through an overscroll the page never shows.
    final atBoundary =
        (value <= 0 && simulation.dx(seconds) < 0) ||
        (value >= maxExtent && simulation.dx(seconds) > 0);
    if (simulation.isDone(seconds) || atBoundary) {
      stop();
      onSettled?.call();
    }
  }

  // ─── Pushing to the page ───────────────────────────────────────────

  void _setOffset(double value) {
    final clamped = value.clamp(0.0, maxExtent);
    if ((clamped - _offset).abs() < _offsetEpsilon) return;
    _offset = clamped;
    onOffsetChanged?.call();
    _schedulePush(clamped);
  }

  /// Pushes [value] to the page, coalescing with any push already in flight.
  void _schedulePush(double value) {
    _pendingOffset = value;
    if (_isFlushing) return;
    _isFlushing = true;
    unawaited(_flush());
  }

  Future<void> _flush() async {
    while (_pendingOffset != null) {
      final value = _pendingOffset!;
      _pendingOffset = null;
      await _onPushOffset(value);
    }
    _isFlushing = false;
  }

  void dispose() {
    _ticker.dispose();
  }
}

/// A fixed-duration eased interpolation, expressed as a [Simulation] so it can
/// share the session's ticker loop with the ballistic ones.
class _EasedSimulation extends Simulation {
  _EasedSimulation({
    required this.start,
    required this.end,
    required this.duration,
    required this.curve,
  });

  final double start;
  final double end;
  final Duration duration;
  final Curve curve;

  double get _seconds => duration.inMicroseconds / Duration.microsecondsPerSecond;

  @override
  double x(double time) {
    final t = (time / _seconds).clamp(0.0, 1.0);
    return start + (end - start) * curve.transform(t);
  }

  @override
  double dx(double time) {
    const epsilon = 0.001;
    return (x(time + epsilon) - x(time)) / epsilon;
  }

  @override
  bool isDone(double time) => time >= _seconds;
}
