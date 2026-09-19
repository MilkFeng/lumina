// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the platform file picker.
///
/// Wraps the native `com.lumina.ereader/native_picker` channel. Feature layers
/// build their own domain logic (hashing, backup classification, …) on top of
/// the raw [PlatformPath] lists this service returns.

@ProviderFor(filePicker)
const filePickerProvider = FilePickerProvider._();

/// Provider for the platform file picker.
///
/// Wraps the native `com.lumina.ereader/native_picker` channel. Feature layers
/// build their own domain logic (hashing, backup classification, …) on top of
/// the raw [PlatformPath] lists this service returns.

final class FilePickerProvider
    extends
        $FunctionalProvider<
          FilePickerService,
          FilePickerService,
          FilePickerService
        >
    with $Provider<FilePickerService> {
  /// Provider for the platform file picker.
  ///
  /// Wraps the native `com.lumina.ereader/native_picker` channel. Feature layers
  /// build their own domain logic (hashing, backup classification, …) on top of
  /// the raw [PlatformPath] lists this service returns.
  const FilePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filePickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filePickerHash();

  @$internal
  @override
  $ProviderElement<FilePickerService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FilePickerService create(Ref ref) {
    return filePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FilePickerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FilePickerService>(value),
    );
  }
}

String _$filePickerHash() => r'1b5b4e9d3c36e000e96976cb4fd8a0988c9a5035';
