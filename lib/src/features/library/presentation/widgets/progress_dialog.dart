import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/library/application/progress_log.dart';

import '../../../../../l10n/app_localizations.dart';

/// A "dumb" progress dialog that renders purely from the values passed to it.
/// All stream subscription, state accumulation, and completion handling must
/// be done by the caller; this widget has no internal stream logic.
class ProgressDialog extends StatefulWidget {
  final String title;
  final String completeTitle;
  final String progressMessage;
  final String processingMessage;
  final double? progressValue;

  /// When `true` the dialog shows the complete title and enables the Close
  /// button. Set this from the parent once the stream is done or errors.
  final bool isCompleted;

  /// Accumulated log entries to display in the collapsible details panel.
  final List<ProgressLog> logs;

  const ProgressDialog({
    required this.title,
    required this.completeTitle,
    required this.progressMessage,
    required this.processingMessage,
    required this.progressValue,
    required this.isCompleted,
    required this.logs,
    super.key,
  });

  @override
  State<ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<ProgressDialog> {
  // Only internal UI state: whether the details panel is expanded.
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    const Color warningLight = Color(0xFFED6C02);
    const Color warningDark = Color(0xFFFFB74D);
    final Color warningColor = theme.brightness == Brightness.dark
        ? warningDark
        : warningLight;

    return AlertDialog(
      title: Text(widget.isCompleted ? widget.completeTitle : widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.progressValue == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              LinearProgressIndicator(value: widget.progressValue),
              const SizedBox(height: 12),
              Text(widget.progressMessage, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      widget.isCompleted
                          ? l10n.progressedAll
                          : widget.processingMessage,
                      maxLines: 2,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  if (widget.logs.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _showDetails = !_showDetails),
                      child: Text(
                        l10n.details,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            AnimatedSize(
              duration: const Duration(
                milliseconds: AppTheme.defaultLongAnimationDurationMs,
              ),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: (widget.logs.isNotEmpty && _showDetails)
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: widget.logs.length,
                            reverse: true,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item =
                                  widget.logs[widget.logs.length - 1 - index];
                              Color color;
                              switch (item.type) {
                                case ProgressLogType.error:
                                  color = theme.colorScheme.error;
                                  break;
                                case ProgressLogType.warning:
                                  color = warningColor;
                                  break;
                                case ProgressLogType.success:
                                  color = theme.colorScheme.primary;
                                  break;
                                case ProgressLogType.info:
                                  color = theme.colorScheme.onSurfaceVariant;
                              }
                              return Text(
                                item.message,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w400,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isCompleted
              ? () => Navigator.of(context).pop()
              : null,
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
