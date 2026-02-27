class Rect {
  constructor(x, y, width, height) {
    this.x = Number(x) || 0;
    this.y = Number(y) || 0;
    this.width = Math.max(0, Number(width) || 0);
    this.height = Math.max(0, Number(height) || 0);
  }

  contains(point) {
    if (!point) return false;
    return (
      point.x >= this.x &&
      point.x <= this.x + this.width &&
      point.y >= this.y &&
      point.y <= this.y + this.height
    );
  }

  intersects(other) {
    if (!other) return false;
    return !(
      other.x > this.x + this.width ||
      other.x + other.width < this.x ||
      other.y > this.y + this.height ||
      other.y + other.height < this.y
    );
  }
}

class QuadTree {
  constructor(boundary, capacity = 4) {
    this.boundary = boundary;
    this.capacity = Math.max(1, Number(capacity) || 4);
    this.items = [];
    this.divided = false;
    this.northwest = null;
    this.northeast = null;
    this.southwest = null;
    this.southeast = null;
  }

  _toRect(rawRect) {
    if (!rawRect) return null;
    return new Rect(rawRect.x, rawRect.y, rawRect.width, rawRect.height);
  }

  _subdivide() {
    const x = this.boundary.x;
    const y = this.boundary.y;
    const w = this.boundary.width / 2;
    const h = this.boundary.height / 2;

    this.northwest = new QuadTree(new Rect(x, y, w, h), this.capacity);
    this.northeast = new QuadTree(new Rect(x + w, y, w, h), this.capacity);
    this.southwest = new QuadTree(new Rect(x, y + h, w, h), this.capacity);
    this.southeast = new QuadTree(new Rect(x + w, y + h, w, h), this.capacity);
    this.divided = true;
  }

  insert(item) {
    if (!item || !item.rect) return false;

    const rect = this._toRect(item.rect);
    if (!rect || !this.boundary.intersects(rect)) return false;

    if (!this.divided && this.items.length < this.capacity) {
      this.items.push(item);
      return true;
    }

    if (!this.divided) {
      this._subdivide();
      const existing = this.items;
      this.items = [];
      for (let i = 0; i < existing.length; i++) {
        this._insertIntoChildren(existing[i]);
      }
    }

    return this._insertIntoChildren(item);
  }

  _insertIntoChildren(item) {
    let inserted = false;
    if (this.northwest.insert(item)) inserted = true;
    if (this.northeast.insert(item)) inserted = true;
    if (this.southwest.insert(item)) inserted = true;
    if (this.southeast.insert(item)) inserted = true;
    return inserted;
  }

  query(range, found = []) {
    if (!range || !this.boundary.intersects(range)) return found;

    for (let i = 0; i < this.items.length; i++) {
      const item = this.items[i];
      const rect = this._toRect(item.rect);
      if (rect && range.intersects(rect)) {
        found.push(item);
      }
    }

    if (this.divided) {
      this.northwest.query(range, found);
      this.northeast.query(range, found);
      this.southwest.query(range, found);
      this.southeast.query(range, found);
    }

    return found;
  }
}

class EpubReader {
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

  init(config = {}) {
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

  _frameElement(slotOrId) {
    const id = slotOrId.startsWith('frame-') ? slotOrId : `frame-` + slotOrId;
    return document.getElementById(id);
  }

  _slotFromFrameId(frameId) {
    return frameId ? frameId.replace('frame-', '') : '';
  }

  _getWidth() {
    return this.state.config.safeWidth;
  }

  _getHeight() {
    return this.state.config.safeHeight;
  }

  _isVertical() {
    return this.state.config.direction === 1;
  }

  _scrollTo(iframe, offset) {
    if (!iframe || !iframe.contentWindow) return;

    const scrollOptions = this._isVertical()
      ? { top: offset, left: 0, behavior: 'auto' }
      : { top: 0, left: offset, behavior: 'auto' };

    const doc = iframe.contentDocument;
    doc.body.scrollTo(scrollOptions);
  }

  _waitForAllResources(doc) {
    const imagesReady = Promise.all(Array.from(doc.images).map((img) => {
      if (img.complete && img.naturalHeight !== 0) return Promise.resolve();
      return new Promise((resolve) => {
        img.onload = img.onerror = resolve;
      });
    }));

    const fontsReady = doc.fonts.ready;

    return Promise.all([
      imagesReady,
      fontsReady,
    ]);
  }

  _calculatePageCount(iframe) {
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

  _calculateScrollOffset(pageIndex) {
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

  _convertToColumnBreak(value) {
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

  _applyRules(style) {
    if (style.fontSize && !style.fontSize.includes('calc')) {
      const match = style.fontSize.trim().toLowerCase().match(/^(\d+(?:\.\d+)?)(px|pt)$/);
      if (match) {
        style.setProperty(
          'font-size',
          `calc(${match[0]} * var(--lumina-zoom))`,
          style.getPropertyPriority('font-size')
        );
      }
    }

    if (style.breakBefore) style.webkitColumnBreakBefore = this._convertToColumnBreak(style.breakBefore);
    if (style.pageBreakBefore) style.webkitColumnBreakBefore = this._convertToColumnBreak(style.pageBreakBefore);
    if (style.breakAfter && style.breakAfter !== 'auto') style.webkitColumnBreakAfter = this._convertToColumnBreak(style.breakAfter);
    if (style.pageBreakAfter && style.pageBreakAfter !== 'auto') style.webkitColumnBreakAfter = this._convertToColumnBreak(style.pageBreakAfter);
  }

  _polyfillCssSheets(doc) {
    for (let sheet of doc.styleSheets) {
      try {
        const rules = sheet.cssRules || sheet.rules;
        if (!rules) continue;
        for (let rule of rules) {
          if (rule.type === 1) this._applyRules(rule.style); // 1 = CSSStyleRule
        }
      } catch (e) {
        console.error('Access to stylesheet blocked: ' + e);
      }
    }
  }

  _polyfillCss(doc) {
    this._polyfillCssSheets(doc);
  }

  _detectActiveAnchor(iframe) {
    if (!iframe || !iframe.contentDocument) return;
    if (iframe.id !== 'frame-curr') return;

    const anchors = this.state.anchors.curr;
    if (!anchors || anchors.length === 0) {
      return;
    }

    const doc = iframe.contentDocument;
    const activeAnchors = [];
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

  _calculatePageIndexOfAnchor(iframe, anchorId) {
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

  _extractTargetIdFromHref(href) {
    if (!href || typeof href !== 'string') return null;
    const hashIndex = href.indexOf('#');
    if (hashIndex < 0 || hashIndex >= href.length - 1) return null;
    try {
      return decodeURIComponent(href.substring(hashIndex + 1));
    } catch (_) {
      return href.substring(hashIndex + 1);
    }
  }

  _extractFootnoteHtml(targetId) {
    const iframe = this._frameElement('curr');
    if (!iframe || !iframe.contentDocument) return '';

    const doc = iframe.contentDocument;
    if (!targetId) return '';

    const sanitizedId = String(targetId).replace(/^#/, '');
    if (!sanitizedId) return '';

    let footnoteEl = doc.getElementById(sanitizedId);
    if (!footnoteEl) {
      // Fallback: some footnotes might not have an ID but can be referenced by name
      footnoteEl = doc.querySelector('[name="' + sanitizedId + '"]');
    }
    if (!footnoteEl) return '';

    // If the footnote element is empty, try to find the next sibling that has content (some footnotes are structured this way)
    if (footnoteEl.textContent.trim() === '' && footnoteEl.nextElementSibling) {
      footnoteEl = footnoteEl.nextElementSibling;
    }

    const container = footnoteEl.closest('li, aside, section, div, p') || footnoteEl;
    return container && container.outerHTML ? container.outerHTML : '';
  }

  _buildInteractionMap() {
    const iframe = this._frameElement('curr');
    if (!iframe || !iframe.contentDocument) {
      this.state.quadTree = null;
      return;
    }

    const doc = iframe.contentDocument;

    requestAnimationFrame(() => {
      const body = doc.body;
      if (!body) {
        this.state.quadTree = null;
        return;
      }

      const width = Math.max(1, body.scrollWidth);
      const height = Math.max(1, body.scrollHeight);
      const quadTree = new QuadTree(new Rect(0, 0, width, height), 4);

      // Extract images and their positions to build the quad tree for hit testing
      const images = doc.querySelectorAll('img, image');
      const bodyRect = body.getBoundingClientRect();

      for (let i = 0; i < images.length; i++) {
        const img = images[i];
        if (!img) continue;

        const rect = img.getBoundingClientRect();
        if (!rect || rect.width < 5 || rect.height < 5) continue;

        const docX = rect.left + body.scrollLeft - bodyRect.left;
        const docY = rect.top + body.scrollTop - bodyRect.top;

        // duokan
        if (img.classList.contains('duokan-footnote')) {
          const altText = img.getAttribute('alt') || img.getAttribute('title') || '';

          quadTree.insert({
            type: 'footnote',
            rect: {
              x: docX,
              y: docY,
              width: rect.width,
              height: rect.height,
            },
            data: '<div class="duokan-footnote-content">' + altText + '</div>',
          });

          continue;
        }

        let src = img.currentSrc || img.src || img.getAttribute('xlink:href') || '';

        // to absolute URL
        const link = doc.createElement('a');
        link.href = src;
        src = link.href;

        quadTree.insert({
          type: 'image',
          rect: {
            x: docX,
            y: docY,
            width: rect.width,
            height: rect.height,
          },
          data: src,
        });
      }

      // Extract links to handle tap interactions
      const links = doc.querySelectorAll('a[href]');
      const currentDocBaseUrl = doc.location.href.split('#')[0];

      for (let i = 0; i < links.length; i++) {
        const link = links[i];
        if (!link) continue;

        const href = link.getAttribute('href');
        const fullHref = link.href;
        const epubType = link.getAttribute('epub:type');
        let innerHtml = '';

        let isFootnote = false;

        if (link.hasAttribute('title') && (!href || href === '#')) {
          // Some footnotes use the link's title attribute to store the content instead of pointing to an element in the page
          innerHtml = '<div class="footnote-content">' + link.getAttribute('title') + '</div>';
          isFootnote = true;
        } else if (epubType === 'noteref') {
          // find the best candidate element to represent the footnote content
          const targetId = this._extractTargetIdFromHref(href);
          innerHtml = this._extractFootnoteHtml(targetId);
          isFootnote = true;
        } else {
          // Regular link
        }

        if (isFootnote && (!innerHtml || innerHtml.trim() === '')) {
          continue;
        }

        const rects = link.getClientRects();

        for (let j = 0; j < rects.length; j++) {
          const rect = rects[j];
          if (!rect || rect.width < 5 || rect.height < 5) continue;

          const docX = rect.left + body.scrollLeft - bodyRect.left;
          const docY = rect.top + body.scrollTop - bodyRect.top;

          if (isFootnote) {
            quadTree.insert({
              type: 'footnote',
              rect: {
                x: docX,
                y: docY,
                width: rect.width,
                height: rect.height,
              },
              data: innerHtml,
            });
          } else {
            quadTree.insert({
              type: 'link',
              rect: {
                x: docX,
                y: docY,
                width: rect.width,
                height: rect.height,
              },
              data: fullHref,
            });
          }
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
            rect: {
              x: docX,
              y: docY,
              width: rect.width,
              height: rect.height,
            },
            data: innerHtml,
          });
        }
      }

      this.state.quadTree = quadTree;
    });
  }

  _onFrameLoad(iframe) {
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

      if (this.state.config.theme.shouldOverrideTextColor) {
        doc.body.classList.add('lumina-override-color');
      } else {
        doc.body.classList.remove('lumina-override-color');
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
    }

    const timeout = new Promise((resolve) => setTimeout(resolve, 3000));

    Promise.race([
      this._waitForAllResources(doc),
      timeout
    ]).then(() => {
      if (!iframe.contentWindow) return;

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

        this._buildInteractionMap();

        requestAnimationFrame(() => {
          this._detectActiveAnchor(iframe);
        });
      });
    });
  }

  loadFrame(slot, url, anchors) {
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
  _reloadFrame(iframe, pageIndexPercentage) {
    if (!iframe || !iframe.contentDocument) return;
    const doc = iframe.contentDocument;

    if (!iframe.contentWindow) return;

    requestAnimationFrame(() => {
      const pageCount = this._calculatePageCount(iframe);
      const slot = this._slotFromFrameId(iframe.id);
      this.state.frames[slot] = pageCount;

      const pageIndex = Math.round(pageIndexPercentage * pageCount);
      const scrollOffset = this._calculateScrollOffset(pageIndex);
      this._scrollTo(iframe, scrollOffset);

      if (iframe.id === 'frame-curr') {
        window.flutter_inappwebview.callHandler('onPageCountReady', pageCount);
        window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);
        window.flutter_inappwebview.callHandler('onRendererInitialized');
      } else if (iframe.id === 'frame-prev') {
        // Jump to the end of the previous frame to prepare for smooth transition when user cycles frames
        this.jumpToLastPageOfFrame(iframe);
      } else if (iframe.id === 'frame-next') {
        // Jump to the start of the next frame to prepare for smooth transition when user cycles frames
        this.jumpToPageFor('next', 0);
      }

      this._buildInteractionMap();

      requestAnimationFrame(() => {
        this._detectActiveAnchor(iframe);
      });
    });
  }

  jumpToPage(pageIndex) {
    const iframe = this._frameElement('curr');
    if (!iframe || !iframe.contentWindow) return;

    const scrollOffset = this._calculateScrollOffset(pageIndex);
    this._scrollTo(iframe, scrollOffset);

    requestAnimationFrame(() => {
      window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);
      this._detectActiveAnchor(iframe);
    });
  }

  jumpToPageFor(slot, pageIndex) {
    const iframe = this._frameElement(slot);
    if (!iframe || !iframe.contentWindow) return;

    const scrollOffset = this._calculateScrollOffset(pageIndex);
    this._scrollTo(iframe, scrollOffset);

    requestAnimationFrame(() => {
      if (iframe.id === 'frame-curr') {
        window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);
      }
      this._detectActiveAnchor(iframe);
    });
  }

  restoreScrollPosition(ratio) {
    const pageCount = this.state.frames.curr;
    const pageIndex = Math.round(ratio * pageCount);

    this.jumpToPage(pageIndex);
  }

  _calculateCurrentPageIndex() {
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

  _updatePageState(iframeId) {
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

  cycleFrames(direction) {
    const elPrev = this._frameElement('prev');
    const elCurr = this._frameElement('curr');
    const elNext = this._frameElement('next');

    if (!elPrev || !elCurr || !elNext) return;

    if (direction === 'next') {
      elPrev.id = 'frame-temp';

      elNext.id = 'frame-curr';
      elNext.style.zIndex = '2';
      elNext.style.opacity = '1';
      elNext.style.pointerEvents = 'auto';

      elCurr.id = 'frame-prev';
      elCurr.style.zIndex = '1';
      elCurr.style.opacity = '0';
      elCurr.style.pointerEvents = 'none';

      const recycled = document.getElementById('frame-temp');
      recycled.id = 'frame-next';
      recycled.style.zIndex = '1';
      recycled.style.opacity = '0';
      recycled.style.pointerEvents = 'none';

      const tempAnchors = this.state.anchors.prev;
      this.state.anchors.prev = this.state.anchors.curr;
      this.state.anchors.curr = this.state.anchors.next;
      this.state.anchors.next = tempAnchors;
    } else if (direction === 'prev') {
      elNext.id = 'frame-temp';

      elPrev.id = 'frame-curr';
      elPrev.style.zIndex = '2';
      elPrev.style.opacity = '1';
      elPrev.style.pointerEvents = 'auto';

      elCurr.id = 'frame-next';
      elCurr.style.zIndex = '1';
      elCurr.style.opacity = '0';
      elCurr.style.pointerEvents = 'none';

      const recycled = document.getElementById('frame-temp');
      recycled.id = 'frame-prev';
      recycled.style.zIndex = '1';
      recycled.style.opacity = '0';
      recycled.style.pointerEvents = 'none';

      const tempAnchors = this.state.anchors.next;
      this.state.anchors.next = this.state.anchors.curr;
      this.state.anchors.curr = this.state.anchors.prev;
      this.state.anchors.prev = tempAnchors;
    }

    requestAnimationFrame(() => {
      this._updatePageState('frame-curr');
      this._updatePageState('frame-prev');
      this._updatePageState('frame-next');
      this._detectActiveAnchor(elPrev);
      this._detectActiveAnchor(elCurr);
      this._detectActiveAnchor(elNext);
      this._buildInteractionMap();
    });
  }

  jumpToLastPageOfFrame(slot) {
    const pageCount = this.state.frames[slot] ?? 0;
    this.jumpToPageFor(slot, pageCount - 1);
  }

  _updateCSSVariables(doc, styleId = 'injected-variable-style') {
    const root = doc.documentElement;
    const body = doc.body;

    root.style.setProperty('--lumina-zoom', this.state.config.theme.zoom);
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

    if (this.state.config.theme.shouldOverrideTextColor) {
      body.classList.add('lumina-override-color');
    } else {
      body.classList.remove('lumina-override-color');
    }

    const existingStyle = doc.getElementById(styleId);
    if (existingStyle) {
      existingStyle.innerHTML = this.state.config.theme.variableCss;
    }
  }

  _generateVariableStyle() {
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

    return ':root {'
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
      + '}';
  }

  updateTheme(viewWidth, viewHeight, newTheme) {
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
        const pageIndex = this._calculateCurrentPageIndex();
        const pageCount = this._calculatePageCount(iframe);
        const pageIndexPercentage = pageCount > 0 ? pageIndex / pageCount : 0;
        this._updateCSSVariables(doc, 'injected-variable-style');
        requestAnimationFrame(() => {
          this._reloadFrame(iframe, pageIndexPercentage);
        });
      }
    }

    setTimeout(() => {
      this._buildInteractionMap();
    }, 220);
  }

  _checkElementAt(x, y, checkIfAllowed) {
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

    let bestCandidate = null;
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
      let distance;
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

  checkTapElementAt(x, y) {
    const bestCandidate = this._checkElementAt(x, y, (candidate) => {
      if (candidate.type === 'footnote' || candidate.type === 'link') {
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
      } else if (bestCandidate.type === 'link') {
        window.flutter_inappwebview.callHandler(
          'onLinkTap', bestCandidate.data,
          absoluteLeft, absoluteTop, rect.width, rect.height
        );
      } else {
        window.flutter_inappwebview.callHandler('onTap', x, y);
      }
    } else {
      // Fall back to just sending tap coordinates if no interactive element is found nearby
      window.flutter_inappwebview.callHandler('onTap', x, y);
    }
  }

  checkElementAt(x, y) {
    const bestCandidate = this._checkElementAt(x, y, (candidate) => {
      if (candidate.type === 'image') {
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

      window.flutter_inappwebview.callHandler(
        'onImageLongPress',
        bestCandidate.data,
        absoluteLeft,
        absoluteTop,
        rect.width,
        rect.height,
      );
    }
  }

  waitForRender(token) {
    requestAnimationFrame(function () {
      requestAnimationFrame(function () {
        window.flutter_inappwebview.callHandler('onRendered', token);
      });
    });
  }
}

window.reader = new EpubReader();