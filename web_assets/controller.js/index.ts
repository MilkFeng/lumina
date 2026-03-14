import { LuminaApi } from './api';
import { EpubRenderer } from './renderer/epub_renderer';

const api: LuminaApi = new EpubRenderer();
window.api = api;

