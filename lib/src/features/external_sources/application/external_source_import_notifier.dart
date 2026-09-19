import 'dart:async';
import 'dart:io';

import 'package:lumina/src/core/platform/import_cache_manager.dart';
import 'package:lumina/src/core/widgets/progress_dialog.dart';
import 'package:lumina/src/features/external_sources/application/external_sources_notifier.dart';
import 'package:lumina/src/features/external_sources/domain/external_source.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_failure.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_item.dart';
import 'package:lumina/src/features/library/application/bookshelf_notifier.dart';
import 'package:lumina/src/features/library/application/library_notifier.dart';
import 'package:lumina/src/features/library/data/services/epub_import_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'external_source_import_notifier.g.dart';

/// Downloads books from an external source and feeds them into the library.
///
/// Two concerns chained in one place: downloading is the external-sources
/// feature's job (through its adapter), importing is the library feature's
/// ([EpubImportService]).
///
/// Emitting [ImportProgress] — the library's own event type — is deliberate: it
/// lets the existing import progress dialog render a remote import without
/// knowing where the bytes came from.
///
/// Kept alive because the generator holds a `Ref` across a download and an
/// import per file, and an `autoDispose` provider would be torn down as soon as
/// the progress dialog is the only thing on screen.
@Riverpod(keepAlive: true)
class ExternalSourceImportNotifier extends _$ExternalSourceImportNotifier {
  /// Shortest gap between two reported download ticks.
  ///
  /// A chunk is a few kilobytes, so a book reports hundreds of times, and every
  /// tick repaints the progress dialog. Ten updates a second is more than the
  /// counter can show; the end of a download always gets through regardless, so
  /// the last number the user sees is the file's real size.
  static const Duration tickInterval = Duration(milliseconds: 100);

  @override
  void build() {}

  /// Downloads [items] one at a time, importing each into the library.
  ///
  /// Sequential on purpose, for the same reason the local import pipeline is:
  /// one EPUB in memory and on disk at a time. Each downloaded file is deleted
  /// before the next one starts.
  Stream<ProgressLog> importStream(
    ExternalSource source,
    List<ExternalSourceItem> items,
  ) async* {
    final total = items.length;
    yield ProgressLog(
      'Preparing to import $total book(s) from "${source.name}"',
      ProgressLogType.info,
    );
    if (total == 0) return;

    final cache = ImportCacheManager();
    final sources = ref.read(externalSourcesProvider.notifier);
    final importService = ref.read(epubImportServiceProvider);
    var current = 0;
    var imported = 0;

    for (final item in items) {
      yield ImportProgress(
        totalCount: total,
        currentCount: current,
        currentFileName: item.name,
        status: ImportStatus.processing,
      );

      File? cached;
      try {
        cached = await cache.createCacheFile(extensionOf(item));

        // A generator cannot `yield` from inside a callback, so the ticks the
        // download reports are pushed into a controller: the download runs as a
        // future while the loop below turns those ticks into stream events, and
        // the failure is read off the future once it has settled.
        final ticks = StreamController<FileTransferProgress>();
        final clock = Stopwatch()..start();
        var lastTickAt = Duration.zero;

        final downloading = _download(
          source,
          item,
          cached,
          sources,
          onProgress: (received, total) {
            // Dropped once the mirroring loop is over: a tick that arrives after
            // the file is finished describes nothing anyone still shows.
            if (ticks.isClosed) return;

            final isComplete = total != null && received >= total;
            final now = clock.elapsed;
            if (!isComplete && now - lastTickAt < tickInterval) return;
            lastTickAt = now;

            ticks.add(
              FileTransferProgress(
                fileName: item.name,
                receivedBytes: received,
                // Servers are free to answer without a `Content-Length`; the
                // listing already reported the size, so that is the fallback.
                totalBytes: total ?? item.size,
              ),
            );
          },
        );
        // Registered before the ticks are drained, so the loop always ends.
        // Handling the error here keeps it from being reported as unhandled;
        // the `await` below still receives it.
        unawaited(
          downloading.then<void>(
            (_) => ticks.close(),
            onError: (_) => ticks.close(),
          ),
        );

        await for (final tick in ticks.stream) {
          yield tick;
        }

        final failure = await downloading;
        if (failure != null) {
          yield ImportProgress(
            totalCount: total,
            currentCount: current,
            currentFileName: item.name,
            status: ImportStatus.failed,
            errorMessage: describeFailure(failure),
          );
          continue;
        }

        final result = await importService.importBook(cached);

        yield result.fold(
          (error) => ImportProgress(
            totalCount: total,
            currentCount: current,
            currentFileName: item.name,
            status: ImportStatus.failed,
            errorMessage: error,
          ),
          (book) {
            imported++;
            return ImportProgress(
              totalCount: total,
              currentCount: current,
              currentFileName: item.name,
              status: ImportStatus.success,
              book: book,
            );
          },
        );
      } catch (error) {
        yield ImportProgress(
          totalCount: total,
          currentCount: current,
          currentFileName: item.name,
          status: ImportStatus.failed,
          errorMessage: '$error',
        );
      } finally {
        // Deleted per file rather than per batch: an import that fails midway
        // must not leave a downloaded EPUB behind in the cache directory.
        if (cached != null) await cache.clean(cached);
        current++;
      }
    }

    yield ProgressLog(
      'Imported $imported of $total book(s) from "${source.name}"',
      imported == total ? ProgressLogType.success : ProgressLogType.warning,
    );

    // The shelf is owned by the library feature, so it is refreshed through that
    // feature rather than by poking its repositories directly.
    await ref.read(bookshelfProvider.notifier).refresh();
  }

  /// Streams one entry to [target], reporting bytes received to [onProgress].
  Future<ExternalSourceFailure?> _download(
    ExternalSource source,
    ExternalSourceItem item,
    File target,
    ExternalSourcesNotifier sources, {
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    final adapter = ref
        .read(externalSourceRegistryProvider)
        .createAdapter(
          source,
          credentials: await sources.credentialsFor(source),
        );
    try {
      final result = await adapter.downloadTo(
        item.path,
        target,
        onProgress: onProgress,
      );
      return result.fold<ExternalSourceFailure?>(
        (failure) => failure,
        (_) => null,
      );
    } finally {
      adapter.dispose();
    }
  }

  /// Cache-file extension for [item]: its own when it has one, `.epub`
  /// otherwise.
  ///
  /// The name only supplies an extension — the file itself lands in the cache
  /// under a generated name — so a hostile entry name cannot influence where
  /// anything is written.
  static String extensionOf(ExternalSourceItem item) {
    final dot = item.name.lastIndexOf('.');
    if (dot <= 0 || dot == item.name.length - 1) return '.epub';
    final extension = item.name.substring(dot);
    // Anything odd enough to contain a separator is not an extension.
    if (extension.contains('/') || extension.contains(r'\')) return '.epub';
    return extension;
  }

  /// Untranslated reason for a failure, for the progress log.
  ///
  /// The log panel is a diagnostics surface and stays English, matching the
  /// local import pipeline; the localized sentence a user sees in a toast is
  /// built from the same typed failure by `AppLocalizations`.
  static String describeFailure(ExternalSourceFailure failure) {
    final status = failure.statusCode;
    final base = status == null
        ? failure.kind.name
        : '${failure.kind.name} (HTTP $status)';
    final detail = failure.detail;
    return detail == null || detail.isEmpty ? base : '$base: $detail';
  }
}
