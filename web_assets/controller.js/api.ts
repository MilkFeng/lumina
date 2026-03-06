import { FrameSlot, InitConfig, ThemeUpdate } from "./types";

/** The interface exposed on `window.api` */
export interface LuminaApi {
    init(config: InitConfig): void;
    loadFrame(token: number, slot: FrameSlot, url: string, anchors?: string[]): void;
    jumpToPage(pageIndex: number): void;
    jumpToPageFor(slot: FrameSlot, pageIndex: number): void;
    jumpToLastPageOfFrame(slot: FrameSlot): void;
    restoreScrollPosition(token: number, ratio: number): void;
    cycleFrames(direction: 'next' | 'prev'): void;
    updateTheme(token: number, viewWidth: number, viewHeight: number, newTheme: ThemeUpdate): void;
    checkTapElementAt(x: number, y: number): void;
    checkElementAt(x: number, y: number): void;
    waitForRender(token: number): void;
}