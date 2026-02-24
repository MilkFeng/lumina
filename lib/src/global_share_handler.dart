import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/library/application/library_notifier.dart';
import 'features/library/application/bookshelf_notifier.dart';
import 'features/library/presentation/widgets/progress_dialog.dart';
import '../l10n/app_localizations.dart';
import 'core/services/toast_service.dart';
import 'core/file_handling/platform_path.dart';
import 'features/library/data/services/unified_import_service_provider.dart';

// State provider to hold pending file path for processing after returning to library screen
final pendingRouteFileProvider = StateProvider<String?>((ref) => null);

/// A transparent widget that lives above the app navigator and listens for
/// incoming EPUB files from the OS ("Open with" / share-sheet).
class GolbalShareHandler extends ConsumerWidget {
  final Widget child;

  const GolbalShareHandler({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _listenPendingRouteFile(context, ref);
    return child;
  }

  void _listenPendingRouteFile(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(pendingRouteFileProvider, (previous, nextPath) {
      if (nextPath != null && nextPath.isNotEmpty) {
        final platformPath = PlatformPath.fromString(nextPath);

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _runImportPipeline(context, ref, [platformPath]);
        });

        Future.microtask(() {
          ref.read(pendingRouteFileProvider.notifier).state = null;
        });
      }
    });
  }

  Future<void> _runImportPipeline(
    BuildContext context,
    WidgetRef ref,
    List<PlatformPath> paths,
  ) async {
    // Use the navigator key's context so we can show a dialog / overlay from
    // anywhere in the tree, regardless of the current route.
    final navContext = ToastService.navigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;

    final l10n = AppLocalizations.of(navContext)!;

    final stream = ref
        .read(libraryNotifierProvider.notifier)
        .importPipelineStream(paths);

    int totalCount = 0;
    int currentCount = 0;
    int successCount = 0;
    int failedCount = 0;
    String currentFileName = '';

    await showDialog(
      context: navContext,
      barrierDismissible: false,
      barrierColor: Theme.of(
        navContext,
      ).colorScheme.scrim.withValues(alpha: 0.5),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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
                  setDialogState(() {
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

    // Clean up any leftover temp cache files created during this session.
    ref.read(unifiedImportServiceProvider).clearAllCache();

    // Refresh the bookshelf so the newly imported book appears immediately.
    await ref.read(bookshelfNotifierProvider.notifier).refresh();
  }
}
