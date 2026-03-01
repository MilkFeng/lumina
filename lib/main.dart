import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/providers/shared_preferences_provider.dart';
import 'package:lumina/src/core/storage/app_storage.dart';
import 'package:lumina/src/features/library/data/services/storage_cleanup_service_provider.dart';
import 'package:lumina/src/features/reader/data/services/epub_stream_service_provider.dart';
import 'package:lumina/src/features/reader/presentation/reader_webview.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Force portrait orientation for mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Preload shared preferences before building the provider container to avoid delays when
  // the UI first accesses them.
  final prefs = await SharedPreferences.getInstance();

  // Create provider container
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Initialize Isar database
  await container.read(isarProvider.future);
  container.read(epubStreamServiceProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LuminaReaderApp(),
    ),
  );

  Future.delayed(const Duration(seconds: 3), () {
    container.read(storageCleanupServiceProvider).cleanCacheFiles();
    container.read(storageCleanupServiceProvider).cleanShareFiles();
  });
}
