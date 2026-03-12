
export function removePaddingAndMarginAndFillScreen(element: HTMLElement) {
  if (!element || !element.style) return;
  element.style.setProperty('padding', '0', 'important');
  element.style.setProperty('padding-top', '0', 'important');
  element.style.setProperty('padding-bottom', '0', 'important');
  element.style.setProperty('padding-left', '0', 'important');
  element.style.setProperty('padding-right', '0', 'important');

  element.style.setProperty('height', '100vh', 'important');
  element.style.setProperty('width', '100vw', 'important');

  element.style.setProperty('max-width', 'none', 'important');
  element.style.setProperty('max-height', 'none', 'important');

  element.style.setProperty('margin', '0', 'important');
  element.style.setProperty('margin-top', '0', 'important');
  element.style.setProperty('margin-bottom', '0', 'important');
  element.style.setProperty('margin-left', '0', 'important');
  element.style.setProperty('margin-right', '0', 'important');

  element.style.setProperty('column-width', 'auto', 'important');
  element.style.setProperty('column-count', '1', 'important');
  element.style.setProperty('column-gap', '0', 'important');

  element.style.setProperty('-webkit-column-width', 'auto', 'important');
  element.style.setProperty('-webkit-column-count', '1', 'important');
  element.style.setProperty('-webkit-column-gap', '0', 'important');

  element.style.setProperty('overflow', 'hidden', 'important');
}

export function setupFullscreenElement(el: HTMLElement | SVGElement, doc: Document) {
  if (!el) return;

  let isRotated90 = false;
  let rotationDeg = 0;

  let current: HTMLElement | null = el as HTMLElement;
  while (current && current !== doc.documentElement) {
    const style = window.getComputedStyle(current);
    const transform = style.transform || style.webkitTransform;

    if (!isRotated90 && transform && transform !== 'none') {
      const values = transform.split('(')[1].split(')')[0].split(',');
      if (values.length >= 6) {
        const a = parseFloat(values[0]);
        const b = parseFloat(values[1]);
        if (Math.abs(b) > 0.5 && Math.abs(a) < 0.5) {
          isRotated90 = true;
          rotationDeg = b > 0 ? 90 : -90;
        }
      }
    }

    if (current && current !== el && current.style) {
      current.style.setProperty('transform', 'none', 'important');
      current.style.setProperty('-webkit-transform', 'none', 'important');
    }

    current = current.parentElement;
  }

  if (!el.style) return;

  el.style.setProperty('position', 'fixed', 'important');
  el.style.setProperty('z-index', '9999', 'important');
  el.style.setProperty('max-width', 'none', 'important');
  el.style.setProperty('max-height', 'none', 'important');
  el.style.setProperty('margin', '0', 'important');
  el.style.setProperty('padding', '0', 'important');

  if (isRotated90) {
    el.style.setProperty('width', '100vh', 'important');
    el.style.setProperty('height', '100vw', 'important');

    el.style.setProperty('top', '50%', 'important');
    el.style.setProperty('left', '50%', 'important');

    const transformValue = `translate(-50%, -50%) rotate(${rotationDeg}deg)`;
    el.style.setProperty('transform', transformValue, 'important');
    el.style.setProperty('-webkit-transform', transformValue, 'important');
    el.style.setProperty('transform-origin', 'center center', 'important');
  } else {
    el.style.setProperty('width', '100vw', 'important');
    el.style.setProperty('height', '100vh', 'important');
    el.style.setProperty('top', '0', 'important');
    el.style.setProperty('left', '0', 'important');

    el.style.setProperty('transform', 'none', 'important');
    el.style.setProperty('-webkit-transform', 'none', 'important');
  }
}

export function applyCenteringStyles(iframe: HTMLIFrameElement) {
  if (!iframe) return;
  if (!iframe.contentDocument && !iframe.contentWindow) return;

  const doc = iframe.contentDocument!;

  const root = doc.documentElement;
  removePaddingAndMarginAndFillScreen(root);
  removePaddingAndMarginAndFillScreen(doc.body);

  const svgs = doc.querySelectorAll('svg');
  for (let i = 0; i < svgs.length; i++) {
    svgs[i].setAttribute('preserveAspectRatio', 'xMidYMid meet');
    setupFullscreenElement(svgs[i], doc);
  }

  const svgImages = doc.querySelectorAll('svg image');
  for (let i = 0; i < svgImages.length; i++) {
    svgImages[i].setAttribute('width', '100%');
    svgImages[i].setAttribute('height', '100%');
  }

  const imgs = doc.querySelectorAll('img');
  for (let i = 0; i < imgs.length; i++) {
    imgs[i].style.setProperty('object-fit', 'contain', 'important');
    setupFullscreenElement(imgs[i], doc);
  }

  const allElements = doc.body.querySelectorAll('*');
  for (let i = 0; i < allElements.length; i++) {
    const el = allElements[i] as HTMLElement;
    if (!el.style) continue;
    if (el.tagName !== 'IMG' && el.tagName !== 'SVG' && el.tagName !== 'image') {
      el.style.setProperty('margin', '0', 'important');
      el.style.setProperty('padding', '0', 'important');
      el.style.setProperty('max-width', 'none', 'important');
      el.style.setProperty('max-height', 'none', 'important');
    }
  }
}