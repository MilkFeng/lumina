import 'package:flutter/gestures.dart';

/// A [TapGestureRecognizer] that claims the tap itself instead of waiting to be
/// handed the arena when it is swept.
///
/// A tap is normally decided by the arena sweep, and the sweep hands the win to
/// the **first** member — the recognizer whose render object was hit-tested
/// deepest.  That order is not always the reader's: the reader lives in a
/// `Scaffold`, and a closed drawer keeps a translucent `GestureDetector` over
/// the leading edge of the body (`DrawerController` builds a full-height strip
/// `_kEdgeDragWidth` wide).  A translucent target that hits nothing still adds
/// itself to the result, so a tap landing in that strip puts the drawer's
/// horizontal drag recognizer into the arena *before* this tap — and the sweep
/// would hand such a tap to the drawer, which does nothing with it.  The reader's
/// left-most tap zone would quietly stop working.
///
/// Resolving the arena on the up event takes the tap back, independently of the
/// order the recognizers joined in.  Drags are unaffected:
/// [PrimaryPointerGestureRecognizer] rejects itself as soon as the pointer moves
/// past [preAcceptSlopTolerance], which leaves the drag to whoever else is
/// competing.
///
/// Paginated mode is the only mode that uses this recognizer.  Scroll mode
/// declares no gesture at all on purpose — a pointer sequence reaches the
/// platform view only when no arena member claims it, and that is what lets a
/// touch-down abort the page's momentum scroll.  See `ReaderRenderer`.
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
      // what keeps the sweep from handing the tap to a recognizer that joined
      // the arena earlier.
      resolve(GestureDisposition.accepted);
    }
    super.handlePrimaryPointer(event);
  }
}
