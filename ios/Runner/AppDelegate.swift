import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let pageTurnPluginKey = "LuminaReaderPageTurnChannel"
  private var pageTurnChannel: FlutterMethodChannel?
  private weak var pageTurnSnapshotView: UIView?
  private weak var pageTurnWebView: WKWebView?
  private var pageTurnAnimator: UIViewPropertyAnimator?
  private var pageTurnAnimationToken: Int = 0

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register the lazy copy-on-demand native file picker plugin.
    if let registrar = self.registrar(forPlugin: "NativePickerPlugin") {
      NativePickerPlugin.register(with: registrar)
    }

    if let registrar = self.registrar(forPlugin: pageTurnPluginKey) {
      let channel = FlutterMethodChannel(
        name: "lumina/reader_page_turn",
        binaryMessenger: registrar.messenger()
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
        self.pageTurnAnimationToken += 1
        self.cancelActivePageTurnAnimation()

        if let existingSnapshot = self.pageTurnSnapshotView,
           let existingWebView = self.pageTurnWebView {
          self.cleanupAfterAnimation(snapshot: existingSnapshot, webView: existingWebView)
        } else {
          self.pageTurnSnapshotView?.removeFromSuperview()
          self.pageTurnSnapshotView = nil
          self.pageTurnWebView = nil
        }

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
        self.cancelActivePageTurnAnimation()

      guard let snapshot = self.pageTurnSnapshotView, 
            let webView = self.pageTurnWebView,
            let superview = webView.superview else {
        result(nil)
        return
      }

        self.pageTurnAnimationToken += 1
        let animationToken = self.pageTurnAnimationToken

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

      let isDarkMode = self.window?.traitCollection.userInterfaceStyle == .dark
      let shadowOpacity: Float = isDarkMode ? 0.3 : 0.15
      
      shadowLayer.shadowColor = UIColor.black.cgColor
      shadowLayer.shadowOpacity = shadowOpacity
      shadowLayer.shadowRadius = 10
      shadowLayer.shadowOffset = .zero
      shadowLayer.shadowPath = UIBezierPath(rect: webView.bounds).cgPath


      if isNext {
        superview.bringSubviewToFront(snapshot)
        
        snapshot.transform = .identity
        webView.transform = .identity

          let animator = UIViewPropertyAnimator(duration: 0.18, curve: .easeOut) {
            snapshot.transform = CGAffineTransform(translationX: -width, y: 0)
          }
          self.pageTurnAnimator = animator
          animator.addCompletion { _ in
            if animationToken == self.pageTurnAnimationToken {
              self.cleanupAfterAnimation(snapshot: snapshot, webView: webView)
          }
            if self.pageTurnAnimator === animator {
              self.pageTurnAnimator = nil
            }
            result(nil)
          }
          animator.startAnimation()

      } else {        
        superview.bringSubviewToFront(webView)
        
        webView.transform = CGAffineTransform(translationX: -width, y: 0)
        snapshot.transform = .identity

          let animator = UIViewPropertyAnimator(duration: 0.18, curve: .easeOut) {
            webView.transform = .identity
          }
          self.pageTurnAnimator = animator
          animator.addCompletion { _ in
            if animationToken == self.pageTurnAnimationToken {
              self.cleanupAfterAnimation(snapshot: snapshot, webView: webView)
            }
            if self.pageTurnAnimator === animator {
              self.pageTurnAnimator = nil
          }
            result(nil)
          }
          animator.startAnimation()
      }
    }
  }

  private func cancelActivePageTurnAnimation() {
    guard let animator = self.pageTurnAnimator else { return }
    animator.stopAnimation(true)
    self.pageTurnAnimator = nil
  }

  private func cleanupAfterAnimation(snapshot: UIView, webView: WKWebView) {
    snapshot.removeFromSuperview()
    snapshot.transform = .identity
    
    snapshot.layer.shadowOpacity = 0
    snapshot.layer.shadowOffset = .zero
    snapshot.layer.shadowPath = nil
    webView.layer.shadowOpacity = 0
    webView.layer.shadowOffset = .zero
    webView.layer.shadowPath = nil
    
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
