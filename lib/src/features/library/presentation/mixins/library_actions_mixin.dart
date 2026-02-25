import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/file_handling/file_handling.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/library/presentation/widgets/progress_dialog.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/services/toast_service.dart';
import '../../application/bookshelf_notifier.dart';
import '../../application/library_notifier.dart';
import '../../data/services/import_backup_service.dart';
import '../../data/services/unified_import_service_provider.dart';
import '../../domain/shelf_group.dart';
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

    final l10n = AppLocalizations.of(context)!;

    int totalCount = 0;
    int currentCount = 0;
    int successCount = 0;
    int failedCount = 0;
    String currentFileName = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final hasProgress = totalCount > 0;
            final isCompleted = currentCount == totalCount && totalCount > 0;
            final progressValue = hasProgress
                ? (isCompleted ? 1.0 : currentCount / totalCount)
                : null;

            return ProgressDialog(
              title: l10n.importing,
              completeTitle: l10n.importCompleted,
              progressMessage: l10n.importingProgress(
                successCount,
                failedCount,
                totalCount - successCount - failedCount,
              ),
              processingMessage: l10n.progressing(currentFileName),
              progressStream: stream,
              progressValue: progressValue,

              onProgress: (log) {
                if (log is ImportProgress) {
                  setState(() {
                    totalCount = log.totalCount;
                    currentCount = log.currentCount;
                    currentFileName = log.currentFileName;

                    if (log.status == ImportStatus.success) {
                      successCount++;
                    } else if (log.status == ImportStatus.failed) {
                      failedCount++;
                    }
                  });
                }
              },
              onError: (error, stackTrace) {
                ToastService.showError(l10n.importFailed(error.toString()));
              },
              onCompleted: () {
                ToastService.showSuccess(l10n.importCompleted);
              },
            );
          },
        );
      },
    );

    // Clean all temporary files after import is done
    ref.read(unifiedImportServiceProvider).clearAllCache();

    if (context.mounted) {
      await ref.read(bookshelfNotifierProvider.notifier).refresh();
    }
  }

  Future<void> importPaths(
    BuildContext context,
    WidgetRef ref,
    List<PlatformPath> paths,
  ) async {
    try {
      isSelectingFiles = true;
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
          FilledButton(
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
        if (name != null && name.trim().isEmpty) {
          ToastService.showError(l10n.categoryNameCannotBeEmpty);
        }
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
        title: Text(AppLocalizations.of(context)!.editCategory),
        content: TextFormField(
          initialValue: group.name,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.categoryName,
          ),
          onChanged: (value) => draftName = value,
          onFieldSubmitted: (value) => Navigator.pop(context, value.trim()),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
          ],
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
          FilledButton(
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
  // Backup
  // ---------------------------------------------------------------------------

  /// Triggers a full library backup restore.
  ///
  /// Uses [UnifiedImportService.pickBackupDirectory] to select the folder so
  /// that all platform-specific picker logic stays in one place.
  Future<void> handleRestoreBackup(BuildContext context, WidgetRef ref) async {
    isSelectingFiles = true;
    try {
      // 1. Ask the user to select the backup directory.
      final selectedPath = await ref
          .read(unifiedImportServiceProvider)
          .pickBackupFolder();

      // User cancelled — exit silently.
      if (selectedPath == null) {
        isSelectingFiles = false;
        return;
      }

      if (!context.mounted) {
        isSelectingFiles = false;
        return;
      }

      // 2. Start the stream before opening the dialog so that no work is
      //    duplicated on dialog rebuilds.
      final progressStream = ref
          .read(libraryNotifierProvider.notifier)
          .importLibraryFromFolder(selectedPath);

      // 3. Show the restore dialog; it subscribes to the stream and returns
      //    the final ImportResult when the user closes it.
      final l10n = AppLocalizations.of(context)!;

      int totalCount = 0;
      int currentCount = 0;
      int successCount = 0;
      int failedCount = 0;
      String currentFileName = '';

      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Theme.of(
          context,
        ).colorScheme.scrim.withValues(alpha: 0.5),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (dialogContext, setState) {
              final hasProgress = totalCount > 0;
              final isCompleted = currentCount == totalCount && totalCount > 0;
              final progressValue = hasProgress
                  ? (isCompleted ? 1.0 : currentCount / totalCount)
                  : null;

              return ProgressDialog(
                title: l10n.restoring,
                completeTitle: l10n.restoreCompleted,
                progressMessage: l10n.restoringProgress(
                  successCount,
                  failedCount,
                  totalCount - successCount - failedCount,
                ),
                processingMessage: l10n.progressing(currentFileName),
                progressStream: progressStream,
                progressValue: progressValue,

                onProgress: (log) {
                  if (log is BackupImportProgress) {
                    setState(() {
                      totalCount = log.total;
                      currentCount = log.current;
                      currentFileName = log.currentFileName;

                      if (log.result != null) {
                        if (log.result is ImportSuccess) {
                          successCount++;
                        } else if (log.result is ImportFailure) {
                          failedCount++;
                        }
                      }
                    });
                  }
                },
                onError: (error, stackTrace) {
                  ToastService.showError(l10n.restoreFailed(error.toString()));
                },
                onCompleted: () {
                  ToastService.showSuccess(l10n.restoreCompleted);
                },
              );
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(
          AppLocalizations.of(context)!.restoreFailed(e.toString()),
        );
      }
    } finally {
      isSelectingFiles = false;
    }

    // 4. Refresh the library shelf after a successful restore.
    if (context.mounted) {
      await ref.read(bookshelfNotifierProvider.notifier).refresh();
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
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, draftName.trim()),
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
    return (result?.trim().isNotEmpty ?? false) ? result : null;
  }
}
