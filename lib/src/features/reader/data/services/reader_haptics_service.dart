import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the reader's vibration under Flutter's control.
///
/// Android's WebView plays its own haptic feedback on a long press that it
/// handled, which is not something the reader asks for: the reader detects its
/// image long press inside the page (`GestureObserver` in
/// `web_assets/controller.js`) and vibrates from Dart when it acts on one.  The
/// browser's buzz also fires on presses that hit nothing at all, so it is muted
/// natively — see `ReaderHapticsPlugin.kt` for why that has to happen on the
/// Android side.
class ReaderHapticsService {
  static const MethodChannel _methodChannel = MethodChannel(
    'lumina/reader_haptics',
  );

  /// How many times the native walk is retried, and how long to wait between
  /// attempts.
  ///
  /// The WebView the reader shows is the pre-warmed one, handed over to the
  /// visible platform view, and it can only be found once it is attached to the
  /// window.  The first call therefore often finds none; a handful of retries
  /// covers the frames between creating the platform view and displaying it.
  static const int _maxAttempts = 6;
  static const Duration _retryDelay = Duration(milliseconds: 200);

  /// Silences the WebView's own haptics.
  ///
  /// Idempotent, and meant to be called when a platform view has just been
  /// created.  Silent on every other platform, and silent on failure: a reader
  /// whose WebView still buzzes is still a reader, and this must never be a
  /// reason for the chapter not to load.
  static Future<void> muteWebViewHaptics() async {
    if (!Platform.isAndroid) return;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      try {
        final muted = await _methodChannel.invokeMethod<int>(
          'muteWebViewHaptics',
        );
        if (muted != null && muted > 0) return;
      } on PlatformException catch (e) {
        debugPrint('Reader haptics: muting the WebView failed: ${e.message}');
        return;
      } on MissingPluginException {
        return;
      }

      await Future<void>.delayed(_retryDelay);
    }

    debugPrint('Reader haptics: no WebView found to mute');
  }
}
