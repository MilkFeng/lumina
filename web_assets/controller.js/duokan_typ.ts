import { applyCenteringStyles } from './typ_common';

export class DuokanTypConfig {
  isFullscreen: boolean;
  isFitWindow: boolean;

  constructor(isFullscreen: boolean, isFitWindow: boolean) {
    this.isFullscreen = isFullscreen;
    this.isFitWindow = isFitWindow;
  }

  havePadding(): boolean {
    return !this.isFullscreen && !this.isFitWindow;
  }
};

export function getDuokanTypConfig(iframe: HTMLIFrameElement): DuokanTypConfig {
  if (!iframe) return new DuokanTypConfig(false, false);
  if (!iframe.contentDocument && !iframe.contentWindow) return new DuokanTypConfig(false, false);
  const doc = iframe.contentDocument!;
  return new DuokanTypConfig(
    doc.body.classList.contains('lumina-spine-property-duokan-page-fullscreen'),
    doc.body.classList.contains('lumina-spine-property-duokan-page-fitwindow')
  );
}

export function applyDuokanTyp(iframe: HTMLIFrameElement) {
  if (!iframe) return;
  if (!iframe.contentDocument && !iframe.contentWindow) return;

  const config = getDuokanTypConfig(iframe);

  if (config.isFullscreen || config.isFitWindow) {
    applyCenteringStyles(iframe);
  }
}