import type { ReaderState, FrameSlot, Direction } from '../common/types';

export class FrameManager {
  constructor(private state: ReaderState) { }

  /// Get the iframe element by slot name or full id
  getFrame(slotOrId: string): HTMLIFrameElement | null {
    const id = slotOrId.startsWith('frame-') ? slotOrId : 'frame-' + slotOrId;
    return document.getElementById(id) as HTMLIFrameElement | null;
  }

  /// Get the current frame element
  getCurrFrame(): HTMLIFrameElement | null {
    return this.getFrame('curr');
  }

  /// Extract the slot name from a full frame id
  getSlotFromId(frameId: string): FrameSlot {
    return (frameId ? frameId.replace('frame-', '') : '') as FrameSlot;
  }

  /// Get the slot name from an iframe element
  getSlotFromElement(iframe: HTMLIFrameElement): FrameSlot {
    return this.getSlotFromId(iframe.id);
  }

  /// Check if the reading direction is vertical
  isVertical(): boolean {
    return this.state.config.direction === 1;
  }

  /// Get the safe width for the iframes based on the configuration
  getWidth(): number {
    return this.state.config.safeWidth;
  }

  /// Get the safe height for the iframes based on the configuration
  getHeight(): number {
    return this.state.config.safeHeight;
  }

  /// Scroll the content of the given iframe to the specified offset
  scrollTo(iframe: HTMLIFrameElement, offset: number): void {
    if (!iframe || !iframe.contentWindow || !iframe.contentDocument) return;

    const scrollOptions: ScrollToOptions = this.isVertical()
      ? { top: offset, left: 0, behavior: 'auto' }
      : { top: 0, left: offset, behavior: 'auto' };

    iframe.contentDocument.body.scrollTo(scrollOptions);
  }

  /// Cycle the frames in the DOM and update the state based on the given direction
  cycleFramesDOMAndState(direction: Direction): {
    elPrev: HTMLIFrameElement;
    elCurr: HTMLIFrameElement;
    elNext: HTMLIFrameElement;
  } | null {
    const elPrev = this.getFrame('prev');
    const elCurr = this.getFrame('curr');
    const elNext = this.getFrame('next');

    if (!elPrev || !elCurr || !elNext) return null;

    if (direction === 'next') {
      elPrev.id = 'frame-temp';

      elNext.id = 'frame-curr';
      elNext.style.zIndex = '2';
      elNext.style.opacity = '1';

      elCurr.id = 'frame-prev';
      elCurr.style.zIndex = '1';
      elCurr.style.opacity = '0';

      const recycled = document.getElementById('frame-temp') as HTMLElement;
      recycled.id = 'frame-next';
      recycled.style.zIndex = '1';
      recycled.style.opacity = '0';

      const tempAnchors = this.state.anchors.prev;
      this.state.anchors.prev = this.state.anchors.curr;
      this.state.anchors.curr = this.state.anchors.next;
      this.state.anchors.next = tempAnchors;

      const tempProperties = this.state.properties.prev;
      this.state.properties.prev = this.state.properties.curr;
      this.state.properties.curr = this.state.properties.next;
      this.state.properties.next = tempProperties;

    } else if (direction === 'prev') {
      elNext.id = 'frame-temp';

      elPrev.id = 'frame-curr';
      elPrev.style.zIndex = '2';
      elPrev.style.opacity = '1';

      elCurr.id = 'frame-next';
      elCurr.style.zIndex = '1';
      elCurr.style.opacity = '0';

      const recycled = document.getElementById('frame-temp') as HTMLElement;
      recycled.id = 'frame-prev';
      recycled.style.zIndex = '1';
      recycled.style.opacity = '0';

      const tempAnchors = this.state.anchors.next;
      this.state.anchors.next = this.state.anchors.curr;
      this.state.anchors.curr = this.state.anchors.prev;
      this.state.anchors.prev = tempAnchors;

      const tempProperties = this.state.properties.next;
      this.state.properties.next = this.state.properties.curr;
      this.state.properties.curr = this.state.properties.prev;
      this.state.properties.prev = tempProperties;
    }

    return {
      elPrev: this.getFrame('prev')!,
      elCurr: this.getFrame('curr')!,
      elNext: this.getFrame('next')!
    };
  }
}