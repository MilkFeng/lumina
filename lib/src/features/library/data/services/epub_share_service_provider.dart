import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'epub_share_service.dart';

part 'epub_share_service_provider.g.dart';

/// Provider for [EpubShareService] — temporary `.epub` copies for the platform
/// share sheet.
@riverpod
EpubShareService epubShareService(Ref ref) {
  return EpubShareService();
}
