import { QuadTree, Rect, QuadTreeItem, RectLike } from './quad_tree';

// ─── Type Definitions ────────────────────────────────────────────────

type FrameSlot = 'prev' | 'curr' | 'next';

interface ReaderPadding {
    top: number;
    left: number;
    right: number;
    bottom: number;
}

interface ReaderTheme {
    zoom: number;
    paginationCss: string;
    variableCss: string;
    surfaceColor: string;
    onSurfaceColor: string;
    shouldOverrideTextColor: boolean;
    primaryColor: string;
    primaryContainerColor: string;
    onSurfaceVariantColor: string;
    outlineVariantColor: string;
    surfaceContainerColor: string;
    surfaceContainerHighColor: string;
    overrideFontFamily?: boolean;
    fontFileName?: string | null;
    overridePrimaryColor?: string | null;
}

interface ReaderConfig {
    safeWidth: number;
    safeHeight: number;
    direction: number;
    padding: ReaderPadding;
    theme: ReaderTheme;
}

interface ReaderState {
    frames: Record<FrameSlot, number>;
    anchors: Record<FrameSlot, string[]>;
    quadTree: QuadTree<InteractionItem> | null;
    config: ReaderConfig;
}

interface InteractionItem extends QuadTreeItem {
    type: string;
    rect: RectLike;
    data: string;
}

interface InitConfig {
    safeWidth?: number;
    safeHeight?: number;
    direction?: number;
    padding?: Partial<ReaderPadding>;
    theme: ReaderTheme;
}

interface ThemeUpdate {
    zoom: number;
    padding: ReaderPadding;
    shouldOverrideTextColor: boolean;
    fontFileName?: string | null;
    overrideFontFamily?: boolean;
    overridePrimaryColor?: string | null;
    primaryColor: string;
    primaryContainerColor: string;
    surfaceColor: string;
    onSurfaceColor: string;
    onSurfaceVariantColor: string;
    outlineVariantColor: string;
    surfaceContainerColor: string;
    surfaceContainerHighColor: string;
}

// WebKit-specific CSS properties not in the standard CSSStyleDeclaration
interface WebKitCSSStyle extends CSSStyleDeclaration {
    webkitColumnBreakBefore: string;
    webkitColumnBreakAfter: string;
}

// ─── EpubReader Class ────────────────────────────────────────────────

class EpubReader {
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
                    variableCss: '',
                    surfaceColor: '#FFFFFF',
                    onSurfaceColor: '#000000',
                    shouldOverrideTextColor: true,
                    primaryColor: '#000000',
                    primaryContainerColor: '#000000',
                    onSurfaceVariantColor: '#000000',
                    outlineVariantColor: '#000000',
                    surfaceContainerColor: '#000000',
                    surfaceContainerHighColor: '#000000',
                }
            }
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

    init(config: InitConfig): void {
        const padding = config.padding || {};

        this.state.config.safeWidth = Math.floor(config.safeWidth ?? 0);
        this.state.config.safeHeight = Math.floor(config.safeHeight ?? 0);
        this.state.config.direction = Number(config.direction) || 0;
        this.state.config.padding = {
            top: Number(padding.top ?? 0),
            left: Number(padding.left ?? 0),
            right: Number(padding.right ?? 0),
            bottom: Number(padding.bottom ?? 0)
        };
        this.state.config.theme = config.theme;

        this._updateCSSVariables(document, 'skeleton-variable-style');
        window.removeEventListener('resize', this._onResize);
        window.addEventListener('resize', this._onResize, { passive: true });
    }

    private _frameElement(slotOrId: string): HTMLIFrameElement | null {
        const id = slotOrId.startsWith('frame-') ? slotOrId : `frame-` + slotOrId;
        return document.getElementById(id) as HTMLIFrameElement | null;
    }

    private _slotFromFrameId(frameId: string): FrameSlot {
        return (frameId ? frameId.replace('frame-', '') : '') as FrameSlot;
    }

    private _getWidth(): number {
        return this.state.config.safeWidth;
    }

    private _getHeight(): number {
        return this.state.config.safeHeight;
    }

    private _isVertical(): boolean {
        return this.state.config.direction === 1;
    }

    private _scrollTo(iframe: HTMLIFrameElement, offset: number): void {
        if (!iframe || !iframe.contentWindow) return;

        const scrollOptions: ScrollToOptions = this._isVertical()
            ? { top: offset, left: 0, behavior: 'auto' }
            : { top: 0, left: offset, behavior: 'auto' };

        const doc = iframe.contentDocument!;
        doc.body.scrollTo(scrollOptions);
    }

    private _waitForAllResources(doc: Document): Promise<void> {
        const imagesReady = Promise.all(Array.from(doc.images).map((img) => {
            if (!img.src) return Promise.resolve();
            if (img.complete) return Promise.resolve();
            if (img.naturalHeight !== 0) return Promise.resolve();

            return new Promise<void>((resolve) => {
                const timer = setTimeout(() => {
                    img.removeEventListener('load', onLoadOrError);
                    img.removeEventListener('error', onLoadOrError);
                    console.warn('Image load timeout:', img.src);
                    resolve();
                }, 3000);

                const onLoadOrError = () => {
                    clearTimeout(timer);
                    resolve();
                };

                img.addEventListener('load', onLoadOrError, { once: true });
                img.addEventListener('error', onLoadOrError, { once: true });
            });
        }));
        const fontsReady = (doc.fonts && doc.fonts.ready)
            ? doc.fonts.ready
            : Promise.resolve();
        const allResources = Promise.all([imagesReady, fontsReady]);
        const masterTimeout = new Promise<void>((resolve) => {
            setTimeout(() => {
                resolve();
            }, 5000);
        });

        return Promise.race([allResources, masterTimeout]) as Promise<void>;
    }

    private _calculatePageCount(iframe: HTMLIFrameElement): number {
        if (!iframe || !iframe.contentDocument) return 0;

        if (this._isVertical()) {
            const scrollHeight = iframe.contentDocument.body.scrollHeight;
            const viewportHeight = this._getHeight();
            const pageCount = Math.round((scrollHeight + 128) / (viewportHeight + 128));
            return pageCount;
        } else {
            const scrollWidth = iframe.contentDocument.body.scrollWidth;
            const viewportWidth = this._getWidth();
            const pageCount = Math.round((scrollWidth + 128) / (viewportWidth + 128));
            return pageCount;
        }
    }

    private _calculateScrollOffset(pageIndex: number): number {
        if (this._isVertical()) {
            const viewportHeight = this._getHeight();
            const scrollTop = pageIndex * viewportHeight + (pageIndex * 128);
            return scrollTop;
        } else {
            const viewportWidth = this._getWidth();
            const scrollLeft = pageIndex * viewportWidth + (pageIndex * 128);
            return scrollLeft;
        }
    }

    private _convertToColumnBreak(value: string): string {
        switch (value) {
            case 'page':
            case 'right':
            case 'left':
                return 'always';
            case 'avoid':
                return 'avoid';
            case 'auto':
            default:
                return 'auto';
        }
    }

    private _applyRuleWithFixedValue(style: CSSStyleDeclaration, property: string): void {
        const value = style.getPropertyValue(property);
        if (value && !value.includes('calc')) {
            const match = value.trim().toLowerCase().match(/^(\d+(?:\.\d+)?)(px|pt)$/);
            if (match) {
                style.setProperty(
                    property,
                    'calc(' + value + ' * var(--lumina-zoom))',
                    style.getPropertyPriority(property)
                );
            }
        }
    }

    private _applyRules(style: CSSStyleDeclaration): void {
        this._applyRuleWithFixedValue(style, 'font-size');
        this._applyRuleWithFixedValue(style, 'line-height');
        const wkStyle = style as WebKitCSSStyle;
        if (style.breakBefore) wkStyle.webkitColumnBreakBefore = this._convertToColumnBreak(style.breakBefore);
        if (style.pageBreakBefore) wkStyle.webkitColumnBreakBefore = this._convertToColumnBreak(style.pageBreakBefore);
        if (style.breakAfter && style.breakAfter !== 'auto') wkStyle.webkitColumnBreakAfter = this._convertToColumnBreak(style.breakAfter);
        if (style.pageBreakAfter && style.pageBreakAfter !== 'auto') wkStyle.webkitColumnBreakAfter = this._convertToColumnBreak(style.pageBreakAfter);
    }

    private _polyfillCssSheets(doc: Document): void {
        for (let i = 0; i < doc.styleSheets.length; i++) {
            const sheet = doc.styleSheets[i];
            try {
                const rules = sheet.cssRules || (sheet as any).rules;
                if (!rules) continue;
                for (let j = 0; j < rules.length; j++) {
                    const rule = rules[j];
                    if (rule.type === 1) this._applyRules((rule as CSSStyleRule).style);
                }
            } catch (e) {
                console.error('Access to stylesheet blocked: ' + e);
            }
        }
    }

    private _polyfillCss(doc: Document): void {
        this._polyfillCssSheets(doc);
    }

    private _detectActiveAnchor(iframe: HTMLIFrameElement): void {
        if (!iframe || !iframe.contentDocument) return;
        if (iframe.id !== 'frame-curr') return;

        const anchors = this.state.anchors.curr;
        if (!anchors || anchors.length === 0) {
            return;
        }

        const doc = iframe.contentDocument;
        const activeAnchors: string[] = [];
        let lastPassedAnchor = 'top';
        const threshold = 50;

        const isVertical = this._isVertical();

        for (let i = 0; i < anchors.length; i++) {
            const anchorId = anchors[i];
            if (anchorId === 'top') {
                if (isVertical) {
                    if (doc.body.scrollTop < threshold) {
                        activeAnchors.push('top');
                    }
                } else {
                    if (doc.body.scrollLeft < threshold) {
                        activeAnchors.push('top');
                    }
                }
                continue;
            }

            const element = doc.getElementById(anchorId);

            if (element) {
                const rect = element.getBoundingClientRect();

                if (isVertical) {
                    if (rect.top < threshold && rect.bottom > threshold) {
                        activeAnchors.push(anchorId);
                    }
                    if (rect.top < threshold) {
                        lastPassedAnchor = anchorId;
                    }
                } else {
                    if (rect.left < threshold && rect.right > threshold) {
                        activeAnchors.push(anchorId);
                    }
                    if (rect.left < threshold) {
                        lastPassedAnchor = anchorId;
                    }
                }
            }
        }

        if (activeAnchors.length === 0 && lastPassedAnchor) {
            activeAnchors.push(lastPassedAnchor);
        }
        window.flutter_inappwebview.callHandler('onScrollAnchors', activeAnchors);
    }

    private _calculatePageIndexOfAnchor(iframe: HTMLIFrameElement, anchorId: string): number {
        if (!iframe || !iframe.contentDocument) return 0;
        const doc = iframe.contentDocument;
        const element = doc.getElementById(anchorId);
        if (!element) return 0;

        const bodyRect = doc.body.getBoundingClientRect();
        const rects = element.getClientRects();
        const elementRect = rects.length > 0 ? rects[0] : element.getBoundingClientRect();

        if (this._isVertical()) {
            const viewportHeight = this._getHeight();
            const absoluteTop = elementRect.top + doc.body.scrollTop - bodyRect.top + (elementRect.height / 5) + 1;
            const pageIndex = Math.floor((absoluteTop + 128) / (viewportHeight + 128));
            return pageIndex;
        } else {
            const viewportWidth = this._getWidth();
            const absoluteLeft = elementRect.left + doc.body.scrollLeft - bodyRect.left + (elementRect.width / 5) + 1;
            const pageIndex = Math.floor((absoluteLeft + 128) / (viewportWidth + 128));
            return pageIndex;
        }
    }

    private _extractTargetIdFromHref(href: string | null): string | null {
        if (!href || typeof href !== 'string') return null;
        const hashIndex = href.indexOf('#');
        if (hashIndex < 0 || hashIndex >= href.length - 1) return null;
        try {
            return decodeURIComponent(href.substring(hashIndex + 1));
        } catch (_) {
            return href.substring(hashIndex + 1);
        }
    }

    private _extractFootnoteHtml(targetId: string | null): string {
        const iframe = this._frameElement('curr');
        if (!iframe || !iframe.contentDocument) return '';

        const doc = iframe.contentDocument;
        if (!targetId) return '';

        const sanitizedId = String(targetId).replace(/^#/, '');
        if (!sanitizedId) return '';

        let footnoteEl: Element | null = doc.getElementById(sanitizedId);
        if (!footnoteEl) {
            // Fallback: some footnotes might not have an ID but can be referenced by name
            footnoteEl = doc.querySelector('[name="' + sanitizedId + '"]');
        }
        if (!footnoteEl) return '';

        // If the footnote element is empty, try to find the next sibling that has content (some footnotes are structured this way)
        if (footnoteEl.textContent!.trim() === '' && footnoteEl.nextElementSibling) {
            footnoteEl = footnoteEl.nextElementSibling;
        }

        const container = footnoteEl.closest('li, aside, section, div, p') || footnoteEl;
        return container && container.outerHTML ? container.outerHTML : '';
    }

    private _buildInteractionMap(): Promise<void> {
        const iframe = this._frameElement('curr');
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

            const width = Math.max(1, body.scrollWidth);
            const height = Math.max(1, body.scrollHeight);
            const quadTree = new QuadTree<InteractionItem>(new Rect(0, 0, width, height), 4);

            // Extract images and their positions to build the quad tree for hit testing
            const images = doc.querySelectorAll('img, image');
            const bodyRect = body.getBoundingClientRect();

            for (let i = 0; i < images.length; i++) {
                const img = images[i] as Element;
                if (!img) continue;

                const rect = img.getBoundingClientRect();
                if (!rect || rect.width < 5 || rect.height < 5) continue;

                const docX = rect.left + body.scrollLeft - bodyRect.left;
                const docY = rect.top + body.scrollTop - bodyRect.top;

                // zy-footnote support:
                // 1. img with zy-footnote attribute
                let isZyFootnote = false;
                if (img.hasAttribute('zy-footnote')) {
                    isZyFootnote = true;
                }

                // duokan footnote support:
                // 1. img with duokan-footnote class
                // 2. img with alt or title attribute within a link with duokan-footnote class
                //    and without epub:type="noteref" attribute and without href
                //    (to avoid conflict with regular footnotes)
                let isDuokanFootnote = false;
                if (!isZyFootnote) {
                    if (img.classList.contains('duokan-footnote')) {
                        isDuokanFootnote = true;
                    } else {
                        const closestLink = img.closest('a');
                        if (closestLink &&
                            closestLink.classList.contains('duokan-footnote') &&
                            !closestLink.hasAttribute('href') &&
                            !closestLink.hasAttribute('epub:type')) {
                            isDuokanFootnote = true;
                        }
                    }
                }
                if (isZyFootnote || isDuokanFootnote) {
                    let altText = '';
                    if (isZyFootnote) {
                        altText = img.getAttribute('zy-footnote') || '';
                    } else {
                        altText = img.getAttribute('alt') || img.getAttribute('title') || '';
                    }

                    quadTree.insert({
                        type: 'footnote',
                        rect: new Rect(docX, docY, rect.width, rect.height),
                        data: '<div>' + altText + '</div>',
                    });
                }
            }

            // Extract links to handle tap interactions
            const links = doc.querySelectorAll('a');

            for (let i = 0; i < links.length; i++) {
                const link = links[i];
                if (!link) continue;

                const href = link.getAttribute('href');
                const epubType = link.getAttribute('epub:type');
                let innerHtml = '';

                let isFootnote = false;

                if (!href && !link.classList.contains('duokan-footnote')) {
                    // duokan footnote support for links within <note> element
                    const noteAncestor = link.closest('note');
                    if (noteAncestor) {
                        // Find all aside elements within the note with epub:type="footnote" and concatenate their content as the footnote content
                        const asideElements = noteAncestor.querySelectorAll('aside');
                        for (let j = 0; j < asideElements.length; j++) {
                            innerHtml += asideElements[j].outerHTML;
                        }
                        isFootnote = true;
                    }
                } if (link.hasAttribute('title') && (!href || href === '#')) {
                    // Some footnotes use the link's title attribute to store the content instead of pointing to an element in the page
                    innerHtml = '<div class="footnote-content">' + link.getAttribute('title') + '</div>';
                    isFootnote = true;
                } else if (epubType === 'noteref') {
                    // find the best candidate element to represent the footnote content
                    const targetId = this._extractTargetIdFromHref(href);
                    innerHtml = this._extractFootnoteHtml(targetId);
                    isFootnote = true;
                } else if (link.classList.contains('duokan-footnote') && href && href.includes('#')) {
                    const fullHref = link.href;
                    let thisUrl = link.ownerDocument.location.href;
                    if (thisUrl.includes('#')) {
                        thisUrl = thisUrl.split('#')[0];
                    }
                    if (fullHref === thisUrl || thisUrl === fullHref.split('#')[0]) {
                        const targetId = this._extractTargetIdFromHref(href);
                        innerHtml = this._extractFootnoteHtml(targetId);
                        isFootnote = true;
                    }
                }

                if (!isFootnote || (!innerHtml || innerHtml.trim() === '')) {
                    continue;
                }

                const rects = link.getClientRects();
                for (let j = 0; j < rects.length; j++) {
                    const rect = rects[j];
                    if (!rect || rect.width < 5 || rect.height < 5) continue;

                    const docX = rect.left + body.scrollLeft - bodyRect.left;
                    const docY = rect.top + body.scrollTop - bodyRect.top;

                    quadTree.insert({
                        type: 'footnote',
                        rect: new Rect(docX, docY, rect.width, rect.height),
                        data: innerHtml,
                    });
                }
            }

            // Aozora Bunko style footnotes
            const aozoraNotes = doc.querySelectorAll('span.notes, .notes');
            for (let i = 0; i < aozoraNotes.length; i++) {
                const noteSpan = aozoraNotes[i];
                if (!noteSpan) continue;
                const innerHtml = '<div class="aozora-footnote-content">' + noteSpan.innerHTML + '</div>';
                const rects = noteSpan.getClientRects();

                for (let j = 0; j < rects.length; j++) {
                    const rect = rects[j];
                    if (!rect || rect.width < 5 || rect.height < 5) continue;

                    const docX = rect.left + body.scrollLeft - bodyRect.left;
                    const docY = rect.top + body.scrollTop - bodyRect.top;

                    quadTree.insert({
                        type: 'footnote',
                        rect: new Rect(docX, docY, rect.width, rect.height),
                        data: innerHtml,
                    });
                }
            }

            this.state.quadTree = quadTree;

            resolve();
        });
    }

    private _getOriginalBackgroundColor(iframe: HTMLIFrameElement): string | null {
        if (!iframe || !iframe.contentDocument) return null;
        const doc = iframe.contentDocument;
        const win = iframe.contentWindow!;
        const bgColor = win.getComputedStyle(doc.body).backgroundColor;
        if (bgColor && bgColor !== 'rgba(0, 0, 0, 0)' && bgColor !== 'transparent') {
            return bgColor;
        }
        return null;
    }

    private _applyOriginalBackgroundColor(): void {
        const iframe = this._frameElement('curr');
        if (!iframe) return;
        const originalBgColor = this._getOriginalBackgroundColor(iframe);
        if (originalBgColor) {
            document.documentElement.style.setProperty('--lumina-epub-original-bg-color', originalBgColor);
        } else {
            document.documentElement.style.removeProperty('--lumina-epub-original-bg-color');
        }
    }

    private _onFrameLoad(iframe: HTMLIFrameElement): void {
        if (!iframe || !iframe.contentDocument) return;

        const doc = iframe.contentDocument;

        // check if style already exists (e.g. from previous load), if so update it, otherwise create new
        const existingVariableStyle = doc.getElementById('injected-variable-style');
        if (existingVariableStyle) {
            this._updateCSSVariables(doc, 'injected-variable-style');
        } else {
            const variableStyle = doc.createElement('style');
            variableStyle.id = 'injected-variable-style';
            variableStyle.innerHTML = this.state.config.theme.variableCss;
            doc.head.appendChild(variableStyle);

            const originalBgColor = this._getOriginalBackgroundColor(iframe);
            if (this.state.config.theme.shouldOverrideTextColor && originalBgColor == null) {
                doc.body.classList.add('lumina-override-color');
            } else {
                doc.body.classList.remove('lumina-override-color');
            }

            if (this.state.config.theme.overrideFontFamily && this.state.config.theme.fontFileName) {
                doc.body.classList.add('lumina-override-font');
            } else {
                doc.body.classList.remove('lumina-override-font');
            }

            if (this._isVertical()) {
                doc.body.classList.add('is-vertical');
            } else {
                doc.body.classList.remove('is-vertical');
            }
        }

        const existingPaginationStyle = doc.getElementById('injected-pagination-style');
        if (existingPaginationStyle) {
            existingPaginationStyle.innerHTML = this.state.config.theme.paginationCss;
        } else {
            const style = doc.createElement('style');
            style.id = 'injected-pagination-style';
            style.innerHTML = this.state.config.theme.paginationCss;
            doc.head.appendChild(style);

            // Apply polyfill for break properties to support more pagination-related CSS in WebKit-based browsers (like iOS)
            this._polyfillCss(doc);

            // Apply original background color of the page to the iframe
            this._applyOriginalBackgroundColor();
        }

        this._waitForAllResources(doc).then(() => {
            if (!iframe.contentWindow) return;

            // Force reflow to ensure styles are applied before calculating page count and scroll offset
            const _forceReflow = doc.body.scrollHeight;
            void _forceReflow;
            requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                    const pageCount = this._calculatePageCount(iframe);
                    const slot = this._slotFromFrameId(iframe.id);
                    this.state.frames[slot] = pageCount;

                    let pageIndex = 0;
                    const url = iframe.src;
                    if (url && url.includes('#')) {
                        const anchor = url.split('#')[1];
                        pageIndex = this._calculatePageIndexOfAnchor(iframe, anchor);
                        const offset = this._calculateScrollOffset(pageIndex);
                        this._scrollTo(iframe, offset);
                    }
                    this._buildInteractionMap().then(() => {
                        if (iframe.id === 'frame-curr') {
                            window.flutter_inappwebview.callHandler('onPageCountReady', pageCount);
                            window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);
                            window.flutter_inappwebview.callHandler('onRendererInitialized');
                        } else if (iframe.id === 'frame-prev') {
                            // Jump to the end of the previous frame to prepare for smooth transition when user cycles frames
                            this.jumpToLastPageOfFrame('prev');
                        } else if (iframe.id === 'frame-next') {
                            // Jump to the start of the next frame to prepare for smooth transition when user cycles frames
                            this.jumpToPageFor('next', 0);
                        }

                        this._detectActiveAnchor(iframe);
                    });
                });
            });
        });
    }

    loadFrame(slot: FrameSlot, url: string, anchors?: string[]): void {
        const iframe = this._frameElement(slot);
        if (!iframe) return;

        this.state.anchors[slot] = anchors || [];
        iframe.onload = null;

        if (iframe.src == null || iframe.src === '' || iframe.src === 'about:blank') {
            iframe.onload = () => {
                this._onFrameLoad(iframe);
            };
            iframe.src = url;
        } else {
            const currentUrl = new URL(iframe.src);
            const newUrl = new URL(url);
            if (currentUrl.origin === newUrl.origin && currentUrl.pathname === newUrl.pathname) {
                iframe.onload = () => {
                    this._onFrameLoad(iframe);
                };
                iframe.src = url;
                this._onFrameLoad(iframe);
            } else {
                iframe.onload = () => {
                    this._onFrameLoad(iframe);
                };
                iframe.src = url;
            }
        }
    }

    // Reload the iframe to apply new theme or settings while preserving the current page index
    private _reloadFrame(iframe: HTMLIFrameElement, pageIndexPercentage: number, token: string): void {
        if (!iframe || !iframe.contentDocument) return;
        const doc = iframe.contentDocument;

        if (!iframe.contentWindow) return;

        this._applyOriginalBackgroundColor();

        this._waitForAllResources(doc).then(() => {
            // Force reflow to ensure styles are applied before calculating page count and scroll offset
            const _forceReflow = doc.body.scrollHeight;
            void _forceReflow;

            requestAnimationFrame(() => {
                requestAnimationFrame(() => {
                    const pageCount = this._calculatePageCount(iframe);
                    const slot = this._slotFromFrameId(iframe.id);
                    this.state.frames[slot] = pageCount;

                    const pageIndex = Math.round(pageIndexPercentage * pageCount);
                    const scrollOffset = this._calculateScrollOffset(pageIndex);
                    this._scrollTo(iframe, scrollOffset);
                    this._buildInteractionMap().then(() => {
                        if (iframe.id === 'frame-curr') {
                            window.flutter_inappwebview.callHandler('onPageCountReady', pageCount);
                            window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);
                            window.flutter_inappwebview.callHandler('onRendererInitialized');
                        } else if (iframe.id === 'frame-prev') {
                            // Jump to the end of the previous frame to prepare for smooth transition when user cycles frames
                            this.jumpToLastPageOfFrame('prev');
                        } else if (iframe.id === 'frame-next') {
                            // Jump to the start of the next frame to prepare for smooth transition when user cycles frames
                            this.jumpToPageFor('next', 0);
                        }

                        this._detectActiveAnchor(iframe);

                        requestAnimationFrame(() => {
                            window.flutter_inappwebview.callHandler('onEventFinished', token);
                        });
                    });
                });
            });
        });
    }

    jumpToPage(pageIndex: number): void {
        const iframe = this._frameElement('curr');
        if (!iframe || !iframe.contentWindow) return;

        const scrollOffset = this._calculateScrollOffset(pageIndex);
        this._scrollTo(iframe, scrollOffset);

        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);
                this._detectActiveAnchor(iframe);
            });
        });
    }

    jumpToPageFor(slot: FrameSlot, pageIndex: number): void {
        const iframe = this._frameElement(slot);
        if (!iframe || !iframe.contentWindow) return;

        const scrollOffset = this._calculateScrollOffset(pageIndex);
        this._scrollTo(iframe, scrollOffset);

        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                if (iframe.id === 'frame-curr') {
                    window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);
                }
                this._detectActiveAnchor(iframe);
            });
        });
    }

    restoreScrollPosition(ratio: number): void {
        const pageCount = this.state.frames.curr;
        const pageIndex = Math.round(ratio * pageCount);

        this.jumpToPage(pageIndex);
    }

    private _calculateCurrentPageIndex(): number {
        const iframe = this._frameElement('curr');
        if (!iframe || !iframe.contentWindow || !iframe.contentDocument) return 0;

        if (this._isVertical()) {
            const scrollTop = iframe.contentDocument.body.scrollTop || 0;
            const viewportHeight = this._getHeight();
            const pageIndex = Math.round((scrollTop + 128) / (viewportHeight + 128));
            return pageIndex;
        } else {
            const scrollLeft = iframe.contentDocument.body.scrollLeft;
            const viewportWidth = this._getWidth();
            const pageIndex = Math.round((scrollLeft + 128) / (viewportWidth + 128));
            return pageIndex;
        }
    }

    private _updatePageState(iframeId: string): void {
        const iframe = this._frameElement(iframeId);
        if (!iframe || !iframe.contentWindow) return;

        const pageCount = this._calculatePageCount(iframe);
        const slot = this._slotFromFrameId(iframeId);
        this.state.frames[slot] = pageCount;

        if (iframeId === 'frame-curr') {
            window.flutter_inappwebview.callHandler('onPageCountReady', pageCount);
            window.flutter_inappwebview.callHandler('onPageChanged', this._calculateCurrentPageIndex());
        } else if (iframeId === 'frame-prev') {
            // Jump to the end of the previous frame to prepare for smooth transition when user cycles frames
            this.jumpToLastPageOfFrame('prev');
        } else if (iframeId === 'frame-next') {
            // Jump to the start of the next frame to prepare for smooth transition when user cycles frames
            this.jumpToPageFor('next', 0);
        }
    }

    cycleFrames(direction: 'next' | 'prev'): void {
        const elPrev = this._frameElement('prev');
        const elCurr = this._frameElement('curr');
        const elNext = this._frameElement('next');

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

        // Apply original background color of the page to the iframe
        this._applyOriginalBackgroundColor();

        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                this._updatePageState('frame-curr');
                this._updatePageState('frame-prev');
                this._updatePageState('frame-next');
                this._detectActiveAnchor(elPrev);
                this._detectActiveAnchor(elCurr);
                this._detectActiveAnchor(elNext);
                this._buildInteractionMap();
            });
        });
    }

    jumpToLastPageOfFrame(slot: FrameSlot): void {
        const pageCount = this.state.frames[slot] ?? 0;
        this.jumpToPageFor(slot, pageCount - 1);
    }

    private _updateCSSVariables(doc: Document, styleId: string = 'injected-variable-style', iframe: HTMLIFrameElement | null = null): void {
        const root = doc.documentElement;
        const body = doc.body;

        root.style.setProperty('--lumina-zoom', String(this.state.config.theme.zoom));
        root.style.setProperty('--lumina-safe-width', this.state.config.safeWidth + 'px');
        root.style.setProperty('--lumina-safe-height', this.state.config.safeHeight + 'px');
        root.style.setProperty('--lumina-padding-top', this.state.config.padding.top + 'px');
        root.style.setProperty('--lumina-padding-left', this.state.config.padding.left + 'px');
        root.style.setProperty('--lumina-padding-right', this.state.config.padding.right + 'px');
        root.style.setProperty('--lumina-padding-bottom', this.state.config.padding.bottom + 'px');
        root.style.setProperty('--lumina-reader-overflow-x', this._isVertical() ? 'hidden' : 'auto');
        root.style.setProperty('--lumina-reader-overflow-y', this._isVertical() ? 'auto' : 'hidden');

        root.style.setProperty('--lumina-surface-color', this.state.config.theme.surfaceColor);
        root.style.setProperty('--lumina-on-surface-color', this.state.config.theme.onSurfaceColor);
        root.style.setProperty('--lumina-primary-color', this.state.config.theme.primaryColor);
        root.style.setProperty('--lumina-primary-container', this.state.config.theme.primaryContainerColor);
        root.style.setProperty('--lumina-on-surface-variant', this.state.config.theme.onSurfaceVariantColor);
        root.style.setProperty('--lumina-outline-variant', this.state.config.theme.outlineVariantColor);
        root.style.setProperty('--lumina-surface-container', this.state.config.theme.surfaceContainerColor);
        root.style.setProperty('--lumina-surface-container-high', this.state.config.theme.surfaceContainerHighColor);

        if (iframe != null) {
            const originalBgColor = this._getOriginalBackgroundColor(iframe);
            if (this.state.config.theme.shouldOverrideTextColor && originalBgColor == null) {
                body.classList.add('lumina-override-color');
            } else {
                body.classList.remove('lumina-override-color');
            }

            if (this.state.config.theme.overrideFontFamily && this.state.config.theme.fontFileName) {
                body.classList.add('lumina-override-font');
            } else {
                body.classList.remove('lumina-override-font');
            }
        } else {
            if (this.state.config.theme.shouldOverrideTextColor) {
                body.classList.add('lumina-override-color');
            } else {
                body.classList.remove('lumina-override-color');
            }

            if (this.state.config.theme.overrideFontFamily && this.state.config.theme.fontFileName) {
                body.classList.add('lumina-override-font');
            } else {
                body.classList.remove('lumina-override-font');
            }
        }

        const existingStyle = doc.getElementById(styleId);
        if (existingStyle) {
            existingStyle.innerHTML = this.state.config.theme.variableCss;
        }
    }

    private _generateVariableStyle(): string {
        const zoomItem = '--lumina-zoom: ' + this.state.config.theme.zoom + ';';
        const safeWidthItem = '--lumina-safe-width: ' + this.state.config.safeWidth + 'px;';
        const safeHeightItem = '--lumina-safe-height: ' + this.state.config.safeHeight + 'px;';
        const paddingTopItem = '--lumina-padding-top: ' + this.state.config.padding.top + 'px;';
        const paddingLeftItem = '--lumina-padding-left: ' + this.state.config.padding.left + 'px;';
        const paddingRightItem = '--lumina-padding-right: ' + this.state.config.padding.right + 'px;';
        const paddingBottomItem = '--lumina-padding-bottom: ' + this.state.config.padding.bottom + 'px;';
        const readerOverflowXItem = '--lumina-reader-overflow-x: ' + (this._isVertical() ? 'hidden' : 'auto') + ';';
        const readerOverflowYItem = '--lumina-reader-overflow-y: ' + (this._isVertical() ? 'auto' : 'hidden') + ';';

        const surfaceColorItem = '--lumina-surface-color: ' + this.state.config.theme.surfaceColor + ';';
        const onSurfaceColorItem = '--lumina-on-surface-color: ' + this.state.config.theme.onSurfaceColor + ';';
        const primaryColorItem = '--lumina-primary-color: ' + this.state.config.theme.primaryColor + ';';
        const primaryContainerItem = '--lumina-primary-container-color: ' + this.state.config.theme.primaryContainerColor + ';';
        const onSurfaceVariantItem = '--lumina-on-surface-variant-color: ' + this.state.config.theme.onSurfaceVariantColor + ';';
        const outlineVariantItem = '--lumina-outline-variant-color: ' + this.state.config.theme.outlineVariantColor + ';';
        const surfaceContainerItem = '--lumina-surface-container-color: ' + this.state.config.theme.surfaceContainerColor + ';';
        const surfaceContainerHighItem = '--lumina-surface-container-high-color: ' + this.state.config.theme.surfaceContainerHighColor + ';';

        const fontFaceBlock = this.state.config.theme.fontFileName
            ? '@font-face { font-family: \'LuminaCustomFont\'; src: url(\'epub://localhost/fonts/' + this.state.config.theme.fontFileName + '\'); }'
            : '';
        const fontFamilyItem = this.state.config.theme.fontFileName
            ? '--lumina-font-family: \'LuminaCustomFont\';'
            : '';

        return fontFaceBlock + ' :root {'
            + zoomItem
            + safeWidthItem
            + safeHeightItem
            + paddingTopItem
            + paddingLeftItem
            + paddingRightItem
            + paddingBottomItem
            + readerOverflowXItem
            + readerOverflowYItem
            + surfaceColorItem
            + onSurfaceColorItem
            + primaryColorItem
            + primaryContainerItem
            + onSurfaceVariantItem
            + outlineVariantItem
            + surfaceContainerItem
            + surfaceContainerHighItem
            + fontFamilyItem
            + '}';
    }

    updateTheme(token: string, viewWidth: number, viewHeight: number, newTheme: ThemeUpdate): void {
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
        if (newTheme.overridePrimaryColor) {
            this.state.config.theme.primaryColor = newTheme.overridePrimaryColor;
        } else {
            this.state.config.theme.primaryColor = newTheme.primaryColor;
        }
        this.state.config.theme.primaryContainerColor = newTheme.primaryContainerColor;
        this.state.config.theme.surfaceColor = newTheme.surfaceColor;
        this.state.config.theme.onSurfaceColor = newTheme.onSurfaceColor;
        this.state.config.theme.onSurfaceVariantColor = newTheme.onSurfaceVariantColor;
        this.state.config.theme.outlineVariantColor = newTheme.outlineVariantColor;
        this.state.config.theme.surfaceContainerColor = newTheme.surfaceContainerColor;
        this.state.config.theme.surfaceContainerHighColor = newTheme.surfaceContainerHighColor;

        this.state.config.theme.variableCss = this._generateVariableStyle();

        this._updateCSSVariables(document, 'skeleton-variable-style');

        const iframes = document.getElementsByTagName('iframe');
        for (let i = 0; i < iframes.length; i++) {
            const iframe = iframes[i];
            if (iframe && iframe.contentDocument) {
                const doc = iframe.contentDocument;
                void doc;
                const pageIndex = this._calculateCurrentPageIndex();
                const pageCount = this._calculatePageCount(iframe);
                const pageIndexPercentage = pageCount > 0 ? pageIndex / pageCount : 0;
                this._updateCSSVariables(doc, 'injected-variable-style', iframe);
                requestAnimationFrame(() => {
                    this._reloadFrame(iframe, pageIndexPercentage, token);
                });
            }
        }
    }

    private _checkElementAt(x: number, y: number, checkIfAllowed?: (candidate: InteractionItem) => boolean): InteractionItem | undefined {
        const relX = x - this.state.config.padding.left;
        const relY = y - this.state.config.padding.top;

        const iframe = this._frameElement('curr');
        if (!iframe || !iframe.contentDocument || !this.state.quadTree) return;

        const doc = iframe.contentDocument;
        const body = doc.body;
        if (!body) return;

        const docX = relX + body.scrollLeft;
        const docY = relY + body.scrollTop;

        // HIG
        const radius = 20;
        const queryRect = new Rect(docX - radius, docY - radius, radius * 2, radius * 2);
        const candidates = this.state.quadTree.query(queryRect, []);

        let bestCandidate: InteractionItem | undefined;
        let minDistance = Infinity;

        for (let i = candidates.length - 1; i >= 0; i--) {
            const candidate = candidates[i];
            if (!candidate || !candidate.rect) continue;
            if (checkIfAllowed && !checkIfAllowed(candidate)) continue;

            const rect = new Rect(
                candidate.rect.x,
                candidate.rect.y,
                candidate.rect.width,
                candidate.rect.height,
            );

            // Calculate distance from the tap point to the center of the candidate rect
            let distance: number;
            if (rect.contains({ x: docX, y: docY })) {
                distance = 0;
            } else {
                const centerX = rect.x + rect.width / 2;
                const centerY = rect.y + rect.height / 2;
                const dx = docX - centerX;
                const dy = docY - centerY;
                distance = Math.sqrt(dx * dx + dy * dy);
            }

            // Prioritize candidates based on distance to the tap point
            if (distance < minDistance) {
                minDistance = distance;
                bestCandidate = candidate;
            }
        }

        return bestCandidate;
    }

    checkLinkAt(x: number, y: number): boolean {
        const iframe = this._frameElement('curr');
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
        const bestCandidate = this._checkElementAt(x, y, (candidate) => {
            if (candidate.type === 'footnote') {
                return true;
            }
            return false;
        });

        if (bestCandidate) {
            const iframe = this._frameElement('curr');
            if (!iframe || !iframe.contentDocument) return;
            const doc = iframe.contentDocument;
            const body = doc.body;
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

        if (this.checkLinkAt(x, y)) {
            return;
        }

        // Fall back to just sending tap coordinates if no interactive element is found nearby
        window.flutter_inappwebview.callHandler('onTap', x, y);
    }

    checkImageAt(x: number, y: number): boolean {
        const iframe = this._frameElement('curr');
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
                        // to absolute URL
                        const link = doc.createElement('a');
                        link.href = src;
                        src = link.href;

                        const rect = imgEl.getBoundingClientRect();
                        if (!rect || rect.width < 5 || rect.height < 5) return false;

                        const docX = rect.left - bodyRect.left + this.state.config.padding.left;
                        const docY = rect.top - bodyRect.top + this.state.config.padding.top;

                        // Notify Flutter of the image long press with the image source and the tap coordinates
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

    waitForRender(token: string): void {
        requestAnimationFrame(function () {
            requestAnimationFrame(function () {
                window.flutter_inappwebview.callHandler('onEventFinished', token);
            });
        });
    }
}

(window as any).reader = new EpubReader();
