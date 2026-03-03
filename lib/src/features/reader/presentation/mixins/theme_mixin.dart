part of '../reader_screen.dart';

mixin _ThemeMixin on ConsumerState<ReaderScreen> {
  // === Borrowed state (provided by _ReaderScreenState fields) ===
  ReaderRendererController get rendererController;

  ThemeData? get currentTheme;
  set currentTheme(ThemeData? v);

  bool get updatingTheme;
  set updatingTheme(bool v);

  Timer? get themeUpdateDebouncer;
  set themeUpdateDebouncer(Timer? v);

  EpubTheme getEpubTheme() {
    final settings = ref.read(readerSettingsNotifierProvider);
    return settings.toEpubTheme(context);
  }

  void updateWebViewThemeWithDebounce() {
    themeUpdateDebouncer?.cancel();
    themeUpdateDebouncer = Timer(const Duration(milliseconds: 50), () {
      updateWebViewTheme();
    });
  }

  Future<void> updateWebViewTheme() async {
    final newTheme = getEpubTheme();
    final currentTheme = rendererController.currentTheme;
    if (currentTheme != null && currentTheme == newTheme) {
      return;
    }

    setState(() {
      updatingTheme = true;
    });

    await rendererController.updateTheme(getEpubTheme());

    setState(() {
      updatingTheme = false;
    });
  }
}
