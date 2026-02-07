import 'dart:ui';

String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

String generateSkeletonStyle(Color backgroundColor, Color defaultTextColor) {
  return '''
/* Full viewport, no margins */
html, body {
  margin: 0;
  padding: 0;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
  background-color: ${colorToHex(backgroundColor)} !important;
  color: ${colorToHex(defaultTextColor)} !important;
}

/* Container for iframes */
#frame-container {
  position: relative;
  width: 100%;
  height: 100%;
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
  transition: opacity 0.15s ease-in-out;
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
}

/// Skeleton HTML containing 3 iframes for prev/curr/next chapters
String generateSkeletonHtml(Color backgroundColor, Color defaultTextColor) {
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style id="skeleton-style">
    ${generateSkeletonStyle(backgroundColor, defaultTextColor)}
  </style>
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
String generatePaginationCss(
  double viewWidth,
  double viewHeight,
  Color defaultTextColor,
) {
  final safeWidth = viewWidth.floor();
  final safeHeight = viewHeight.floor();

  return '''
/* Reset and base styles */
html, body {
  margin: 0 !important;
  padding: 0 !important;
  width: ${safeWidth}px !important;
  height: ${safeHeight}px !important;
  background-color: transparent !important;
  touch-action: none !important;
  overflow-y: hidden !important;
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
  column-width: ${safeWidth}px !important;
  column-gap: 128px !important;
  column-fill: auto !important;
  height: ${safeHeight}px !important;
}

/* Fit within viewport */
body * {
  max-width: ${safeWidth - 5}px !important;

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
  max-height: ${safeHeight - 5}px !important;
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
  text-decoration: none !important;
  color: inherit !important;
  cursor: default !important;
}

p, h1, h2, h3, h4, h5, h6, li, blockquote, pre, code, span, div, section {
  color: ${colorToHex(defaultTextColor)};
}
''';
}

/// JavaScript controller for managing the iframe carousel
String generateControllerJs(
  double viewWidth,
  double viewHeight,
  Color defaultTextColor,
) {
  final safeWidth = viewWidth.floor();

  return '''
// Global state
// framePages stores the page count for each DOM ID
let framePages = {
  'frame-prev': 0,
  'frame-curr': 0,
  'frame-next': 0
};

let framePageStarts = {
  'frame-prev': 0,
  'frame-curr': 0,
  'frame-next': 0
};

let startAnchors = {
  'frame-prev': null,
  'frame-curr': null,
  'frame-next': null
};

let endAnchors = {
  'frame-prev': null,
  'frame-curr': null,
  'frame-next': null
};

function getWidth(iframe) {
  return $safeWidth;
}

let PAGINATION_CSS = `${generatePaginationCss(viewWidth, viewHeight, defaultTextColor)}`;

// Load a chapter into a specific iframe slot
function loadFrame(slot, url, endAnchor) {
  const iframe = document.getElementById('frame-' + slot);
  if (!iframe) return;

  endAnchors[iframe.id] = endAnchor;

  // Clear previous onload to prevent ghost calls
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

function calculateStartPageIndex(iframe) {
  if (!iframe || !iframe.contentDocument) return 0;

  const startAnchor = startAnchors[iframe.id];
  if (startAnchor) {
    const startEl = iframe.contentDocument.getElementById(startAnchor);
    if (startEl) {
      const startLeft = startEl.offsetLeft + startEl.offsetWidth / 5;
      const viewportWidth = getWidth(iframe);
      return Math.round((startLeft + 128) / (viewportWidth + 128));
    }
  }
  return 0;
}

function calculateEndPageIndex(iframe) {
  if (!iframe || !iframe.contentDocument) return;

  const endAnchor = endAnchors[iframe.id];
  if (endAnchor) {
    const endEl = iframe.contentDocument.getElementById(endAnchor);
    if (endEl) {
      const endRight = endEl.offsetLeft + endEl.offsetWidth / 5;
      const viewportWidth = getWidth(iframe);
      return Math.round((endRight + 128) / (viewportWidth + 128));
    }
  }
  const scrollWidth = iframe.contentDocument.body.scrollWidth;
  const viewportWidth = getWidth(iframe);
  const pageCount = Math.round((scrollWidth + 128) / (viewportWidth + 128));
  return pageCount;
}

function calculatePageCount(iframe) {
  if (!iframe || !iframe.contentDocument) return;

  const startPageIndex = calculateStartPageIndex(iframe);
  const endPageIndex = calculateEndPageIndex(iframe);

  return endPageIndex - startPageIndex;
}

function calculateScrollLeft(iframe, pageIndex) {
  if (!iframe || !iframe.contentDocument) return;
  const viewportWidth = getWidth(iframe);
  const offsetPageIndex = pageIndex + framePageStarts[iframe.id];
  const scrollLeft = offsetPageIndex * viewportWidth + (offsetPageIndex * 128);
  return scrollLeft;
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
          
          if (style.breakBefore && style.breakBefore !== 'auto') {
            style.breakBefore = 'always';
            style.webkitColumnBreakBefore = 'always';
          }
          
          if (style.pageBreakBefore && style.pageBreakBefore !== 'auto') {
            style.webkitColumnBreakBefore = 'always';
            style.breakBefore = 'always';
          }

          if (style.breakAfter && style.breakAfter !== 'auto') {
            style.breakAfter = 'always';
            style.webkitColumnBreakAfter = 'always';
          }

          if (style.pageBreakAfter && style.pageBreakAfter !== 'auto') {
            style.webkitColumnBreakAfter = 'always';
            style.breakAfter = 'always';
          }
        }
      }
    } catch (e) {
      console.error('Access to stylesheet blocked: ' + e);
    }
  }
}

// Called when an iframe finishes loading
function onFrameLoad(iframe) {
  if (!iframe || !iframe.contentDocument) return;

  const url = new URL(iframe.src);
  if (url.hash) {
    startAnchors[iframe.id] = url.hash.substring(1);
  } else {
    startAnchors[iframe.id] = null;
  }
  endAnchors[iframe.id] = endAnchors[iframe.id];
  
  const doc = iframe.contentDocument;
  
  // Inject CSS
  const style = doc.createElement('style');
  style.id = 'injected-pagination-style';
  style.innerHTML = PAGINATION_CSS;
  doc.head.appendChild(style);

  // Polyfill for break-before if not supported
  polyfillCss(doc);
  
  // Inject click handler with 3-zone tap logic
  doc.body.onclick = function(e) {
    console.log('Body clicked at: ' + e.clientX + ', ' + e.clientY);
    const clickX = e.clientX;
    const width = window.innerWidth || 1;
    const ratio = clickX / width;
    if (ratio < 0.2) {
      window.flutter_inappwebview.callHandler('onTapLeft');
    } else if (ratio > 0.8) {
      window.flutter_inappwebview.callHandler('onTapRight');
    } else {
      window.flutter_inappwebview.callHandler('onTapCenter');
    }
  };

  const timeout = new Promise((resolve) => setTimeout(resolve, 3000));

  Promise.race([
    waitForAllResources(), 
    timeout
  ]).then(() => {
    if (!iframe.contentWindow) return;

    requestAnimationFrame(() => {
      const pageCount = calculatePageCount(iframe);
      const pageStart = calculateStartPageIndex(iframe);
      framePages[iframe.id] = pageCount;
      framePageStarts[iframe.id] = pageStart;
      if (iframe.id === 'frame-curr') {
        window.flutter_inappwebview.callHandler('onPageCountReady', pageCount);
      }
    });
  });
}

// Jump to a specific page in the current frame
function jumpToPage(pageIndex) {
  const iframe = document.getElementById('frame-curr');
  if (!iframe || !iframe.contentWindow) return;

  const scrollLeft = calculateScrollLeft(iframe, pageIndex);
  iframe.contentDocument.body.scrollTo({ left: scrollLeft, top: 0, behavior: 'auto' });
}

function jumpToPageFor(slot, pageIndex) {
  const id = 'frame-' + slot;
  const iframe = document.getElementById(id);
  if (!iframe || !iframe.contentWindow) return;
  
  const scrollLeft = calculateScrollLeft(iframe, pageIndex);
  iframe.contentDocument.body.scrollTo({ left: scrollLeft, top: 0, behavior: 'auto' });
}

// Restore scroll position using ratio and snap to column boundaries
function restoreScrollPosition(ratio) {
  const iframe = document.getElementById('frame-curr');
  if (!iframe || !iframe.contentWindow || !iframe.contentDocument) return;

  const pageCount = framePages['frame-curr'];
  const pageIndex = Math.round(ratio * pageCount);

  jumpToPage(pageIndex);
  window.flutter_inappwebview.callHandler('onGoToPage', pageIndex);
}

function updatePageCountAndStart(iframeId, direction) {
  const iframe = document.getElementById(iframeId);
  if (!iframe || !iframe.contentWindow) return;
  
  const pageCount = calculatePageCount(iframe);
  framePages[iframeId] = pageCount;

  const pageStart = calculateStartPageIndex(iframe);
  framePageStarts[iframeId] = pageStart;
  
  // If this is the current frame, notify Flutter
  if (iframeId === 'frame-curr') {
    window.flutter_inappwebview.callHandler('onPageCountReady', pageCount);
    if (direction === 'prev') {
      window.flutter_inappwebview.callHandler('onGoToPage', pageCount - 1);
    }
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
    const tempStart = startAnchors['frame-prev'];
    const tempEnd = endAnchors['frame-prev'];
    const tempStartPageIndex = framePageStarts['frame-prev'];
    const tempPageCount = framePages['frame-prev'];

    startAnchors['frame-prev'] = startAnchors['frame-curr'];
    endAnchors['frame-prev'] = endAnchors['frame-curr'];
    framePageStarts['frame-prev'] = framePageStarts['frame-curr'];
    framePages['frame-prev'] = framePages['frame-curr'];

    startAnchors['frame-curr'] = startAnchors['frame-next'];
    endAnchors['frame-curr'] = endAnchors['frame-next'];
    framePageStarts['frame-curr'] = framePageStarts['frame-next'];
    framePages['frame-curr'] = framePages['frame-next'];

    startAnchors['frame-next'] = tempStart;
    endAnchors['frame-next'] = tempEnd;
    framePageStarts['frame-next'] = tempStartPageIndex;
    framePages['frame-next'] = tempPageCount;
    
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
    const tempStart = startAnchors['frame-next'];
    const tempEnd = endAnchors['frame-next'];
    const tempStartPageIndex = framePageStarts['frame-next'];
    const tempPageCount = framePages['frame-next'];

    startAnchors['frame-next'] = startAnchors['frame-curr'];
    endAnchors['frame-next'] = endAnchors['frame-curr'];
    framePageStarts['frame-next'] = framePageStarts['frame-curr'];
    framePages['frame-next'] = framePages['frame-curr'];

    startAnchors['frame-curr'] = startAnchors['frame-prev'];
    endAnchors['frame-curr'] = endAnchors['frame-prev'];
    framePageStarts['frame-curr'] = framePageStarts['frame-prev'];
    framePages['frame-curr'] = framePages['frame-prev'];

    startAnchors['frame-prev'] = tempStart;
    endAnchors['frame-prev'] = tempEnd;
    framePageStarts['frame-prev'] = tempStartPageIndex;
    framePages['frame-prev'] = tempPageCount;
    
  }

  updatePageCountAndStart('frame-curr', direction);
}

// Helper to scroll the PREV frame to the last page immediately
// (Used before sliding back to it, or after cycling back)
function jumpToLastPageOfFrame(slot) {
  const pageCount = framePages['frame-' + slot];
  jumpToPageFor(slot, pageCount - 1);
}

function reveal() {
  requestAnimationFrame(function() {
    window.flutter_inappwebview.callHandler('onRenderComplete');
  });
}

function replaceStyles(skeletonCss, iframeCss) {
  const styleEl = document.getElementById('skeleton-style');
  if (styleEl) {
    styleEl.innerHTML = skeletonCss;
  }
  const iframes = document.getElementsByTagName('iframe');
  for (let i = 0; i < iframes.length; i++) {
    const iframe = iframes[i];
    if (iframe && iframe.contentDocument) {
      const doc = iframe.contentDocument;
      const style = doc.getElementById('injected-pagination-style');
      if (style) {
        style.innerHTML = iframeCss;
      }
    }
  }

  PAGINATION_CSS = iframeCss;
}
''';
}
