import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'epub_stream_service.dart';

part 'epub_stream_service_provider.g.dart';

/// Provider for EpubStreamService
/// This service handles streaming EPUB files without extraction
@Riverpod(keepAlive: true)
EpubStreamService epubStreamService(EpubStreamServiceRef ref) {
  final service = EpubStreamService();
  service.warmUp();

  // Dispose the service and its isolate when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
