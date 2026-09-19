import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/platform/provider.dart';
import 'package:lumina/src/core/providers/cover_file_provider.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/library/application/bookshelf_notifier.dart';
import 'package:lumina/src/features/library/application/library_notifier.dart';
import 'package:lumina/src/features/library/data/services/backup_folder_resolver.dart';
import 'package:lumina/src/features/settings/presentation/widgets/restore_progress_dialog.dart';
import '../../../../../l10n/app_localizations.dart';

/// List tile that replaces the current library with a backup folder.
///
/// Restoring is destructive: the library that is on the device right now —
/// database records, book files, covers and reading progress — is cleared
/// before the backup is applied. The flow therefore always pauses on a
/// confirmation dialog and shows its own [_isRestoring] busy state, mirroring
/// the backup tile next to it in the settings screen.
class RestoreTile extends ConsumerStatefulWidget {
  const RestoreTile({super.key});

  @override
  ConsumerState<RestoreTile> createState() => _RestoreTileState();
}

class _RestoreTileState extends ConsumerState<RestoreTile> {
  bool _isRestoring = false;

  Future<void> _restore() async {
    if (_isRestoring) return;

    final l10n = AppLocalizations.of(context)!;
    final picker = ref.read(filePickerProvider);
    setState(() => _isRestoring = true);

    // Stays `false` until the restore stream takes over the security-scoped
    // access held by the picker; ImportBackupService releases it in its own
    // `finally` block, so it must not be released twice for one pick.
    var streamOwnsAccess = false;

    try {
      // 1. Let the user pick the backup folder and resolve its layout.
      final backupPaths = await const BackupFolderResolver().pickAndResolve();

      // Cancelled — exit silently.
      if (backupPaths == null) return;
      if (!mounted) return;

      // 2. Restoring wipes the current library, so ask first.
      if (!await _confirmRestore(l10n, backupPaths.rootPath.name)) return;
      if (!mounted) return;

      // 3. Start the stream before opening the dialog so that no work is
      //    duplicated on dialog rebuilds.
      final stream = ref
          .read(libraryProvider.notifier)
          .restoreLibraryFromBackup(backupPaths);
      streamOwnsAccess = true;

      // 4. Show the progress dialog; it closes itself once the stream is done.
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Theme.of(
          context,
        ).colorScheme.scrim.withValues(alpha: 0.5),
        builder: (ctx) => RestoreProgressDialog(stream: stream, l10n: l10n),
      );
    } catch (e) {
      if (mounted) {
        ToastService.showError(l10n.restoreFailed(e.toString()));
      }
    } finally {
      if (!streamOwnsAccess) {
        await picker.releaseIosAccess();
      }
      if (mounted) {
        setState(() => _isRestoring = false);
        if (streamOwnsAccess) {
          // Every file was rewritten: drop the cached cover lookups and reload
          // the shelf so the library screen reflects the restored data.
          ref.invalidate(coverFileProvider);
          await ref.read(bookshelfProvider.notifier).resetAfterRestore();
        }
      }
    }
  }

  /// Warns that the current library will be erased and asks for confirmation.
  Future<bool> _confirmRestore(AppLocalizations l10n, String backupName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Text(l10n.restoreConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.restoreConfirmMessage),
              const SizedBox(height: 12),
              Text(
                l10n.restoreConfirmSource(backupName),
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.restoreConfirmAction),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(
        Icons.settings_backup_restore_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(l10n.restoreFromBackup),
      subtitle: Text(
        l10n.restoreBackupDescription,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: _isRestoring
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _isRestoring ? null : _restore,
    );
  }
}
