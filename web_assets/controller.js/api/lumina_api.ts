import { Direction, FrameSlot, InitConfig, ThemeUpdate } from "../common/types";

/// The interface exposed on `window.api`
export interface LuminaApi {
  init(config: InitConfig): void;

  /// Loads the given URL into the specified frame slot
  /// `token`: A unique identifier for an event, when this event is finished, `onEventFinished(token)` will be called
  /// `anchors`: An optional list of element IDs to detect as anchors for page tracking
  /// `properties`: An optional list of properties to apply specifical typography (e.g. duokan-page-fitwidow)
  /// `initialScrollRatio`: An optional position to start the frame at, as a
  /// fraction of the scrollable length (scroll mode) or of the page count.
  /// It is applied while the frame loads, so restoring a reading position needs
  /// no separate scroll call.
  loadFrame(
    token: number,
    slot: FrameSlot,
    url: string,
    anchors?: string[],
    properties?: string[],
    initialScrollRatio?: number | null
  ): void;

  /// Jumps to the specified page index in the current frame. The page index is 0-based
  jumpToPage(token: number, pageIndex: number): void;

  /// Jumps to the specified page index in the specified frame. The page index is 0-based
  jumpToPageFor(token: number, slot: FrameSlot, pageIndex: number): void;

  /// Jumps to the last page in the current frame.
  jumpToLastPageOfFrame(token: number, slot: FrameSlot): void;

  /// Scrolls the current frame by roughly one screenful in `direction`, in
  /// scroll mode.
  ///
  /// This is a one-shot command for a turn that has no gesture of its own
  /// behind it — the volume keys, the control panel arrows, a tap in the outer
  /// third of the page.  It is deliberately not part of the gesture path: the
  /// page scrolls itself with its own scrolling, and its progress comes back
  /// through `onScrollProgress`.
  ///
  /// `onEventFinished(token)` fires once the screenful has landed, with the
  /// position it landed on reported just before it — Flutter drives turns one
  /// at a time and needs both to decide what the next turn means.
  scrollByViewport(token: number, direction: Direction): void;

  /// Lands the viewport scroll that is animating, if any, on its target now.
  ///
  /// Called when a turn arrives while an earlier one is still scrolling: the
  /// reader has asked to move on, so that screenful is completed rather than
  /// abandoned halfway.  Resolves the token the scroll was started with.
  finishScrollByViewport(): void;

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