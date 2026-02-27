import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../reader_webview.dart';

class AndroidPageTurnSession {
  late final AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  ui.Image? screenshotData;
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
    screenshotData?.dispose();
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

  Future<void> perform({
    required ReaderWebViewController webViewController,
    required bool isNext,
    required bool isVertical,
    required Future<void> Function(bool) onPerformPageTurn,
    required void Function(VoidCallback) setState,
    required bool Function() isMounted,
  }) async {
    final int turnToken = ++_pageTurnToken;

    ui.Image? screenshot;
    try {
      screenshot = await webViewController.takeScreenshot();
    } catch (e) {
      debugPrint('Error taking screenshot: $e');
      screenshot = null;
    }

    if (screenshot == null) {
      screenshotData?.dispose();
      setState(() {
        screenshotData = null;
      });
      _animController.reset();

      await onPerformPageTurn(isNext);
      return;
    }

    if (!isMounted() || turnToken != _pageTurnToken) {
      screenshot.dispose();
      return;
    }

    if (_animController.isAnimating) {
      _animController.stop();
    }

    setState(() {
      _isForwardAnimation = isNext;

      screenshotData?.dispose();
      screenshotData = screenshot;
      _isAnimating = true;

      _setupTween(isNext, isVertical);
      _animController.reset();
    });

    await onPerformPageTurn(isNext);

    if (!isMounted() || turnToken != _pageTurnToken) {
      _isAnimating = false;
      return;
    }

    try {
      await _animController.forward();
    } finally {
      if (turnToken == _pageTurnToken) {
        final finishedScreenshot = screenshotData;
        if (isMounted()) {
          setState(() {
            screenshotData = null;
          });
        } else {
          screenshotData = null;
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
          Positioned.fill(child: buildScreenshotContainer(screenshotData)),
        // Backward animation: slide the previous page in from the left
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
              child: buildScreenshotContainer(screenshotData),
            ),
          ),
      ],
    );
  }
}
