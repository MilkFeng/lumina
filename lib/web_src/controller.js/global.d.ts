interface Window {
  flutter_inappwebview: {
    callHandler(handlerName: string, ...args: any[]): Promise<any>;
  };
  reader: any;
}