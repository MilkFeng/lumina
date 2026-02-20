import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/file_handling/file_handling.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/services/toast_service.dart';
import '../../application/bookshelf_notifier.dart';
import '../../application/library_notifier.dart';
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

  Future<void> handleImportFiles(BuildContext context, WidgetRef ref) async {
    try {
      isSelectingFiles = true;

      // Use unified import service for cross-platform file picking
      final importService = ref.read(unifiedImportServiceProvider);
      final paths = await importService.pickFiles();

      if (paths.isEmpty) {
        isSelectingFiles = false;
        return;
      }

      // Process files one by one
      final importables = <ImportableEpub>[];
      for (final path in paths) {
        try {
          final importable = await importService.processEpub(path);
          importables.add(importable);
        } catch (e) {
          // Skip files that fail to process and log the error
          debugPrint('Failed to process file: $path, error: $e');
        }
      }

      isSelectingFiles = false;

      if (importables.isEmpty) {
        if (context.mounted) {
          ToastService.showError(AppLocalizations.of(context)!.fileAccessError);
        }
        return;
      }

      // Extract cache files from ImportableEpub objects
      final files = importables
          .map((importable) => importable.cacheFile)
          .toList();

      final stream = ref
          .read(libraryNotifierProvider.notifier)
          .importMultipleBooks(files);

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Theme.of(
          context,
        ).colorScheme.scrim.withValues(alpha: 0.5),
        builder: (ctx) => BatchImportDialog(progressStream: stream),
      );

      // Clean up cache files after import
      for (final importable in importables) {
        await importService.cleanCache(importable.cacheFile);
      }

      if (context.mounted) {
        ref.read(bookshelfNotifierProvider.notifier).refresh();
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
