interface Window {
  flutter_inappwebview: {
    callHandler(handlerName: string, ...args: any[]): Promise<any>;
  };
  api: import('./api').LuminaApi;
}