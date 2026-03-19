import { colorToHex, type ReaderState, type ThemeUpdate } from '../common/types';
import { FrameManager } from './frame_manager';

export class ThemeManager {
  constructor(
    private state: ReaderState,
    private frameMgr: FrameManager
  ) { }

  updateThemeState(viewWidth: number, viewHeight: number, newTheme: ThemeUpdate): void {
    this.state.config.safeWidth = Math.floor(viewWidth);
    this.state.config.safeHeight = Math.floor(viewHeight);
    this.state.config.padding = newTheme.padding;
    this.state.config.theme = newTheme.theme;
  }

  haveBackground(iframe: HTMLIFrameElement): boolean {
    if (!iframe || !iframe.contentDocument || !iframe.contentWindow) return false;
    try {
      const window = iframe.contentWindow!;
      const body = iframe.contentDocument.body;
      if (!body) {
        console.warn('Iframe body is null, possibly not fully loaded or not an HTML document.');
        return false;
      }
      const bgColor = window.getComputedStyle(body).backgroundColor;
      if (bgColor && bgColor !== 'rgba(0, 0, 0, 0)' && bgColor !== 'transparent') {
        return true;
      }
      const bgImage = window.getComputedStyle(body).backgroundImage;
      if (bgImage && bgImage !== 'none') {
        // Add a white background to body to ensure text is visible
        body.style.backgroundColor = '#ffffff';
        return true;
      }
    } catch (e) {
      console.warn('Failed to get original background color from iframe:', e);
      return false;
    }
    return false;
  }

  generateVariableStyle(): string {
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
      + `--lumina-surface-color: ${colorToHex(t.surfaceColor)};`
      + `--lumina-surface-color-rgb: ${t.surfaceColor.r}, ${t.surfaceColor.g}, ${t.surfaceColor.b};`
      + `--lumina-on-surface-color: ${colorToHex(t.onSurfaceColor)};`
      + `--lumina-on-surface-color-rgb: ${t.onSurfaceColor.r}, ${t.onSurfaceColor.g}, ${t.onSurfaceColor.b};`
      + `--lumina-primary-color: ${colorToHex(t.primaryColor)};`
      + `--lumina-primary-color-rgb: ${t.primaryColor.r}, ${t.primaryColor.g}, ${t.primaryColor.b};`
      + `--lumina-primary-container-color: ${colorToHex(t.primaryContainerColor)};`
      + `--lumina-primary-container-color-rgb: ${t.primaryContainerColor.r}, ${t.primaryContainerColor.g}, ${t.primaryContainerColor.b};`
      + `--lumina-on-surface-variant-color: ${colorToHex(t.onSurfaceVariantColor)};`
      + `--lumina-on-surface-variant-color-rgb: ${t.onSurfaceVariantColor.r}, ${t.onSurfaceVariantColor.g}, ${t.onSurfaceVariantColor.b};`
      + `--lumina-outline-variant-color: ${colorToHex(t.outlineVariantColor)};`
      + `--lumina-outline-variant-color-rgb: ${t.outlineVariantColor.r}, ${t.outlineVariantColor.g}, ${t.outlineVariantColor.b};`
      + `--lumina-surface-container-color: ${colorToHex(t.surfaceContainerColor)};`
      + `--lumina-surface-container-color-rgb: ${t.surfaceContainerColor.r}, ${t.surfaceContainerColor.g}, ${t.surfaceContainerColor.b};`
      + `--lumina-surface-container-high-color: ${colorToHex(t.surfaceContainerHighColor)};`
      + `--lumina-surface-container-high-color-rgb: ${t.surfaceContainerHighColor.r}, ${t.surfaceContainerHighColor.g}, ${t.surfaceContainerHighColor.b};`
      + fontFamilyItem
      + '}';
  }

  updateCSSVariables(
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
    root.style.setProperty('--lumina-surface-color', colorToHex(t.surfaceColor));
    root.style.setProperty('--lumina-surface-color-rgb', `${t.surfaceColor.r}, ${t.surfaceColor.g}, ${t.surfaceColor.b}`);
    root.style.setProperty('--lumina-on-surface-color', colorToHex(t.onSurfaceColor));
    root.style.setProperty('--lumina-on-surface-color-rgb', `${t.onSurfaceColor.r}, ${t.onSurfaceColor.g}, ${t.onSurfaceColor.b}`);
    root.style.setProperty('--lumina-primary-color', colorToHex(t.primaryColor));
    root.style.setProperty('--lumina-primary-color-rgb', `${t.primaryColor.r}, ${t.primaryColor.g}, ${t.primaryColor.b}`);
    root.style.setProperty('--lumina-primary-container-color', colorToHex(t.primaryContainerColor));
    root.style.setProperty('--lumina-primary-container-color-rgb', `${t.primaryContainerColor.r}, ${t.primaryContainerColor.g}, ${t.primaryContainerColor.b}`);
    root.style.setProperty('--lumina-on-surface-variant-color', colorToHex(t.onSurfaceVariantColor));
    root.style.setProperty('--lumina-on-surface-variant-color-rgb', `${t.onSurfaceVariantColor.r}, ${t.onSurfaceVariantColor.g}, ${t.onSurfaceVariantColor.b}`);
    root.style.setProperty('--lumina-outline-variant-color', colorToHex(t.outlineVariantColor));
    root.style.setProperty('--lumina-outline-variant-color-rgb', `${t.outlineVariantColor.r}, ${t.outlineVariantColor.g}, ${t.outlineVariantColor.b}`);
    root.style.setProperty('--lumina-surface-container-color', colorToHex(t.surfaceContainerColor));
    root.style.setProperty('--lumina-surface-container-color-rgb', `${t.surfaceContainerColor.r}, ${t.surfaceContainerColor.g}, ${t.surfaceContainerColor.b}`);
    root.style.setProperty('--lumina-surface-container-high-color', colorToHex(t.surfaceContainerHighColor));
    root.style.setProperty('--lumina-surface-container-high-color-rgb', `${t.surfaceContainerHighColor.r}, ${t.surfaceContainerHighColor.g}, ${t.surfaceContainerHighColor.b}`);

    const overrideColor = iframe != null
      ? t.shouldOverrideTextColor && !this.haveBackground(iframe)
      : t.shouldOverrideTextColor;

    body.classList.toggle('lumina-override-color', overrideColor);
    body.classList.toggle('lumina-force-override-font', !!(t.overrideFontFamily && t.fontFileName));
    body.classList.toggle('lumina-override-font', !!(t.fontFileName));

    const existingStyle = doc.getElementById(styleId);
    if (existingStyle) {
      existingStyle.innerHTML = this.generateVariableStyle();
    }
  }

  injectInitialStyles(doc: Document, iframe: HTMLIFrameElement): void {
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
      existingPaginationStyle.innerHTML = this.state.config.paginationCss;
    } else {
      const style = doc.createElement('style');
      style.id = 'injected-pagination-style';
      style.innerHTML = this.state.config.paginationCss;
      doc.head.appendChild(style);
    }
  }
}