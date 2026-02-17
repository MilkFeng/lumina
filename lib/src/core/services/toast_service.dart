import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/toast_bubble.dart';

class ToastService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayEntry? _currentEntry;

  static void showSuccess(String message) {
    _show(message, ToastBubbleType.success);
  }

  static void showError(String message) {
    _show(message, ToastBubbleType.error);
  }

  static void showInfo(String message) {
    _show(message, ToastBubbleType.info);
  }

  static void _show(
    String message,
    ToastBubbleType type, {
    Duration duration = const Duration(seconds: 3),
  }) {
    debugPrint('Toast: [${type.name.toUpperCase()}] $message');

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      return;
    }

    _removeCurrent();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        type: type,
        duration: duration,
        onDismissed: () {
          if (_currentEntry == entry) {
            _removeCurrent();
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void _removeCurrent() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final ToastBubbleType type;
  final Duration duration;
  final VoidCallback onDismissed;

  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(_opacity);
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(_opacity);

    _controller.forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!_controller.isAnimating && _controller.value == 0) {
      widget.onDismissed();
      return;
    }

    await _controller.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 50, left: 25, right: 25),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: _dismiss,
            child: FadeTransition(
              opacity: _opacity,
              child: SlideTransition(
                position: _slide,
                child: ScaleTransition(
                  scale: _scale,
                  child: ToastBubble(
                    message: widget.message,
                    type: widget.type,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
