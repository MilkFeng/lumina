import 'package:flutter/material.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/core/theme/app_theme.dart';

import '../../data/services/import_backup_service.dart';
import '../../../../../l10n/app_localizations.dart';

class RestoreBackupDialog extends StatefulWidget {
  const RestoreBackupDialog({required this.restoreFuture, super.key});

  /// The running restore operation. Should be started before the dialog is
  /// shown so that work is not duplicated on dialog rebuilds.
  final Future<ImportResult> restoreFuture;

  @override
  State<RestoreBackupDialog> createState() => _RestoreBackupDialogState();
}

class _RestoreBackupDialogState extends State<RestoreBackupDialog> {
  bool _isCompleted = false;
  ImportResult? _result;

  @override
  void initState() {
    super.initState();
    widget.restoreFuture
        .then((result) {
          if (!mounted) return;
          setState(() {
            _result = result;
            _isCompleted = true;
          });
          final l10n = AppLocalizations.of(context)!;
          switch (result) {
            case ImportSuccess(:final importedBooks):
              ToastService.showSuccess(l10n.restoreSuccess(importedBooks));
            case ImportFailure(:final message):
              ToastService.showError(l10n.restoreFailed(message));
          }
        })
        .catchError((Object error) {
          if (!mounted) return;
          setState(() {
            _result = ImportFailure(error.toString());
            _isCompleted = true;
          });
          ToastService.showError(
            AppLocalizations.of(context)!.restoreFailed(error.toString()),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final title = _isCompleted ? l10n.restoreCompleted : l10n.restoringBackup;

    Widget body;
    if (!_isCompleted) {
      body = const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else {
      final result = _result;
      final isSuccess = result is ImportSuccess;

      final color = isSuccess
          ? theme.colorScheme.primary
          : theme.colorScheme.error;

      final indicator = isSuccess ? '●' : '✕';
      final message = switch (result) {
        ImportSuccess(:final importedBooks) => l10n.restoreSuccess(
          importedBooks,
        ),
        ImportFailure(:final message) => l10n.restoreFailed(message),
        null => '',
      };

      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$indicator ',
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontFamily: AppTheme.fontFamilyContent,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AlertDialog(
      title: Text(title),
      content: SizedBox(width: double.maxFinite, child: body),
      actions: [
        TextButton(
          onPressed: _isCompleted ? () => Navigator.of(context).pop() : null,
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
