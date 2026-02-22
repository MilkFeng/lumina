import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/file_handling/file_handling.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/services/toast_service.dart';
import '../../application/bookshelf_notifier.dart';
import '../../application/library_notifier.dart';
import '../../data/services/export_backup_service.dart';
import '../../data/services/export_backup_service_provider.dart';
import '../../data/services/import_backup_service.dart';
import '../../data/services/import_backup_service_provider.dart';
import '../../data/services/unified_import_service_provider.dart';
import '../../domain/shelf_group.dart';
import '../widgets/batch_import_dialog.dart';
import '../widgets/group_selection_dialog.dart';

/// Mixin that provides action methods for LibraryScreen.
/// Handles imports, deletions, group management, and file operations.
mixin LibraryActionsMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  bool _isSelectingFiles = false;

  bool get isSelectingFiles => _isSelectingFiles;

  set isSelectingFiles(bool value) {
    if (mounted) {
      setState(() {
        _isSelectingFiles = value;
      });
    }
  }

  Future<void> _importPaths(
    BuildContext context,
    WidgetRef ref,
    List<PlatformPath> paths,
    Function() onImportablesReady,
  ) async {
    if (paths.isEmpty) {
      onImportablesReady();
      return;
    }

    // Process files one by one
    onImportablesReady();

    final stream = ref
        .read(libraryNotifierProvider.notifier)
        .importPipelineStream(paths);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5),
      builder: (ctx) => BatchImportDialog(progressStream: stream),
    );

    // Clean all temporary files after import is done
    ref.read(unifiedImportServiceProvider).clearAllCache();

    if (context.mounted) {
      ref.read(bookshelfNotifierProvider.notifier).refresh();
    }
  }

  Future<void> handleScanFolder(BuildContext context, WidgetRef ref) async {
    try {
      isSelectingFiles = true;

      // Use unified import service for cross-platform file picking
      final importService = ref.read(unifiedImportServiceProvider);
      final paths = await importService.pickFolder();

      if (context.mounted) {
        await _importPaths(context, ref, paths, () {
          isSelectingFiles = false;
        });
      }
    } catch (e) {
      isSelectingFiles = false;
      if (context.mounted) {
        ToastService.showError(
          AppLocalizations.of(context)!.importFailed(e.toString()),
        );
      }
    }
  }

  Future<void> handleImportFiles(BuildContext context, WidgetRef ref) async {
    try {
      isSelectingFiles = true;

      // Use unified import service for cross-platform file picking
      final importService = ref.read(unifiedImportServiceProvider);
      final paths = await importService.pickFiles();

      if (context.mounted) {
        await _importPaths(context, ref, paths, () {
          isSelectingFiles = false;
        });
      }
    } catch (e) {
      isSelectingFiles = false;
      if (context.mounted) {
        ToastService.showError(
          AppLocalizations.of(context)!.importFailed(e.toString()),
        );
      }
    }
  }

  Future<void> confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteBooks),
        content: Text(AppLocalizations.of(context)!.deleteBooksConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(bookshelfNotifierProvider.notifier)
          .deleteSelected();
      if (context.mounted) {
        if (success) {
          ToastService.showSuccess(AppLocalizations.of(context)!.deleted);
        } else {
          ToastService.showError(AppLocalizations.of(context)!.failedToDelete);
        }
      }
    }
  }

  Future<void> showMoveToGroup(
    BuildContext context,
    WidgetRef ref,
    BookshelfState state,
  ) async {
    const createGroupResult = -2;

    final l10n = AppLocalizations.of(context)!;

    var result = await showDialog<int?>(
      context: context,
      builder: (context) => GroupSelectionDialog(
        groups: state.availableGroups,
        createGroupResult: createGroupResult,
      ),
    );
    String? newName;

    if (result == createGroupResult) {
      if (!context.mounted) return;
      final name = await promptForGroupName(context);
      if (!context.mounted) return;
      if (name != null && name.trim().isNotEmpty) {
        final groupId = await ref
            .read(bookshelfNotifierProvider.notifier)
            .createGroup(name);
        if (!context.mounted) return;

        if (groupId == null) {
          if (state is AsyncError) {
            ToastService.showError(l10n.failedToCreateCategory);
          }
          return;
        } else {
          ToastService.showSuccess(l10n.categoryCreated(name));
        }

        result = groupId;
        newName = name;
      } else {
        ToastService.showError(l10n.categoryNameCannotBeEmpty);
        return;
      }
    }

    if (result != null) {
      final targetGroupId = result == -1 ? null : result;
      final success = await ref
          .read(bookshelfNotifierProvider.notifier)
          .moveSelectedItems(targetGroupId);
      if (!context.mounted) return;
      {
        if (success) {
          var targetName = l10n.categoryName;
          if (targetGroupId == null) {
            targetName = l10n.uncategorized;
          } else {
            if (newName != null) {
              targetName = newName;
            } else {
              for (final group in state.availableGroups) {
                if (group.id == targetGroupId) {
                  targetName = group.name;
                  break;
                }
              }
            }
          }
          ToastService.showSuccess(l10n.movedTo(targetName));
        } else {
          ToastService.showError(l10n.failedToMove);
        }
      }
    }
  }

  Future<void> showEditGroupDialog(
    BuildContext context,
    WidgetRef ref,
    ShelfGroup group,
    AppLocalizations l10n,
  ) async {
    var draftName = group.name;
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.editCategory,
          style: AppTheme.contentTextStyle,
        ),
        content: TextFormField(
          initialValue: group.name,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.categoryName,
          ),
          onChanged: (value) => draftName = value,
          onFieldSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ref
                  .read(bookshelfNotifierProvider.notifier)
                  .deleteGroup(group.id);
              if (context.mounted) {
                if (result) {
                  ToastService.showSuccess(l10n.categoryDeleted(group.name));
                } else {
                  ToastService.showError(l10n.failedToDeleteCategory);
                }
              }
            },
            child: Text(l10n.delete),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, draftName.trim()),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != group.name) {
      await ref
          .read(bookshelfNotifierProvider.notifier)
          .renameGroup(group.id, result);
    }
  }

  // ---------------------------------------------------------------------------
  // Export / Backup
  // ---------------------------------------------------------------------------

  /// Triggers a full library backup export.
  ///
  /// Shows a non-dismissible loading dialog while the export runs, then
  /// presents feedback via a [SnackBar]:
  ///   - Android success → folder path in Downloads
  ///   - iOS / other success → Share Sheet was presented by the service
  ///   - Failure → error message in red
  Future<void> handleExportBackup(BuildContext context, WidgetRef ref) async {
    // Show a non-dismissible progress dialog for the duration of the export.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Positioned.fill(
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );

    final result = await ref
        .read(exportBackupServiceProvider)
        .exportLibraryAsFolder();

    // Guard against widget being unmounted while awaiting.
    if (!context.mounted) return;

    // Dismiss the loading dialog.
    Navigator.of(context, rootNavigator: true).pop();

    if (!context.mounted) return;

    switch (result) {
      case ExportSuccess(:final path):
        final message = (Platform.isAndroid && path != null)
            ? AppLocalizations.of(context)!.backupSavedToDownloads(path)
            : AppLocalizations.of(context)!.backupReadyToShare;
        ToastService.showSuccess(message);
      case ExportFailure(:final message):
        ToastService.showError(
          AppLocalizations.of(context)!.exportFailed(message),
        );
    }
  }

  /// Triggers a full library backup restore.
  ///
  /// Uses [UnifiedImportService.pickBackupDirectory] to select the folder so
  /// that all platform-specific picker logic stays in one place.
  Future<void> handleRestoreBackup(BuildContext context, WidgetRef ref) async {
    // 1. Ask the user to select the backup directory.
    final selectedPath = await ref
        .read(unifiedImportServiceProvider)
        .pickBackupDirectory();

    // User cancelled — exit silently.
    if (selectedPath == null) return;

    if (!context.mounted) return;

    // 2. Show a non-dismissible progress dialog while the restore runs.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text('Restoring backup...'),
          content: SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      ),
    );

    // 3. Run the restore.
    final result = await ref
        .read(importBackupServiceProvider)
        .importLibraryFromFolder(selectedPath);

    if (!context.mounted) return;

    // 4. Dismiss the loading dialog.
    Navigator.of(context, rootNavigator: true).pop();

    if (!context.mounted) return;

    // 5. Show feedback and refresh the library on success.
    switch (result) {
      case ImportSuccess(:final importedBooks):
        ref.read(bookshelfNotifierProvider.notifier).refresh();
        ToastService.showSuccess('Successfully restored $importedBooks books.');
      case ImportFailure(:final message):
        ToastService.showError('Failed to restore backup: $message');
    }
  }

  Future<String?> promptForGroupName(BuildContext context) async {
    var draftName = '';
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.newCategory),
        content: TextField(
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.categoryName,
          ),
          onChanged: (value) => draftName = value,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
          style: AppTheme.contentTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, draftName.trim()),
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
    return (result?.trim().isNotEmpty ?? false) ? result : null;
  }
}
