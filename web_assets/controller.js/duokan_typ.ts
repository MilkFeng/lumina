
function removePaddingAndMarginAndFillScreen(element: HTMLElement) {
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
}

export function applyDuokanTyp(iframe: HTMLIFrameElement) {
  if (!iframe) return;
  if (!iframe.contentDocument && !iframe.contentWindow) return;

  const doc = iframe.contentDocument!;

  if (doc.body.classList.contains('lumina-spine-property-duokan-page-fullscreen')) {
    // duokan-page-fullscreen

    const root = doc.documentElement;
    removePaddingAndMarginAndFillScreen(root);
    removePaddingAndMarginAndFillScreen(doc.body);

    // Set all svg elements to fill the viewport while preserving aspect ratio
    const svgs = doc.querySelectorAll('svg');
    for (let i = 0; i < svgs.length; i++) {
      svgs[i].setAttribute('preserveAspectRatio', 'none');
      svgs[i].style.setProperty('width', '100vw', 'important');
      svgs[i].style.setProperty('height', '100vh', 'important');
      svgs[i].style.setProperty('max-width', 'none', 'important');
      svgs[i].style.setProperty('max-height', 'none', 'important');
    }

    // Set all svg image elements to fill their parent svg while preserving aspect ratio
    const svgImages = doc.querySelectorAll('svg image');
    for (let i = 0; i < svgImages.length; i++) {
      svgImages[i].setAttribute('width', '100%');
      svgImages[i].setAttribute('height', '100%');
    }

    // Set all img elements to fill the viewport while preserving aspect ratio
    const imgs = doc.querySelectorAll('img');
    for (let i = 0; i < imgs.length; i++) {
      imgs[i].style.setProperty('width', '100vw', 'important');
      imgs[i].style.setProperty('height', '100vh', 'important');
      imgs[i].style.setProperty('object-fit', 'fill', 'important');
      imgs[i].style.setProperty('max-width', 'none', 'important');
      imgs[i].style.setProperty('max-height', 'none', 'important');
    }

    // Set all elements to have no max-width or max-height to allow them to fill the viewport
    const allElements = doc.body.querySelectorAll('*');
    for (let i = 0; i < allElements.length; i++) {
      const el = allElements[i] as HTMLElement;
      el.style.setProperty('max-width', 'none', 'important');
      el.style.setProperty('max-height', 'none', 'important');
    }
  }
}