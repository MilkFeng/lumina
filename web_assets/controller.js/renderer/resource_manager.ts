import { ReaderState } from "../common/types";

export class ResourceManager {
  constructor(
    private state: ReaderState,
  ) { }

  /// Waits for all images and fonts in the document to finish loading,
  /// with a hard 5-second master timeout.
  public waitForAllResources(doc: Document): Promise<void> {
    const imagesReady = Promise.all(
      Array.from(doc.images).map((img) => {
        if (!img.src) return Promise.resolve();
        if (img.complete) return Promise.resolve();
        if (img.naturalHeight !== 0) return Promise.resolve();

        return new Promise<void>((resolve) => {
          const timer = setTimeout(() => {
            img.removeEventListener('load', onLoadOrError);
            img.removeEventListener('error', onLoadOrError);
            console.warn('Image load timeout:', img.src);
            resolve();
          }, 3000);

          const onLoadOrError = () => {
            clearTimeout(timer);
            resolve();
          };

          img.addEventListener('load', onLoadOrError, { once: true });
          img.addEventListener('error', onLoadOrError, { once: true });
        });
      })
    );

    const fontsReady = doc.fonts?.ready ?? Promise.resolve();
    const masterTimeout = new Promise<void>((resolve) => setTimeout(resolve, 5000));

    return Promise.race([
      Promise.all([imagesReady, fontsReady]).then(() => { }),
      masterTimeout,
    ]);
  }
}