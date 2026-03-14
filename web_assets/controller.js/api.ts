import { Direction, FrameSlot, InitConfig, ThemeUpdate } from "./types";

/// The interface exposed on `window.api`
export interface LuminaApi {
  init(config: InitConfig): void;

  /// Loads the given URL into the specified frame slot
  /// `token`: A unique identifier for an event, when this event is finished, `onEventFinished(token)` will be called
  /// `anchors`: An optional list of element IDs to detect as anchors for page tracking
  /// `properties`: An optional list of properties to apply specifical typography (e.g. duokan-page-fitwidow)
  loadFrame(token: number, slot: FrameSlot, url: string, anchors?: string[], properties?: string[]): void;

  /// Jumps to the specified page index in the current frame. The page index is 0-based
  jumpToPage(token: number, pageIndex: number): void;

  /// Jumps to the specified page index in the specified frame. The page index is 0-based
  jumpToPageFor(token: number, slot: FrameSlot, pageIndex: number): void;

  /// Jumps to the last page in the current frame.
  jumpToLastPageOfFrame(token: number, slot: FrameSlot): void;

  /// Restores the scroll position in the current frame. The ratio is a value between 0 and 1, representing the scroll position as a percentage of the total scrollable height
  restoreScrollPosition(token: number, ratio: number): void;

  /// Cycles to the next or previous page in the current frame, depending on the direction
  cycleFrames(token: number, direction: Direction): void;

  /// Updates the theme and layout settings for the current frame
  updateTheme(token: number, viewWidth: number, viewHeight: number, newTheme: ThemeUpdate): void;

  /// Checks whether there is an interactive element (image, etc.) at (x, y).
  /// If there is nothing, `onTap` will be called
  checkTapElementAt(x: number, y: number): void;

  /// Checks whether there is an interactive element (image, etc.) at (x, y) for long press.
  checkLongPressElementAt(x: number, y: number): void;

  waitForRender(token: number): void;
}