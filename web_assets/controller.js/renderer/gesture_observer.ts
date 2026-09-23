import { FrameManager } from './frame_manager';
import { InteractionManager } from './interaction';

/// Recognises the reader's own gestures inside the chapter, in scroll mode.
///
/// Scroll mode hands every pointer sequence to the platform view:
/// `ReaderRenderer` deliberately declares no gesture there, because the framework
/// dispatches a sequence to a platform view only when no member of the gesture
/// arena claims it — and a touch-down arriving while the chapter is still
/// flinging is the only thing that aborts Chromium's momentum scroll.  The
/// consequence is that the page becomes the only place where a tap can be told
/// apart from a scroll, so the reader's taps are recognised here and reported
/// back over the bridge.
///
/// * `click` is the tap signal, and Chromium's own semantics do the work: it
///   dispatches one for a press-and-lift and none once the touch has turned into
///   a scroll, so no movement or duration thresholds are needed.  A tap that
///   lands on a fling therefore both stops it and still counts as a tap.
/// * The default action is always cancelled.  Links, footnotes and plain taps
///   are resolved by `InteractionManager` and reported to Flutter, so an anchor
///   must never navigate the frame.
/// * A long press over an image reports the image viewer's source.  Flutter used
///   to recognise that press with its own long press recogniser, which had to go
///   with the rest of them: a recogniser that claims the arena takes the whole
///   sequence, so a press held past its deadline left the chapter unable to
///   scroll for as long as the finger stayed down.
///
/// The listeners are attached per *document* rather than per slot, because
/// `cycleFrames` swaps the `id`s of the three recycled iframes: an element that
/// used to be `frame-next` becomes `frame-curr` without ever reloading, so its
/// listeners have to keep working and decide from the current `id` whether it is
/// still the frame the reader is looking at.  Same reasoning as `ScrollObserver`.
export class GestureObserver {
  /// How long an image has to be held before the image viewer is opened.
  private static readonly longPressMs = 500;

  /// How far the finger may drift before the press stops counting as a long
  /// press.  A pan cannot start without moving at least this far, so a press
  /// that turns into a scroll never opens the image viewer.
  private static readonly longPressSlopPx = 10;

  private readonly observed = new WeakSet<Document>();

  private longPressTimer: ReturnType<typeof setTimeout> | null = null;
  private longPressFrame: HTMLIFrameElement | null = null;
  private longPressX = 0;
  private longPressY = 0;

  /// Whether the `click` Chromium dispatches when the finger finally lifts
  /// belongs to a long press that already opened the image viewer.
  private isLongPressReported = false;

  constructor(
    private frameMgr: FrameManager,
    private interactionMgr: InteractionManager
  ) { }

  /// Starts observing the gestures of [iframe].
  ///
  /// Calling it again for a frame that is already observed is a no-op.  Does
  /// nothing while paginated: there the frames are inert, every gesture belongs
  /// to Flutter, and a reported tap would arrive twice.
  observe(iframe: HTMLIFrameElement | null): void {
    if (!this.frameMgr.isScrollMode()) return;

    const doc = iframe ? iframe.contentDocument : null;
    if (!iframe || !doc || this.observed.has(doc)) return;

    this.observed.add(doc);

    // Capture phase, so the anchor's default action is cancelled before the
    // dispatch even reaches the target.
    doc.addEventListener('click', (event) => this.onClick(iframe, event), true);
    doc.addEventListener('touchstart', (event) => this.onTouchStart(iframe, event), {
      passive: true,
    });
    doc.addEventListener('touchmove', (event) => this.onTouchMove(event), {
      passive: true,
    });
    doc.addEventListener('touchend', () => this.cancelLongPress(), { passive: true });
    doc.addEventListener('touchcancel', () => this.cancelLongPress(), { passive: true });
  }

  private onClick(iframe: HTMLIFrameElement, event: MouseEvent): void {
    // The listener outlives the slot: only the frame on screen reports.
    if (iframe.id !== 'frame-curr') return;

    // Nothing in the reader navigates natively, whatever the click landed on.
    event.preventDefault();

    if (this.isLongPressReported) {
      // The press already opened the image viewer; lifting the finger is not a
      // tap on top of it.
      this.isLongPressReported = false;
      return;
    }

    // Viewport coordinates, which is what the hit test and the footnote overlay
    // both work in.
    this.interactionMgr.checkTapElementAt(event.clientX, event.clientY);
  }

  private onTouchStart(iframe: HTMLIFrameElement, event: TouchEvent): void {
    this.cancelLongPress();
    // A click can only follow its own press, so the flag cannot leak into a
    // later gesture.
    this.isLongPressReported = false;

    if (iframe.id !== 'frame-curr' || event.touches.length !== 1) return;

    const touch = event.touches[0];
    this.longPressFrame = iframe;
    this.longPressX = touch.clientX;
    this.longPressY = touch.clientY;
    this.longPressTimer = setTimeout(() => {
      this.longPressTimer = null;
      this.reportLongPress();
    }, GestureObserver.longPressMs);
  }

  private onTouchMove(event: TouchEvent): void {
    if (this.longPressTimer === null) return;

    const touch = event.touches[0];
    if (!touch) return;
    if (
      Math.abs(touch.clientX - this.longPressX) > GestureObserver.longPressSlopPx ||
      Math.abs(touch.clientY - this.longPressY) > GestureObserver.longPressSlopPx
    ) {
      this.cancelLongPress();
    }
  }

  /// Reports the image under the held finger, if it is holding one.
  ///
  /// A chapter turn can recycle the frame while the finger is down, in which
  /// case the recorded position no longer belongs to the chapter on screen.
  /// [InteractionManager.checkImageAt] does the reporting itself, and only for
  /// the frame that is current.
  private reportLongPress(): void {
    const iframe = this.longPressFrame;
    this.longPressFrame = null;
    if (!iframe || iframe.id !== 'frame-curr') return;

    if (this.interactionMgr.checkImageAt(this.longPressX, this.longPressY)) {
      this.isLongPressReported = true;
    }
  }

  private cancelLongPress(): void {
    if (this.longPressTimer !== null) {
      clearTimeout(this.longPressTimer);
      this.longPressTimer = null;
    }
    this.longPressFrame = null;
  }
}
