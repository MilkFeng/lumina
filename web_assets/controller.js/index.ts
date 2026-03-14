import { LuminaApi } from './api';
import { Renderer } from './renderer/renderer';

const api: LuminaApi = new Renderer();
window.api = api;

