import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'epub_stream_service.dart';

part 'epub_stream_service_provider.g.dart';

/// Provider for EpubStreamService
/// This service handles streaming EPUB files without extraction
@riverpod
EpubStreamService epubStreamService(EpubStreamServiceRef ref) {
  return EpubStreamService();
}
