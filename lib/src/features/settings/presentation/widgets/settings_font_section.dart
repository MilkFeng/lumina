import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/settings/application/font_manager_notifier.dart';
import 'package:lumina/src/features/settings/domain/imported_font.dart';
import 'settings_info_section.dart';

/// Inline font management section embedded directly in the Settings screen.
///
/// Lists all imported custom fonts with delete actions, and provides an
/// "Import Font" action. No separate navigation screen is required.
class SettingsFontSection extends ConsumerWidget {
  const SettingsFontSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fonts = ref.watch(fontManagerNotifierProvider);
    final notifier = ref.read(fontManagerNotifierProvider.notifier);

    return SettingsInfoSection(
      title: l10n.fontManagement,
      children: [
        if (fonts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              l10n.noFontsHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...fonts.map(
            (font) => ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 0,
              ),
              leading: Icon(
                Icons.font_download_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              title: Text(font.displayName),
              subtitle: Text(
                font.fileName,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Theme.of(context).colorScheme.error,
                tooltip: l10n.delete,
                onPressed: () => _confirmDelete(context, notifier, font, l10n),
              ),
            ),
          ),

        // Import action
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 0,
          ),
          leading: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          title: Text(l10n.importFont),
          subtitle: Text(
            l10n.fontManagementSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          onTap: () => _importFont(context, notifier, l10n),
        ),
      ],
    );
  }

  Future<void> _importFont(
    BuildContext context,
    FontManagerNotifier notifier,
    AppLocalizations l10n,
  ) async {
    try {
      final fonts = await notifier.importFonts();
      if (fonts.isEmpty) return;
      if (fonts.length == 1) {
        ToastService.showSuccess(
          l10n.importFontSuccess(fonts.first.displayName),
        );
      } else {
        ToastService.showSuccess(l10n.importFontsSuccess(fonts.length));
      }
    } catch (e) {
      ToastService.showError(l10n.importFontFailed(e.toString()));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FontManagerNotifier notifier,
    ImportedFont font,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteFontConfirm),
        content: Text(l10n.deleteFontConfirmText(font.displayName)),
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
