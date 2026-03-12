import { Direction, FrameSlot, InitConfig, ThemeUpdate } from "./types";

/** The interface exposed on `window.api` */
export interface LuminaApi {
    init(config: InitConfig): void;
    loadFrame(token: number, slot: FrameSlot, url: string, anchors?: string[], properties?: string[]): void;
    jumpToPage(token: number, pageIndex: number): void;
    jumpToPageFor(token: number, slot: FrameSlot, pageIndex: number): void;
    jumpToLastPageOfFrame(token: number, slot: FrameSlot): void;
    restoreScrollPosition(token: number, ratio: number): void;
    cycleFrames(token: number, direction: Direction): void;
    updateTheme(token: number, viewWidth: number, viewHeight: number, newTheme: ThemeUpdate): void;
    checkTapElementAt(x: number, y: number): void;
    checkElementAt(x: number, y: number): void;
    waitForRender(token: number): void;
}