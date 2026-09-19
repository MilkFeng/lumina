import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/core/utils/byte_size.dart';
import 'package:lumina/src/features/library/application/library_notifier.dart';
import 'package:lumina/src/core/widgets/progress_dialog.dart';

/// Hosts the import-pipeline progress dialog.
/// Subscribes to [stream] exactly once (in initState) and accumulates
/// [ImportProgress] events so that every rebuild sees a fully coherent state.
class ImportProgressDialog extends StatefulWidget {
  final Stream<ProgressLog> stream;
  final AppLocalizations l10n;

  const ImportProgressDialog({
    super.key,
    required this.stream,
    required this.l10n,
  });

  @override
  State<ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<ImportProgressDialog> {
  StreamSubscription<ProgressLog>? _sub;

  int _totalCount = 0;
  int _currentCount = 0;
  int _successCount = 0;
  int _failedCount = 0;
  String _currentFileName = '';
  bool _isCompleted = false;

  /// Latest byte measurement of the file being processed.
  ///
  /// `null` whenever nothing is being transferred — a local import never reports
  /// bytes, and a remote one stops reporting the moment the file is done.
  FileTransferProgress? _transfer;

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
      // A transfer tick is live state, not a log line: one arrives per chunk, so
      // recording them all would bury the details panel under repetitions of the
      // current file name.
      if (log is FileTransferProgress) {
        _transfer = log;
        return;
      }

      _logs.add(log);
      if (log is ImportProgress) {
        _totalCount = log.totalCount;
        _currentCount = log.currentCount;
        _currentFileName = log.currentFileName;
        if (log.status == ImportStatus.success) {
          _successCount++;
        } else if (log.status == ImportStatus.failed) {
          _failedCount++;
        }
        if (log.status != ImportStatus.processing) {
          // This file is finished, so its byte counter no longer measures
          // anything the user is waiting on.
          _transfer = null;
        }
      }
    });
  }

  void _onError(Object error, StackTrace st) {
    if (!mounted) return;
    setState(() => _isCompleted = true);
    ToastService.showError(widget.l10n.importFailed(error.toString()));
  }

  void _onDone() {
    if (!mounted) return;
    setState(() => _isCompleted = true);
    ToastService.showSuccess(widget.l10n.importCompleted);
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

    return ProgressDialog(
      title: widget.l10n.importing,
      completeTitle: widget.l10n.importCompleted,
      progressMessage: widget.l10n.importingProgress(
        _successCount,
        _failedCount,
        _totalCount - _successCount - _failedCount,
      ),
      processingMessage: widget.l10n.progressing(_currentFileName),
      progressDetail: isDone ? null : _transferDetail(),
      progressValue: progressValue,
      isCompleted: isDone,
      logs: _logs,
    );
  }

  /// How far the current file's transfer has come, or `null` when there is
  /// nothing to measure.
  ///
  /// The bar keeps showing whole files — a batch is only ever as fine-grained as
  /// its file count — so this line is where a single large download becomes
  /// visible while it is still running.
  ///
  /// Numbers and unit symbols only, which is why it is built here rather than
  /// translated: `MB` is written the same way in every locale this app ships,
  /// and the phrase around it comes from the localized `processingMessage`.
  String? _transferDetail() {
    final transfer = _transfer;
    if (transfer == null) return null;

    final received = formatByteSize(transfer.receivedBytes);
    final total = transfer.totalBytes;
    final percent = transfer.percent;
    if (total == null || percent == null) return received;
    return '$received / ${formatByteSize(total)} · $percent%';
  }
}
