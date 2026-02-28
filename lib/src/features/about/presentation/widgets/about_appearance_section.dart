import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/core/theme/app_theme_notifier.dart';
import 'package:lumina/src/core/theme/app_theme_settings.dart';
import 'package:lumina/src/features/about/presentation/widgets/about_info_section.dart';
import 'package:lumina/src/features/about/presentation/widgets/about_theme_chips.dart';
import '../../../../../l10n/app_localizations.dart';

/// Renders the Appearance card on the About screen, containing the theme-mode
/// selector and the active-brightness variant picker.
class AboutAppearanceSection extends ConsumerWidget {
  const AboutAppearanceSection({super.key});

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
    final isEffectivelyDark = effectiveBrightness == Brightness.dark;

    return AboutInfoSection(
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

              // Variant picker — only shows options for the active brightness
              if (!isEffectivelyDark) ...[
                Text(
                  l10n.appLightTheme,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    AppThemeVariantChip(
                      colorScheme: AppTheme.lightColorScheme,
                      isSelected:
                          settings.lightVariant ==
                          AppLightThemeVariant.standard,
                      onTap: () => notifier.setLightVariant(
                        AppLightThemeVariant.standard,
                      ),
                    ),
                    AppThemeVariantChip(
                      colorScheme: AppTheme.eyeCareColorScheme,
                      isSelected:
                          settings.lightVariant == AppLightThemeVariant.eyeCare,
                      onTap: () => notifier.setLightVariant(
                        AppLightThemeVariant.eyeCare,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  l10n.appDarkTheme,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    AppThemeVariantChip(
                      colorScheme: AppTheme.darkColorScheme,
                      isSelected:
                          settings.darkVariant == AppDarkThemeVariant.standard,
                      onTap: () =>
                          notifier.setDarkVariant(AppDarkThemeVariant.standard),
                    ),
                    AppThemeVariantChip(
                      colorScheme: AppTheme.darkEyeCareColorScheme,
                      isSelected:
                          settings.darkVariant == AppDarkThemeVariant.eyeCare,
                      onTap: () =>
                          notifier.setDarkVariant(AppDarkThemeVariant.eyeCare),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
