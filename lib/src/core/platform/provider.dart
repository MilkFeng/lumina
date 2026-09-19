import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'file_picker_service.dart';

part 'provider.g.dart';

/// Provider for the platform file picker.
///
/// Wraps the native `com.lumina.ereader/native_picker` channel. Feature layers
/// build their own domain logic (hashing, backup classification, …) on top of
/// the raw [PlatformPath] lists this service returns.
@riverpod
FilePickerService filePicker(Ref ref) {
  return FilePickerService();
}
