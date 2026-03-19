import { parseColorString, type ReaderState, type WebKitCSSStyle } from '../common/types';
import { FrameManager } from './frame_manager';
import { ThemeManager } from './theme_manager';

export class CssPolyfillManager {
  constructor(
    private state: ReaderState,
    private themeMgr: ThemeManager,
    private frameMgr: FrameManager
  ) { }

  private convertToColumnBreak(value: string): string {
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

  private applyRuleWithFixedValue(
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

  private applyBackgroundColorPolyfill(style: CSSStyleDeclaration): void {
    if (style.backgroundColor &&
      style.backgroundColor !== 'transparent' &&
      !style.backgroundColor.includes('var(--lumina-') &&
      !style.backgroundColor.includes('var(rgba(var(--lumina-')) {
      const oldValue = style.getPropertyValue('background-color');
      const oldColor = parseColorString(oldValue);
      let newColor = '--lumina-surface-container-color';
      if (oldColor) {
        const alpha = oldColor.a !== undefined ? oldColor.a : 1;
        if (alpha < 1) {
          // If the original color has transparency, we need to blend it with the surface color
          // to get a more accurate override color.
          newColor = `rgba(var(--lumina-surface-container-color-rgb), ${alpha})`;
        }
      }
      console.log('Applying background-color polyfill. Original:', oldValue, 'New:', newColor, 'All styles:', 'var(' + newColor + ', ' + oldValue + ')');
      style.setProperty(
        'background-color',
        'var(' + newColor + ', ' + oldValue + ')',
        style.getPropertyPriority('background-color')
      );
    }
  }


  private extractOriginalValue(cssVarStr: string): string | null {
    const s = cssVarStr.trim();
    if (!s.startsWith('var(') || !s.endsWith(')')) {
      return null;
    }
    const content = s.substring(4, s.length - 1);

    let depth = 0;
    let commaIndex = -1;

    for (let i = 0; i < content.length; i++) {
      const char = content[i];
      if (char === '(') {
        depth++;
      } else if (char === ')') {
        depth--;
      } else if (char === ',' && depth === 0) {
        commaIndex = i;
        break;
      }
    }

    if (commaIndex === -1) {
      return null;
    }

    const result = content.substring(commaIndex + 1).trim();
    return result || null;
  }

  private removeBackgroundColorPolyfill(style: CSSStyleDeclaration): void {
    const value = style.getPropertyValue('background-color');
    if (value.includes('var(--lumina-surface-container-color')
      || value.includes('var(rgba(var(--lumina-surface-container-color-rgb)')) {
      // Attempt to restore the original background-color if it was overridden by the polyfill
      // var(--lumina-surface-container-color, originalValue)
      // var(rgba(var(--lumina-surface-container-color-rgb), alpha), originalValue)
      const originalValue = this.extractOriginalValue(value);
      if (originalValue) {
        style.setProperty(
          'background-color',
          originalValue,
          style.getPropertyPriority('background-color')
        );
      }
    }
  }

  private applyRules(style: CSSStyleDeclaration, shouldOverrideColor: boolean): void {
    this.applyRuleWithFixedValue(style, 'font-size');
    this.applyRuleWithFixedValue(style, 'line-height');

    if (shouldOverrideColor) {
      this.applyBackgroundColorPolyfill(style);
    } else {
      this.removeBackgroundColorPolyfill(style);
    }

    const wk = style as WebKitCSSStyle;
    if (style.breakBefore)
      wk.webkitColumnBreakBefore = this.convertToColumnBreak(style.breakBefore);
    if (style.pageBreakBefore)
      wk.webkitColumnBreakBefore = this.convertToColumnBreak(style.pageBreakBefore);
    if (style.breakAfter && style.breakAfter !== 'auto')
      wk.webkitColumnBreakAfter = this.convertToColumnBreak(style.breakAfter);
    if (style.pageBreakAfter && style.pageBreakAfter !== 'auto')
      wk.webkitColumnBreakAfter = this.convertToColumnBreak(style.pageBreakAfter);
  }

  public polyfillCss(frame: HTMLIFrameElement | null): void {
    if (!frame || !frame.contentDocument) return;
    const doc = frame.contentDocument;

    const shouldOverrideColor = frame
      ? this.state.config.theme.shouldOverrideTextColor && !this.themeMgr.haveBackground(frame)
      : this.state.config.theme.shouldOverrideTextColor;

    for (let i = 0; i < doc.styleSheets.length; i++) {
      const sheet = doc.styleSheets[i];
      try {
        const rules = sheet.cssRules || (sheet as any).rules;
        if (!rules) continue;
        for (let j = 0; j < rules.length; j++) {
          const rule = rules[j];
          if (rule.type === 1) this.applyRules((rule as CSSStyleRule).style, shouldOverrideColor);
        }
      } catch (e) {
        console.error('Access to stylesheet blocked: ' + e);
      }
    }
  }
}