part of '../reader_screen.dart';

mixin _LinkHandlingMixin on ConsumerState<ReaderScreen> {
  // === Borrowed state (provided by _ReaderScreenState fields) ===
  BookSession get bookSession;

  // === Cross-mixin: _SpineNavigationMixin ===
  Future<void> loadCarousel([String anchor = 'top', int? overrideSpineIndex]);

  // === Cross-mixin: _ThemeMixin ===
  EpubTheme getEpubTheme();

  bool shouldHandleLinkTap(String url) {
    final settings = ref.read(readerSettingsNotifierProvider);
    if (url.startsWith('epub://')) {
      if (!settings.handleIntraLink) return false;
      final index = bookSession.findSpineIndexByUrl(url);
      return index != null;
    } else {
      return settings.linkHandling != ReaderLinkHandling.never;
    }
  }

  Future<void> handleLinkTap(String url) async {
    if (url.startsWith('epub://')) {
      final index = bookSession.findSpineIndexByUrl(url);
      if (index != null) {
        String anchor = 'top';
        if (url.contains('#')) {
          anchor = url.split('#').last;
        }
        await loadCarousel(anchor, index);
      }
    } else {
      final linkHandling = ref
          .read(readerSettingsNotifierProvider)
          .linkHandling;

      final uri = Uri.tryParse(url);

      if (uri != null && await canLaunchUrl(uri)) {
        if (linkHandling == ReaderLinkHandling.always) {
          await launchUrl(uri);
        } else if (linkHandling == ReaderLinkHandling.ask) {
          if (mounted && context.mounted) {
            final themeData = getEpubTheme().themeData;
            final shouldOpen =
                await showDialog<bool>(
                  context: context,
                  builder: (context) => Theme(
                    data: themeData,
                    child: AlertDialog(
                      title: Text(
                        AppLocalizations.of(context)!.openExternalLink,
                      ),
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!.openExternalLinkConfirmation(url),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(AppLocalizations.of(context)!.open),
                        ),
                      ],
                    ),
                  ),
                ) ??
                false;

            if (shouldOpen) {
              await launchUrl(uri);
            }
          }
        }
        // ReaderLinkHandling.never: do nothing
      } else {
        if (mounted && context.mounted) {
          ToastService.showError(
            AppLocalizations.of(context)!.cannotOpenLink(url),
            theme: getEpubTheme().themeData,
          );
        }
      }
    }
  }
}
