import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/library/application/progress_log.dart';
import 'package:lumina/src/features/library/data/services/import_backup_service.dart';
import 'package:lumina/src/features/library/presentation/widgets/progress_dialog.dart';

/// Hosts the restore-backup progress dialog.
///
/// Interprets [BackupImportProgress] events instead of the plain [ProgressLog]s
/// of the import pipeline, and reports the outcome once the stream is done: a
/// failed restore must never look like a successful one, because the previous
/// library has already been cleared by the time it fails.
///
/// The dialog cannot be dismissed while the stream is running — aborting in the
/// middle would leave the library half restored.
class RestoreProgressDialog extends StatefulWidget {
  final Stream<ProgressLog> stream;
  final AppLocalizations l10n;

  const RestoreProgressDialog({
    super.key,
    required this.stream,
    required this.l10n,
  });

  @override
  State<RestoreProgressDialog> createState() => _RestoreProgressDialogState();
}

class _RestoreProgressDialogState extends State<RestoreProgressDialog> {
  StreamSubscription<ProgressLog>? _sub;

  int _totalCount = 0;
  int _currentCount = 0;
  int _successCount = 0;
  int _failedCount = 0;
  String _currentFileName = '';
  bool _isCompleted = false;
  String? _failureMessage;
  final List<ProgressLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _sub = widget.stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  void _onData(ProgressLog log) {
    if (!mounted) return;
    setState(() {
      _logs.add(log);
      if (log is BackupImportProgress) {
        _totalCount = log.total;
        _currentCount = log.current;
        _currentFileName = log.currentFileName;
        final result = log.result;
        if (result is ImportSuccess) {
          _successCount++;
        } else if (result is ImportFailure) {
          _failedCount++;
          _failureMessage = result.message;
        }
      }
    });
  }

  void _onError(Object error, StackTrace st) {
    if (!mounted) return;
    setState(() {
      _isCompleted = true;
      _failureMessage = error.toString();
    });
  }

  void _onDone() {
    if (!mounted) return;
    final failure = _failureMessage;
    setState(() => _isCompleted = true);

    if (failure != null) {
      ToastService.showError(widget.l10n.restoreFailed(failure));
    } else if (_successCount > 0) {
      ToastService.showSuccess(widget.l10n.restoreSuccess(_successCount));
    } else {
      ToastService.showSuccess(widget.l10n.restoreCompleted);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasProgress = _totalCount > 0;
    final isDone =
        _isCompleted || (_totalCount > 0 && _currentCount == _totalCount);
    final progressValue = hasProgress
        ? (isDone ? 1.0 : _currentCount / _totalCount)
        : null;
    final remaining = isDone
        ? 0
        : _totalCount - _successCount - _failedCount;

    return PopScope(
      canPop: isDone,
      child: ProgressDialog(
        title: widget.l10n.restoring,
        completeTitle: _failureMessage == null
            ? widget.l10n.restoreCompleted
            : widget.l10n.restoreFailedTitle,
        progressMessage: widget.l10n.restoringProgress(
          _successCount,
          _failedCount,
          remaining,
        ),
        processingMessage: widget.l10n.progressing(_currentFileName),
        progressValue: progressValue,
        isCompleted: isDone,
        logs: _logs,
      ),
    );
  }
}
