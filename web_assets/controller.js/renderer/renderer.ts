import {
  type FrameSlot,
  type ReaderState,
  type ThemeUpdate,
  type Direction,
  WhiteColor,
  BlackColor,
  InitConfig
} from '../common/types';
import { LuminaApi } from '../api/lumina_api';
import { FlutterBridge } from '../api/flutter_bridge';
import { applyTyp } from '../typ/typ';
import { FrameManager } from './frame_manager';
import { PaginationManager } from './pagination';
import { ScrollObserver } from './scroll_observer';
import { GestureObserver } from './gesture_observer';
import { InteractionManager } from './interaction';
import { ThemeManager } from './theme_manager';
import { CssPolyfillManager } from './css_polyfill';
import { ResourceManager } from './resource_manager';

/// A viewport scroll that is still animating.
///
/// One at a time: `scrollByViewport` lands whatever it finds before it starts
/// its own, so the reader never has two screenfuls moving at once.
interface ViewportScroll {
  token: number;
  iframe: HTMLIFrameElement;
  doc: Document;
  body: HTMLElement;
  from: number;
  to: number;
  startedAt: number;
  frameId: number;
  /// Detaches the guard that lets a finger take the scroll back.
  onTouchStart: () => void;
}

export class Renderer implements LuminaApi {
  /// How much of the previous screenful stays visible when the volume keys
  /// scroll by a whole viewport.
  private static readonly viewportOverlap = 48;

  /// How long a viewport scroll takes.
  ///
  /// Long enough for the eye to follow the text, short enough that a second
  /// press does not feel like waiting for the first one.
  private static readonly scrollTurnDurationMs = 300;

  private state: ReaderState;

  private frameMgr: FrameManager;
  private paginationMgr: PaginationManager;
  private scrollObserver: ScrollObserver;
  private gestureObserver: GestureObserver;
  private interactionMgr: InteractionManager;
  private themeMgr: ThemeManager;
  private polyfillMgr: CssPolyfillManager;
  private resourceMgr: ResourceManager;

  private resizeDebounceTimer: ReturnType<typeof setTimeout> | null;
  private onResize: (ev: UIEvent) => void;
  private currentSize: { width: number; height: number } = { width: 0, height: 0 };

  /// Position each frame should start at, as handed over by `loadFrame` and
  /// consumed by `onFrameLoad`.
  private initialScrollRatios: Record<FrameSlot, number | null> = {
    prev: null,
    curr: null,
    next: null,
  };

  /// The viewport scroll in flight, if any.  See `scrollByViewport`.
  private viewportScroll: ViewportScroll | null = null;

  constructor() {
    this.state = {
      anchors: { prev: [], curr: [], next: [] },
      properties: { prev: [], curr: [], next: [] },
      quadTree: null,
      config: {
        safeWidth: 0,
        safeHeight: 0,
        direction: 0,
        scrollMode: false,
        padding: { top: 0, left: 0 },
        theme: {
          zoom: 1.0,
          surfaceColor: WhiteColor,
          onSurfaceColor: BlackColor,
          shouldOverrideTextColor: true,
          primaryColor: BlackColor,
          primaryContainerColor: BlackColor,
          onSurfaceVariantColor: BlackColor,
          outlineVariantColor: BlackColor,
          surfaceContainerColor: BlackColor,
          surfaceContainerHighColor: BlackColor,
          fontFileName: null,
          overrideFontFamily: false,
          lineHeight: null
        },
        paginationCss: '',
      },
    };

    this.frameMgr = new FrameManager(this.state);
    this.paginationMgr = new PaginationManager(this.state, this.frameMgr);
    this.scrollObserver = new ScrollObserver(this.frameMgr, this.paginationMgr);
    this.interactionMgr = new InteractionManager(this.state, this.frameMgr);
    this.gestureObserver = new GestureObserver(this.frameMgr, this.interactionMgr);
    this.themeMgr = new ThemeManager(this.state, this.frameMgr);
    this.polyfillMgr = new CssPolyfillManager(this.state, this.themeMgr, this.frameMgr);
    this.resourceMgr = new ResourceManager(this.state);

    this.resizeDebounceTimer = null;
    this.onResize = (ev: UIEvent) => {
      const newWidth = window.innerWidth;
      const newHeight = window.innerHeight;
      if (this.currentSize.width === 0 && this.currentSize.height === 0) {
        this.currentSize = { width: newWidth, height: newHeight };
      } else if (this.currentSize.width !== newWidth || this.currentSize.height !== newHeight) {
        this.currentSize = { width: newWidth, height: newHeight };
        if (this.resizeDebounceTimer) {
          clearTimeout(this.resizeDebounceTimer);
        }
        this.resizeDebounceTimer = setTimeout(() => {
          FlutterBridge.onViewportResize();
        }, 120);
      }
    };
  }

  init(config: InitConfig): void {
    this.state.config = config;
    this.state.config.safeHeight = Math.floor(this.state.config.safeHeight);
    this.state.config.safeWidth = Math.floor(this.state.config.safeWidth);
    this.state.config.scrollMode = this.state.config.scrollMode === true;

    this.themeMgr.updateCSSVariables(document, 'skeleton-variable-style');
    this.syncSkeletonMode();
    window.removeEventListener('resize', this.onResize);
    window.addEventListener('resize', this.onResize, { passive: true });
  }

  /// Mirrors the layout mode onto the skeleton document.
  ///
  /// In scroll mode the current frame has to accept pointer events, because it
  /// is the frame that scrolls itself; while paginated it stays inert and every
  /// gesture is Flutter's.  See the `iframe` rules in `skeleton.css`.
  private syncSkeletonMode(): void {
    document.body.classList.toggle('lumina-scroll-mode', this.frameMgr.isScrollMode());
  }

  loadFrame(
    token: number,
    slot: FrameSlot,
    url: string,
    anchors?: string[],
    properties?: string[],
    initialScrollRatio?: number | null
  ): void {
    const iframe = this.frameMgr.getFrame(slot);
    if (!iframe) return;

    this.state.anchors[slot] = anchors || [];
    this.state.properties[slot] = properties || [];
    this.initialScrollRatios[slot] = (typeof initialScrollRatio === 'number' && isFinite(initialScrollRatio))
      ? initialScrollRatio
      : null;
    iframe.onload = null;

    if (iframe.src == null || iframe.src === '' || iframe.src === 'about:blank') {
      iframe.onload = () => { this.onFrameLoad(iframe, token); };
      iframe.src = url;
    } else {
      const currentUrl = new URL(iframe.src);
      const newUrl = new URL(url);
      if (currentUrl.origin === newUrl.origin && currentUrl.pathname === newUrl.pathname) {
        iframe.onload = () => { this.onFrameLoad(iframe, token); };
        iframe.src = url;
        this.onFrameLoad(iframe, token);
      } else {
        iframe.onload = () => { this.onFrameLoad(iframe, token); };
        iframe.src = url;
      }
    }
  }

  jumpToPage(token: number, pageIndex: number): void {
    const iframe = this.frameMgr.getFrame('curr');
    if (!iframe || !iframe.contentWindow) return;

    const scrollOffset = this.paginationMgr.calculateScrollOffset(pageIndex);
    this.frameMgr.scrollTo(iframe, scrollOffset);

    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        FlutterBridge.onPageChanged(pageIndex);
        this.paginationMgr.detectActiveAnchor(iframe);
        FlutterBridge.onEventFinished(token);
      });
    });
  }

  jumpToPageFor(token: number, slot: FrameSlot, pageIndex: number): void {
    const iframe = this.frameMgr.getFrame(slot);
    if (!iframe || !iframe.contentWindow) return;

    const scrollOffset = this.paginationMgr.calculateScrollOffset(pageIndex);
    this.frameMgr.scrollTo(iframe, scrollOffset);

    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        if (iframe.id === 'frame-curr') {
          FlutterBridge.onPageChanged(pageIndex);
        }
        this.paginationMgr.detectActiveAnchor(iframe);
        FlutterBridge.onEventFinished(token);
      });
    });
  }

  jumpToLastPageOfFrame(token: number, slot: FrameSlot): void {
    const iframe = this.frameMgr.getFrame(slot);
    if (!iframe || !iframe.contentWindow) return;
    const pageCount = this.paginationMgr.calculatePageCount(iframe);
    this.jumpToPageFor(token, slot, pageCount - 1);
  }

  /// Scrolls the current frame by roughly one screenful, in scroll mode.
  ///
  /// This is the one deliberate exception to "the page scrolls itself": a turn
  /// started from Flutter — the volume keys, the control panel arrows, a tap in
  /// the outer third of the page — has no gesture of its own behind it.  It
  /// stays a single call per turn: nothing is pushed from Flutter per frame.
  ///
  /// The screenful is animated here rather than by
  /// `scrollBy({ behavior: 'smooth' })` because Flutter drives turns by press:
  /// it has to know when a turn has *landed*, and a turn that the next press
  /// interrupts has to be landable on its target.  `token` resolves at that
  /// point, and the position the frame landed on is reported just before it.
  scrollByViewport(token: number, direction: Direction): void {
    // One screenful at a time: a turn that is still animating is landed on its
    // target before this one starts, so a press never races the press before
    // it.
    this.finishScrollByViewport();

    const iframe = this.frameMgr.getFrame('curr');
    const doc = iframe && iframe.contentDocument ? iframe.contentDocument : null;
    const body = doc ? doc.body : null;
    if (!iframe || !doc || !body) {
      FlutterBridge.onEventFinished(token);
      return;
    }

    const position = this.frameMgr.getScrollPosition(iframe);
    // A small overlap keeps the line that was at the edge visible.
    const step = Math.max(0, body.clientHeight - Renderer.viewportOverlap);
    const delta = direction === 'next' ? step : -step;
    const to = Math.max(0, Math.min(position.maxOffset, position.offset + delta));

    // The chapter has nothing left to scroll that way.  What the turn means
    // then — the chapter beyond this one — is Flutter's to decide, so the turn
    // simply reports the position it is already at.
    if (to === position.offset) {
      this.scrollObserver.report(iframe);
      FlutterBridge.onEventFinished(token);
      return;
    }

    const animation: ViewportScroll = {
      token,
      iframe,
      doc,
      body,
      from: position.offset,
      to,
      startedAt: performance.now(),
      frameId: 0,
      onTouchStart: () => this.abortViewportScroll(),
    };

    // A finger on the page takes the scroll back, the same way a touch cancels
    // the browser's own smooth scrolling.  Without this the animation would
    // keep writing `scrollTop` over the reader's drag.
    doc.addEventListener('touchstart', animation.onTouchStart, { passive: true });

    this.viewportScroll = animation;
    animation.frameId = requestAnimationFrame(() => this.stepViewportScroll());
  }

  /// Lands the viewport scroll that is animating, if any, on its target.
  ///
  /// This is what the turn after an interrupted one does first: the reader has
  /// asked to move on, so the screenful in flight finishes instead of being
  /// abandoned halfway, and the token it was started with resolves.
  finishScrollByViewport(): void {
    const animation = this.viewportScroll;
    if (!animation) return;
    this.endViewportScroll(animation, animation.to);
  }

  /// Advances the viewport scroll that is animating.
  private stepViewportScroll(): void {
    const animation = this.viewportScroll;
    if (!animation) return;

    const elapsed = performance.now() - animation.startedAt;
    const progress = Math.min(1, elapsed / Renderer.scrollTurnDurationMs);
    if (progress >= 1) {
      this.endViewportScroll(animation, animation.to);
      return;
    }

    // Ease-out cubic: the screenful sets off at speed and settles onto its
    // target, which is what makes it read as a page turn rather than a jump.
    const eased = 1 - Math.pow(1 - progress, 3);
    animation.body.scrollTop = animation.from + (animation.to - animation.from) * eased;
    animation.frameId = requestAnimationFrame(() => this.stepViewportScroll());
  }

  /// Gives the scroll back to the finger that just touched the page.
  private abortViewportScroll(): void {
    const animation = this.viewportScroll;
    if (!animation) return;
    this.endViewportScroll(animation, null);
  }

  /// Ends [animation], optionally at [offset], and releases what it holds.
  ///
  /// The position is reported *before* the token: the `scroll` event a
  /// programmatic move produces only reaches `ScrollObserver` on a later frame,
  /// and Flutter decides what the next turn means — a screenful on, or the
  /// chapter beyond this one — the moment this turn's token resolves.
  private endViewportScroll(animation: ViewportScroll, offset: number | null): void {
    if (this.viewportScroll === animation) this.viewportScroll = null;

    cancelAnimationFrame(animation.frameId);
    animation.doc.removeEventListener('touchstart', animation.onTouchStart);

    if (offset !== null) animation.body.scrollTop = offset;

    this.scrollObserver.report(animation.iframe);
    FlutterBridge.onEventFinished(animation.token);
  }

  /// Applies [ratio] to [iframe] and returns the page index it lands on.
  ///
  /// [ratio] is a fraction of the scrollable length in scroll mode and of the
  /// page count while paginated.  Only used while a frame loads or re-lays
  /// out, never on a gesture.
  private applyPositionRatio(iframe: HTMLIFrameElement, ratio: number): number {
    if (!this.frameMgr.isScrollMode()) {
      const pageCount = this.paginationMgr.calculatePageCount(iframe);
      const pageIndex = Math.round(ratio * pageCount);
      this.frameMgr.scrollTo(iframe, this.paginationMgr.calculateScrollOffset(pageIndex));
      return pageIndex;
    }

    const position = this.frameMgr.getScrollPosition(iframe);
    this.applyScrollOffset(iframe, ratio * position.maxOffset);
    return 0;
  }

  /// Clamps [offset] into the scrollable range of [iframe] and applies it.
  private applyScrollOffset(iframe: HTMLIFrameElement, offset: number): void {
    const body = iframe.contentDocument && iframe.contentDocument.body;
    if (!body) return;
    const maxOffset = Math.max(0, body.scrollHeight - body.clientHeight);
    body.scrollTop = Math.max(0, Math.min(maxOffset, offset));
  }

  /// Takes the starting position `loadFrame` carried for [iframe], if any.
  ///
  /// Restoring a reading position travels with the frame load instead of
  /// following it as a separate scroll call.
  private takeInitialScrollRatio(iframe: HTMLIFrameElement): number | null {
    const slot = this.frameMgr.getSlotFromElement(iframe);
    const ratio = this.initialScrollRatios[slot];
    this.initialScrollRatios[slot] = null;
    return ratio;
  }

  cycleFrames(token: number, direction: Direction): void {
    // The screenful that is scrolling on screen belongs to the chapter that is
    // about to leave it: it is dropped where it is, and its turn is resolved so
    // that whoever started it is not left waiting.
    this.abortViewportScroll();

    const res = this.frameMgr.cycleFramesDOMAndState(direction);
    // Timers scheduled by the frame that is leaving the screen would report its
    // position as if it belonged to the chapter being turned to.
    this.scrollObserver.reset();
    if (!res) {
      FlutterBridge.onEventFinished(token);
    }

    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.paginationMgr.updatePageState('frame-curr');
        this.paginationMgr.updatePageState('frame-prev');
        this.paginationMgr.updatePageState('frame-next');
        this.paginationMgr.detectActiveAnchor(res!.elPrev);
        this.paginationMgr.detectActiveAnchor(res!.elCurr);
        this.paginationMgr.detectActiveAnchor(res!.elNext);
        this.interactionMgr.buildInteractionMap().then(() => {
          this.scrollObserver.report(this.frameMgr.getCurrFrame());
          FlutterBridge.onEventFinished(token);
        });
      });
    });
  }

  checkTapElementAt(x: number, y: number): void {
    this.interactionMgr.checkTapElementAt(x, y);
  }
  checkLongPressElementAt(x: number, y: number): void {
    this.interactionMgr.checkLongPressElementAt(x, y);
  }

  updateTheme(token: number, viewWidth: number, viewHeight: number, newTheme: ThemeUpdate): void {
    this.themeMgr.updateThemeState(viewWidth, viewHeight, newTheme);
    this.themeMgr.updateCSSVariables(document, 'skeleton-variable-style');
    this.syncSkeletonMode();

    // In scroll mode the position within the chapter is a scroll ratio rather
    // than a page index, and it is only meaningful for the current frame.
    const scrollRatio = this.currentScrollRatio();

    const iframes = document.getElementsByTagName('iframe');
    for (let i = 0; i < iframes.length; i++) {
      const iframe = iframes[i];
      if (iframe && iframe.contentDocument) {
        const doc = iframe.contentDocument;
        let positionRatio: number;
        if (this.frameMgr.isScrollMode()) {
          positionRatio = iframe.id === 'frame-curr' ? scrollRatio : 0;
        } else {
          const pageIndex = this.paginationMgr.calculateCurrentPageIndex();
          const pageCount = this.paginationMgr.calculatePageCount(iframe);
          positionRatio = pageCount > 0 ? pageIndex / pageCount : 0;
        }
        this.themeMgr.updateCSSVariables(doc, 'injected-variable-style', iframe);
        requestAnimationFrame(() => {
          this.reloadFrame(iframe, positionRatio, token);
        });
      }
    }
  }

  /// How far the current frame is scrolled through its chapter, in [0,1].
  private currentScrollRatio(): number {
    const iframe = this.frameMgr.getFrame('curr');
    if (!iframe) return 0;
    const position = this.frameMgr.getScrollPosition(iframe);
    return position.maxOffset > 0 ? position.offset / position.maxOffset : 0;
  }

  waitForRender(token: number): void {
    requestAnimationFrame(function () {
      requestAnimationFrame(function () {
        FlutterBridge.onEventFinished(token);
      });
    });
  }

  private onFrameLoad(iframe: HTMLIFrameElement, token: number): void {
    if (!iframe || !iframe.contentDocument) return;

    const doc = iframe.contentDocument;
    this.themeMgr.injectInitialStyles(doc, iframe);
    // The window is recreated by every navigation, so the scroll listener has
    // to be re-attached per load.  The gesture listeners go with it: a frame
    // that reloads gets a fresh document.
    this.scrollObserver.observe(iframe);
    this.gestureObserver.observe(iframe);

    this.resourceMgr.waitForAllResources(doc).then(() => {
      if (!iframe.contentWindow) return;
      requestAnimationFrame(() => {
        const shouldOverrideColor = this.state.config.theme.shouldOverrideTextColor
          && !this.themeMgr.haveBackground(iframe);
        doc.body.classList.toggle('lumina-apply-line-height', this.state.config.theme.lineHeight !== null);
        doc.body.classList.toggle('lumina-override-color', shouldOverrideColor);
        doc.body.classList.toggle(
          'lumina-force-override-font',
          !!(this.state.config.theme.overrideFontFamily && this.state.config.theme.fontFileName)
        );
        doc.body.classList.toggle('lumina-override-font', !!(this.state.config.theme.fontFileName));
        doc.body.classList.toggle('lumina-is-vertical', this.frameMgr.isVertical());
        doc.body.classList.toggle('lumina-is-scroll', this.frameMgr.isScrollMode());

        const properties = this.state.properties[this.frameMgr.getSlotFromElement(iframe)] || [];
        for (const prop of properties) {
          doc.body.classList.toggle('lumina-spine-property-' + prop, true);
        }
        applyTyp(iframe);

        const reflow = doc.body.scrollHeight; void reflow;
        requestAnimationFrame(() => {
          this.polyfillMgr.polyfillCss(iframe);

          requestAnimationFrame(() => {
            const reflow = doc.body.scrollHeight; void reflow;
            requestAnimationFrame(() => {
              const reflow = doc.body.scrollHeight; void reflow;
              const pageCount = this.paginationMgr.calculatePageCount(iframe);

              let pageIndex = 0;
              const url = iframe.src;
              const initialRatio = this.takeInitialScrollRatio(iframe);
              // `top` is the reader's own default anchor, not a position inside
              // the chapter — every frame URL carries it.  Treating it as a real
              // anchor would scroll the frame to its beginning and quietly throw
              // away the reading position that came with the load.
              const fragment = url && url.includes('#') ? url.split('#')[1] : '';
              const anchor = fragment && fragment !== 'top' ? fragment : '';
              if (anchor) {
                if (this.frameMgr.isScrollMode()) {
                  // There are no pages to index into: scroll straight to the
                  // anchor's pixel offset instead.
                  this.applyScrollOffset(
                    iframe,
                    this.paginationMgr.calculateAnchorOffset(iframe, anchor)
                  );
                } else {
                  pageIndex = this.paginationMgr.calculatePageIndexOfAnchor(iframe, anchor);
                  this.frameMgr.scrollTo(iframe, this.paginationMgr.calculateScrollOffset(pageIndex));
                }
              } else if (initialRatio !== null) {
                // The reading position travelled with `loadFrame`, so the frame
                // comes up already scrolled instead of being moved afterwards.
                pageIndex = this.applyPositionRatio(iframe, initialRatio);
              }

              requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                  this.interactionMgr.buildInteractionMap().then(() => {
                    if (iframe.id === 'frame-curr') {
                      FlutterBridge.onPageCountReady(pageCount);
                      FlutterBridge.onPageChanged(pageIndex);
                      this.scrollObserver.report(iframe);
                    } else if (iframe.id === 'frame-prev') {
                      this.jumpToLastPageOfFrame(-1, 'prev');
                    } else if (iframe.id === 'frame-next') {
                      this.jumpToPageFor(-1, 'next', 0);
                    }
                    this.paginationMgr.detectActiveAnchor(iframe);
                    requestAnimationFrame(() => {
                      FlutterBridge.onEventFinished(token);
                    });
                  });
                });
              });
            });
          });
        });
      });
    });
  }

  /// Re-lays-out [iframe] after a theme change and restores its position.
  /// [positionRatio] is a page-index ratio when paginated and a scroll ratio
  /// in scroll mode.
  private reloadFrame(iframe: HTMLIFrameElement, positionRatio: number, token: number): void {
    if (!iframe || !iframe.contentDocument || !iframe.contentWindow) return;

    this.scrollObserver.observe(iframe);
    this.gestureObserver.observe(iframe);

    this.resourceMgr.waitForAllResources(iframe.contentDocument).then(() => {
      const doc = iframe.contentDocument!;
      this.polyfillMgr.polyfillCss(iframe);

      const reflow = doc.body.scrollHeight; void reflow;

      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          const pageCount = this.paginationMgr.calculatePageCount(iframe);
          const pageIndex = this.applyPositionRatio(iframe, positionRatio);

          requestAnimationFrame(() => {
            requestAnimationFrame(() => {
              this.interactionMgr.buildInteractionMap().then(() => {
                if (iframe.id === 'frame-curr') {
                  FlutterBridge.onPageCountReady(pageCount);
                  FlutterBridge.onPageChanged(pageIndex);
                  this.scrollObserver.report(iframe);
                } else if (iframe.id === 'frame-prev') {
                  this.jumpToLastPageOfFrame(-1, 'prev');
                } else if (iframe.id === 'frame-next') {
                  this.jumpToPageFor(-1, 'next', 0);
                }
                this.paginationMgr.detectActiveAnchor(iframe);

                requestAnimationFrame(() => {
                  FlutterBridge.onEventFinished(token);
                });
              });
            });
          });
        });
      });
    });
  }
}
