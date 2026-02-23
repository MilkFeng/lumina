import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let pageTurnPluginKey = "LuminaReaderPageTurnChannel"
  private var pageTurnChannel: FlutterMethodChannel?
  private weak var pageTurnSnapshotView: UIView?
  private weak var pageTurnWebView: WKWebView?
  private var pageTurnAnimator: UIViewPropertyAnimator?
  private var pageTurnAnimationToken: Int = 0

  // Helper to get the active window's root view controller for snapshotting.
  private var activeWindow: UIWindow? {
    return UIApplication.shared.connectedScenes
      .filter { $0.activationState == .foregroundActive }
      .compactMap { $0 as? UIWindowScene }
      .first?.windows
      .first(where: { $0.isKeyWindow })
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: any FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Register the lazy copy-on-demand native file picker plugin.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NativePickerPlugin") {
      NativePickerPlugin.register(with: registrar)
    }

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: pageTurnPluginKey) {
      let channel = FlutterMethodChannel(
        name: "lumina/reader_page_turn",
        binaryMessenger: engineBridge.applicationRegistrar.messenger()
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
          let isVertical = args?["isVertical"] as? Bool ?? false
          self.handleAnimatePageTurn(isNext: isNext, isVertical: isVertical, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      pageTurnChannel = channel
    }
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

      guard let rootView = self.activeWindow?.rootViewController?.view,
            let webView = self.findTopmostWKWebView(in: rootView) else {
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

  private func handleAnimatePageTurn(isNext: Bool, isVertical: Bool, result: @escaping FlutterResult) {
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

      let isDarkMode = self.activeWindow?.traitCollection.userInterfaceStyle == .dark
      let shadowOpacity: Float = isDarkMode ? 0.3 : 0.15
      
      shadowLayer.shadowColor = UIColor.black.cgColor
      shadowLayer.shadowOpacity = shadowOpacity
      shadowLayer.shadowRadius = 10
      shadowLayer.shadowOffset = .zero
      shadowLayer.shadowPath = UIBezierPath(rect: webView.bounds).cgPath


      if isNext {
        superview.bringSubviewToFront(snapshot)
        
        // if vertical, (0, 0) -> (width, 0)
        // else (0, 0) -> (-width, 0)
        snapshot.transform = .identity
        webView.transform = .identity

        let animator = UIViewPropertyAnimator(duration: 0.18, curve: .easeOut) {
          if isVertical {
            snapshot.transform = CGAffineTransform(translationX: width, y: 0)
          } else {
            snapshot.transform = CGAffineTransform(translationX: -width, y: 0)
          }
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
        
        // if vertical, (width, 0) -> (0, 0)
        // else (-width, 0) -> (0, 0)
        if isVertical {
          webView.transform = CGAffineTransform(translationX: width, y: 0)
        } else {
          webView.transform = CGAffineTransform(translationX: -width, y: 0)
        }
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
