import 'package:flutter/gestures.dart';

/// A [TapGestureRecognizer] that claims the tap itself instead of waiting to be
/// handed the arena when it is swept.
///
/// A tap is normally decided by the arena sweep: a tap recognizer resolves
/// nothing while the pointer is down, so when the pointer goes up the arena is
/// swept and its *first* member wins.  A platform view competes as a team with a
/// captain, and a team with a captain takes the sweep — the captain never claims
/// anything by itself, and the platform view is hit-tested below every Flutter
/// widget wrapping it, which makes its team the first member.  Over a WebView
/// that has to stay in the hit test path (scroll mode, where the page scrolls
/// itself), a plain [TapGestureRecognizer] therefore never sees a tap: the tap
/// is forwarded to the page instead, and taps stop reaching Flutter altogether.
///
/// Resolving the arena on the up event takes the tap back, because the sweep
/// only runs once the whole event has been routed.  Drags are unaffected:
/// [PrimaryPointerGestureRecognizer] rejects itself as soon as the pointer moves
/// past [preAcceptSlopTolerance], which leaves the drag to the platform view.
class EagerTapGestureRecognizer extends TapGestureRecognizer {
  EagerTapGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
    super.allowedButtonsFilter,
    super.preAcceptSlopTolerance,
    super.postAcceptSlopTolerance,
  });

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      // Win the arena now, while the pointer is still being routed: this is
      // what keeps the platform view's team captain from taking the sweep.
      resolve(GestureDisposition.accepted);
    }
    super.handlePrimaryPointer(event);
  }
}
