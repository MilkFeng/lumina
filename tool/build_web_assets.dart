import 'dart:io';

void main() async {
  print('🚀 start build lumina web assets...');

  const jsProjectDir = 'web_viewer/controller.js';

  String minifiedJs = '';
  String minifiedPaginationCss = '';
  String minifiedSkeletonCss = '';

  Future<String> runEsbuild(List<String> args) async {
    final result = await Process.run(
      'npx',
      ['esbuild', ...args],
      workingDirectory: jsProjectDir,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      print('❌ esbuild error:\n${result.stderr}');
      exit(1);
    }
    return (result.stdout as String).trim();
  }

  try {
    print('📦 com: controller.js...');
    minifiedJs = await runEsbuild([
      'index.ts',
      '--bundle',
      '--minify',
      '--format=iife',
    ]);

    print('📦 com: pagination.css...');
    minifiedPaginationCss = await runEsbuild(['../pagination.css', '--minify']);

    print('📦 com: skeleton.css...');
    minifiedSkeletonCss = await runEsbuild(['../skeleton.css', '--minify']);
  } catch (e) {
    print('❌ error: $e');
    exit(1);
  }

  final outputPath = 'lib/src/web/web_assets.dart';
  final buffer = StringBuffer();

  buffer.writeln('// ==========================================');
  buffer.writeln('// 🚨 GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// ==========================================\n');

  buffer.writeln(
    'const String kControllerJs = r\'\'\'\n$minifiedJs\n\'\'\';\n',
  );
  buffer.writeln(
    'const String kPaginationCss = r\'\'\'\n$minifiedPaginationCss\n\'\'\';\n',
  );
  buffer.writeln(
    'const String kSkeletonCss = r\'\'\'\n$minifiedSkeletonCss\n\'\'\';\n',
  );

  final outFile = File(outputPath);
  if (!outFile.parent.existsSync()) {
    outFile.parent.createSync(recursive: true);
  }
  await outFile.writeAsString(buffer.toString());

  print('✅ web assets generated: $outputPath');
}
