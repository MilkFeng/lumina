import type { ReaderState } from '../common/types';
import { FrameManager } from './frame_manager';
import { FlutterBridge } from '../api/flutter_bridge';

export class PaginationManager {
  constructor(
    private state: ReaderState,
    private frameMgr: FrameManager
  ) { }

  calculatePageCount(iframe: HTMLIFrameElement | null): number {
    if (!iframe || !iframe.contentDocument) return 0;
    if (this.frameMgr.isVertical()) {
      const scrollHeight = iframe.contentDocument.body.scrollHeight;
      return Math.round((scrollHeight + 128) / (this.frameMgr.getHeight() + 128));
    } else {
      const scrollWidth = iframe.contentDocument.body.scrollWidth;
      return Math.round((scrollWidth + 128) / (this.frameMgr.getWidth() + 128));
    }
  }

  calculateScrollOffset(pageIndex: number): number {
    if (this.frameMgr.isVertical()) {
      return pageIndex * this.frameMgr.getHeight() + pageIndex * 128;
    } else {
      return pageIndex * this.frameMgr.getWidth() + pageIndex * 128;
    }
  }

  calculateCurrentPageIndex(): number {
    const iframe = this.frameMgr.getCurrFrame();
    if (!iframe || !iframe.contentWindow || !iframe.contentDocument) return 0;

    if (this.frameMgr.isVertical()) {
      const scrollTop = iframe.contentDocument.body.scrollTop || 0;
      return Math.round((scrollTop + 128) / (this.frameMgr.getHeight() + 128));
    } else {
      const scrollLeft = iframe.contentDocument.body.scrollLeft || 0;
      return Math.round((scrollLeft + 128) / (this.frameMgr.getWidth() + 128));
    }
  }

  calculatePageIndexOfAnchor(iframe: HTMLIFrameElement | null, anchorId: string): number {
    if (!iframe || !iframe.contentDocument) return 0;
    const doc = iframe.contentDocument;
    const element = doc.getElementById(anchorId);
    if (!element) return 0;

    const bodyRect = doc.body.getBoundingClientRect();
    const rects = element.getClientRects();
    const elementRect = rects.length > 0 ? rects[0] : element.getBoundingClientRect();

    if (this.frameMgr.isVertical()) {
      const absoluteTop = elementRect.top + doc.body.scrollTop - bodyRect.top + (elementRect.height / 5) + 1;
      return Math.floor((absoluteTop + 128) / (this.frameMgr.getHeight() + 128));
    } else {
      const absoluteLeft = elementRect.left + doc.body.scrollLeft - bodyRect.left + (elementRect.width / 5) + 1;
      return Math.floor((absoluteLeft + 128) / (this.frameMgr.getWidth() + 128));
    }
  }


  updatePageState(iframeId: string): void {
    const iframe = this.frameMgr.getFrame(iframeId);
    if (!iframe || !iframe.contentWindow) return;

    const pageCount = this.calculatePageCount(iframe);

    if (iframeId === 'frame-curr') {
      FlutterBridge.onPageCountReady(pageCount);
      FlutterBridge.onPageChanged(this.calculateCurrentPageIndex());
    } else if (iframeId === 'frame-prev') {
      const targetIndex = Math.max(0, pageCount - 1);
      const offset = this.calculateScrollOffset(targetIndex);
      this.frameMgr.scrollTo(iframe, offset);
    } else if (iframeId === 'frame-next') {
      const offset = this.calculateScrollOffset(0);
      this.frameMgr.scrollTo(iframe, offset);
    }
  }

  detectActiveAnchor(iframe: HTMLIFrameElement | null): void {
    if (!iframe || !iframe.contentDocument) return;
    if (iframe.id !== 'frame-curr') return;

    const anchors = this.state.anchors.curr;
    if (!anchors || anchors.length === 0) return;

    const doc = iframe.contentDocument;
    const activeAnchors: string[] = [];
    let lastPassedAnchor = 'top';
    const threshold = 50;
    const isVertical = this.frameMgr.isVertical();

    for (let i = 0; i < anchors.length; i++) {
      const anchorId = anchors[i];
      if (anchorId === 'top') {
        if (isVertical ? doc.body.scrollTop < threshold : doc.body.scrollLeft < threshold) {
          activeAnchors.push('top');
        }
        continue;
      }

      const element = doc.getElementById(anchorId);
      if (element) {
        const rect = element.getBoundingClientRect();
        if (isVertical) {
          if (rect.top < threshold && rect.bottom > threshold) activeAnchors.push(anchorId);
          if (rect.top < threshold) lastPassedAnchor = anchorId;
        } else {
          if (rect.left < threshold && rect.right > threshold) activeAnchors.push(anchorId);
          if (rect.left < threshold) lastPassedAnchor = anchorId;
        }
      }
    }

    if (activeAnchors.length === 0 && lastPassedAnchor) {
      activeAnchors.push(lastPassedAnchor);
    }
    FlutterBridge.onScrollAnchors(activeAnchors);
  }
}