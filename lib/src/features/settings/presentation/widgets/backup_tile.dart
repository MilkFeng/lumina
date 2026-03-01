import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/library/data/services/export_backup_service.dart';
import 'package:lumina/src/features/library/data/services/export_backup_service_provider.dart';
import '../../../../../l10n/app_localizations.dart';

/// List tile that triggers a full library backup export.
///
/// Manages its own [_isExporting] busy state and uses a [GlobalKey] to anchor
/// the iOS Share Sheet popover to the tile's screen position.
class BackupTile extends ConsumerStatefulWidget {
  const BackupTile({super.key});

  @override
  ConsumerState<BackupTile> createState() => _BackupTileState();
}

class _BackupTileState extends ConsumerState<BackupTile> {
  bool _isExporting = false;
  final _tileKey = GlobalKey();

  /// Returns the screen-space [Rect] of this tile for the Share Sheet anchor.
  Rect? _tileRect() {
    final box = _tileKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  Future<void> _export() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    // Capture l10n before the async gap to avoid BuildContext use after await.
    final l10n = AppLocalizations.of(context)!;

    final result = await ref
        .read(exportBackupServiceProvider)
        .exportLibraryAsFolder(sharePositionOrigin: _tileRect());

    if (!mounted) {
      _isExporting = false;
      return;
    }

    switch (result) {
      case ExportSuccess(:final path):
        final message = (Platform.isAndroid && path != null)
            ? l10n.backupSavedToDownloads(path)
            : l10n.backupShared;
        ToastService.showSuccess(message);
      case ExportFailure(:final message):
        ToastService.showError(l10n.exportFailed(message));
    }

    setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      key: _tileKey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(
        Icons.archive_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(l10n.backupLibrary),
      subtitle: Text(
        l10n.backupLibraryDescription,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: _isExporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _isExporting ? null : _export,
    );
  }
}
