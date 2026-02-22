import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lumina/src/core/theme/app_theme.dart';

import '../../application/library_notifier.dart';
import '../../domain/shelf_book.dart';
import '../../../../../l10n/app_localizations.dart';

class BatchImportDialog extends StatefulWidget {
  const BatchImportDialog({required this.progressStream, super.key});

  final Stream<ImportProgress> progressStream;

  @override
  State<BatchImportDialog> createState() => _BatchImportDialogState();
}

class _BatchImportDialogState extends State<BatchImportDialog> {
  StreamSubscription<ImportProgress>? _subscription;

  int _totalCount = 0;
  int _currentCount = 0;
  String _currentFileName = '';
  int _successCount = 0;
  int _failedCount = 0;
  bool _isCompleted = false;

  final List<_ImportResultItem> _results = [];

  @override
  void initState() {
    super.initState();
    _subscription = widget.progressStream.listen(
      _handleProgress,
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        setState(() {
          _failedCount++;
          _isCompleted = true;
          _results.add(
            _ImportResultItem.failed(
              fileName: '',
              errorMessage: error.toString(),
            ),
          );
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _isCompleted = true;
        });
      },
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _handleProgress(ImportProgress progress) {
    if (!mounted) return;

    setState(() {
      _totalCount = progress.totalCount;
      _currentCount = progress.currentCount;
      _currentFileName = progress.currentFileName;

      if (progress.status == ImportStatus.success) {
        _successCount++;
        _results.last = _ImportResultItem.success(
          fileName: progress.currentFileName,
          book: progress.book,
        );
      } else if (progress.status == ImportStatus.failed) {
        _failedCount++;
        _results.last = _ImportResultItem.failed(
          fileName: progress.currentFileName,
          errorMessage: progress.errorMessage,
        );
      } else if (progress.status == ImportStatus.processing) {
        _results.add(
          _ImportResultItem.processing(
            fileName: progress.currentFileName,
            errorMessage: progress.errorMessage,
          ),
        );
      }

      final isLastFile = _currentCount == _totalCount && _totalCount > 0;
      final hasResultForLastFile =
          progress.status == ImportStatus.success ||
          progress.status == ImportStatus.failed;
      if (isLastFile && hasResultForLastFile) {
        _isCompleted = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final hasProgress = _totalCount > 0;
    final progressValue = hasProgress
        ? (_isCompleted ? 1.0 : (_currentCount - 1) / _totalCount)
        : null;

    return AlertDialog(
      title: Text(_isCompleted ? l10n.importCompleted : l10n.importing),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasProgress)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              LinearProgressIndicator(value: progressValue),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.importingProgress(
                  _successCount,
                  _failedCount,
                  _totalCount - _successCount - _failedCount,
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _currentFileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.8,
                  ),
                  fontFamily: AppTheme.fontFamilyContent,
                ),
              ),
            ],
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  reverse: true,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = _results[_results.length - 1 - index];
                    final isSuccess = item.isSuccess;
                    final isProcessing = item.isProcessing;

                    final color = isProcessing
                        ? theme.colorScheme.secondary.withValues(alpha: 0.8)
                        : isSuccess
                        ? theme.colorScheme.primary.withValues(alpha: 0.8)
                        : theme.colorScheme.error.withValues(alpha: 0.8);
                    String message = isProcessing
                        ? l10n.importingFile(item.fileName)
                        : isSuccess
                        ? l10n.successfullyImported(
                            item.book?.title ?? item.fileName,
                          )
                        : l10n.importFailed(
                            item.errorMessage ?? 'Unknown error',
                          );

                    final indicator = isProcessing ? '○' : '●';
                    final fileName = item.fileName.isNotEmpty
                        ? item.fileName
                        : '';
                    message = '$indicator $fileName\n$message';

                    return Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: AppTheme.fontFamilyContent,
                        color: color,
                      ),
                    );
                  },
                ),
              ),
            ],
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

class _ImportResultItem {
  _ImportResultItem.success({required this.fileName, this.book})
    : isSuccess = true,
      isProcessing = false,
      errorMessage = null;

  _ImportResultItem.failed({required this.fileName, this.errorMessage})
    : isSuccess = false,
      isProcessing = false,
      book = null;

  _ImportResultItem.processing({required this.fileName, this.errorMessage})
    : isSuccess = false,
      isProcessing = true,
      book = null;

  final bool isSuccess;
  final String fileName;
  final String? errorMessage;
  final ShelfBook? book;
  final bool isProcessing;
}
