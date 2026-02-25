import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/core/storage/app_storage.dart';
import 'package:lumina/src/features/library/data/services/storage_cleanup_service_provider.dart';
import '../domain/shelf_book.dart';
import '../../../../l10n/app_localizations.dart';

/// Copies the book's EPUB source file to a sanitised temporary path, opens
/// the platform share sheet, and deletes the temporary copy when done.
///
/// Any error is surfaced via [ToastService] instead of propagating.
Future<void> shareEpub(
  BuildContext context,
  ShelfBook book,
  WidgetRef ref,
) async {
  final service = ref.read(storageCleanupServiceProvider);

  File? tempFile;
  try {
    final sourcePath = '${AppStorage.documentsPath}${book.filePath}';
    tempFile = await service.saveTempFileForSharing(
      File(sourcePath),
      book.title,
    );

    final params = ShareParams(
      subject: book.title,
      files: [XFile(tempFile.path, mimeType: 'application/epub+zip')],
    );
    await SharePlus.instance.share(params);
  } catch (e) {
    if (context.mounted) {
      ToastService.showError(
        AppLocalizations.of(context)!.shareEpubFailed(e.toString()),
      );
    }
  } finally {
    if (tempFile != null && await tempFile.exists()) {
      await tempFile.delete();
    }
  }
}
