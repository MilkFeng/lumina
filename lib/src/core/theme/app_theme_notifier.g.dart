// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_theme_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appThemeNotifierHash() => r'c6ce3a981ba2a0d632d861eeb1ba85ce6c200b6e';

/// Keeps the user's chosen app-wide theme settings alive for the entire
/// app session and persists them with [SharedPreferences].
///
/// Copied from [AppThemeNotifier].
@ProviderFor(AppThemeNotifier)
final appThemeNotifierProvider =
    NotifierProvider<AppThemeNotifier, AppThemeSettings>.internal(
  AppThemeNotifier.new,
  name: r'appThemeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appThemeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppThemeNotifier = Notifier<AppThemeSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
