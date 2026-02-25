import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lumina/src/features/reader/domain/epub_theme.dart';

String colorToHex(Color color) {
  final argb = color.toARGB32();
  return '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
}

const _skeletonCss = '''
/* Full viewport, no margins */
html, body {
  margin: 0;
  padding: 0;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
  background-color: var(--background-color, #FFFFFF) !important;
}

/* Container for iframes */
#frame-container {
  position: absolute;
  top: var(--padding-top, 0px);
  left: var(--padding-left, 0px);
  right: var(--padding-right, 0px);
  bottom: var(--padding-bottom, 0px);
  overflow: hidden;
}

/* All iframes: absolute positioning, full size, no border */
iframe {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  border: none;
}

/* Prev iframe: hidden, low z-index */
#frame-prev {
  z-index: 1;
  opacity: 0;
  pointer-events: none;
}

/* Current iframe: visible, high z-index */
#frame-curr {
  z-index: 2;
  opacity: 1;
  pointer-events: auto;
}

/* Next iframe: hidden, low z-index */
#frame-next {
  z-index: 1;
  opacity: 0;
  pointer-events: none;
}
''';

/// JavaScript controller for managing the iframe carousel
const _controllerJS =
    '''
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
          paginationCss: `$_paginationCss`,
          variableCss: '',
          backgroundColor: '#FFFFFF',
          defaultTextColor: '#000000',
          shouldOverrideTextColor: true,
          primaryColor: '#000000',
          primaryContainer: '#000000',
          onSurfaceVariant: '#000000',
          outlineVariant: '#000000',
          surfaceContainer: '#000000',
          surfaceContainerHigh: '#000000',
        }
      }
    };

    this._resizeDebounceTimer = null;
    this._onResize = () => {
      if (this._resizeDebounceTimer) {
        clearTimeout(this._resizeDebounceTimer);
      }
      this._resizeDebounceTimer = setTimeout(() => {
        this._buildInteractionMap();
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

  _polyfillCss(doc) {
    for (let i = 0; i < doc.styleSheets.length; i++) {
      const sheet = doc.styleSheets[i];
      try {
        const rules = sheet.cssRules || sheet.rules;
        if (!rules) continue;

        for (let j = 0; j < rules.length; j++) {
          const rule = rules[j];
          if (rule.type === 1) {
            const style = rule.style;

            if (style.breakBefore) {
              style.webkitColumnBreakBefore = this._convertToColumnBreak(style.breakBefore);
            }

            if (style.pageBreakBefore) {
              style.webkitColumnBreakBefore = this._convertToColumnBreak(style.pageBreakBefore);
            }

            if (style.breakAfter && style.breakAfter !== 'auto') {
              style.webkitColumnBreakAfter = this._convertToColumnBreak(style.breakAfter);
            }

            if (style.pageBreakAfter && style.pageBreakAfter !== 'auto') {
              style.webkitColumnBreakAfter = this._convertToColumnBreak(style.pageBreakAfter);
            }
          }
        }
      } catch (e) {
        console.error('Access to stylesheet blocked: ' + e);
      }
    }
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

    if (this._isVertical()) {
      const viewportHeight = this._getHeight();
      const elementRect = element.getBoundingClientRect();
      const bodyRect = doc.body.getBoundingClientRect();
      const absoluteTop = elementRect.top + doc.body.scrollTop - bodyRect.top + (elementRect.height / 5);
      const pageIndex = Math.round((absoluteTop + 128) / (viewportHeight + 128));
      return pageIndex;
    } else {
      const viewportWidth = this._getWidth();
      const elementRect = element.getBoundingClientRect();
      const bodyRect = doc.body.getBoundingClientRect();
      const absoluteLeft = elementRect.left + doc.body.scrollLeft - bodyRect.left + (elementRect.width / 5);
      const pageIndex = Math.round((absoluteLeft + 128) / (viewportWidth + 128));
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
        const epubType = link.getAttribute('epub:type');
        let innerHtml = '';

        if (link.hasAttribute('title') && (!href || href === '#')) {
          // Some footnotes use the link's title attribute to store the content instead of pointing to an element in the page
          innerHtml = '<div class="footnote-content">' + link.getAttribute('title') + '</div>';
        } else {
          if (epubType === 'noteref') {
            // find the best candidate element to represent the footnote content
            const targetId = this._extractTargetIdFromHref(href);
            innerHtml = this._extractFootnoteHtml(targetId);
          } else if (href) {
            const linkBaseUrl = link.href.split('#')[0];
            if (linkBaseUrl === currentDocBaseUrl) {
              // Only support extracting footnote content for same-page links to avoid cross-origin issues and complexity of handling multiple documents
              const targetId = this._extractTargetIdFromHref(href);
              innerHtml = this._extractFootnoteHtml(targetId);
            } else {
              continue;
            }
          } else {
            continue;
          }
        }

        if (!innerHtml || innerHtml.trim() === '') {
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

      if (this.state.config.theme.defaultTextColor) {
        doc.body.classList.add('override-color');
      } else {
        doc.body.classList.remove('override-color');
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
      recycled.src = 'about:blank';

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
      recycled.src = 'about:blank';

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

    root.style.setProperty('--zoom', this.state.config.theme.zoom);
    root.style.setProperty('--safe-width', this.state.config.safeWidth + 'px');
    root.style.setProperty('--safe-height', this.state.config.safeHeight + 'px');
    root.style.setProperty('--padding-top', this.state.config.padding.top + 'px');
    root.style.setProperty('--padding-left', this.state.config.padding.left + 'px');
    root.style.setProperty('--padding-right', this.state.config.padding.right + 'px');
    root.style.setProperty('--padding-bottom', this.state.config.padding.bottom + 'px');
    root.style.setProperty('--reader-overflow-x', this._isVertical() ? 'hidden' : 'auto');
    root.style.setProperty('--reader-overflow-y', this._isVertical() ? 'auto' : 'hidden');

    root.style.setProperty('--background-color', this.state.config.theme.backgroundColor);
    root.style.setProperty('--default-text-color', this.state.config.theme.defaultTextColor);
    root.style.setProperty('--primary-color', this.state.config.theme.primaryColor);
    root.style.setProperty('--primary-container', this.state.config.theme.primaryContainer);
    root.style.setProperty('--on-surface-variant', this.state.config.theme.onSurfaceVariant);
    root.style.setProperty('--outline-variant', this.state.config.theme.outlineVariant);
    root.style.setProperty('--surface-container', this.state.config.theme.surfaceContainer);
    root.style.setProperty('--surface-container-high', this.state.config.theme.surfaceContainerHigh);

    if (this.state.config.theme.shouldOverrideTextColor) {
      body.classList.add('override-color');
    } else {
      body.classList.remove('override-color');
    }

    const existingStyle = doc.getElementById(styleId);
    if (existingStyle) {
      existingStyle.innerHTML = this.state.config.theme.variableCss;
    }
  }

  _generateVariableStyle() {
    const zoomItem = '--zoom: ' + this.state.config.theme.zoom + ';';
    const safeWidthItem = '--safe-width: ' + this.state.config.safeWidth + 'px;';
    const safeHeightItem = '--safe-height: ' + this.state.config.safeHeight + 'px;';
    const paddingTopItem = '--padding-top: ' + this.state.config.padding.top + 'px;';
    const paddingLeftItem = '--padding-left: ' + this.state.config.padding.left + 'px;';
    const paddingRightItem = '--padding-right: ' + this.state.config.padding.right + 'px;';
    const paddingBottomItem = '--padding-bottom: ' + this.state.config.padding.bottom + 'px;';
    const readerOverflowXItem = '--reader-overflow-x: ' + (this._isVertical() ? 'hidden' : 'auto') + ';';
    const readerOverflowYItem = '--reader-overflow-y: ' + (this._isVertical() ? 'auto' : 'hidden') + ';';
    
    const backgroundColorItem = '--background-color: ' + this.state.config.theme.backgroundColor + ';';
    const defaultTextColorItem = '--default-text-color: ' + this.state.config.theme.defaultTextColor + ';';
    const primaryColorItem = '--primary-color: ' + this.state.config.theme.primaryColor + ';';
    const primaryContainerItem = '--primary-container: ' + this.state.config.theme.primaryContainer + ';';
    const onSurfaceVariantItem = '--on-surface-variant: ' + this.state.config.theme.onSurfaceVariant + ';';
    const outlineVariantItem = '--outline-variant: ' + this.state.config.theme.outlineVariant + ';';
    const surfaceContainerItem = '--surface-container: ' + this.state.config.theme.surfaceContainer + ';';
    const surfaceContainerHighItem = '--surface-container-high: ' + this.state.config.theme.surfaceContainerHigh + ';';

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
            + backgroundColorItem
            + defaultTextColorItem
            + primaryColorItem
            + primaryContainerItem
            + onSurfaceVariantItem
            + outlineVariantItem
            + surfaceContainerItem
            + surfaceContainerHighItem
            + '}';
  }

  updateTheme(
    viewWidth,
    viewHeight,
    paddingTop,
    paddingLeft,
    paddingRight,
    paddingBottom,
    zoom,
    backgroundColor,
    defaultTextColor,
    shouldOverrideTextColor,
    primaryColor,
    primaryContainer,
    onSurfaceVariant,
    outlineVariant,
    surfaceContainer,
    surfaceContainerHigh
  ) {
    this.state.config.safeWidth = Math.floor(viewWidth);
    this.state.config.safeHeight = Math.floor(viewHeight);
    this.state.config.padding = {
      top: paddingTop,
      left: paddingLeft,
      right: paddingRight,
      bottom: paddingBottom,
    };
    this.state.config.theme.zoom = zoom;
    
    this.state.config.theme.backgroundColor = backgroundColor;
    this.state.config.theme.defaultTextColor = defaultTextColor;
    this.state.config.theme.shouldOverrideTextColor = shouldOverrideTextColor;
    this.state.config.theme.primaryColor = primaryColor;
    this.state.config.theme.primaryContainer = primaryContainer;
    this.state.config.theme.onSurfaceVariant = onSurfaceVariant;
    this.state.config.theme.outlineVariant = outlineVariant;
    this.state.config.theme.surfaceContainer = surfaceContainer;
    this.state.config.theme.surfaceContainerHigh = surfaceContainerHigh;

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

      window.flutter_inappwebview.callHandler(
        'onFootnoteTap', bestCandidate.data,
        absoluteLeft, absoluteTop, rect.width, rect.height
      );
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
}

window.reader = new EpubReader();
''';

String _generateVariableStyle(
  double viewWidth,
  double viewHeight,
  EpubTheme theme,
  int direction,
) {
  final safeWidth = viewWidth.floor();
  final safeHeight = viewHeight.floor();

  final padding = theme.padding;
  final colorScheme = theme.colorScheme;

  return '''
    :root {
      --zoom: ${theme.zoom};
      --safe-width: ${safeWidth}px;
      --safe-height: ${safeHeight}px;
      --padding-top: ${padding.top}px;
      --padding-left: ${padding.left}px;
      --padding-right: ${padding.right}px;
      --padding-bottom: ${padding.bottom}px;
      --reader-overflow-x: ${direction == 1 ? 'hidden' : 'auto'};
      --reader-overflow-y: ${direction == 1 ? 'auto' : 'hidden'};
      
      --background-color: ${colorToHex(colorScheme.surface)};
      --default-text-color: ${colorToHex(colorScheme.onSurface)};

      --primary-color: ${colorToHex(colorScheme.primary)};
      --primary-container: ${colorToHex(colorScheme.primaryContainer)};
      --on-surface-variant: ${colorToHex(colorScheme.onSurfaceVariant)};
      --outline-variant: ${colorToHex(colorScheme.outlineVariant)};
      --surface-container: ${colorToHex(colorScheme.surfaceContainer)};
      --surface-container-high: ${colorToHex(colorScheme.surfaceContainerHigh)};
    }
  ''';
}

/// Skeleton HTML containing 3 iframes for prev/curr/next chapters
String generateSkeletonHtml(
  double viewWidth,
  double viewHeight,
  EpubTheme theme,
  int direction,
) {
  final safeWidth = viewWidth.floor();
  final safeHeight = viewHeight.floor();

  final variableStyle = _generateVariableStyle(
    viewWidth,
    viewHeight,
    theme,
    direction,
  );

  final colorScheme = theme.colorScheme;

  final initialConfigJson = jsonEncode({
    'safeWidth': safeWidth,
    'safeHeight': safeHeight,
    'padding': {
      'top': theme.padding.top,
      'left': theme.padding.left,
      'right': theme.padding.right,
      'bottom': theme.padding.bottom,
    },
    'direction': direction,
    'theme': {
      'zoom': theme.zoom,
      'paginationCss': _paginationCss,
      'variableCss': variableStyle,

      'backgroundColor': colorToHex(colorScheme.surface),
      'defaultTextColor': colorToHex(colorScheme.onSurface),

      'shouldOverrideTextColor': theme.shouldOverrideTextColor,

      'primaryColor': colorToHex(colorScheme.primary),
      'primaryContainer': colorToHex(colorScheme.primaryContainer),
      'onSurfaceVariant': colorToHex(colorScheme.onSurfaceVariant),
      'outlineVariant': colorToHex(colorScheme.outlineVariant),
      'surfaceContainer': colorToHex(colorScheme.surfaceContainer),
      'surfaceContainerHigh': colorToHex(colorScheme.surfaceContainerHigh),
    },
  });

  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style id="skeleton-style">
    $_skeletonCss
  </style>
  <style id="skeleton-variable-style">
    $variableStyle
  </style>
  <script id="skeleton-script">
    $_controllerJS
  </script>
  <script id="skeleton-variable-script">
    const initialConfig = $initialConfigJson;
    window.addEventListener('DOMContentLoaded', () => {
      window.reader.init(initialConfig);
    });
  </script>
</head>
<body>
  <div id="frame-container">
    <iframe id="frame-prev" scrolling="no"></iframe>
    <iframe id="frame-curr" scrolling="no"></iframe>
    <iframe id="frame-next" scrolling="no"></iframe>
  </div>
</body>
</html>
''';
}

/// CSS to inject into each iframe for horizontal pagination

const _paginationCss = '''
html, body {
  margin: 0 !important;
  padding: 0 !important;
  width: var(--safe-width) !important;
  height: var(--safe-height) !important;
  background-color: transparent !important;
  touch-action: none !important;

  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
  
  -webkit-touch-callout: none;
  -webkit-tap-highlight-color: transparent;

  font-family: "Noto Serif CJK SC", "Source Han Serif SC", "STSong", "Songti SC", "SimSun", serif;
  line-height: 1.6;
  text-align: justify;

  font-size: calc(100% * var(--zoom)) !important;

  -webkit-text-size-adjust: none !important;
  text-size-adjust: none !important;
}

html, body {
  overflow-x: var(--reader-overflow-x) !important;
  overflow-y: var(--reader-overflow-y) !important;
}

body {
  column-width: var(--safe-width) !important;
  column-gap: 128px !important;
  column-fill: auto !important;
  height: var(--safe-height) !important;
}

body * {
  max-width: var(--safe-width) !important;

  orphans: 1;
  widows: 1;
}

::-webkit-scrollbar, 
::-webkit-scrollbar:horizontal, 
::-webkit-scrollbar:vertical {
  -webkit-appearance: none !important;
  background-color: transparent !important;
  display: none !important;
  height: 0 !important;
  width: 0 !important;
}

body::-webkit-scrollbar, 
body::-webkit-scrollbar:horizontal, 
body::-webkit-scrollbar:vertical {
  -webkit-appearance: none !important;
  background-color: transparent !important;
  display: none !important;
  height: 0 !important;
  width: 0 !important;
}

img, svg, video {
  max-height: var(--safe-height) !important;
  object-fit: contain;
  height: auto !important;

  break-inside: avoid;
  page-break-inside: avoid;
  -webkit-column-break-inside: avoid;
}

figure {
  margin: 0;
  padding: 0;
  break-inside: avoid;
}

a {
  pointer-events: none !important;
  cursor: default !important;
  text-decoration: none;
}

a:visited {
  color: currentColor !important;
  text-decoration: inherit !important;
  border-bottom: inherit !important;
  opacity: 1 !important;
}

body.override-color {
  p, h1, h2, h3, h4, h5, h6, li, span, div, section {
    color: var(--default-text-color);
  }

  ::selection {
    background-color: var(--primary-container) !important;
    color: inherit !important;
  }

  a, a:link, a:visited, a:active {
    color: var(--primary-color);
  }

  blockquote {
    background-color: var(--surface-container) !important;
    border-color: var(--primary-color) !important;
    color: var(--on-surface-variant) !important;
  }

  hr {
    background-color: var(--outline-variant) !important;
  }

  code {
    background-color: var(--surface-container-high) !important;
    color: var(--primary-color) !important;
  }

  pre {
    background-color: var(--surface-container) !important;
    border: 1px solid var(--outline-variant) !important;
  }

  pre code {
    color: var(--on-surface-variant) !important;
  }

  figcaption {
    color: var(--on-surface-variant) !important;
  }
}

aside[epub\\:type~="footnote"],
aside[epub\\:type~="endnote"],
div[epub\\:type~="footnote"] {
  display: none !important;
}

[role~="doc-footnote"],
[role~="doc-endnote"] {
  display: none !important;
}

.duokan-footnote-content,
.footnotes,
.footnote-container,
.endnotes,
.noteText {
  display: none !important;
}

a[epub\\:type~="noteref"],
a[role~="doc-noteref"] {
  display: inline !important;
}

span.notes, .notes {
  opacity: 0.7;
  text-decoration: underline dotted !important;
  cursor: pointer;
}
''';
