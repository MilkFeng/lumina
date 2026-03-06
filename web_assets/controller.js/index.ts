import { LuminaApi } from './api';
import { EpubReader } from './epub_reader';

const api: LuminaApi = new EpubReader();
window.api = api;

