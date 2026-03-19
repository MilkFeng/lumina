import {
  waitForAllResources,
  polyfillCss,
} from './css_polyfill';
import {
  type FrameSlot,
  type ReaderState,
  type ThemeUpdate,
  type Direction,
  WhiteColor,
  BlackColor,
  ReaderConfig
} from '../common/types';
import { LuminaApi } from '../api/lumina_api';
import { FlutterBridge } from '../api/flutter_bridge';
import { applyTyp } from '../typ/typ';
import { FrameManager } from './frame_manager';
import { PaginationManager } from './pagination';
import { InteractionManager } from './interaction';
import { ThemeManager } from './theme_manager';

export class Renderer implements LuminaApi {
  private state: ReaderState;

  private frameMgr: FrameManager;
  private paginationMgr: PaginationManager;
  private interactionMgr: InteractionManager;
  private themeMgr: ThemeManager;

  private resizeDebounceTimer: ReturnType<typeof setTimeout> | null;
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
        },
        paginationCss: '',
      },
    };

    this.frameMgr = new FrameManager(this.state);
    this.paginationMgr = new PaginationManager(this.state, this.frameMgr);
    this.interactionMgr = new InteractionManager(this.state, this.frameMgr);
    this.themeMgr = new ThemeManager(this.state, this.frameMgr);

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

  init(config: ReaderConfig): void {
    this.state.config = config;
    this.state.config.safeHeight = Math.floor(this.state.config.safeHeight);
    this.state.config.safeWidth = Math.floor(this.state.config.safeWidth);

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
    const pageCount = this.paginationMgr.calculatePageCount(iframe);
    const pageIndex = Math.round(ratio * pageCount);
    this.jumpToPage(token, pageIndex);
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

    const iframes = document.getElementsByTagName('iframe');
    for (let i = 0; i < iframes.length; i++) {
      const iframe = iframes[i];
      if (iframe && iframe.contentDocument) {
        const doc = iframe.contentDocument;
        const pageIndex = this.paginationMgr.calculateCurrentPageIndex();
        const pageCount = this.paginationMgr.calculatePageCount(iframe);
        const pageIndexPercentage = pageCount > 0 ? pageIndex / pageCount : 0;
        this.themeMgr.updateCSSVariables(doc, 'injected-variable-style', iframe);
        requestAnimationFrame(() => {
          this.reloadFrame(iframe, pageIndexPercentage, token);
        });
      }
    }
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

    waitForAllResources(doc).then(() => {
      if (!iframe.contentWindow) return;
      requestAnimationFrame(() => {
        const shouldOverrideColor = this.state.config.theme.shouldOverrideTextColor
          && !this.themeMgr.haveBackground(iframe);
        doc.body.classList.toggle('lumina-override-color', shouldOverrideColor);
        doc.body.classList.toggle(
          'lumina-force-override-font',
          !!(this.state.config.theme.overrideFontFamily && this.state.config.theme.fontFileName)
        );
        doc.body.classList.toggle('lumina-override-font', !!(this.state.config.theme.fontFileName));
        doc.body.classList.toggle('lumina-is-vertical', this.frameMgr.isVertical());

        const properties = this.state.properties[this.frameMgr.getSlotFromElement(iframe)] || [];
        for (const prop of properties) {
          doc.body.classList.toggle('lumina-spine-property-' + prop, true);
        }
        applyTyp(iframe);

        const reflow = doc.body.scrollHeight; void reflow;
        requestAnimationFrame(() => {
          polyfillCss(doc, shouldOverrideColor);

          requestAnimationFrame(() => {
            const reflow = doc.body.scrollHeight; void reflow;
            requestAnimationFrame(() => {
              const reflow = doc.body.scrollHeight; void reflow;
              const pageCount = this.paginationMgr.calculatePageCount(iframe);

              let pageIndex = 0;
              const url = iframe.src;
              if (url && url.includes('#')) {
                const anchor = url.split('#')[1];
                pageIndex = this.paginationMgr.calculatePageIndexOfAnchor(iframe, anchor);
                this.frameMgr.scrollTo(iframe, this.paginationMgr.calculateScrollOffset(pageIndex));
              }

              requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                  this.interactionMgr.buildInteractionMap().then(() => {
                    if (iframe.id === 'frame-curr') {
                      FlutterBridge.onPageCountReady(pageCount);
                      FlutterBridge.onPageChanged(pageIndex);
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

  private reloadFrame(iframe: HTMLIFrameElement, pageIndexPercentage: number, token: number): void {
    if (!iframe || !iframe.contentDocument || !iframe.contentWindow) return;

    waitForAllResources(iframe.contentDocument).then(() => {
      const doc = iframe.contentDocument!;
      const overrideColor = this.state.config.theme.shouldOverrideTextColor
        && !this.themeMgr.haveBackground(iframe);
      polyfillCss(doc, overrideColor);

      const reflow = doc.body.scrollHeight; void reflow;

      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          const pageCount = this.paginationMgr.calculatePageCount(iframe);

          const pageIndex = Math.round(pageIndexPercentage * pageCount);
          this.frameMgr.scrollTo(iframe, this.paginationMgr.calculateScrollOffset(pageIndex));

          requestAnimationFrame(() => {
            requestAnimationFrame(() => {
              this.interactionMgr.buildInteractionMap().then(() => {
                if (iframe.id === 'frame-curr') {
                  FlutterBridge.onPageCountReady(pageCount);
                  FlutterBridge.onPageChanged(pageIndex);
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
