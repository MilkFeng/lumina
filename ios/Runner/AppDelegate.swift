import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var pageTurnChannel: FlutterMethodChannel?
  private weak var pageTurnSnapshotView: UIView?
  private weak var pageTurnWebView: WKWebView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "lumina/reader_page_turn",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else {
          result(
            FlutterError(
              code: "UNAVAILABLE",
              message: "AppDelegate deallocated",
              details: nil
            )
          )
          return
        }

        switch call.method {
        case "preparePageTurn":
          self.handlePreparePageTurn(result: result)
        case "animatePageTurn":
          let args = call.arguments as? [String: Any]
          let isNext = args?["isNext"] as? Bool ?? true
          self.handleAnimatePageTurn(isNext: isNext, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      pageTurnChannel = channel
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handlePreparePageTurn(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      self.pageTurnSnapshotView?.removeFromSuperview()
      self.pageTurnSnapshotView = nil
      self.pageTurnWebView = nil

      guard let webView = self.findTopmostWKWebView(in: self.window?.rootViewController?.view) else {
        result(FlutterError(code: "NO_WEBVIEW", message: "No WKWebView found", details: nil))
        return
      }

      guard let superview = webView.superview else {
        result(FlutterError(code: "NO_SUPERVIEW", message: "No superview", details: nil))
        return
      }

      guard let snapshot = webView.snapshotView(afterScreenUpdates: false) else {
        result(FlutterError(code: "SNAPSHOT_FAILED", message: "Failed snapshot", details: nil))
        return
      }

      snapshot.frame = webView.frame
      snapshot.autoresizingMask = [.flexibleWidth, .flexibleHeight]

      superview.addSubview(snapshot)
      // superview.bringSubviewToFront(snapshot)

      self.pageTurnSnapshotView = snapshot
      self.pageTurnWebView = webView
      
      result(nil)
    }
  }

  private func handleAnimatePageTurn(isNext: Bool, result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      guard let snapshot = self.pageTurnSnapshotView, 
            let webView = self.pageTurnWebView,
            let superview = webView.superview else {
        result(nil)
        return
      }

      let width = webView.bounds.width
      if width <= 0 {
        snapshot.removeFromSuperview()
        self.pageTurnSnapshotView = nil
        result(nil)
        return
      }

      let shadowLayer: CALayer
      if isNext {
        shadowLayer = snapshot.layer
      } else {
        shadowLayer = webView.layer
      }
      
      shadowLayer.shadowColor = UIColor.black.cgColor
      shadowLayer.shadowOpacity = 0.3
      shadowLayer.shadowRadius = 10
      shadowLayer.shadowOffset = CGSize(width: isNext ? 5 : -5, height: 0)
      shadowLayer.shadowPath = UIBezierPath(rect: webView.bounds).cgPath


      if isNext {
        superview.bringSubviewToFront(snapshot)
        
        snapshot.transform = .identity
        webView.transform = .identity

        UIView.animate(
          withDuration: 0.18,
          delay: 0,
          options: [.curveEaseOut],
          animations: {
            snapshot.transform = CGAffineTransform(translationX: -width, y: 0)
          },
          completion: { _ in
            self.cleanupAfterAnimation(snapshot: snapshot, webView: webView)
            result(nil)
          }
        )

      } else {        
        superview.bringSubviewToFront(webView)
        
        webView.transform = CGAffineTransform(translationX: -width, y: 0)
        snapshot.transform = .identity

        UIView.animate(
          withDuration: 0.18,
          delay: 0,
          options: [.curveEaseOut],
          animations: {
            webView.transform = .identity
          },
          completion: { _ in
            self.cleanupAfterAnimation(snapshot: snapshot, webView: webView)
            result(nil)
          }
        )
      }
    }
  }

  private func cleanupAfterAnimation(snapshot: UIView, webView: WKWebView) {
    snapshot.removeFromSuperview()
    snapshot.transform = .identity
    
    snapshot.layer.shadowOpacity = 0
    webView.layer.shadowOpacity = 0
    
    webView.transform = .identity
    
    self.pageTurnSnapshotView = nil
    self.pageTurnWebView = nil
  }

  private func findTopmostWKWebView(in view: UIView?) -> WKWebView? {
    guard let view = view else { return nil }
    if let webView = view as? WKWebView {
      return webView
    }

    for subview in view.subviews.reversed() {
      if let webView = findTopmostWKWebView(in: subview) {
        return webView
      }
    }
    return nil
  }
}
