import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/fonts/application/font_manager_notifier.dart';
import 'package:lumina/src/features/fonts/domain/imported_font.dart';

/// Screen for managing user-imported fonts (.ttf / .otf).
class FontManagementScreen extends ConsumerWidget {
  const FontManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fonts = ref.watch(fontManagerNotifierProvider);
    final notifier = ref.read(fontManagerNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fontManagement),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.importFont,
        onPressed: () => _importFont(context, notifier, l10n),
        child: const Icon(Icons.add),
      ),
      body: fonts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.noFontsHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: fonts.length,
              itemBuilder: (context, index) {
                final font = fonts[index];
                return _FontTile(
                  font: font,
                  onDelete: () => _deleteFont(context, notifier, font, l10n),
                );
              },
            ),
    );
  }

  Future<void> _importFont(
    BuildContext context,
    FontManagerNotifier notifier,
    AppLocalizations l10n,
  ) async {
    try {
      final font = await notifier.importFont();
      if (font == null) return;
      ToastService.showSuccess(l10n.importFontSuccess(font.displayName));
    } catch (e) {
      ToastService.showError(l10n.importFontFailed(e.toString()));
    }
  }

  Future<void> _deleteFont(
    BuildContext context,
    FontManagerNotifier notifier,
    ImportedFont font,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteFontConfirm(font.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.deleteFont(font);
    }
  }
}

class _FontTile extends StatelessWidget {
  const _FontTile({required this.font, required this.onDelete});

  final ImportedFont font;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.font_download_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(font.displayName),
      subtitle: Text(
        font.fileName,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        color: Theme.of(context).colorScheme.error,
        tooltip: null,
        onPressed: onDelete,
      ),
    );
  }
}
