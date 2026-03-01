import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'shared_preferences_provider.g.dart';

/// A synchronous, keep-alive provider for [SharedPreferences].
///
/// ⚠️ This will throw an [UnimplementedError] by default.
/// It MUST be overridden in `main.dart` using `overrideWithValue`
/// after `SharedPreferences.getInstance()` is awaited.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(SharedPreferencesRef ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider MUST be initialized via override in main.dart using ProviderScope!',
  );
}
