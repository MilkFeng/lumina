import 'package:flutter/material.dart';

String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
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
// Global state
// framePages stores the page count for each DOM ID
let framePages = {
  'frame-prev': 0,
  'frame-curr': 0,
  'frame-next': 0
};

let tocAnchors = {
  'frame-prev': [],
  'frame-curr': [],
  'frame-next': []
};

function getWidth(iframe) {
  return SAFE_WIDTH;
}

// Load a chapter into a specific iframe slot
function loadFrame(slot, url, anchors) {
  const iframe = document.getElementById('frame-' + slot);
  if (!iframe) return;

  tocAnchors['frame-' + slot] = anchors || [];

  iframe.onload = null;
  
  if (iframe.src == null || iframe.src === '' || iframe.src === 'about:blank') {
    iframe.onload = function() {
      onFrameLoad(iframe);
    };
    iframe.src = url;
  } else {
    const currentUrl = new URL(iframe.src);
    const newUrl = new URL(url);
    if (currentUrl.origin === newUrl.origin && currentUrl.pathname === newUrl.pathname) {
      iframe.onload = function() {
        onFrameLoad(iframe);
      };
      iframe.src = url;
      onFrameLoad(iframe);
    } else {
      iframe.onload = function() {
        onFrameLoad(iframe);
      };
      iframe.src = url;
    }
  }
}

function waitForAllResources() {
  const imagesReady = Promise.all(Array.from(document.images).map(img => {
    if (img.complete && img.naturalHeight !== 0) return Promise.resolve();
    return new Promise(resolve => {
      img.onload = img.onerror = resolve;
    });
  }));

  const fontsReady = document.fonts.ready;

  return Promise.all([
    imagesReady,
    fontsReady,
  ]);
}

function calculatePageCount(iframe) {
  if (!iframe || !iframe.contentDocument) return;

  const scrollWidth = iframe.contentDocument.body.scrollWidth;
  const viewportWidth = getWidth(iframe);
  const pageCount = Math.round((scrollWidth + 128) / (viewportWidth + 128));
  return pageCount;
}

function calculateScrollLeft(iframe, pageIndex) {
  if (!iframe || !iframe.contentDocument) return;
  const viewportWidth = getWidth(iframe);
  const scrollLeft = pageIndex * viewportWidth + (pageIndex * 128);
  return scrollLeft;
}

function convertToColumnBreak(value) {
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

function polyfillCss(doc) {
  for (var i = 0; i < doc.styleSheets.length; i++) {
    var sheet = doc.styleSheets[i];
    try {
      var rules = sheet.cssRules || sheet.rules;
      if (!rules) continue;

      for (var j = 0; j < rules.length; j++) {
        var rule = rules[j];
        if (rule.type === 1) {
          var style = rule.style;
          
          if (style.breakBefore) {
            style.webkitColumnBreakBefore = convertToColumnBreak(style.breakBefore);
          }
          
          if (style.pageBreakBefore) {
            style.webkitColumnBreakBefore = convertToColumnBreak(style.pageBreakBefore);
          }

          if (style.breakAfter && style.breakAfter !== 'auto') {
            style.webkitColumnBreakAfter = convertToColumnBreak(style.breakAfter);
          }

          if (style.pageBreakAfter && style.pageBreakAfter !== 'auto') {
            style.webkitColumnBreakAfter = convertToColumnBreak(style.pageBreakAfter);
          }
        }
      }
    } catch (e) {
      console.error('Access to stylesheet blocked: ' + e);
    }
  }
}

// Detect the "last passed anchor" algorithm
function detectActiveAnchor(iframe) {
  if (!iframe || !iframe.contentDocument) return;
  if (iframe.id !== 'frame-curr') return; // Only track anchors in the current frame

  let anchors = tocAnchors['frame-curr'];
  if (!anchors || anchors.length === 0) {
    return;
  }
  
  const doc = iframe.contentDocument;
  let activeAnchors = [];
  let lastPassedAnchor = 'top';
  const threshold = 50; // Left threshold in pixels for horizontal scrolling
  
  // Iterate through anchors to find the last one that has passed the threshold
  for (let i = 0; i < anchors.length; i++) {
    const anchorId = anchors[i];
    if (anchorId === 'top') {
      if (doc.body.scrollLeft < threshold) {
        activeAnchors.push('top');
      }
      continue;
    }

    const element = doc.getElementById(anchorId);
    
    if (element) {
      const rect = element.getBoundingClientRect();
      
      // If this anchor has scrolled past the left edge (left < 50px from viewport left)
      if (rect.left < threshold && rect.right > threshold) {
        activeAnchors.push(anchorId);
        // Continue to find potentially later anchors
      }

      if (rect.left < threshold) {
        lastPassedAnchor = anchorId;
      }
    }
  }

  if (activeAnchors.length === 0 && lastPassedAnchor) {
    activeAnchors.push(lastPassedAnchor);
  }  
  window.flutter_inappwebview.callHandler('onScrollAnchors', activeAnchors);
}

function calculatePageIndexOfAnchor(iframe, anchorId) {
  if (!iframe || !iframe.contentDocument) return 0;
  const doc = iframe.contentDocument;
  const element = doc.getElementById(anchorId);
  if (!element) return 0;

  const viewportWidth = getWidth(iframe);
  const elementRect = element.getBoundingClientRect();
  const bodyRect = doc.body.getBoundingClientRect();
  const absoluteLeft = elementRect.left + doc.body.scrollLeft - bodyRect.left + (elementRect.width /5);

  const pageIndex = Math.round((absoluteLeft + 128) / (viewportWidth + 128));
  return pageIndex;
}

// Called when an iframe finishes loading
function onFrameLoad(iframe) {
  if (!iframe || !iframe.contentDocument) return;
  
  const doc = iframe.contentDocument;

  // Inject CSS variables for theming
  // Using skeleton-variable-style content to ensure variables are available before pagination CSS
  const existingStyle = document.getElementById('skeleton-variable-style');
  if (existingStyle) {
    const style = existingStyle.cloneNode(true);
    style.id = 'injected-variable-style';
    doc.head.appendChild(style);
  }
  
  // Inject CSS
  const style = doc.createElement('style');
  style.id = 'injected-pagination-style';
  style.innerHTML = `$_paginationCss`;
  doc.head.appendChild(style);

  // Update body class list
  if (DEFAULT_TEXT_COLOR) {
    doc.body.classList.add('override-color');
  } else {
    doc.body.classList.remove('override-color');
  }

  // Polyfill for break-before if not supported
  polyfillCss(doc);

  const timeout = new Promise((resolve) => setTimeout(resolve, 3000));

  Promise.race([
    waitForAllResources(), 
    timeout
  ]).then(() => {
    if (!iframe.contentWindow) return;

    requestAnimationFrame(() => {
      const pageCount = calculatePageCount(iframe);
      framePages[iframe.id] = pageCount;

      let pageIndex = 0;
      const url = iframe.src;
      if (url && url.includes('#')) {
        const anchor = url.split('#')[1];
        pageIndex = calculatePageIndexOfAnchor(iframe, anchor);
        const scrollLeft = calculateScrollLeft(iframe, pageIndex);
        doc.body.scrollTo({ left: scrollLeft, top: 0, behavior: 'auto' });
      }

      if (iframe.id === 'frame-curr') {
        // Notify Flutter of page count and current page
        window.flutter_inappwebview.callHandler('onPageCountReady', pageCount);
        window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);

        // Notify that renderer is initialized
        window.flutter_inappwebview.callHandler('onRendererInitialized');
      }
    });
  });

  requestAnimationFrame(() => {
    detectActiveAnchor(iframe);
  });
}

// Jump to a specific page in the current frame
function jumpToPage(pageIndex) {
  const iframe = document.getElementById('frame-curr');
  if (!iframe || !iframe.contentWindow) return;

  const scrollLeft = calculateScrollLeft(iframe, pageIndex);
  iframe.contentDocument.body.scrollTo({ left: scrollLeft, top: 0, behavior: 'auto' });

  requestAnimationFrame(() => {
    window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);
    detectActiveAnchor(iframe);
  });
}

function jumpToPageFor(slot, pageIndex) {
  const id = 'frame-' + slot;
  const iframe = document.getElementById(id);
  if (!iframe || !iframe.contentWindow) return;

  const scrollLeft = calculateScrollLeft(iframe, pageIndex);
  iframe.contentDocument.body.scrollTo({ left: scrollLeft, top: 0, behavior: 'auto' });

  requestAnimationFrame(() => {
    if (iframe.id === 'frame-curr') {
      window.flutter_inappwebview.callHandler('onPageChanged', pageIndex);
    }
    detectActiveAnchor(iframe);
  });
}

// Restore scroll position using ratio and snap to column boundaries
function restoreScrollPosition(ratio) {
  const iframe = document.getElementById('frame-curr');
  if (!iframe || !iframe.contentWindow || !iframe.contentDocument) return;

  const pageCount = framePages['frame-curr'];
  const pageIndex = Math.round(ratio * pageCount);

  jumpToPage(pageIndex);
}

function calculateCurrentPageIndex() {
  const iframe = document.getElementById('frame-curr');
  if (!iframe || !iframe.contentWindow || !iframe.contentDocument) return 0;

  const scrollLeft = iframe.contentDocument.body.scrollLeft;
  const viewportWidth = getWidth(iframe);
  const pageIndex = Math.round((scrollLeft + 128) / (viewportWidth + 128));
  return pageIndex;
}

// Update page state (page index and page count) and notify Flutter if current frame
function updatePageState(iframeId, direction) {
  const iframe = document.getElementById(iframeId);
  if (!iframe || !iframe.contentWindow) return;

  const pageCount = calculatePageCount(iframe);
  framePages[iframeId] = pageCount;

  // If this is the current frame, notify Flutter
  if (iframeId === 'frame-curr') {
    window.flutter_inappwebview.callHandler('onPageCountReady', pageCount);
    window.flutter_inappwebview.callHandler('onPageChanged', calculateCurrentPageIndex());
  }
}

// Cycle the frames logically to avoid reloading
// direction: 'next' or 'prev'
function cycleFrames(direction) {
  const elPrev = document.getElementById('frame-prev');
  const elCurr = document.getElementById('frame-curr');
  const elNext = document.getElementById('frame-next');

  if (!elPrev || !elCurr || !elNext) return;

  if (direction === 'next') {
    // Logic: 
    // Old Next (Visible) -> Becomes New Curr
    // Old Curr -> Becomes New Prev
    // Old Prev -> Becomes New Next (Recycled for future load)
    
    elPrev.id = 'frame-temp'; // Prevent ID collision
    
    elNext.id = 'frame-curr';
    elNext.style.zIndex = '2';
    elNext.style.opacity = '1';
    elNext.style.pointerEvents = 'auto';
    
    elCurr.id = 'frame-prev';
    elCurr.style.zIndex = '1';
    elCurr.style.opacity = '0';
    elCurr.style.pointerEvents = 'none';
    
    // The recycled frame
    const recycled = document.getElementById('frame-temp');
    recycled.id = 'frame-next';
    recycled.style.zIndex = '1';
    recycled.style.opacity = '0';
    recycled.style.pointerEvents = 'none';
    recycled.src = 'about:blank'; // Clear it

    // cycle anchors
    const tempAnchors = tocAnchors['frame-prev'];
    tocAnchors['frame-prev'] = tocAnchors['frame-curr'];
    tocAnchors['frame-curr'] = tocAnchors['frame-next'];
    tocAnchors['frame-next'] = tempAnchors;
  } else if (direction === 'prev') {
    // Logic:
    // Old Prev (Hidden, but loaded) -> Becomes New Curr
    // Old Curr -> Becomes New Next
    // Old Next -> Becomes New Prev (Recycled)

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

    // cycle anchors
    const tempAnchors = tocAnchors['frame-next'];
    tocAnchors['frame-next'] = tocAnchors['frame-curr'];
    tocAnchors['frame-curr'] = tocAnchors['frame-prev'];
    tocAnchors['frame-prev'] = tempAnchors;
  }

  requestAnimationFrame(() => {
    updatePageState('frame-curr', direction);
    updatePageState('frame-prev', direction);
    updatePageState('frame-next', direction);
    detectActiveAnchor(elPrev);
    detectActiveAnchor(elCurr);
    detectActiveAnchor(elNext);
  });
}

// Helper to scroll the PREV frame to the last page immediately
// (Used before sliding back to it, or after cycling back)
function jumpToLastPageOfFrame(slot) {
  const pageCount = framePages['frame-' + slot];
  jumpToPageFor(slot, pageCount - 1);
}

function checkElementAt(x, y) {
  x = x - PADDING.left;
  y = y - PADDING.top;

  const iframe = document.getElementById('frame-curr');
  if (!iframe || !iframe.contentDocument) return;

  const doc = iframe.contentDocument;

  let el = doc.elementFromPoint(x, y);
  if (!el) return;

  while (el && el !== doc.body) {
    if (el.tagName.toLowerCase() === 'img') {
      let rect = el.getBoundingClientRect();
      let iframeRect = iframe.getBoundingClientRect();
      rect = {
        left: rect.left + iframeRect.left,
        top: rect.top + iframeRect.top,
        width: rect.width,
        height: rect.height
      };
      window.flutter_inappwebview.callHandler('onImageLongPress', el.src, rect.left, rect.top, rect.width, rect.height);
      return;
    }
    el = el.parentElement;
  }
}
''';

String _generateVariableStyle(
  double viewWidth,
  double viewHeight,
  Color backgroundColor,
  Color? defaultTextColor,
  EdgeInsets padding,
) {
  final safeWidth = viewWidth.floor();
  final safeHeight = viewHeight.floor();

  return '''
    :root {
      --background-color: ${colorToHex(backgroundColor)};
      ${defaultTextColor != null ? '--default-text-color: ${colorToHex(defaultTextColor)};' : ''}
      --safe-width: ${safeWidth}px;
      --safe-height: ${safeHeight}px;
      --padding-top: ${padding.top}px;
      --padding-left: ${padding.left}px;
      --padding-right: ${padding.right}px;
      --padding-bottom: ${padding.bottom}px;
    }
  ''';
}

/// Skeleton HTML containing 3 iframes for prev/curr/next chapters
String generateSkeletonHtml(
  double viewWidth,
  double viewHeight,
  Color backgroundColor,
  Color? defaultTextColor,
  EdgeInsets padding,
) {
  final safeWidth = viewWidth.floor();

  final variableStyle = _generateVariableStyle(
    viewWidth,
    viewHeight,
    backgroundColor,
    defaultTextColor,
    padding,
  );

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
    let SAFE_WIDTH = $safeWidth;
    let PADDING = { top: ${padding.top}, left: ${padding.left}, right: ${padding.right}, bottom: ${padding.bottom} };

    let BACKGROUND_COLOR = '${colorToHex(backgroundColor)}';
    let DEFAULT_TEXT_COLOR = ${defaultTextColor != null ? "'${colorToHex(defaultTextColor)}'" : 'null'};

    function updateCSSVariables(root, body) {
      root.style.setProperty('--safe-width', SAFE_WIDTH + 'px');
      root.style.setProperty('--padding-top', PADDING.top + 'px');
      root.style.setProperty('--padding-left', PADDING.left + 'px');
      root.style.setProperty('--padding-right', PADDING.right + 'px');
      root.style.setProperty('--padding-bottom', PADDING.bottom + 'px');
      root.style.setProperty('--background-color', BACKGROUND_COLOR);
      if (DEFAULT_TEXT_COLOR) {
        body.classList.add('override-color');
        root.style.setProperty('--default-text-color', DEFAULT_TEXT_COLOR);
      } else {
        body.classList.remove('override-color');
        root.style.removeProperty('--default-text-color');
      }
    }

    function updateTheme(viewWidth, viewHeight, paddingTop, paddingLeft, paddingRight, paddingBottom, backgroundColor, defaultTextColor) {
      // Update JS variables
      SAFE_WIDTH = Math.floor(viewWidth);
      PADDING = { top: paddingTop, left: paddingLeft, right: paddingRight, bottom: paddingBottom };
      BACKGROUND_COLOR = backgroundColor;
      DEFAULT_TEXT_COLOR = defaultTextColor;

      // Update CSS variables
      updateCSSVariables(document.documentElement, document.body);

      // Update CSS variables inside iframes
      const iframes = document.getElementsByTagName('iframe');
      for (let i = 0; i < iframes.length; i++) {
        const iframe = iframes[i];
        if (iframe && iframe.contentDocument) {
          const doc = iframe.contentDocument;
          const scrollLeft = doc.body.scrollLeft;
          updateCSSVariables(doc.documentElement, doc.body);
          requestAnimationFrame(() => {
            setTimeout(() => {
              doc.body.scrollTo({ left: scrollLeft, top: 0, behavior: 'auto' });
            }, 200);
          });
        }
      }
    }
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
/* Reset and base styles */
html, body {
  margin: 0 !important;
  padding: 0 !important;
  width: var(--safe-width) !important;
  height: var(--safe-height) !important;
  background-color: transparent !important;
  touch-action: none !important;
  overflow-y: hidden !important;

  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
  
  -webkit-touch-callout: none;
  -webkit-tap-highlight-color: transparent;

  font-family: "Noto Serif CJK SC", "Source Han Serif SC", "STSong", "Songti SC", "SimSun", serif;
  line-height: 1.6;
  text-align: justify;
}

/* CRITICAL: Disable all scrolling vertically - horizontal only */
html {
  overflow-y: hidden !important;
  overflow-x: scroll !important;
}

body {
  overflow-y: hidden !important;
  overflow-x: scroll !important;
}

/* Horizontal columnization for pagination */
body {
  column-width: var(--safe-width) !important;
  column-gap: 128px !important;
  column-fill: auto !important;
  height: var(--safe-height) !important;
}

/* Fit within viewport */
body * {
  max-width: var(--safe-width) !important;

  orphans: 2;
  widows: 2;
}

/* Hide scrollbars completely */
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
}

a:visited {
  color: currentColor !important;
  text-decoration: inherit !important;
  border-bottom: inherit !important;
  opacity: 1 !important;
}

p {
  margin-bottom: 1.0em;
}

body.override-color {
  p, h1, h2, h3, h4, h5, h6, li, blockquote, pre, code, span, div, section {
    color: var(--default-text-color) !important;
  }
}
''';
