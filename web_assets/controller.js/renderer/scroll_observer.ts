import { FlutterBridge } from '../api/flutter_bridge';
import { FrameManager } from './frame_manager';
import { PaginationManager } from './pagination';

/// Reports the native scrolling of the current frame back to Flutter.
///
/// In scroll mode the WebView scrolls its own content: the touch gesture is
/// forwarded to the platform view by Flutter, the page's own scroller moves,
/// and Flutter only mirrors the result.  There is deliberately no counterpart
/// command — pushing an offset from Flutter crosses the platform channel once
/// per frame and cannot keep up with a finger.
///
/// The listener is attached per iframe element rather than per slot, because
/// `cycleFrames` swaps the `id`s of the three recycled iframes: an element that
/// used to be `frame-next` becomes `frame-curr` without ever reloading, so its
/// listener has to keep working and decide from the current `id` whether it is
/// still reporting the frame the reader is looking at.
export class ScrollObserver {
  /// Anchor detection walks every anchor in the chapter, so it is throttled
  /// rather than run on every scroll frame.
  private static readonly anchorThrottleMs = 250;

  /// How long the page has to stand still before the scroll counts as settled.
  private static readonly settleDelayMs = 150;

  private readonly observed = new WeakSet<Window>();

  private anchorTimer: ReturnType<typeof setTimeout> | null = null;
  private settleTimer: ReturnType<typeof setTimeout> | null = null;
  private isProgressScheduled = false;

  constructor(
    private frameMgr: FrameManager,
    private paginationMgr: PaginationManager
  ) { }

  /// Starts observing the scrolling of [iframe].
  ///
  /// Calling it again for a frame that is already observed is a no-op.  Does
  /// nothing while paginated: there the page never scrolls itself, so there is
  /// nothing to report and no listener to keep.
  observe(iframe: HTMLIFrameElement | null): void {
    if (!this.frameMgr.isScrollMode()) return;

    const win = iframe ? iframe.contentWindow : null;
    if (!iframe || !win || this.observed.has(win)) return;

    this.observed.add(win);
    // Capture, because the chapter scrolls as an *element* (the chapter body is
    // the scroll container), and a scroll event on an element does not bubble
    // up to the window.  The capture phase still walks down from the window, so
    // this catches both element and document scrolling.
    win.addEventListener('scroll', () => this.onScroll(iframe), {
      passive: true,
      capture: true,
    });
  }

  /// Reports the current position right away, for the moments where the page
  /// moves without the reader scrolling: a frame finishing its load, a theme
  /// change re-laying the chapter out, or a chapter turn.
  report(iframe: HTMLIFrameElement | null = this.frameMgr.getCurrFrame()): void {
    if (!iframe || !this.frameMgr.isScrollMode()) return;
    const position = this.frameMgr.getScrollPosition(iframe);
    FlutterBridge.onScrollProgress(position.offset, position.maxOffset);
  }

  /// Drops the pending anchor and settle timers.
  ///
  /// Called when the reader moves to another chapter: those timers were
  /// scheduled for the frame that is leaving the screen.
  reset(): void {
    if (this.anchorTimer !== null) {
      clearTimeout(this.anchorTimer);
      this.anchorTimer = null;
    }
    if (this.settleTimer !== null) {
      clearTimeout(this.settleTimer);
      this.settleTimer = null;
    }
  }

  private onScroll(iframe: HTMLIFrameElement): void {
    // The listener outlives the slot: only the frame on screen reports.
    if (iframe.id !== 'frame-curr') return;

    this.scheduleProgress(iframe);
    this.scheduleAnchorDetection(iframe);
    this.scheduleSettled();
  }

  /// Coalesces every scroll event of a frame into one report per animation
  /// frame — the page can scroll several times between two of them.
  private scheduleProgress(iframe: HTMLIFrameElement): void {
    if (this.isProgressScheduled) return;
    this.isProgressScheduled = true;

    requestAnimationFrame(() => {
      this.isProgressScheduled = false;
      // A chapter turn can land between the scroll event and this frame; by
      // then the element is no longer the one on screen, and its position
      // belongs to the chapter the reader just left.
      if (iframe.id !== 'frame-curr') return;
      this.report(iframe);
    });
  }

  private scheduleAnchorDetection(iframe: HTMLIFrameElement): void {
    if (this.anchorTimer !== null) return;
    this.anchorTimer = setTimeout(() => {
      this.anchorTimer = null;
      this.paginationMgr.detectActiveAnchor(iframe);
    }, ScrollObserver.anchorThrottleMs);
  }

  /// Fires once the page has come to rest, which is when reading progress is
  /// worth persisting — writing it on every frame would be far too often.
  private scheduleSettled(): void {
    if (this.settleTimer !== null) clearTimeout(this.settleTimer);
    this.settleTimer = setTimeout(() => {
      this.settleTimer = null;
      FlutterBridge.onScrollSettled();
    }, ScrollObserver.settleDelayMs);
  }
}
