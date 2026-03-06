import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VolumeControlService {
  static const MethodChannel _methodChannel = MethodChannel(
    'lumina/volume_control',
  );
  static const EventChannel _eventChannel = EventChannel(
    'lumina/volume_events',
  );

  static Future<void> enableInterception() async {
    if (!Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod('enableInterception');
    } on PlatformException catch (e) {
      debugPrint('Volume interception enable failed: ${e.message}');
    }
  }

  static Future<void> disableInterception() async {
    if (!Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod('disableInterception');
    } on PlatformException catch (e) {
      debugPrint('Volume interception disable failed: ${e.message}');
    }
  }

  static Stream<String> get volumeKeyEvents {
    if (!Platform.isAndroid) return const Stream.empty();

    return _eventChannel.receiveBroadcastStream().map(
      (event) => event as String,
    );
  }
}
