import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme.dart';

import '../../../l10n/app_localizations.dart';

/// Severity of a single progress log entry.
enum ProgressLogType { info, warning, error, success }

/// One line of progress output emitted by a long-running batch operation.
///
/// Feature layers subclass this to carry their own counters (see
/// `ImportProgress` and `BackupImportProgress`).
class ProgressLog {
  final String message;
  final ProgressLogType type;

  ProgressLog(this.message, this.type);
}

/// How far the transfer of the file currently being processed has come.
///
/// A stream of these is *state*, not a log: one arrives per reported step, so a
/// large file produces hundreds of them. [ProgressDialog] therefore renders the
/// latest one as the live measurement and never appends it to the details list.
class FileTransferProgress extends ProgressLog {
  FileTransferProgress({
    required this.fileName,
    required this.receivedBytes,
    this.totalBytes,
  }) : super('Transferring $fileName', ProgressLogType.info);

  /// Name of the file the bytes belong to.
  final String fileName;

  /// Bytes received so far.
  final int receivedBytes;

  /// Total the transport declared, or `null` when it did not declare one
  /// (a chunked response, for instance).
  final int? totalBytes;

  /// [receivedBytes] as a percentage of [totalBytes], clamped to 0–100, or
  /// `null` when the total is unknown or nonsensical.
  int? get percent {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    return ((receivedBytes / total) * 100).clamp(0, 100).round();
  }
}

/// A "dumb" progress dialog that renders purely from the values passed to it.
///
/// All stream subscription, state accumulation, and completion handling must
/// be done by the caller; this widget has no internal stream logic.
class ProgressDialog extends StatefulWidget {
  final String title;
  final String completeTitle;
  final String progressMessage;
  final String processingMessage;

  /// Optional live measurement of the step currently running — the bytes a
  /// download has received, for instance — rendered as a line of its own under
  /// [processingMessage].
  ///
  /// Its own line rather than a suffix on [processingMessage] because that one
  /// shares a row with the details link and runs out of width early. Pass `null`
  /// when there is nothing to measure, or once the operation is complete.
  final String? progressDetail;

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
    this.progressDetail,
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

              if (!widget.isCompleted && widget.progressDetail != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.progressDetail!,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
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
