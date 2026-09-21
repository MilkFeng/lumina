import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/src/features/reader/presentation/gestures/eager_tap_gesture_recognizer.dart';

/// Reproduces the arena behaviour of a platform view: a recognizer that is
/// hit-tested below the Flutter widgets wrapping it and never resolves anything
/// by itself — which is how `_PlatformViewGestureRecognizer`, the captain of a
/// platform view's team, behaves.
class _NeverResolvingRecognizer extends OneSequenceGestureRecognizer {
  bool won = false;

  @override
  void handleEvent(PointerEvent event) {}

  @override
  void acceptGesture(int pointer) {
    won = true;
  }

  @override
  void rejectGesture(int pointer) {}

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'never resolving';
}

Widget _host({
  required Widget Function(Widget child) detector,
  required _NeverResolvingRecognizer competitor,
}) {
  return MaterialApp(
    home: Scaffold(
      body: detector(
        // Deeper than the detector, so its recognizer joins the arena first.
        RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: <Type, GestureRecognizerFactory>{
            _NeverResolvingRecognizer:
                GestureRecognizerFactoryWithHandlers<_NeverResolvingRecognizer>(
                  () => competitor,
                  (instance) {},
                ),
          },
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

Widget _eagerTapDetector(Widget child, VoidCallback onTapUp) {
  return RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    gestures: <Type, GestureRecognizerFactory>{
      EagerTapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<EagerTapGestureRecognizer>(
            () => EagerTapGestureRecognizer(),
            (instance) => instance.onTapUp = (_) => onTapUp(),
          ),
    },
    child: child,
  );
}

void main() {
  testWidgets('a plain GestureDetector loses the tap to the platform view', (
    tester,
  ) async {
    // Pins the reason `EagerTapGestureRecognizer` exists: this is what the
    // reader did before, and it is why taps stopped reaching Flutter once the
    // WebView had to stay in the hit test path for scroll mode.
    final competitor = _NeverResolvingRecognizer();
    var taps = 0;

    await tester.pumpWidget(
      _host(
        competitor: competitor,
        detector: (child) =>
            GestureDetector(onTapUp: (_) => taps++, child: child),
      ),
    );

    await tester.tapAt(const Offset(400, 300));
    await tester.pump();

    expect(taps, 0, reason: 'the sweep handed the tap to the platform view');
    expect(competitor.won, isTrue);
  });

  testWidgets('EagerTapGestureRecognizer claims the tap instead', (
    tester,
  ) async {
    final competitor = _NeverResolvingRecognizer();
    var taps = 0;

    await tester.pumpWidget(
      _host(
        competitor: competitor,
        detector: (child) => _eagerTapDetector(child, () => taps++),
      ),
    );

    await tester.tapAt(const Offset(400, 300));
    await tester.pump();

    expect(taps, 1);
    expect(competitor.won, isFalse, reason: 'the tap never reached the page');
  });

  testWidgets('a drag past the slop still goes to the platform view', (
    tester,
  ) async {
    // Scroll mode depends on this: the drag has to reach the WebView, which is
    // what makes the chapter scroll natively.
    final competitor = _NeverResolvingRecognizer();
    var taps = 0;

    await tester.pumpWidget(
      _host(
        competitor: competitor,
        detector: (child) => _eagerTapDetector(child, () => taps++),
      ),
    );

    final gesture = await tester.startGesture(const Offset(400, 300));
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(taps, 0);
    expect(competitor.won, isTrue);
  });
}
