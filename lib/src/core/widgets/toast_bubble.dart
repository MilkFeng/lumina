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
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = _backgroundColor(type, isDark);
    final contentColor = _contentColor(type, isDark);
    final icon = iconOverride ?? _iconForType(type, isDark);

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.shadow.withValues(alpha: isDark ? 0.4 : 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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

    if (!useBlur) return bubble;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: bubble,
      ),
    );
  }

  static Color _backgroundColor(ToastBubbleType type, bool isDark) {
    if (isDark) {
      switch (type) {
        case ToastBubbleType.success:
        case ToastBubbleType.info:
          return const Color.fromARGB(160, 224, 224, 224);
        case ToastBubbleType.error:
          return const Color.fromARGB(160, 255, 205, 210);
      }
    }
    switch (type) {
      case ToastBubbleType.success:
      case ToastBubbleType.info:
        return const Color.fromARGB(160, 25, 25, 25);
      case ToastBubbleType.error:
        return const Color.fromARGB(160, 185, 28, 28);
    }
  }

  static Color _contentColor(ToastBubbleType type, bool isDark) {
    if (isDark) {
      if (type == ToastBubbleType.error) {
        return const Color.fromARGB(255, 77, 8, 8);
      }
      return const Color.fromARGB(255, 25, 25, 25);
    } else {
      return Colors.white;
    }
  }

  static IconData? _iconForType(ToastBubbleType type, bool isDark) {
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
