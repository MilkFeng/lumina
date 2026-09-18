import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/providers/shared_preferences_provider.dart';
import 'package:lumina/src/core/storage/app_storage.dart';
import 'package:lumina/src/features/reader/data/services/epub_stream_service_provider.dart';
import 'package:lumina/src/features/reader/presentation/reader_webview.dart';
import 'package:lumina/src/rust/frb_generated.dart';
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

  // Initialize Rust FFI runtime (must be called before any Rust API functions)
  await RustLib.init();

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

  // Register Rust licenses
  LicenseRegistry.addLicense(() async* {
    final jsonString = await rootBundle.loadString(
      'assets/licenses/rust_licenses.json',
    );
    final List<dynamic> licenses = jsonDecode(jsonString);

    for (var license in licenses) {
      final List<String> crates = List<String>.from(license['crates']);
      final String text = license['text'];

      yield LicenseEntryWithLineBreaks(crates, text);
    }
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LuminaReaderApp(),
    ),
  );
}
