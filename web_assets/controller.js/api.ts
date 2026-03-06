import { FrameSlot, InitConfig, ThemeUpdate } from "./types";

/** The interface exposed on `window.api` */
export interface LuminaApi {
    init(config: InitConfig): void;
    loadFrame(slot: FrameSlot, url: string, anchors?: string[]): void;
    jumpToPage(pageIndex: number): void;
    jumpToPageFor(slot: FrameSlot, pageIndex: number): void;
    jumpToLastPageOfFrame(slot: FrameSlot): void;
    restoreScrollPosition(ratio: number): void;
    cycleFrames(direction: 'next' | 'prev'): void;
    updateTheme(token: string, viewWidth: number, viewHeight: number, newTheme: ThemeUpdate): void;
    checkLinkAt(x: number, y: number): boolean;
    checkTapElementAt(x: number, y: number): void;
    checkImageAt(x: number, y: number): boolean;
    checkElementAt(x: number, y: number): void;
    waitForRender(token: string): void;
}