import 'dart:ui';
import 'package:flutter/material.dart';

enum ToastBubbleType { success, error, info }

class ToastBubble extends StatelessWidget {
  final String message;
  final ToastBubbleType type;
  final IconData? iconOverride;
  final bool useBlur;

  const ToastBubble({
    super.key,
    required this.message,
    required this.type,
    this.iconOverride,
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgAlpha = useBlur ? 0.8 : 1.0;
    final backgroundColor = _backgroundColor(
      type,
      colorScheme,
    ).withValues(alpha: bgAlpha);
    final contentColor = _contentColor(type, colorScheme);
    final icon = iconOverride ?? _iconForType(type);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: contentColor),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: contentColor,
                height: 1.2,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );

    final glassDecoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(999),
    );

    final innerBubble = useBlur
        ? ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(decoration: glassDecoration, child: content),
            ),
          )
        : Container(decoration: glassDecoration, child: content);

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(999)),
      child: innerBubble,
    );
  }

  static Color _backgroundColor(ToastBubbleType type, ColorScheme colorScheme) {
    switch (type) {
      case ToastBubbleType.success:
      case ToastBubbleType.info:
        return colorScheme.inverseSurface;
      case ToastBubbleType.error:
        return colorScheme.error;
    }
  }

  static Color _contentColor(ToastBubbleType type, ColorScheme colorScheme) {
    switch (type) {
      case ToastBubbleType.success:
      case ToastBubbleType.info:
        return colorScheme.onInverseSurface;
      case ToastBubbleType.error:
        return colorScheme.onError;
    }
  }

  static IconData? _iconForType(ToastBubbleType type) {
    switch (type) {
      case ToastBubbleType.success:
        return Icons.check_circle_outlined;
      case ToastBubbleType.error:
        return Icons.error_outlined;
      case ToastBubbleType.info:
        return Icons.info_outlined;
    }
  }
}
