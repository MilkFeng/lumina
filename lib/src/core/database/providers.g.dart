// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$isarDatabaseHash() => r'723f4a7baeccdb9ecac887385f8c55054aee7ae8';

/// Provider for IsarDatabase interface
/// Use this to access the database throughout the app
///
/// Copied from [isarDatabase].
@ProviderFor(isarDatabase)
final isarDatabaseProvider = Provider<IsarDatabase>.internal(
  isarDatabase,
  name: r'isarDatabaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isarDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsarDatabaseRef = ProviderRef<IsarDatabase>;
String _$isarHash() => r'8adffff302ffdac95f157c90001907c2b78cd017';

/// Provider for Isar instance
/// Convenience provider that returns the actual Isar instance
///
/// Copied from [isar].
@ProviderFor(isar)
final isarProvider = FutureProvider<Isar>.internal(
  isar,
  name: r'isarProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isarHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsarRef = FutureProviderRef<Isar>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
