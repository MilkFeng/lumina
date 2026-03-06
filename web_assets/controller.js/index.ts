import { LuminaApi } from './api';
import { EpubReader } from './epub_reader';

const reader: LuminaApi = new EpubReader();
window.api = reader;

