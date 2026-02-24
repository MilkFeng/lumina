import Flutter
import UIKit
import WebKit

/// Flutter plugin that drives slide-transition page-turn animations inside the
/// Lumina reader by snapshotting the active `WKWebView` and animating it.
///
/// Channel: `lumina/reader_page_turn`
/// Methods:
///   - `preparePageTurn`   → snapshots the current web view (returns nil / error)
///   - `animatePageTurn`   → slides the snapshot away revealing the new content
class ReaderPageTurnPlugin: NSObject, FlutterPlugin {

  // -------------------------------------------------------------------------
  // MARK: - State
  // -------------------------------------------------------------------------

  private weak var snapshotView: UIView?
  private weak var webView: WKWebView?
  private var animator: UIViewPropertyAnimator?
  private var animationToken: Int = 0

  private let animationDuration: TimeInterval = 0.25
  private let shadowRadius: CGFloat = 10
  private let shadowOpacityDarkMode: Float = 0.3
  private let shadowOpacityLightMode: Float = 0.15

  // -------------------------------------------------------------------------
  // MARK: - FlutterPlugin registration
  // -------------------------------------------------------------------------

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "lumina/reader_page_turn",
      binaryMessenger: registrar.messenger()
    )
    let instance = ReaderPageTurnPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  // -------------------------------------------------------------------------
  // MARK: - Method dispatch
  // -------------------------------------------------------------------------

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "preparePageTurn":
      handlePreparePageTurn(result: result)
    case "animatePageTurn":
      let args = call.arguments as? [String: Any]
      let isNext = args?["isNext"] as? Bool ?? true
      let isVertical = args?["isVertical"] as? Bool ?? false
      handleAnimatePageTurn(isNext: isNext, isVertical: isVertical, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // -------------------------------------------------------------------------
  // MARK: - preparePageTurn
  // -------------------------------------------------------------------------

  private func handlePreparePageTurn(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      self.animationToken += 1
      self.cancelActiveAnimation()

      if let existingSnapshot = self.snapshotView,
        let existingWebView = self.webView
      {
        self.cleanupAfterAnimation(snapshot: existingSnapshot, webView: existingWebView)
      } else {
        self.snapshotView?.removeFromSuperview()
        self.snapshotView = nil
        self.webView = nil
      }

      guard let rootView = self.activeWindow?.rootViewController?.view,
        let webView = self.findTopmostWKWebView(in: rootView)
      else {
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

      self.snapshotView = snapshot
      self.webView = webView

      result(nil)
    }
  }

  // -------------------------------------------------------------------------
  // MARK: - animatePageTurn
  // -------------------------------------------------------------------------

  private func handleAnimatePageTurn(
    isNext: Bool, isVertical: Bool, result: @escaping FlutterResult
  ) {
    DispatchQueue.main.async {
      self.cancelActiveAnimation()

      guard let snapshot = self.snapshotView,
        let webView = self.webView,
        let superview = webView.superview
      else {
        result(nil)
        return
      }

      self.animationToken += 1
      let token = self.animationToken

      let width = webView.bounds.width
      guard width > 0 else {
        snapshot.removeFromSuperview()
        self.snapshotView = nil
        result(nil)
        return
      }

      // Apply directional shadow to the leading view.
      let shadowLayer: CALayer = isNext ? snapshot.layer : webView.layer
      let isDarkMode = self.activeWindow?.traitCollection.userInterfaceStyle == .dark
      shadowLayer.shadowColor = UIColor.black.cgColor
      shadowLayer.shadowOpacity = isDarkMode ? self.shadowOpacityDarkMode : self.shadowOpacityLightMode
      shadowLayer.shadowRadius = self.shadowRadius
      shadowLayer.shadowOffset = .zero
      shadowLayer.shadowPath = UIBezierPath(rect: webView.bounds).cgPath

      if isNext {
        // Snapshot slides out; new content is already underneath.
        superview.bringSubviewToFront(snapshot)
        snapshot.transform = .identity
        webView.transform = .identity

        let anim = UIViewPropertyAnimator(duration: self.animationDuration, curve: .linear) {
          snapshot.transform = CGAffineTransform(
            translationX: isVertical ? width : -width, y: 0)
        }
        self.animator = anim
        anim.addCompletion { _ in
          if token == self.animationToken {
            self.cleanupAfterAnimation(snapshot: snapshot, webView: webView)
          }
          if self.animator === anim { self.animator = nil }
          result(nil)
        }
        anim.startAnimation()

      } else {
        // New content slides in from the side; snapshot stays put underneath.
        superview.bringSubviewToFront(webView)
        webView.transform = CGAffineTransform(
          translationX: isVertical ? width : -width, y: 0)
        snapshot.transform = .identity

        let anim = UIViewPropertyAnimator(duration: self.animationDuration, curve: .linear) {
          webView.transform = .identity
        }
        self.animator = anim
        anim.addCompletion { _ in
          if token == self.animationToken {
            self.cleanupAfterAnimation(snapshot: snapshot, webView: webView)
          }
          if self.animator === anim { self.animator = nil }
          result(nil)
        }
        anim.startAnimation()
      }
    }
  }

  // -------------------------------------------------------------------------
  // MARK: - Helpers
  // -------------------------------------------------------------------------

  private func cancelActiveAnimation() {
    guard let anim = animator else { return }
    anim.stopAnimation(true)
    animator = nil
  }

  private func cleanupAfterAnimation(snapshot: UIView, webView: WKWebView) {
    snapshot.removeFromSuperview()
    snapshot.transform = .identity
    snapshot.layer.shadowOpacity = 0
    snapshot.layer.shadowOffset = .zero
    snapshot.layer.shadowPath = nil

    webView.transform = .identity
    webView.layer.shadowOpacity = 0
    webView.layer.shadowOffset = .zero
    webView.layer.shadowPath = nil

    snapshotView = nil
    self.webView = nil
  }

  private var activeWindow: UIWindow? {
    UIApplication.shared.connectedScenes
      .filter { $0.activationState == .foregroundActive }
      .compactMap { $0 as? UIWindowScene }
      .first?.windows
      .first(where: { $0.isKeyWindow })
  }

  private func findTopmostWKWebView(in view: UIView?) -> WKWebView? {
    guard let view = view else { return nil }
    if let webView = view as? WKWebView { return webView }
    for subview in view.subviews.reversed() {
      if let found = findTopmostWKWebView(in: subview) { return found }
    }
    return nil
  }
}
