import type { WebKitCSSStyle } from '../common/types';

// ─── Resource Loading ─────────────────────────────────────────────────

/**
 * Waits for all images and fonts in the document to finish loading,
 * with a hard 5-second master timeout.
 */
export function waitForAllResources(doc: Document): Promise<void> {
  const imagesReady = Promise.all(
    Array.from(doc.images).map((img) => {
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
    })
  );

  const fontsReady = doc.fonts?.ready ?? Promise.resolve();
  const masterTimeout = new Promise<void>((resolve) => setTimeout(resolve, 5000));

  return Promise.race([
    Promise.all([imagesReady, fontsReady]).then(() => { }),
    masterTimeout,
  ]);
}

// ─── Column Break Polyfill ────────────────────────────────────────────

/**
 * Maps CSS `break-before` / `break-after` values to the legacy
 * `-webkit-column-break-*` equivalents used by WebKit pagination.
 */
export function convertToColumnBreak(value: string): string {
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

/**
 * Wraps numeric font-size / line-height values in a `calc(...* var(--lumina-zoom))`
 * expression so the reader zoom factor is applied correctly.
 */
export function applyRuleWithFixedValue(
  style: CSSStyleDeclaration,
  property: string
): void {
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

export function applyBackgroundColorPolyfill(style: CSSStyleDeclaration): void {
  if (style.backgroundColor &&
    style.backgroundColor !== 'transparent' &&
    !style.backgroundColor.includes('var(--lumina-')) {
    const oldValue = style.getPropertyValue('background-color');
    style.setProperty(
      'background-color',
      'var(--lumina-surface-container-color, ' + oldValue + ')',
      style.getPropertyPriority('background-color')
    );
  }
}

export function removeBackgroundColorPolyfill(style: CSSStyleDeclaration): void {
  const value = style.getPropertyValue('background-color');
  if (value.includes('var(--lumina-surface-container-color')) {
    // Attempt to restore the original background-color if it was overridden by the polyfill
    const originalValue = value.replace(/var\(--lumina-surface-container-color,\s*(.+?)\)/, '$1').trim();
    if (originalValue !== 'transparent' &&
      !originalValue.startsWith('var(--lumina-surface-container-color')) {
      style.setProperty(
        'background-color',
        originalValue,
        style.getPropertyPriority('background-color')
      );
    }
  }
}

/**
 * Applies zoom scaling and WebKit column-break polyfills to a single
 * `CSSStyleDeclaration` (typically one `CSSStyleRule`).
 */
export function applyRules(style: CSSStyleDeclaration, shouldOverrideColor: boolean): void {
  applyRuleWithFixedValue(style, 'font-size');
  applyRuleWithFixedValue(style, 'line-height');

  if (shouldOverrideColor) {
    applyBackgroundColorPolyfill(style);
  } else {
    removeBackgroundColorPolyfill(style);
  }

  const wk = style as WebKitCSSStyle;
  if (style.breakBefore)
    wk.webkitColumnBreakBefore = convertToColumnBreak(style.breakBefore);
  if (style.pageBreakBefore)
    wk.webkitColumnBreakBefore = convertToColumnBreak(style.pageBreakBefore);
  if (style.breakAfter && style.breakAfter !== 'auto')
    wk.webkitColumnBreakAfter = convertToColumnBreak(style.breakAfter);
  if (style.pageBreakAfter && style.pageBreakAfter !== 'auto')
    wk.webkitColumnBreakAfter = convertToColumnBreak(style.pageBreakAfter);
}

/**
 * Iterates every rule in every stylesheet inside `doc` and applies the
 * WebKit break-property polyfill. Cross-origin sheets are silently skipped.
 */
export function polyfillCss(doc: Document, shouldOverrideColor: boolean): void {
  for (let i = 0; i < doc.styleSheets.length; i++) {
    const sheet = doc.styleSheets[i];
    try {
      const rules = sheet.cssRules || (sheet as any).rules;
      if (!rules) continue;
      for (let j = 0; j < rules.length; j++) {
        const rule = rules[j];
        if (rule.type === 1) applyRules((rule as CSSStyleRule).style, shouldOverrideColor);
      }
    } catch (e) {
      console.error('Access to stylesheet blocked: ' + e);
    }
  }
}
