import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';
import 'src/core/database/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create provider container
  final container = ProviderContainer();

  // Initialize Isar database
  await container.read(isarProvider.future);

  // Force portrait orientation for mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LuminaReaderApp(),
    ),
  );
  FilePicker.platform.clearTemporaryFiles();
}
