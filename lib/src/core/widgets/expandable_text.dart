import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// A text widget that can be expanded to show full content
/// Useful for long descriptions that need to be truncated
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 4,
    this.style,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;
  bool _isExceeded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate if text exceeds max lines
        if (!_isExpanded && !_isExceeded) {
          final span = TextSpan(
            text: widget.text,
            style:
                widget.style ??
                Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: AppTheme.fontFamilyContent,
                  fontWeight: FontWeight.w400,
                ),
          );

          final tp = TextPainter(
            text: span,
            maxLines: widget.maxLines,
            textDirection: TextDirection.ltr,
          );
          tp.layout(maxWidth: constraints.maxWidth);

          // Update exceeded state after first build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && tp.didExceedMaxLines != _isExceeded) {
              setState(() => _isExceeded = tp.didExceedMaxLines);
            }
          });
        }

        return AnimatedSize(
          duration: const Duration(
            milliseconds: AppTheme.defaultAnimationDurationMs,
          ),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.text,
                style:
                    widget.style ??
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: AppTheme.fontFamilyContent,
                      fontWeight: FontWeight.w400,
                    ),
                maxLines: _isExpanded ? null : widget.maxLines,
                overflow: _isExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              if (_isExceeded)
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _isExpanded
                          ? AppLocalizations.of(context)!.collapse
                          : AppLocalizations.of(context)!.expandAll,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
