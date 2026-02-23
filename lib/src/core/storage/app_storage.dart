import 'package:path_provider/path_provider.dart';

class AppStorage {
  AppStorage._();

  static late String _documentsPath;
  static late String _tempPath;
  static late String _supportPath;

  static String get documentsPath => _documentsPath;
  static String get tempPath => _tempPath;
  static String get supportPath => _supportPath;

  static Future<void> init() async {
    final docDir = await getApplicationDocumentsDirectory();
    _documentsPath = docDir.path;
    if (!_documentsPath.endsWith('/')) {
      _documentsPath += '/';
    }

    final tempDir = await getTemporaryDirectory();
    _tempPath = tempDir.path;
    if (!_tempPath.endsWith('/')) {
      _tempPath += '/';
    }

    final supportDir = await getApplicationSupportDirectory();
    _supportPath = supportDir.path;
    if (!_supportPath.endsWith('/')) {
      _supportPath += '/';
    }
  }
}
