import { QuadTree, Rect } from '../quad_tree';
import {
  waitForAllResources,
  polyfillCss,
} from '../css_polyfill';
import type {
  FrameSlot,
  ReaderState,
  InteractionItem,
  InitConfig,
  ThemeUpdate,
  Direction
} from '../types';
import { LuminaApi } from '../api';
import { FlutterBridge } from '../flutter_bridge';
import { applyTyp, getTypConfig } from '../typ/typ';
import { FrameManager } from './frame_manager';
import { PaginationManager } from './pagination';
import { InteractionManager } from './interaction';

export class EpubRenderer implements LuminaApi {
  state: ReaderState;

  private frameMgr: FrameManager;
  private paginationMgr: PaginationManager;
  private interactionMgr: InteractionManager;

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
          paginationCss: '',
          surfaceColor: '#FFFFFF',
          onSurfaceColor: '#000000',
          shouldOverrideTextColor: true,
          primaryColor: '#000000',
          primaryContainerColor: '#000000',
          onSurfaceVariantColor: '#000000',
          outlineVariantColor: '#000000',
          surfaceContainerColor: '#000000',
          surfaceContainerHighColor: '#000000',
        },
      },
    };

    this.frameMgr = new FrameManager(this.state);
    this.paginationMgr = new PaginationManager(this.state, this.frameMgr);
    this.interactionMgr = new InteractionManager(this.state, this.frameMgr);

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
    const padding = config.padding || {};

    this.state.config.safeWidth = Math.floor(config.safeWidth ?? 0);
    this.state.config.safeHeight = Math.floor(config.safeHeight ?? 0);
    this.state.config.direction = Number(config.direction) || 0;
    this.state.config.padding = {
      top: Number(padding.top ?? 0),
      left: Number(padding.left ?? 0),
    };
    this.state.config.theme = config.theme;

    this.updateCSSVariables(document, 'skeleton-variable-style');
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
  checkElementAt(x: number, y: number): void {
    this.interactionMgr.checkElementAt(x, y);
  }

  updateTheme(token: number, viewWidth: number, viewHeight: number, newTheme: ThemeUpdate): void {
    this.state.config.safeWidth = Math.floor(viewWidth);
    this.state.config.safeHeight = Math.floor(viewHeight);
    this.state.config.padding = {
      top: newTheme.padding.top,
      left: newTheme.padding.left,
    };
    this.state.config.theme.zoom = newTheme.zoom;
    this.state.config.theme.shouldOverrideTextColor = newTheme.shouldOverrideTextColor;
    this.state.config.theme.fontFileName = newTheme.fontFileName || null;
    this.state.config.theme.overrideFontFamily = newTheme.overrideFontFamily || false;
    this.state.config.theme.primaryColor = newTheme.overridePrimaryColor || newTheme.primaryColor;
    this.state.config.theme.primaryContainerColor = newTheme.primaryContainerColor;
    this.state.config.theme.surfaceColor = newTheme.surfaceColor;
    this.state.config.theme.onSurfaceColor = newTheme.onSurfaceColor;
    this.state.config.theme.onSurfaceVariantColor = newTheme.onSurfaceVariantColor;
    this.state.config.theme.outlineVariantColor = newTheme.outlineVariantColor;
    this.state.config.theme.surfaceContainerColor = newTheme.surfaceContainerColor;
    this.state.config.theme.surfaceContainerHighColor = newTheme.surfaceContainerHighColor;

    this.updateCSSVariables(document, 'skeleton-variable-style');

    const iframes = document.getElementsByTagName('iframe');
    for (let i = 0; i < iframes.length; i++) {
      const iframe = iframes[i];
      if (iframe && iframe.contentDocument) {
        const doc = iframe.contentDocument;
        const pageIndex = this.paginationMgr.calculateCurrentPageIndex();
        const pageCount = this.paginationMgr.calculatePageCount(iframe);
        const pageIndexPercentage = pageCount > 0 ? pageIndex / pageCount : 0;
        this.updateCSSVariables(doc, 'injected-variable-style', iframe);
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

  private getOriginalBackgroundColor(iframe: HTMLIFrameElement): string | null {
    if (!iframe || !iframe.contentDocument || !iframe.contentWindow) return null;
    try {
      const window = iframe.contentWindow!;
      const body = iframe.contentDocument.body;
      if (!body) {
        console.warn('Iframe body is null, possibly not fully loaded or not an HTML document.');
        return null;
      }
      const bgColor = window.getComputedStyle(body).backgroundColor;
      if (bgColor && bgColor !== 'rgba(0, 0, 0, 0)' && bgColor !== 'transparent') {
        return bgColor;
      }
    } catch (e) {
      console.warn('Failed to get original background color from iframe:', e);
      return null;
    }
    return null;
  }

  // ─── CSS Variables ─────────────────────────────────────────────────

  private generateVariableStyle(): string {
    const cfg = this.state.config;
    const t = cfg.theme;
    const isV = this.frameMgr.isVertical();

    const fontFaceBlock = t.fontFileName
      ? `@font-face { font-family: 'LuminaCustomFont'; src: url('epub://localhost/fonts/${t.fontFileName}'); }`
      : '';
    const fontFamilyItem = t.fontFileName ? `--lumina-font-family: 'LuminaCustomFont';` : '';

    return fontFaceBlock + ' :root {'
      + `--lumina-zoom: ${t.zoom};`
      + `--lumina-safe-width: ${cfg.safeWidth}px;`
      + `--lumina-safe-height: ${cfg.safeHeight}px;`
      + `--lumina-padding-top: ${cfg.padding.top}px;`
      + `--lumina-padding-left: ${cfg.padding.left}px;`
      + `--lumina-reader-overflow-x: ${isV ? 'hidden' : 'auto'};`
      + `--lumina-reader-overflow-y: ${isV ? 'auto' : 'hidden'};`
      + `--lumina-surface-color: ${t.surfaceColor};`
      + `--lumina-on-surface-color: ${t.onSurfaceColor};`
      + `--lumina-primary-color: ${t.primaryColor};`
      + `--lumina-primary-container-color: ${t.primaryContainerColor};`
      + `--lumina-on-surface-variant-color: ${t.onSurfaceVariantColor};`
      + `--lumina-outline-variant-color: ${t.outlineVariantColor};`
      + `--lumina-surface-container-color: ${t.surfaceContainerColor};`
      + `--lumina-surface-container-high-color: ${t.surfaceContainerHighColor};`
      + fontFamilyItem
      + '}';
  }

  private updateCSSVariables(
    doc: Document,
    styleId: string = 'injected-variable-style',
    iframe: HTMLIFrameElement | null = null
  ): void {
    const root = doc.documentElement;
    const body = doc.body;
    const cfg = this.state.config;
    const t = cfg.theme;
    const isV = this.frameMgr.isVertical();

    root.style.setProperty('--lumina-zoom', String(t.zoom));
    root.style.setProperty('--lumina-safe-width', cfg.safeWidth + 'px');
    root.style.setProperty('--lumina-safe-height', cfg.safeHeight + 'px');
    root.style.setProperty('--lumina-padding-top', cfg.padding.top + 'px');
    root.style.setProperty('--lumina-padding-left', cfg.padding.left + 'px');
    root.style.setProperty('--lumina-reader-overflow-x', isV ? 'hidden' : 'auto');
    root.style.setProperty('--lumina-reader-overflow-y', isV ? 'auto' : 'hidden');
    root.style.setProperty('--lumina-surface-color', t.surfaceColor);
    root.style.setProperty('--lumina-on-surface-color', t.onSurfaceColor);
    root.style.setProperty('--lumina-primary-color', t.primaryColor);
    root.style.setProperty('--lumina-primary-container', t.primaryContainerColor);
    root.style.setProperty('--lumina-on-surface-variant', t.onSurfaceVariantColor);
    root.style.setProperty('--lumina-outline-variant', t.outlineVariantColor);
    root.style.setProperty('--lumina-surface-container', t.surfaceContainerColor);
    root.style.setProperty('--lumina-surface-container-high', t.surfaceContainerHighColor);

    const overrideColor = iframe != null
      ? t.shouldOverrideTextColor && this.getOriginalBackgroundColor(iframe) == null
      : t.shouldOverrideTextColor;

    body.classList.toggle('lumina-override-color', overrideColor);
    body.classList.toggle('lumina-force-override-font', !!(t.overrideFontFamily && t.fontFileName));
    body.classList.toggle('lumina-override-font', !!(t.fontFileName));

    const existingStyle = doc.getElementById(styleId);
    if (existingStyle) existingStyle.innerHTML = this.generateVariableStyle();
  }

  // ─── Frame Loading ─────────────────────────────────────────────────

  private onFrameLoad(iframe: HTMLIFrameElement, token: number): void {
    if (!iframe || !iframe.contentDocument) return;

    const doc = iframe.contentDocument;

    const existingVariableStyle = doc.getElementById('injected-variable-style');
    if (existingVariableStyle) {
      existingVariableStyle.innerHTML = this.generateVariableStyle();
      this.updateCSSVariables(doc, 'injected-variable-style', iframe);
    } else {
      const variableStyle = doc.createElement('style');
      variableStyle.id = 'injected-variable-style';
      variableStyle.innerHTML = this.generateVariableStyle();
      doc.head.appendChild(variableStyle);
    }

    const existingPaginationStyle = doc.getElementById('injected-pagination-style');
    if (existingPaginationStyle) {
      existingPaginationStyle.innerHTML = this.state.config.theme.paginationCss;
    } else {
      const style = doc.createElement('style');
      style.id = 'injected-pagination-style';
      style.innerHTML = this.state.config.theme.paginationCss;
      doc.head.appendChild(style);
    }

    waitForAllResources(doc).then(() => {
      if (!iframe.contentWindow) return;
      requestAnimationFrame(() => {
        const originalBgColor = this.getOriginalBackgroundColor(iframe);
        const shouldOverrideColor = this.state.config.theme.shouldOverrideTextColor && originalBgColor == null;
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
        && this.getOriginalBackgroundColor(iframe) == null;
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
