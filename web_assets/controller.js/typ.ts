import { applyDuokanTyp, DuokanTypConfig, getDuokanTypConfig } from './duokan_typ.js';
import { applyRenditionTyp, getRenditionTypConfig, RenditionTypConfig } from './rendition_typ.js';

export function applyTyp(iframe: HTMLIFrameElement) {
  applyDuokanTyp(iframe);
  applyRenditionTyp(iframe);
}

export class TypConfig {
  duokanTypConfig: DuokanTypConfig;
  renditionTypConfig: RenditionTypConfig;

  constructor(duokanTypConfig: DuokanTypConfig, renditionTypConfig: RenditionTypConfig) {
    this.duokanTypConfig = duokanTypConfig;
    this.renditionTypConfig = renditionTypConfig;
  }

  havePadding(): boolean {
    return this.duokanTypConfig.havePadding() && this.renditionTypConfig.havePadding();
  }
}

export function getTypConfig(iframe: HTMLIFrameElement): TypConfig {
  return new TypConfig(getDuokanTypConfig(iframe), getRenditionTypConfig(iframe));
}