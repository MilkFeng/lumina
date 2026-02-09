import 'package:path_provider/path_provider.dart';

class AppStorage {
  AppStorage._();

  static late final String documentsPath;
  static late final String tempPath;

  static Future<void> init() async {
    final docDir = await getApplicationDocumentsDirectory();
    documentsPath = docDir.path;

    final tempDir = await getTemporaryDirectory();
    tempPath = tempDir.path;
  }
}
