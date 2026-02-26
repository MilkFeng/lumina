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
      print('❌ Cannot find source file: $path. Please ensure it exists.');
      return;
    }
  }

  Map<String, String> contentMap = {};

  String escape(String str) {
    return str.replaceAll('\\', '\\\\').replaceAll('\$', '\\\$');
  }

  for (final entry in fileMap.entries) {
    final content = File(entry.key).readAsStringSync();
    contentMap.putIfAbsent(entry.value, () => escape(content));
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
  print(
    '✅ Web assets generated successfully at lib/web_src/reader_assets.dart',
  );
}
