import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IOSPageTurnSession {
  static const MethodChannel _nativePageTurnChannel = MethodChannel(
    'lumina/reader_page_turn',
  );

  Future<void> _prepareIOSPageTurn() async {
    if (!Platform.isIOS) return;
    try {
      await _nativePageTurnChannel.invokeMethod<void>('preparePageTurn');
    } on MissingPluginException {
      // no-op for configurations without iOS native channel
    } catch (e) {
      debugPrint('preparePageTurn failed: $e');
    }
  }

  Future<void> _animateIOSPageTurn(bool isNext, bool isVertical) async {
    if (!Platform.isIOS) return;
    try {
      await _nativePageTurnChannel.invokeMethod<void>('animatePageTurn', {
        'isNext': isNext,
        'isVertical': isVertical,
      });
    } on MissingPluginException {
      // no-op for configurations without iOS native channel
    } catch (e) {
      debugPrint('animatePageTurn failed: $e');
    }
  }

  Future<void> perform({
    required bool isNext,
    required bool isVertical,
    required Future<void> Function(bool) onPerformPageTurn,
  }) async {
    await _prepareIOSPageTurn();
    await onPerformPageTurn(isNext);
    unawaited(_animateIOSPageTurn(isNext, isVertical));
  }

  Widget buildAnimatedContainer(BuildContext context, Widget child) {
    return child;
  }
}
