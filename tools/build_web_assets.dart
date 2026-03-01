import 'dart:io';

void main() {
  const fileMap = {
    'lib/web_src/controller.js': 'kControllerJs',
    'lib/web_src/pagination.css': 'kPaginationCss',
    'lib/web_src/skeleton.css': 'kSkeletonCss',
  };

  // Check if all source files exist
  for (final path in fileMap.keys) {
    if (!File(path).existsSync()) {
      // ignore: avoid_print
      print('❌ Cannot find source file: $path. Please ensure it exists.');
      return;
    }
  }

  Map<String, String> contentMap = {};

  for (final entry in fileMap.entries) {
    final content = File(entry.key).readAsStringSync();
    contentMap.putIfAbsent(entry.value, () => content);
  }

  String generatedContent = '''
// ==========================================
// 🚨 GENERATED CODE - DO NOT MODIFY BY HAND
// ==========================================
''';

  contentMap.forEach((varName, content) {
    generatedContent +=
        'const String $varName = r\'\'\'\n$content\n\'\'\';\n\n';
  });

  final outFile = File('lib/web_src/reader_assets.dart');

  if (!outFile.parent.existsSync()) {
    outFile.parent.createSync(recursive: true);
  }

  outFile.writeAsStringSync(generatedContent);
  // ignore: avoid_print
  print(
    '✅ Web assets generated successfully at lib/web_src/reader_assets.dart',
  );
}
