import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/library/application/progress_log.dart';

import '../../../../../l10n/app_localizations.dart';

class ProgressDialog extends StatefulWidget {
  final String completeTitle;
  final String title;
  final String progressMessage;
  final String processingMessage;
  final Stream<ProgressLog> progressStream;
  final double? progressValue;
  final Function(ProgressLog) onProgress;
  final Function(Object, StackTrace)? onError;
  final Function()? onCompleted;

  const ProgressDialog({
    required this.completeTitle,
    required this.title,
    required this.progressMessage,
    required this.processingMessage,
    required this.progressStream,
    required this.progressValue,
    required this.onProgress,
    required this.onError,
    required this.onCompleted,
    super.key,
  });

  @override
  State<ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<ProgressDialog> {
  StreamSubscription<ProgressLog>? _subscription;

  bool _isCompleted = false;
  bool _showDetails = false;

  final List<ProgressLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _subscription = widget.progressStream.listen(
      _handleProgress,
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        setState(() {
          _isCompleted = true;
        });
        widget.onError?.call(error, stackTrace);
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _isCompleted = true;
        });
        widget.onCompleted?.call();
      },
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handleProgress(ProgressLog progress) {
    if (!mounted) return;
    widget.onProgress(progress);
    _logs.add(progress);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isCompleted ? widget.completeTitle : widget.title),
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
                      _isCompleted
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

                  SizedBox(width: 12),

                  if (_logs.isNotEmpty)
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
              child: (_logs.isNotEmpty && _showDetails)
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _logs.length,
                            reverse: true,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _logs[_logs.length - 1 - index];
                              Color color;
                              switch (item.type) {
                                case ProgressLogType.error:
                                  color = theme.colorScheme.error;
                                  break;
                                case ProgressLogType.warning:
                                  color = Colors.orangeAccent;
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
          onPressed: _isCompleted ? () => Navigator.of(context).pop() : null,
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
