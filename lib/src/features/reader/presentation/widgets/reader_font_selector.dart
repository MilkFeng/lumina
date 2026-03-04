import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/widgets/labeled_switch_tile.dart';
import 'package:lumina/src/core/widgets/settings_sub_label.dart';
import 'package:lumina/src/features/settings/application/font_manager_notifier.dart';

/// Subsection widget for picking a custom font in the reader style sheet.
///
/// Displayed as a subsection inside "Typography & Layout". Navigation to font
/// management is intentionally omitted here — users must visit
/// Settings → Font Management to import or remove fonts.
class ReaderFontSelector extends ConsumerWidget {
  const ReaderFontSelector({
    super.key,
    required this.fontFileName,
    required this.overrideFontFamily,
    required this.onFontChanged,
    required this.onOverrideChanged,
  });

  final String? fontFileName;
  final bool overrideFontFamily;
  final ValueChanged<String?> onFontChanged;
  final ValueChanged<bool> onOverrideChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fonts = ref.watch(fontManagerNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSubLabel(label: l10n.readerFontSection),
        const SizedBox(height: 8),

        if (fonts.isNotEmpty) ...[
          // Font picker chip list
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // "Book Default" chip
              ChoiceChip(
                label: Text(l10n.readerFontDefault),
                selected: fontFileName == null,
                onSelected: (_) => onFontChanged(null),
              ),
              ...fonts.map(
                (f) => ChoiceChip(
                  label: Text(f.displayName),
                  selected: fontFileName == f.fileName,
                  onSelected: (_) => onFontChanged(f.fileName),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (fontFileName != null)
            LabeledSwitchTile(
              label: l10n.readerOverrideFontFamily,
              icon: Icons.font_download_outlined,
              value: overrideFontFamily,
              onChanged: onOverrideChanged,
            ),

          const SizedBox(height: 8),
        ],

        // Tip: direct users to Settings for font management.
        Text(
          l10n.readerFontManageTip,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
