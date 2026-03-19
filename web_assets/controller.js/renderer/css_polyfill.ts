import type { ReaderState, WebKitCSSStyle } from '../common/types';
import { FrameManager } from './frame_manager';
import { ThemeManager } from './theme_manager';

export class PolyfillManager {
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
      !style.backgroundColor.includes('var(--lumina-')) {
      const oldValue = style.getPropertyValue('background-color');
      style.setProperty(
        'background-color',
        'var(--lumina-surface-container-color, ' + oldValue + ')',
        style.getPropertyPriority('background-color')
      );
    }
  }

  private removeBackgroundColorPolyfill(style: CSSStyleDeclaration): void {
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

  public polyfillCss(doc: Document): void {
    const frame = this.frameMgr.getCurrFrame();
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