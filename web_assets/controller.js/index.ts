import { LuminaApi } from './api/lumina_api';
import { Renderer } from './renderer/renderer';

const api: LuminaApi = new Renderer();
window.api = api;

