import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme.dart';

class FootnotePopupOverlay extends StatefulWidget {
  final Rect anchorRect;
  final String rawHtml;
  final VoidCallback onDismiss;

  const FootnotePopupOverlay({
    super.key,
    required this.anchorRect,
    required this.rawHtml,
    required this.onDismiss,
  });

  @override
  State<FootnotePopupOverlay> createState() => FootnotePopupOverlayState();
}

class FootnotePopupOverlayState extends State<FootnotePopupOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  late bool _slideFromLeft;

  Future<void> playReverseAnimation() async {
    if (mounted) {
      await _animationController.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: AppTheme.defaultAnimationDurationMs,
      ),
    );
    _slideFromLeft = true;
    if (!_animationController.isAnimating &&
        !_animationController.isCompleted) {
      _animationController.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    _slideFromLeft = widget.anchorRect.center.dx < (screenWidth / 2);
    _slideAnimation =
        Tween<Offset>(
          begin: Offset(_slideFromLeft ? -1.0 : 1.0, 0.0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const double maxPopupHeight = 150.0;
    final double bookmarkWidth = screenSize.width * 0.85;

    final spaceBelow = screenSize.height - widget.anchorRect.bottom;
    final spaceAbove = widget.anchorRect.top;

    final bool showBelow =
        spaceBelow >= maxPopupHeight || spaceBelow > spaceAbove;

    final double topPosition = showBelow ? widget.anchorRect.bottom + 6.0 : -1;
    final double bottomPosition = !showBelow
        ? (screenSize.height - widget.anchorRect.top) + 6.0
        : -1;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          top: topPosition != -1 ? topPosition : null,
          bottom: bottomPosition != -1 ? bottomPosition : null,
          left: _slideFromLeft ? 0 : null,
          right: !_slideFromLeft ? 0 : null,
          width: bookmarkWidth,
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                constraints: const BoxConstraints(maxHeight: maxPopupHeight),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 12,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Text(
                    widget.rawHtml,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: AppTheme.fontFamilyContent,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
