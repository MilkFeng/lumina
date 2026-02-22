import Flutter
import UIKit
import UniformTypeIdentifiers

/// Stateful Flutter plugin that handles lazy, copy-on-demand file access for
/// the `com.lumina.ereader/native_picker` MethodChannel.
///
/// Security-scoped resources are kept alive across MethodChannel calls so
/// Dart can request individual files to be copied one at a time rather than
/// copying everything up-front.
class NativePickerPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {

  // -------------------------------------------------------------------------
  // MARK: - State for security-scoped access
  // -------------------------------------------------------------------------

  /// Held open while Dart processes a backup / EPUB-folder import.
  private var activeDirectoryUrl: URL?

  /// Held open while Dart processes individually picked files.
  private var activeFileUrls: [URL] = []

  // -------------------------------------------------------------------------
  // MARK: - Pending async picker state
  // -------------------------------------------------------------------------

  private var pendingPickerResult: FlutterResult?
  private var pendingPickerMode: PickerMode?

  private enum PickerMode {
    case epubFiles
    case epubFolder
    case backupFolder
  }

  // -------------------------------------------------------------------------
  // MARK: - FlutterPlugin registration
  // -------------------------------------------------------------------------

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.lumina.ereader/native_picker",
      binaryMessenger: registrar.messenger()
    )
    let instance = NativePickerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  // -------------------------------------------------------------------------
  // MARK: - MethodCall dispatcher
  // -------------------------------------------------------------------------

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickEpubFiles":
      pickEpubFiles(result: result)

    case "pickEpubFolder":
      pickEpubFolder(result: result)

    case "pickBackupFolder":
      pickBackupFolder(result: result)

    case "fetchIosFile":
      guard let originalPath = call.arguments as? String else {
        result(FlutterError(
          code: "INVALID_ARGUMENT",
          message: "Expected a String originalPath argument",
          details: nil
        ))
        return
      }
      fetchIosFile(originalPath: originalPath, result: result)

    case "releaseIosAccess":
      releaseIosAccess()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // -------------------------------------------------------------------------
  // MARK: - pickEpubFiles  (lazy – files remain security-scoped)
  // -------------------------------------------------------------------------

  private func pickEpubFiles(result: @escaping FlutterResult) {
    // Release any previously held file scopes before starting a new pick.
    releaseActiveFileUrls()

    pendingPickerResult = result
    pendingPickerMode = .epubFiles

    DispatchQueue.main.async {
      let picker: UIDocumentPickerViewController
      if #available(iOS 14.0, *) {
        var types: [UTType] = []
        if let epubType = UTType("org.idpf.epub-container") {
          types = [epubType]
        } else {
          types = [UTType.data]
        }
        picker = UIDocumentPickerViewController(
          forOpeningContentTypes: types,
          asCopy: false
        )
      } else {
        picker = UIDocumentPickerViewController(
          documentTypes: ["org.idpf.epub-container"],
          in: .open
        )
      }
      picker.allowsMultipleSelection = true
      picker.delegate = self
      picker.modalPresentationStyle = .formSheet
      self.presentPicker(picker)
    }
  }

  // -------------------------------------------------------------------------
  // MARK: - pickEpubFolder  (lazy – folder remains security-scoped)
  // -------------------------------------------------------------------------

  private func pickEpubFolder(result: @escaping FlutterResult) {
    releaseActiveDirectoryUrl()

    pendingPickerResult = result
    pendingPickerMode = .epubFolder

    DispatchQueue.main.async {
      let picker: UIDocumentPickerViewController
      if #available(iOS 14.0, *) {
        picker = UIDocumentPickerViewController(
          forOpeningContentTypes: [UTType.folder],
          asCopy: false
        )
      } else {
        picker = UIDocumentPickerViewController(
          documentTypes: ["public.folder"],
          in: .open
        )
      }
      picker.allowsMultipleSelection = false
      picker.delegate = self
      picker.modalPresentationStyle = .formSheet
      self.presentPicker(picker)
    }
  }

  // -------------------------------------------------------------------------
  // MARK: - pickBackupFolder  (lazy – folder remains security-scoped)
  // -------------------------------------------------------------------------

  private func pickBackupFolder(result: @escaping FlutterResult) {
    releaseActiveDirectoryUrl()

    pendingPickerResult = result
    pendingPickerMode = .backupFolder

    DispatchQueue.main.async {
      let picker: UIDocumentPickerViewController
      if #available(iOS 14.0, *) {
        picker = UIDocumentPickerViewController(
          forOpeningContentTypes: [UTType.folder],
          asCopy: false
        )
      } else {
        picker = UIDocumentPickerViewController(
          documentTypes: ["public.folder"],
          in: .open
        )
      }
      picker.allowsMultipleSelection = false
      picker.delegate = self
      picker.modalPresentationStyle = .formSheet
      self.presentPicker(picker)
    }
  }

  // -------------------------------------------------------------------------
  // MARK: - fetchIosFile  (on-demand single-file copier)
  // -------------------------------------------------------------------------

  /// Copies the given security-scoped file to a unique path inside
  /// `NSTemporaryDirectory()` and returns the new absolute path to Dart.
  ///
  /// The security scope for the source file (or its parent folder) must
  /// already be open via a prior `pickEpubFiles` / `pickEpubFolder` /
  /// `pickBackupFolder` call.
  private func fetchIosFile(originalPath: String, result: @escaping FlutterResult) {
    let sourceUrl = URL(fileURLWithPath: originalPath)
    let uniqueName = UUID().uuidString + "_" + sourceUrl.lastPathComponent
    let destUrl = FileManager.default.temporaryDirectory
      .appendingPathComponent(uniqueName)

    do {
      try FileManager.default.copyItem(at: sourceUrl, to: destUrl)
      result(destUrl.path)
    } catch {
      result(FlutterError(
        code: "COPY_FAILED",
        message: "Failed to copy '\(sourceUrl.lastPathComponent)': \(error.localizedDescription)",
        details: nil
      ))
    }
  }

  // -------------------------------------------------------------------------
  // MARK: - releaseIosAccess  (called from Dart when the whole batch is done)
  // -------------------------------------------------------------------------

  /// Stops all active security-scoped resource accesses and clears retained
  /// URLs.  Must be called from Dart's `finally` block after a pick+process
  /// cycle to avoid resource leaks.
  func releaseIosAccess() {
    releaseActiveDirectoryUrl()
    releaseActiveFileUrls()
  }

  // -------------------------------------------------------------------------
  // MARK: - Private helpers
  // -------------------------------------------------------------------------

  private func releaseActiveDirectoryUrl() {
    activeDirectoryUrl?.stopAccessingSecurityScopedResource()
    activeDirectoryUrl = nil
  }

  private func releaseActiveFileUrls() {
    for url in activeFileUrls {
      url.stopAccessingSecurityScopedResource()
    }
    activeFileUrls.removeAll()
  }

  private func presentPicker(_ picker: UIDocumentPickerViewController) {
    guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
      pendingPickerResult?(FlutterError(
        code: "NO_VIEW_CONTROLLER",
        message: "Cannot find root view controller to present picker",
        details: nil
      ))
      pendingPickerResult = nil
      pendingPickerMode = nil
      return
    }

    // Walk to the topmost presented controller.
    var topVC = rootVC
    while let presented = topVC.presentedViewController {
      topVC = presented
    }

    topVC.present(picker, animated: true)
  }

  // -------------------------------------------------------------------------
  // MARK: - UIDocumentPickerDelegate
  // -------------------------------------------------------------------------

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    guard let result = pendingPickerResult, let mode = pendingPickerMode else {
      return
    }
    pendingPickerResult = nil
    pendingPickerMode = nil

    switch mode {

    // -- Multiple EPUB files ------------------------------------------------
    case .epubFiles:
      var paths: [String] = []
      for url in urls {
        // startAccessingSecurityScopedResource may return false for paths
        // that are already accessible (e.g. in-sandbox).  We keep the URL
        // either way; the OS grants access.
        let _ = url.startAccessingSecurityScopedResource()
        activeFileUrls.append(url)
        paths.append(url.path)
      }
      result(paths)

    // -- Single EPUB-containing folder -------------------------------------
    case .epubFolder:
      guard let folderUrl = urls.first else {
        result([String]())
        return
      }

      let _ = folderUrl.startAccessingSecurityScopedResource()
      activeDirectoryUrl = folderUrl

      var paths: [String] = []
      if let enumerator = FileManager.default.enumerator(
        at: folderUrl,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
      ) {
        for case let fileUrl as URL in enumerator {
          if fileUrl.pathExtension.lowercased() == "epub" {
            paths.append(fileUrl.path)
          }
        }
      }
      result(paths)

    // -- Backup folder (EPUBs + covers + manifests + shelf.json) ----------
    case .backupFolder:
      guard let folderUrl = urls.first else {
        result(nil)
        return
      }

      let _ = folderUrl.startAccessingSecurityScopedResource()
      activeDirectoryUrl = folderUrl

      var paths: [String] = []
      let allowedExtensions: Set<String> = ["epub", "json", "jpg", "jpeg", "png", "webp"]

      if let enumerator = FileManager.default.enumerator(
        at: folderUrl,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
      ) {
        for case let fileUrl as URL in enumerator {
          if allowedExtensions.contains(fileUrl.pathExtension.lowercased()) {
            paths.append(fileUrl.path)
          }
        }
      }
      result(paths)
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = pendingPickerResult
    pendingPickerResult = nil
    pendingPickerMode = nil
    // Return an empty list (not null/error) so Dart can detect cancellation
    // with a simple isEmpty check.
    result?([String]())
  }
}
