import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../reader_webview.dart';

class AndroidPageTurnSession {
  late final AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  ui.Image? _screenshotData;
  bool _isAnimating = false;
  bool _isForwardAnimation = true;
  int _pageTurnToken = 0;

  AndroidPageTurnSession({
    required TickerProvider vsync,
    required Duration duration,
  }) {
    _animController = AnimationController(vsync: vsync, duration: duration);
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animController);
  }

  void dispose() {
    _screenshotData?.dispose();
    _animController.dispose();
  }

  void _setupTween(bool isNext, bool isVertical) {
    Tween<Offset> tween;
    if (isNext) {
      tween = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(isVertical ? 1.0 : -1.0, 0.0),
      );
    } else {
      tween = Tween<Offset>(
        begin: Offset(isVertical ? 1.0 : -1.0, 0.0),
        end: Offset.zero,
      );
    }
    _slideAnimation = tween.animate(_animController);
  }

  Future<ui.Image?> _takeScreenshot(
    ReaderWebViewController webViewController,
  ) async {
    ui.Image? screenshot;
    try {
      screenshot = await webViewController.takeScreenshot();
    } catch (e) {
      debugPrint('Error taking screenshot: $e');
      screenshot = null;
    }
    return screenshot;
  }

  Future<void> perform({
    required ReaderWebViewController webViewController,
    required bool isNext,
    required bool isVertical,
    required Future<void> Function(bool) onPerformPageTurn,
    required void Function(VoidCallback) setState,
    required bool Function() isMounted,
  }) async {
    final int turnToken = ++_pageTurnToken;

    final screenshot = await _takeScreenshot(webViewController);

    // If screenshot fails, just perform the page turn without animation
    if (screenshot == null) {
      _screenshotData?.dispose();
      _screenshotData = null;
      _animController.reset();
      await onPerformPageTurn(isNext);
      return;
    }

    // If the widget has been unmounted or a new page turn has started, dispose the screenshot and exit
    if (!isMounted() || turnToken != _pageTurnToken) {
      screenshot.dispose();
      return;
    }

    // Start the animation
    setState(() {
      _isForwardAnimation = isNext;

      _screenshotData?.dispose();
      _screenshotData = screenshot;
      _isAnimating = true;

      _setupTween(isNext, isVertical);
      _animController.reset();
    });

    // Perform the page turn in parallel with the animation
    onPerformPageTurn(isNext);

    try {
      await _animController.forward();
    } finally {
      if (turnToken == _pageTurnToken) {
        final finishedScreenshot = _screenshotData;
        if (isMounted()) {
          setState(() {
            _screenshotData = null;
          });
        } else {
          _screenshotData = null;
        }
        finishedScreenshot?.dispose();

        _animController.reset();
        _isAnimating = false;
      }
    }
  }

  Widget buildAnimatedContainer(
    BuildContext context,
    Widget child,
    Widget Function(ui.Image?) buildScreenshotContainer,
  ) {
    return Stack(
      children: [
        // Backward animation: show the current page as the background
        if (_isAnimating && !_isForwardAnimation)
          Positioned.fill(child: buildScreenshotContainer(_screenshotData)),
        // Webview page: slide it in from the left for backward animation, or keep it static for forward animation
        Positioned.fill(
          child: SlideTransition(
            position: _isAnimating && !_isForwardAnimation
                ? _slideAnimation
                : const AlwaysStoppedAnimation(Offset.zero),
            child: child,
          ),
        ),
        // Forward animation: slide the current page out to the right
        if (_isAnimating && _isForwardAnimation)
          Positioned.fill(
            child: SlideTransition(
              position: _slideAnimation,
              child: buildScreenshotContainer(_screenshotData),
            ),
          ),
      ],
    );
  }
}
