import { QuadTree, Rect } from '../common/quad_tree';
import type { ReaderState, InteractionItem } from '../common/types';
import { FlutterBridge } from '../api/flutter_bridge';
import { getTypConfig } from '../typ/typ';
import { FrameManager } from './frame_manager';

export class InteractionManager {
  constructor(
    private state: ReaderState,
    private frameMgr: FrameManager
  ) { }

  buildInteractionMap(): Promise<void> {
    const iframe = this.frameMgr.getFrame('curr');
    if (!iframe || !iframe.contentDocument) {
      this.state.quadTree = null;
      return Promise.resolve();
    }
    const doc = iframe.contentDocument;

    return new Promise<void>((resolve) => {
      const body = doc.body;
      if (!body) {
        this.state.quadTree = null;
        resolve();
        return;
      }

      const quadTree = new QuadTree<InteractionItem>(
        new Rect(0, 0, Math.max(1, body.scrollWidth), Math.max(1, body.scrollHeight)),
        4
      );
      const bodyRect = body.getBoundingClientRect();

      // ── Images (zy-footnote / duokan-footnote) ──────────────────────
      const images = doc.querySelectorAll('img, image');
      for (let i = 0; i < images.length; i++) {
        const img = images[i] as Element;
        const rect = img.getBoundingClientRect();
        if (!rect || rect.width < 5 || rect.height < 5) continue;

        const docX = rect.left + body.scrollLeft - bodyRect.left;
        const docY = rect.top + body.scrollTop - bodyRect.top;

        // <img class="zhangyue-footnote" zy-footnote="..." />
        let isZyFootnote = img.hasAttribute('zy-footnote');
        let isDuokanFootnote = false;

        if (!isZyFootnote) {
          // <img class="duokan-footnote" alt="..." />
          if (img.classList.contains('duokan-footnote')) {
            isDuokanFootnote = true;
          }
        }

        if (isZyFootnote || isDuokanFootnote) {
          const altText = isZyFootnote
            ? img.getAttribute('zy-footnote') || ''
            : img.getAttribute('alt') || img.getAttribute('title') || '';

          quadTree.insert({
            type: 'footnote',
            // footnotes based on img tag have lower priority than regular footnotes
            // because they often show less content (e.g. image) than regular footnotes
            priority: 2,
            rect: new Rect(docX, docY, rect.width, rect.height),
            data: '<div>' + altText + '</div>',
          });
        }
      }

      // ── Links ────────────────────────────────────────────────────────
      const links = doc.querySelectorAll('a');
      for (let i = 0; i < links.length; i++) {
        const link = links[i];
        const href = link.getAttribute('href');
        const epubType = link.getAttribute('epub:type');
        let innerHtml = '';
        let isFootnote = false;

        if (!href && link.classList.contains('duokan-footnote')) {
          if (!isFootnote) {
            // <note>
            //   <p>
            //     paragraph
            //     <sup> <a class="duokan-footnote" epub:type="noteref" id="note_ref001"> <img /> </a> </sup>
            //     paragraph
            //     <sup> <a class="duokan-footnote" epub:type="noteref" id="note_ref002"> <img /> </a> </sup>
            //     paragraph
            //   </p>
            //   <aside epub:type="footnote" id="note001">
            //     <a href="#note_ref001"> 
            //       ...
            //     </a>
            //   </aside>
            //   <aside epub:type="footnote" id="note002">
            //     <a href="#note_ref001"> 
            //       ...
            //     </a>
            //   </aside>
            // </note>
            const noteAncestor = link.closest('note');
            if (noteAncestor) {
              const asideElements = noteAncestor.querySelectorAll('aside');
              const linkInNoteIndex = Array.from(noteAncestor.querySelectorAll('a')).indexOf(link);
              if (asideElements.length > 0 && linkInNoteIndex >= 0 && linkInNoteIndex < asideElements.length) {
                const aside = asideElements[linkInNoteIndex];
                innerHtml = aside.outerHTML;
                isFootnote = true;
              } else {
                for (let j = 0; j < asideElements.length; j++) {
                  innerHtml += asideElements[j].outerHTML;
                }
                isFootnote = true;
              }
            }
          }

          if (!isFootnote) {
            // <a class="duokan-footnote"> <img alt="..." /> </a>
            if (link.childElementCount === 1) {
              const child = link.children[0];
              if (child.tagName.toLowerCase() === 'img' || child.tagName.toLowerCase() === 'image') {
                const img = child as Element;
                const altText = img.getAttribute('alt') || img.getAttribute('title') || '';
                innerHtml = '<div>' + altText + '</div>';
                isFootnote = true;
              }
            }
          }
        }

        if (!isFootnote) {
          if (link.hasAttribute('title') && (!href || href === '#')) {
            // <a href="#" title="...">...</a>
            // <a title="...">...</a>
            innerHtml = '<div class="footnote-content">' + link.getAttribute('title') + '</div>';
            isFootnote = true;
          }
        }

        if (!isFootnote) {
          if (epubType === 'noteref') {
            // <a epub:type="noteref" href="#note1">...</a>
            innerHtml = this.extractFootnoteHtml(this.extractTargetIdFromHref(href));
            isFootnote = true;
          }
        }

        if (!isFootnote) {
          if (link.classList.contains('duokan-footnote') && href && href.includes('#')) {
            // <a class="duokan-footnote" href="#note1"> ... </a>
            const fullHref = link.href;
            let thisUrl = link.ownerDocument.location.href;
            if (thisUrl.includes('#')) {
              thisUrl = thisUrl.split('#')[0];
            }
            if (fullHref === thisUrl || thisUrl === fullHref.split('#')[0]) {
              innerHtml = this.extractFootnoteHtml(this.extractTargetIdFromHref(href));
              isFootnote = true;
            }
          }
        }

        if (!isFootnote || !innerHtml || innerHtml.trim() === '') continue;

        const rects = link.getClientRects();
        for (let j = 0; j < rects.length; j++) {
          const rect = rects[j];
          if (!rect || rect.width < 5 || rect.height < 5) continue;
          quadTree.insert({
            type: 'footnote',
            // Regular footnotes have the highest priority
            priority: 3,
            rect: new Rect(
              rect.left + body.scrollLeft - bodyRect.left,
              rect.top + body.scrollTop - bodyRect.top,
              rect.width,
              rect.height
            ),
            data: innerHtml,
          });
        }
      }

      // ── Aozora Bunko notes ───────────────────────────────────────────
      const aozoraNotes = doc.querySelectorAll('span.notes, .notes');
      for (let i = 0; i < aozoraNotes.length; i++) {
        const noteSpan = aozoraNotes[i];
        const innerHtml = '<div class="aozora-footnote-content">' + noteSpan.innerHTML + '</div>';
        const rects = noteSpan.getClientRects();
        for (let j = 0; j < rects.length; j++) {
          const rect = rects[j];
          if (!rect || rect.width < 5 || rect.height < 5) continue;
          quadTree.insert({
            type: 'footnote',
            priority: 1,
            rect: new Rect(
              rect.left + body.scrollLeft - bodyRect.left,
              rect.top + body.scrollTop - bodyRect.top,
              rect.width,
              rect.height
            ),
            data: innerHtml,
          });
        }
      }

      this.state.quadTree = quadTree;
      resolve();
    });
  }

  checkLinkAt(x: number, y: number): boolean {
    const iframe = this.frameMgr.getFrame('curr');
    if (iframe && iframe.contentDocument) {
      const doc = iframe.contentDocument;
      const elementAtPoint = doc.elementFromPoint(x, y);
      if (elementAtPoint) {
        const linkEl = elementAtPoint.closest('a');
        if (linkEl) {
          const href = linkEl.getAttribute('href');
          if (href) {
            FlutterBridge.onLinkTap(linkEl.href, x, y);
            return true;
          }
        }
      }
    }
    return false;
  }

  checkTapElementAt(x: number, y: number): void {
    const bestCandidate = this.checkElementAtHelper(x, y, (candidate) => candidate.type === 'footnote');

    if (bestCandidate) {
      const iframe = this.frameMgr.getFrame('curr');
      if (!iframe || !iframe.contentDocument) return;
      const body = iframe.contentDocument.body;
      if (!body) return;

      const rect = bestCandidate.rect;

      let absoluteLeft = rect.x - body.scrollLeft;
      let absoluteTop = rect.y - body.scrollTop;

      const config = getTypConfig(iframe);
      if (config.havePadding()) {
        absoluteLeft += this.state.config.padding.left;
        absoluteTop += this.state.config.padding.top;
      }

      const baseUrl = iframe.contentDocument.baseURI || '';

      if (bestCandidate.type === 'footnote') {
        FlutterBridge.onFootnoteTap(
          bestCandidate.data,
          absoluteLeft, absoluteTop, rect.width, rect.height,
          baseUrl
        );
        return;
      }
    }

    if (this.checkLinkAt(x, y)) return;

    FlutterBridge.onTap(x, y);
  }

  checkImageAt(x: number, y: number): boolean {
    const iframe = this.frameMgr.getFrame('curr');
    if (iframe && iframe.contentDocument) {
      const doc = iframe.contentDocument;
      const bodyRect = doc.body.getBoundingClientRect();
      const elementAtPoint = doc.elementFromPoint(x, y);
      if (elementAtPoint) {
        const imgEl = elementAtPoint.closest('img, image') as HTMLImageElement | SVGImageElement | null;
        if (imgEl) {
          let src = (imgEl as any).currentSrc || (imgEl as any).src || imgEl.getAttribute('xlink:href') || '';
          if (src) {
            const link = doc.createElement('a');
            link.href = src;
            src = link.href;

            const rect = imgEl.getBoundingClientRect();
            if (!rect || rect.width < 5 || rect.height < 5) return false;

            const config = getTypConfig(iframe);

            let docX = rect.left - bodyRect.left;
            let docY = rect.top - bodyRect.top;

            if (config.havePadding()) {
              docX += this.state.config.padding.left;
              docY += this.state.config.padding.top;
            }

            FlutterBridge.onImageLongPress(src, docX, docY, rect.width, rect.height);
            return true;
          }
        }
      }
    }
    return false;
  }

  checkLongPressElementAt(x: number, y: number): void {
    this.checkImageAt(x, y);
  }

  // -- Helper methods ---

  private extractTargetIdFromHref(href: string | null): string | null {
    if (!href || typeof href !== 'string') return null;
    const hashIndex = href.indexOf('#');
    if (hashIndex < 0 || hashIndex >= href.length - 1) return null;
    try {
      return decodeURIComponent(href.substring(hashIndex + 1));
    } catch (_) {
      return href.substring(hashIndex + 1);
    }
  }

  private extractFootnoteHtml(targetId: string | null): string {
    const iframe = this.frameMgr.getFrame('curr');
    if (!iframe || !iframe.contentDocument) return '';

    const doc = iframe.contentDocument;
    if (!targetId) return '';

    const sanitizedId = String(targetId).replace(/^#/, '');
    if (!sanitizedId) return '';

    let footnoteEl: Element | null = doc.getElementById(sanitizedId);
    if (!footnoteEl) {
      footnoteEl = doc.querySelector('[name="' + sanitizedId + '"]');
    }
    if (!footnoteEl) return '';

    if (footnoteEl.textContent!.trim() === '' && footnoteEl.nextElementSibling) {
      footnoteEl = footnoteEl.nextElementSibling;
    }

    const container = footnoteEl.closest('li, aside, section, div, p') || footnoteEl;

    // if the container is li, wrap it in a ol to preserve numbering
    if (container.tagName.toLowerCase() === 'li') {
      const ol = document.createElement('ol');
      const clonedLi = container.cloneNode(true) as HTMLElement;
      ol.appendChild(clonedLi);
      return ol.outerHTML;
    }
    return container?.outerHTML ?? '';
  }

  private checkElementAtHelper(
    x: number,
    y: number,
    checkIfAllowed?: (candidate: InteractionItem) => boolean
  ): InteractionItem | undefined {
    const iframe = this.frameMgr.getCurrFrame();
    if (!iframe || !iframe.contentDocument || !this.state.quadTree) return;

    const body = iframe.contentDocument.body;
    if (!body) return;

    const config = getTypConfig(iframe);

    let docX = x + body.scrollLeft;
    let docY = y + body.scrollTop;

    if (config.havePadding()) {
      docX -= this.state.config.padding.left;
      docY -= this.state.config.padding.top;
    }

    const radius = 20;
    let candidates = this.state.quadTree.query(
      new Rect(docX - radius, docY - radius, radius * 2, radius * 2),
      []
    );

    // Sort candidates by priority (higher first) and then by distance to the point
    candidates.sort((a, b) => {
      if (b.priority !== a.priority) {
        return b.priority - a.priority;
      }
      return 0;
    });

    // Remove candidates whose priority is lower than the highest priority in the list
    if (candidates.length > 0) {
      const highestPriority = candidates[0].priority;
      candidates = candidates.filter(candidate => candidate.priority === highestPriority);
    }

    let bestCandidate: InteractionItem | undefined;
    let minDistance = Infinity;

    for (let i = candidates.length - 1; i >= 0; i--) {
      const candidate = candidates[i];
      if (!candidate?.rect) continue;
      if (checkIfAllowed && !checkIfAllowed(candidate)) continue;

      const rect = new Rect(candidate.rect.x, candidate.rect.y, candidate.rect.width, candidate.rect.height);
      let distance: number;
      if (rect.contains({ x: docX, y: docY })) {
        distance = 0;
      } else {
        const dx = docX - (rect.x + rect.width / 2);
        const dy = docY - (rect.y + rect.height / 2);
        distance = Math.sqrt(dx * dx + dy * dy);
      }

      if (distance < minDistance) {
        minDistance = distance;
        bestCandidate = candidate;
      }
    }

    return bestCandidate;
  }
}