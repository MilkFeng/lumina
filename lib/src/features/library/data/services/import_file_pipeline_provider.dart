import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/platform/provider.dart';
import 'import_file_pipeline.dart';

part 'import_file_pipeline_provider.g.dart';

/// Provider for [ImportFilePipeline] — the picker plus the import cache,
/// wired together for iOS copy-on-demand.
@riverpod
ImportFilePipeline importFilePipeline(Ref ref) {
  return ImportFilePipeline.from(ref.watch(filePickerProvider));
}
