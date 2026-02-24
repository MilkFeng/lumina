import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import './reader_webview.dart';

class AndroidPageTurnSession {
  late final AnimationController animController;
  late Animation<Offset> slideAnimation;
  ui.Image? screenshotData;
  bool isAnimating = false;
  bool isForwardAnimation = true;
  int _pageTurnToken = 0;

  AndroidPageTurnSession({
    required TickerProvider vsync,
    required Duration duration,
  }) {
    animController = AnimationController(vsync: vsync, duration: duration);
    slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(animController);
  }

  void dispose() {
    screenshotData?.dispose();
    animController.dispose();
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
    slideAnimation = tween.animate(animController);
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
    isAnimating = true;

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
      animController.reset();

      await onPerformPageTurn(isNext);
      if (turnToken == _pageTurnToken) {
        isAnimating = false;
      }
      return;
    }

    if (!isMounted() || turnToken != _pageTurnToken) {
      screenshot.dispose();
      isAnimating = false;
      return;
    }

    if (animController.isAnimating) {
      animController.stop();
    }

    setState(() {
      isForwardAnimation = isNext;

      screenshotData?.dispose();
      screenshotData = screenshot;

      _setupTween(isNext, isVertical);
      animController.reset();
    });

    await onPerformPageTurn(isNext);

    if (!isMounted() || turnToken != _pageTurnToken) {
      isAnimating = false;
      return;
    }

    try {
      await animController.forward();
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

        animController.reset();
        isAnimating = false;
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
        if (isAnimating && !isForwardAnimation)
          Positioned.fill(child: buildScreenshotContainer(screenshotData)),
        Positioned.fill(
          child: SlideTransition(
            position: isAnimating && !isForwardAnimation
                ? slideAnimation
                : const AlwaysStoppedAnimation(Offset.zero),
            child: child,
          ),
        ),
        if (isAnimating && isForwardAnimation)
          Positioned.fill(
            child: SlideTransition(
              position: slideAnimation,
              child: buildScreenshotContainer(screenshotData),
            ),
          ),
      ],
    );
  }
}
