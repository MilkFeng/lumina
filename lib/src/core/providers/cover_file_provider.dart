import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cover_file_provider.g.dart';

/// Provider that caches cover file lookups by relative path.
/// Returns null if path is null/empty or file doesn't exist.
@riverpod
Future<File?> coverFile(CoverFileRef ref, String? relativePath) async {
  // Return null for invalid paths
  if (relativePath == null || relativePath.isEmpty) {
    return null;
  }

  try {
    // Get app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    
    // Decode URI components and construct full path
    final decodedPath = Uri.decodeFull(relativePath);
    final file = File('${appDir.path}/$decodedPath');
    
    // Check if file exists
    final exists = await file.exists();
    return exists ? file : null;
  } catch (_) {
    return null;
  }
}
