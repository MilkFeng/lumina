import { QuadTree, Rect } from './quad_tree';
import {
    waitForAllResources,
    polyfillCss,
} from './css_polyfill';
import type {
    FrameSlot,
    ReaderState,
    InteractionItem,
    InitConfig,
    ThemeUpdate
} from './types';
import { LuminaApi } from './api';

export class EpubReader implements LuminaApi {
    state: ReaderState;
    private _resizeDebounceTimer: ReturnType<typeof setTimeout> | null;
    private _onResize: () => void;

    constructor() {
        this.state = {
            frames: { prev: 0, curr: 0, next: 0 },
            anchors: { prev: [], curr: [], next: [] },
            quadTree: null,
            config: {
                safeWidth: 0,
                safeHeight: 0,
                direction: 0,
                padding: { top: 0, left: 0, right: 0, bottom: 0 },
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

        this._resizeDebounceTimer = null;
        this._onResize = () => {
            if (this._resizeDebounceTimer) {
                clearTimeout(this._resizeDebounceTimer);
            }
            this._resizeDebounceTimer = setTimeout(() => {
                window.flutter_inappwebview.callHandler('onViewportResize');
            }, 120);
        };
    }

    // ─── Public API ────────────────────────────────────────────────────

    init(config: InitConfig): void {
        const padding = config.padding || {};

        this.state.config.safeWidth = Math.floor(config.safeWidth ?? 0);
        this.state.config.safeHeight = Math.floor(config.safeHeight ?? 0);
        this.state.config.direction = Number(config.direction) || 0;
        this.state.config.padding = {
            top: Number(padding.top ?? 0),
            left: Number(padding.left ?? 0),
            right: Number(padding.right ?? 0),
            bottom: Number(padding.bottom ?? 0),
        };
        this.state.config.theme = config.theme;

        this.updateCSSVariables(document, 'skeleton-variable-style');
        window.removeEventListener('resize', this._onResize);
        window.addEventListener('resize', this._onResize, { passive: true });
    }

    loadFrame(slot: FrameSlot, url: string, anchors?: string[]): void {
        const iframe = this.frameElement(slot);
        if (!iframe) return;

        this.state.anchors[slot] = anchors || [];
        iframe.onload = null;

        if (iframe.src == null || iframe.src === '' || iframe.src === 'about:blank') {
            iframe.onload = () => { this.onFrameLoad(iframe); };
            iframe.src = url;
        } else {
            const currentUrl = new URL(iframe.src);
            const newUrl = new URL(url);
            if (currentUrl.origin === newUrl.origin && currentUrl.pathname === newUrl.pathname) {
                iframe.onload = () => { this.onFrameLoad(iframe); };
                iframe.src = url;
                this.onFrameLoad(iframe);
            } else {
                iframe.onload = () => { this.onFrameLoad(iframe); };
                iframe.src = url;
            }
        }
    }

    jumpToPage(pageIndex: number): void {
        const iframe = this.frameElement('curr');
        if (!iframe || !iframe.contentWindow) return;

        const scrollOffset = this.calculateScrollOffset(pageIndex);
        this.scrollTo(iframe, scrollOffset);

        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);
                this.detectActiveAnchor(iframe);
            });
        });
    }

    jumpToPageFor(slot: FrameSlot, pageIndex: number): void {
        const iframe = this.frameElement(slot);
        if (!iframe || !iframe.contentWindow) return;

        const scrollOffset = this.calculateScrollOffset(pageIndex);
        this.scrollTo(iframe, scrollOffset);

        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                if (iframe.id === 'frame-curr') {
                    window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);
                }
                this.detectActiveAnchor(iframe);
            });
        });
    }

    jumpToLastPageOfFrame(slot: FrameSlot): void {
        const pageCount = this.state.frames[slot] ?? 0;
        this.jumpToPageFor(slot, pageCount - 1);
    }

    restoreScrollPosition(ratio: number): void {
        const pageCount = this.state.frames.curr;
        const pageIndex = Math.round(ratio * pageCount);
        this.jumpToPage(pageIndex);
    }

    cycleFrames(direction: 'next' | 'prev'): void {
        const elPrev = this.frameElement('prev');
        const elCurr = this.frameElement('curr');
        const elNext = this.frameElement('next');

        if (!elPrev || !elCurr || !elNext) return;

        if (direction === 'next') {
            elPrev.id = 'frame-temp';

            elNext.id = 'frame-curr';
            elNext.style.zIndex = '2';
            elNext.style.opacity = '1';

            elCurr.id = 'frame-prev';
            elCurr.style.zIndex = '1';
            elCurr.style.opacity = '0';

            const recycled = document.getElementById('frame-temp') as HTMLElement;
            recycled.id = 'frame-next';
            recycled.style.zIndex = '1';
            recycled.style.opacity = '0';

            const tempAnchors = this.state.anchors.prev;
            this.state.anchors.prev = this.state.anchors.curr;
            this.state.anchors.curr = this.state.anchors.next;
            this.state.anchors.next = tempAnchors;
        } else if (direction === 'prev') {
            elNext.id = 'frame-temp';

            elPrev.id = 'frame-curr';
            elPrev.style.zIndex = '2';
            elPrev.style.opacity = '1';

            elCurr.id = 'frame-next';
            elCurr.style.zIndex = '1';
            elCurr.style.opacity = '0';

            const recycled = document.getElementById('frame-temp') as HTMLElement;
            recycled.id = 'frame-prev';
            recycled.style.zIndex = '1';
            recycled.style.opacity = '0';

            const tempAnchors = this.state.anchors.next;
            this.state.anchors.next = this.state.anchors.curr;
            this.state.anchors.curr = this.state.anchors.prev;
            this.state.anchors.prev = tempAnchors;
        }

        this.applyOriginalBackgroundColor();

        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                this.updatePageState('frame-curr');
                this.updatePageState('frame-prev');
                this.updatePageState('frame-next');
                this.detectActiveAnchor(elPrev);
                this.detectActiveAnchor(elCurr);
                this.detectActiveAnchor(elNext);
                this.buildInteractionMap();
            });
        });
    }

    updateTheme(token: number, viewWidth: number, viewHeight: number, newTheme: ThemeUpdate): void {
        this.state.config.safeWidth = Math.floor(viewWidth);
        this.state.config.safeHeight = Math.floor(viewHeight);
        this.state.config.padding = {
            top: newTheme.padding.top,
            left: newTheme.padding.left,
            right: newTheme.padding.right,
            bottom: newTheme.padding.bottom,
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
                const pageIndex = this.calculateCurrentPageIndex();
                const pageCount = this.calculatePageCount(iframe);
                const pageIndexPercentage = pageCount > 0 ? pageIndex / pageCount : 0;
                this.updateCSSVariables(doc, 'injected-variable-style', iframe);
                requestAnimationFrame(() => {
                    this.reloadFrame(iframe, pageIndexPercentage, token);
                });
            }
        }
    }

    checkLinkAt(x: number, y: number): boolean {
        const iframe = this.frameElement('curr');
        if (iframe && iframe.contentDocument) {
            const doc = iframe.contentDocument;
            const xx = x - this.state.config.padding.left;
            const yy = y - this.state.config.padding.top;
            const elementAtPoint = doc.elementFromPoint(xx, yy);
            if (elementAtPoint) {
                const linkEl = elementAtPoint.closest('a');
                if (linkEl) {
                    const href = linkEl.getAttribute('href');
                    if (href) {
                        window.flutter_inappwebview.callHandler('onLinkTap', linkEl.href, x, y);
                        return true;
                    }
                }
            }
        }
        return false;
    }

    checkTapElementAt(x: number, y: number): void {
        const bestCandidate = this.checkElementAtHelper(x, y, (candidate) => candidate.type === 'footnote');

        if (bestCandidate) {
            const iframe = this.frameElement('curr');
            if (!iframe || !iframe.contentDocument) return;
            const body = iframe.contentDocument.body;
            if (!body) return;

            const rect = bestCandidate.rect;
            const absoluteLeft = rect.x - body.scrollLeft + this.state.config.padding.left;
            const absoluteTop = rect.y - body.scrollTop + this.state.config.padding.top;

            if (bestCandidate.type === 'footnote') {
                window.flutter_inappwebview.callHandler(
                    'onFootnoteTap', bestCandidate.data,
                    absoluteLeft, absoluteTop, rect.width, rect.height
                );
                return;
            }
        }

        if (this.checkLinkAt(x, y)) return;

        window.flutter_inappwebview.callHandler('onTap', x, y);
    }

    checkImageAt(x: number, y: number): boolean {
        const iframe = this.frameElement('curr');
        if (iframe && iframe.contentDocument) {
            const doc = iframe.contentDocument;
            const bodyRect = doc.body.getBoundingClientRect();
            const xx = x - this.state.config.padding.left;
            const yy = y - this.state.config.padding.top;
            const elementAtPoint = doc.elementFromPoint(xx, yy);
            if (elementAtPoint) {
                const imgEl = elementAtPoint.closest('img, image') as HTMLImageElement | SVGImageElement | null;
                if (imgEl) {
                    let src = (imgEl as any).currentSrc || (imgEl as any).src || imgEl.getAttribute('xlink:href') || '';
                    if (src) {
                        const link = doc.createElement('a');
                        link.href = src;
                        src = link.href;

                        const rect = imgEl.getBoundingClientRect();
                        if (!rect || rect.width < 5 || rect.height < 5) return false;

                        const docX = rect.left - bodyRect.left + this.state.config.padding.left;
                        const docY = rect.top - bodyRect.top + this.state.config.padding.top;

                        window.flutter_inappwebview.callHandler('onImageLongPress', src, docX, docY, rect.width, rect.height);
                        return true;
                    }
                }
            }
        }
        return false;
    }

    checkElementAt(x: number, y: number): void {
        this.checkImageAt(x, y);
    }

    waitForRender(token: number): void {
        requestAnimationFrame(function () {
            requestAnimationFrame(function () {
                window.flutter_inappwebview.callHandler('onEventFinished', token);
            });
        });
    }

    // ─── Frame Helpers ─────────────────────────────────────────────────

    private frameElement(slotOrId: string): HTMLIFrameElement | null {
        const id = slotOrId.startsWith('frame-') ? slotOrId : 'frame-' + slotOrId;
        return document.getElementById(id) as HTMLIFrameElement | null;
    }

    private _slotFromFrameId(frameId: string): FrameSlot {
        return (frameId ? frameId.replace('frame-', '') : '') as FrameSlot;
    }

    private getWidth(): number { return this.state.config.safeWidth; }
    private getHeight(): number { return this.state.config.safeHeight; }
    private isVertical(): boolean { return this.state.config.direction === 1; }

    private scrollTo(iframe: HTMLIFrameElement, offset: number): void {
        if (!iframe || !iframe.contentWindow) return;
        const scrollOptions: ScrollToOptions = this.isVertical()
            ? { top: offset, left: 0, behavior: 'auto' }
            : { top: 0, left: offset, behavior: 'auto' };
        iframe.contentDocument!.body.scrollTo(scrollOptions);
    }

    // ─── Pagination ────────────────────────────────────────────────────

    private calculatePageCount(iframe: HTMLIFrameElement): number {
        if (!iframe || !iframe.contentDocument) return 0;
        if (this.isVertical()) {
            const scrollHeight = iframe.contentDocument.body.scrollHeight;
            return Math.round((scrollHeight + 128) / (this.getHeight() + 128));
        } else {
            const scrollWidth = iframe.contentDocument.body.scrollWidth;
            return Math.round((scrollWidth + 128) / (this.getWidth() + 128));
        }
    }

    private calculateScrollOffset(pageIndex: number): number {
        if (this.isVertical()) {
            return pageIndex * this.getHeight() + pageIndex * 128;
        } else {
            return pageIndex * this.getWidth() + pageIndex * 128;
        }
    }

    private calculateCurrentPageIndex(): number {
        const iframe = this.frameElement('curr');
        if (!iframe || !iframe.contentWindow || !iframe.contentDocument) return 0;
        if (this.isVertical()) {
            const scrollTop = iframe.contentDocument.body.scrollTop || 0;
            return Math.round((scrollTop + 128) / (this.getHeight() + 128));
        } else {
            const scrollLeft = iframe.contentDocument.body.scrollLeft;
            return Math.round((scrollLeft + 128) / (this.getWidth() + 128));
        }
    }

    private calculatePageIndexOfAnchor(iframe: HTMLIFrameElement, anchorId: string): number {
        if (!iframe || !iframe.contentDocument) return 0;
        const doc = iframe.contentDocument;
        const element = doc.getElementById(anchorId);
        if (!element) return 0;

        const bodyRect = doc.body.getBoundingClientRect();
        const rects = element.getClientRects();
        const elementRect = rects.length > 0 ? rects[0] : element.getBoundingClientRect();

        if (this.isVertical()) {
            const absoluteTop = elementRect.top + doc.body.scrollTop - bodyRect.top + (elementRect.height / 5) + 1;
            return Math.floor((absoluteTop + 128) / (this.getHeight() + 128));
        } else {
            const absoluteLeft = elementRect.left + doc.body.scrollLeft - bodyRect.left + (elementRect.width / 5) + 1;
            return Math.floor((absoluteLeft + 128) / (this.getWidth() + 128));
        }
    }

    private updatePageState(iframeId: string): void {
        const iframe = this.frameElement(iframeId);
        if (!iframe || !iframe.contentWindow) return;

        const pageCount = this.calculatePageCount(iframe);
        const slot = this._slotFromFrameId(iframeId);
        this.state.frames[slot] = pageCount;

        if (iframeId === 'frame-curr') {
            window.flutter_inappwebview.callHandler('onPageCountReady', pageCount);
            window.flutter_inappwebview.callHandler('onPageChanged', this.calculateCurrentPageIndex());
        } else if (iframeId === 'frame-prev') {
            this.jumpToLastPageOfFrame('prev');
        } else if (iframeId === 'frame-next') {
            this.jumpToPageFor('next', 0);
        }
    }

    // ─── Anchor Detection ──────────────────────────────────────────────

    private detectActiveAnchor(iframe: HTMLIFrameElement): void {
        if (!iframe || !iframe.contentDocument) return;
        if (iframe.id !== 'frame-curr') return;

        const anchors = this.state.anchors.curr;
        if (!anchors || anchors.length === 0) return;

        const doc = iframe.contentDocument;
        const activeAnchors: string[] = [];
        let lastPassedAnchor = 'top';
        const threshold = 50;
        const isVertical = this.isVertical();

        for (let i = 0; i < anchors.length; i++) {
            const anchorId = anchors[i];
            if (anchorId === 'top') {
                if (isVertical ? doc.body.scrollTop < threshold : doc.body.scrollLeft < threshold) {
                    activeAnchors.push('top');
                }
                continue;
            }

            const element = doc.getElementById(anchorId);
            if (element) {
                const rect = element.getBoundingClientRect();
                if (isVertical) {
                    if (rect.top < threshold && rect.bottom > threshold) activeAnchors.push(anchorId);
                    if (rect.top < threshold) lastPassedAnchor = anchorId;
                } else {
                    if (rect.left < threshold && rect.right > threshold) activeAnchors.push(anchorId);
                    if (rect.left < threshold) lastPassedAnchor = anchorId;
                }
            }
        }

        if (activeAnchors.length === 0 && lastPassedAnchor) {
            activeAnchors.push(lastPassedAnchor);
        }
        window.flutter_inappwebview.callHandler('onScrollAnchors', activeAnchors);
    }

    // ─── Footnote Extraction ───────────────────────────────────────────

    private extractTargetIdFromHref(href: string | null): string | null {
        if (!href || typeof href !== 'string') return null;
        const hashIndex = href.indexOf('#');
        if (hashIndex < 0 || hashIndex >= href.length - 1) return null;
        try {
            return decodeURIComponent(href.substring(hashIndex + 1));
        } catch (_) {
            return href.substring(hashIndex + 1);
        }
    }

    private extractFootnoteHtml(targetId: string | null): string {
        const iframe = this.frameElement('curr');
        if (!iframe || !iframe.contentDocument) return '';

        const doc = iframe.contentDocument;
        if (!targetId) return '';

        const sanitizedId = String(targetId).replace(/^#/, '');
        if (!sanitizedId) return '';

        let footnoteEl: Element | null = doc.getElementById(sanitizedId);
        if (!footnoteEl) {
            footnoteEl = doc.querySelector('[name="' + sanitizedId + '"]');
        }
        if (!footnoteEl) return '';

        if (footnoteEl.textContent!.trim() === '' && footnoteEl.nextElementSibling) {
            footnoteEl = footnoteEl.nextElementSibling;
        }

        const container = footnoteEl.closest('li, aside, section, div, p') || footnoteEl;
        return container?.outerHTML ?? '';
    }

    // ─── Interaction Map ───────────────────────────────────────────────

    private buildInteractionMap(): Promise<void> {
        const iframe = this.frameElement('curr');
        if (!iframe || !iframe.contentDocument) {
            this.state.quadTree = null;
            return Promise.resolve();
        }
        const doc = iframe.contentDocument;

        return new Promise<void>((resolve) => {
            const body = doc.body;
            if (!body) {
                this.state.quadTree = null;
                resolve();
                return;
            }

            const quadTree = new QuadTree<InteractionItem>(
                new Rect(0, 0, Math.max(1, body.scrollWidth), Math.max(1, body.scrollHeight)),
                4
            );
            const bodyRect = body.getBoundingClientRect();

            // ── Images (zy-footnote / duokan-footnote) ──────────────────────
            const images = doc.querySelectorAll('img, image');
            for (let i = 0; i < images.length; i++) {
                const img = images[i] as Element;
                const rect = img.getBoundingClientRect();
                if (!rect || rect.width < 5 || rect.height < 5) continue;

                const docX = rect.left + body.scrollLeft - bodyRect.left;
                const docY = rect.top + body.scrollTop - bodyRect.top;

                let isZyFootnote = img.hasAttribute('zy-footnote');
                let isDuokanFootnote = false;

                if (!isZyFootnote) {
                    if (img.classList.contains('duokan-footnote')) {
                        isDuokanFootnote = true;
                    } else {
                        const closestLink = img.closest('a');
                        if (
                            closestLink &&
                            closestLink.classList.contains('duokan-footnote') &&
                            !closestLink.hasAttribute('href') &&
                            !closestLink.hasAttribute('epub:type')
                        ) {
                            isDuokanFootnote = true;
                        }
                    }
                }

                if (isZyFootnote || isDuokanFootnote) {
                    const altText = isZyFootnote
                        ? img.getAttribute('zy-footnote') || ''
                        : img.getAttribute('alt') || img.getAttribute('title') || '';

                    quadTree.insert({
                        type: 'footnote',
                        rect: new Rect(docX, docY, rect.width, rect.height),
                        data: '<div>' + altText + '</div>',
                    });
                }
            }

            // ── Links ────────────────────────────────────────────────────────
            const links = doc.querySelectorAll('a');
            for (let i = 0; i < links.length; i++) {
                const link = links[i];
                const href = link.getAttribute('href');
                const epubType = link.getAttribute('epub:type');
                let innerHtml = '';
                let isFootnote = false;

                if (!href && !link.classList.contains('duokan-footnote')) {
                    const noteAncestor = link.closest('note');
                    if (noteAncestor) {
                        const asideElements = noteAncestor.querySelectorAll('aside');
                        for (let j = 0; j < asideElements.length; j++) {
                            innerHtml += asideElements[j].outerHTML;
                        }
                        isFootnote = true;
                    }
                }

                if (link.hasAttribute('title') && (!href || href === '#')) {
                    innerHtml = '<div class="footnote-content">' + link.getAttribute('title') + '</div>';
                    isFootnote = true;
                } else if (epubType === 'noteref') {
                    innerHtml = this.extractFootnoteHtml(this.extractTargetIdFromHref(href));
                    isFootnote = true;
                } else if (link.classList.contains('duokan-footnote') && href && href.includes('#')) {
                    const fullHref = link.href;
                    let thisUrl = link.ownerDocument.location.href;
                    if (thisUrl.includes('#')) thisUrl = thisUrl.split('#')[0];
                    if (fullHref === thisUrl || thisUrl === fullHref.split('#')[0]) {
                        innerHtml = this.extractFootnoteHtml(this.extractTargetIdFromHref(href));
                        isFootnote = true;
                    }
                }

                if (!isFootnote || !innerHtml || innerHtml.trim() === '') continue;

                const rects = link.getClientRects();
                for (let j = 0; j < rects.length; j++) {
                    const rect = rects[j];
                    if (!rect || rect.width < 5 || rect.height < 5) continue;
                    quadTree.insert({
                        type: 'footnote',
                        rect: new Rect(
                            rect.left + body.scrollLeft - bodyRect.left,
                            rect.top + body.scrollTop - bodyRect.top,
                            rect.width,
                            rect.height
                        ),
                        data: innerHtml,
                    });
                }
            }

            // ── Aozora Bunko notes ───────────────────────────────────────────
            const aozoraNotes = doc.querySelectorAll('span.notes, .notes');
            for (let i = 0; i < aozoraNotes.length; i++) {
                const noteSpan = aozoraNotes[i];
                const innerHtml = '<div class="aozora-footnote-content">' + noteSpan.innerHTML + '</div>';
                const rects = noteSpan.getClientRects();
                for (let j = 0; j < rects.length; j++) {
                    const rect = rects[j];
                    if (!rect || rect.width < 5 || rect.height < 5) continue;
                    quadTree.insert({
                        type: 'footnote',
                        rect: new Rect(
                            rect.left + body.scrollLeft - bodyRect.left,
                            rect.top + body.scrollTop - bodyRect.top,
                            rect.width,
                            rect.height
                        ),
                        data: innerHtml,
                    });
                }
            }

            this.state.quadTree = quadTree;
            resolve();
        });
    }

    private checkElementAtHelper(
        x: number,
        y: number,
        checkIfAllowed?: (candidate: InteractionItem) => boolean
    ): InteractionItem | undefined {
        const iframe = this.frameElement('curr');
        if (!iframe || !iframe.contentDocument || !this.state.quadTree) return;

        const body = iframe.contentDocument.body;
        if (!body) return;

        const docX = x - this.state.config.padding.left + body.scrollLeft;
        const docY = y - this.state.config.padding.top + body.scrollTop;

        const radius = 20;
        const candidates = this.state.quadTree.query(
            new Rect(docX - radius, docY - radius, radius * 2, radius * 2),
            []
        );

        let bestCandidate: InteractionItem | undefined;
        let minDistance = Infinity;

        for (let i = candidates.length - 1; i >= 0; i--) {
            const candidate = candidates[i];
            if (!candidate?.rect) continue;
            if (checkIfAllowed && !checkIfAllowed(candidate)) continue;

            const rect = new Rect(candidate.rect.x, candidate.rect.y, candidate.rect.width, candidate.rect.height);
            let distance: number;
            if (rect.contains({ x: docX, y: docY })) {
                distance = 0;
            } else {
                const dx = docX - (rect.x + rect.width / 2);
                const dy = docY - (rect.y + rect.height / 2);
                distance = Math.sqrt(dx * dx + dy * dy);
            }

            if (distance < minDistance) {
                minDistance = distance;
                bestCandidate = candidate;
            }
        }

        return bestCandidate;
    }

    // ─── Background Color ──────────────────────────────────────────────

    private getOriginalBackgroundColor(iframe: HTMLIFrameElement): string | null {
        if (!iframe || !iframe.contentDocument) return null;
        const bgColor = iframe.contentWindow!.getComputedStyle(iframe.contentDocument.body).backgroundColor;
        if (bgColor && bgColor !== 'rgba(0, 0, 0, 0)' && bgColor !== 'transparent') {
            return bgColor;
        }
        return null;
    }

    private applyOriginalBackgroundColor(): void {
        const iframe = this.frameElement('curr');
        if (!iframe) return;
        const originalBgColor = this.getOriginalBackgroundColor(iframe);
        if (originalBgColor) {
            document.documentElement.style.setProperty('--lumina-epub-original-bg-color', originalBgColor);
        } else {
            document.documentElement.style.removeProperty('--lumina-epub-original-bg-color');
        }
    }

    // ─── CSS Variables ─────────────────────────────────────────────────

    private generateVariableStyle(): string {
        const cfg = this.state.config;
        const t = cfg.theme;
        const isV = this.isVertical();

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
            + `--lumina-padding-right: ${cfg.padding.right}px;`
            + `--lumina-padding-bottom: ${cfg.padding.bottom}px;`
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
        const isV = this.isVertical();

        root.style.setProperty('--lumina-zoom', String(t.zoom));
        root.style.setProperty('--lumina-safe-width', cfg.safeWidth + 'px');
        root.style.setProperty('--lumina-safe-height', cfg.safeHeight + 'px');
        root.style.setProperty('--lumina-padding-top', cfg.padding.top + 'px');
        root.style.setProperty('--lumina-padding-left', cfg.padding.left + 'px');
        root.style.setProperty('--lumina-padding-right', cfg.padding.right + 'px');
        root.style.setProperty('--lumina-padding-bottom', cfg.padding.bottom + 'px');
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
        body.classList.toggle('lumina-override-font', !!(t.overrideFontFamily && t.fontFileName));

        const existingStyle = doc.getElementById(styleId);
        if (existingStyle) existingStyle.innerHTML = this.generateVariableStyle();
    }

    // ─── Frame Loading ─────────────────────────────────────────────────

    private onFrameLoad(iframe: HTMLIFrameElement): void {
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

            const originalBgColor = this.getOriginalBackgroundColor(iframe);
            doc.body.classList.toggle(
                'lumina-override-color',
                this.state.config.theme.shouldOverrideTextColor && originalBgColor == null
            );
            doc.body.classList.toggle(
                'lumina-override-font',
                !!(this.state.config.theme.overrideFontFamily && this.state.config.theme.fontFileName)
            );
            doc.body.classList.toggle('is-vertical', this.isVertical());
        }

        const existingPaginationStyle = doc.getElementById('injected-pagination-style');
        if (existingPaginationStyle) {
            existingPaginationStyle.innerHTML = this.state.config.theme.paginationCss;
        } else {
            const style = doc.createElement('style');
            style.id = 'injected-pagination-style';
            style.innerHTML = this.state.config.theme.paginationCss;
            doc.head.appendChild(style);
            polyfillCss(doc);
            this.applyOriginalBackgroundColor();
        }

        waitForAllResources(doc).then(() => {
            if (!iframe.contentWindow) return;
            const _reflow = doc.body.scrollHeight; void _reflow;

            requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                    const pageCount = this.calculatePageCount(iframe);
                    const slot = this._slotFromFrameId(iframe.id);
                    this.state.frames[slot] = pageCount;

                    let pageIndex = 0;
                    const url = iframe.src;
                    if (url && url.includes('#')) {
                        const anchor = url.split('#')[1];
                        pageIndex = this.calculatePageIndexOfAnchor(iframe, anchor);
                        this.scrollTo(iframe, this.calculateScrollOffset(pageIndex));
                    }

                    this.buildInteractionMap().then(() => {
                        if (iframe.id === 'frame-curr') {
                            window.flutter_inappwebview.callHandler('onPageCountReady', pageCount);
                            window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);
                            window.flutter_inappwebview.callHandler('onRendererInitialized');
                        } else if (iframe.id === 'frame-prev') {
                            this.jumpToLastPageOfFrame('prev');
                        } else if (iframe.id === 'frame-next') {
                            this.jumpToPageFor('next', 0);
                        }
                        this.detectActiveAnchor(iframe);
                    });
                });
            });
        });
    }

    private reloadFrame(iframe: HTMLIFrameElement, pageIndexPercentage: number, token: number): void {
        if (!iframe || !iframe.contentDocument || !iframe.contentWindow) return;

        this.applyOriginalBackgroundColor();

        waitForAllResources(iframe.contentDocument).then(() => {
            const doc = iframe.contentDocument!;
            const _reflow = doc.body.scrollHeight; void _reflow;

            requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                    const pageCount = this.calculatePageCount(iframe);
                    const slot = this._slotFromFrameId(iframe.id);
                    this.state.frames[slot] = pageCount;

                    const pageIndex = Math.round(pageIndexPercentage * pageCount);
                    this.scrollTo(iframe, this.calculateScrollOffset(pageIndex));

                    this.buildInteractionMap().then(() => {
                        if (iframe.id === 'frame-curr') {
                            window.flutter_inappwebview.callHandler('onPageCountReady', pageCount);
                            window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);
                            window.flutter_inappwebview.callHandler('onRendererInitialized');
                        } else if (iframe.id === 'frame-prev') {
                            this.jumpToLastPageOfFrame('prev');
                        } else if (iframe.id === 'frame-next') {
                            this.jumpToPageFor('next', 0);
                        }
                        this.detectActiveAnchor(iframe);

                        requestAnimationFrame(() => {
                            window.flutter_inappwebview.callHandler('onEventFinished', token);
                        });
                    });
                });
            });
        });
    }
}
