import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/storage/app_storage.dart';
import 'package:lumina/src/features/library/data/services/storage_cleanup_service_provider.dart';
import 'package:lumina/src/features/reader/data/services/epub_stream_service_provider.dart';
import 'package:lumina/src/features/reader/presentation/reader_webview.dart';
import 'src/app.dart';
import 'src/core/database/providers.dart';

HeadlessInAppWebView? headlessWebView;

void _preWarmWebView() async {
  headlessWebView = HeadlessInAppWebView(
    initialSettings: defaultSettings,
    onWebViewCreated: (controller) {
      debugPrint("WebView Engine Warmed Up!");
    },
  );
  await headlessWebView?.run();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app storage paths
  await AppStorage.init();

  // Pre-warm the WebView engine to reduce first load latency
  _preWarmWebView();

  // Create provider container
  final container = ProviderContainer();

  // Initialize Isar database
  await container.read(isarProvider.future);
  container.read(epubStreamServiceProvider);

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

  container.read(storageCleanupServiceProvider).cleanCacheFiles();
}
