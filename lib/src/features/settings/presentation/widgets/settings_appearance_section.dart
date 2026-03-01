import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/theme/app_theme_notifier.dart';
import 'package:lumina/src/core/theme/app_theme_settings.dart';
import 'package:lumina/src/features/settings/presentation/widgets/settings_info_section.dart';
import 'package:lumina/src/features/settings/presentation/widgets/settings_theme_chips.dart';
import '../../../../../l10n/app_localizations.dart';

/// Renders the Appearance card on the Settings screen, containing the theme-mode
/// selector and the active-brightness variant picker.
class SettingsAppearanceSection extends ConsumerWidget {
  const SettingsAppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(appThemeNotifierProvider);
    final notifier = ref.read(appThemeNotifierProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final effectiveBrightness = switch (settings.themeMode) {
      AppThemeMode.light => Brightness.light,
      AppThemeMode.dark => Brightness.dark,
      AppThemeMode.system => systemBrightness,
    };

    return SettingsInfoSection(
      title: l10n.appAppearance,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme mode selector
              Text(
                l10n.appThemeMode,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  AppThemeModeChip(
                    icon: Icons.brightness_auto_outlined,
                    label: l10n.appThemeModeSystem,
                    isSelected: settings.themeMode == AppThemeMode.system,
                    onTap: () => notifier.setThemeMode(AppThemeMode.system),
                  ),
                  const SizedBox(width: 8),
                  AppThemeModeChip(
                    icon: Icons.light_mode_outlined,
                    label: l10n.appThemeModeLight,
                    isSelected: settings.themeMode == AppThemeMode.light,
                    onTap: () => notifier.setThemeMode(AppThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  AppThemeModeChip(
                    icon: Icons.dark_mode_outlined,
                    label: l10n.appThemeModeDark,
                    isSelected: settings.themeMode == AppThemeMode.dark,
                    onTap: () => notifier.setThemeMode(AppThemeMode.dark),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                l10n.appThemeVariant,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),

              // Variant picker
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                // Dynamically build a chip for every AppThemeVariant.
                child: Row(
                  children: AppThemeVariant.values.map((variant) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: AppThemeVariantChip(
                        colorScheme: AppThemeSettings.colorSchemeFor(
                          variant,
                          effectiveBrightness,
                        ),
                        isSelected: settings.themeVariant == variant,
                        onTap: () => notifier.setThemeVariant(variant),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
