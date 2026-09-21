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
import { InteractionManager } from './interaction';
import { ThemeManager } from './theme_manager';
import { CssPolyfillManager } from './css_polyfill';
import { ResourceManager } from './resource_manager';

export class Renderer implements LuminaApi {
  private state: ReaderState;

  private frameMgr: FrameManager;
  private paginationMgr: PaginationManager;
  private interactionMgr: InteractionManager;
  private themeMgr: ThemeManager;
  private polyfillMgr: CssPolyfillManager;
  private resourceMgr: ResourceManager;

  private resizeDebounceTimer: ReturnType<typeof setTimeout> | null;
  private anchorDetectionTimer: ReturnType<typeof setTimeout> | null = null;
  private onResize: (ev: UIEvent) => void;
  private currentSize: { width: number; height: number } = { width: 0, height: 0 };

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
    this.interactionMgr = new InteractionManager(this.state, this.frameMgr);
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
    window.removeEventListener('resize', this.onResize);
    window.addEventListener('resize', this.onResize, { passive: true });
  }

  loadFrame(token: number, slot: FrameSlot, url: string, anchors?: string[], properties?: string[]): void {
    const iframe = this.frameMgr.getFrame(slot);
    if (!iframe) return;

    this.state.anchors[slot] = anchors || [];
    this.state.properties[slot] = properties || [];
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

  restoreScrollPosition(token: number, ratio: number): void {
    const iframe = this.frameMgr.getFrame('curr');
    if (!iframe || !iframe.contentWindow) return;

    if (this.frameMgr.isScrollMode()) {
      const metrics = this.frameMgr.getScrollMetrics(iframe);
      const maxOffset = Math.max(0, metrics.contentHeight - metrics.viewportHeight);
      this.applyScrollOffset(iframe, ratio * maxOffset);
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          this.paginationMgr.detectActiveAnchor(iframe);
          this.reportScrollMetrics();
          FlutterBridge.onEventFinished(token);
        });
      });
      return;
    }

    const pageCount = this.paginationMgr.calculatePageCount(iframe);
    const pageIndex = Math.round(ratio * pageCount);
    this.jumpToPage(token, pageIndex);
  }

  scrollContentTo(offset: number): void {
    const iframe = this.frameMgr.getFrame('curr');
    if (!iframe || !iframe.contentWindow) return;
    this.applyScrollOffset(iframe, offset);
    this.scheduleAnchorDetection(iframe);
  }

  requestScrollMetrics(): void {
    this.reportScrollMetrics();
  }

  /// Clamps [offset] into the scrollable range of [iframe] and applies it.
  private applyScrollOffset(iframe: HTMLIFrameElement, offset: number): void {
    const body = iframe.contentDocument && iframe.contentDocument.body;
    if (!body) return;
    const maxOffset = Math.max(0, body.scrollHeight - body.clientHeight);
    body.scrollTop = Math.max(0, Math.min(maxOffset, offset));
  }

  /// Reports the current frame's scroll extents so Flutter — which owns the
  /// gesture and the physics in scroll mode — knows how far it may scroll.
  private reportScrollMetrics(): void {
    const iframe = this.frameMgr.getFrame('curr');
    if (!iframe) return;
    const metrics = this.frameMgr.getScrollMetrics(iframe);
    FlutterBridge.onScrollMetrics(
      metrics.contentHeight,
      metrics.viewportHeight,
      metrics.offset
    );
  }

  /// Active-anchor detection walks every anchor in the chapter, so it is
  /// throttled rather than run on every scroll frame pushed from Flutter.
  private scheduleAnchorDetection(iframe: HTMLIFrameElement): void {
    if (this.anchorDetectionTimer !== null) return;
    this.anchorDetectionTimer = setTimeout(() => {
      this.anchorDetectionTimer = null;
      this.paginationMgr.detectActiveAnchor(iframe);
    }, 250);
  }

  cycleFrames(token: number, direction: Direction): void {
    const res = this.frameMgr.cycleFramesDOMAndState(direction);
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
          this.reportScrollMetrics();
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
    const metrics = this.frameMgr.getScrollMetrics(iframe);
    const maxOffset = Math.max(0, metrics.contentHeight - metrics.viewportHeight);
    return maxOffset > 0 ? metrics.offset / maxOffset : 0;
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
              if (url && url.includes('#')) {
                const anchor = url.split('#')[1];
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
              }

              requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                  this.interactionMgr.buildInteractionMap().then(() => {
                    if (iframe.id === 'frame-curr') {
                      FlutterBridge.onPageCountReady(pageCount);
                      FlutterBridge.onPageChanged(pageIndex);
                      this.reportScrollMetrics();
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

    this.resourceMgr.waitForAllResources(iframe.contentDocument).then(() => {
      const doc = iframe.contentDocument!;
      this.polyfillMgr.polyfillCss(iframe);

      const reflow = doc.body.scrollHeight; void reflow;

      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          const pageCount = this.paginationMgr.calculatePageCount(iframe);

          let pageIndex = 0;
          if (this.frameMgr.isScrollMode()) {
            const body = iframe.contentDocument!.body;
            const maxOffset = Math.max(0, body.scrollHeight - body.clientHeight);
            this.applyScrollOffset(iframe, positionRatio * maxOffset);
          } else {
            pageIndex = Math.round(positionRatio * pageCount);
            this.frameMgr.scrollTo(iframe, this.paginationMgr.calculateScrollOffset(pageIndex));
          }

          requestAnimationFrame(() => {
            requestAnimationFrame(() => {
              this.interactionMgr.buildInteractionMap().then(() => {
                if (iframe.id === 'frame-curr') {
                  FlutterBridge.onPageCountReady(pageCount);
                  FlutterBridge.onPageChanged(pageIndex);
                  this.reportScrollMetrics();
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
