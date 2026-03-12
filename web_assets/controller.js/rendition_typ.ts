import { applyCenteringStyles } from './typ_common';

export class RenditionTypConfig {
  isPageSpreadCenter: boolean;

  constructor(isPageSpreadCenter: boolean) {
    this.isPageSpreadCenter = isPageSpreadCenter;
  }

  havePadding(): boolean {
    return !this.isPageSpreadCenter;
  }
}

export function getRenditionTypConfig(iframe: HTMLIFrameElement): RenditionTypConfig {
  if (!iframe) return new RenditionTypConfig(false);
  if (!iframe.contentDocument && !iframe.contentWindow) return new RenditionTypConfig(false);

  const doc = iframe.contentDocument!;
  return new RenditionTypConfig(
    doc.body.classList.contains('lumina-spine-property-rendition-COLON-page-spread-center') ||
    doc.body.classList.contains('lumina-spine-property-page-spread-center')
  );
}

export function applyRenditionTyp(iframe: HTMLIFrameElement) {
  if (!iframe) return;
  if (!iframe.contentDocument && !iframe.contentWindow) return;

  const doc = iframe.contentDocument!;
  const config = getRenditionTypConfig(iframe);

  if (config.isPageSpreadCenter) {
    applyCenteringStyles(iframe);
  }
}