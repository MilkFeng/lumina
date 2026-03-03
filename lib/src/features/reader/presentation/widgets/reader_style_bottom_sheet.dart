import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/core/theme/app_theme_settings.dart';
import 'package:lumina/src/core/widgets/integer_stepper.dart';
import 'package:lumina/src/core/widgets/labeled_switch_tile.dart';
import 'package:lumina/src/core/widgets/settings_section_title.dart';
import 'package:lumina/src/core/widgets/settings_sub_label.dart';
import 'package:lumina/src/core/widgets/theme_variant_chip.dart';
import 'package:lumina/src/features/reader/domain/reader_settings.dart';
import '../../application/reader_settings_notifier.dart';
import 'reader_link_handling_selector.dart';
import 'reader_page_animation_selector.dart';
import 'reader_scale_slider.dart';

/// Bottom sheet for configuring reader typography, layout, and appearance.
class ReaderStyleBottomSheet extends ConsumerStatefulWidget {
  const ReaderStyleBottomSheet({super.key});

  @override
  ConsumerState<ReaderStyleBottomSheet> createState() =>
      _ReaderStyleBottomSheetState();
}

class _ReaderStyleBottomSheetState
    extends ConsumerState<ReaderStyleBottomSheet> {
  late double _scale;
  late int _topMargin;
  late int _bottomMargin;
  late int _leftMargin;
  late int _rightMargin;
  late bool _followAppTheme;
  late int _themeIndex;
  late ReaderLinkHandling _linkHandling;
  late bool _handleIntraLink;
  late ReaderPageAnimation _pageAnimation;

  static const int _marginMin = 0;
  static const int _marginMax = 64;
  static const int _marginStep = 2;

  @override
  void initState() {
    super.initState();
    final s = ref.read(readerSettingsNotifierProvider);
    _scale = s.zoom;
    _topMargin = s.marginTop.toInt();
    _bottomMargin = s.marginBottom.toInt();
    _leftMargin = s.marginLeft.toInt();
    _rightMargin = s.marginRight.toInt();
    _followAppTheme = s.followAppTheme;
    _themeIndex = s.themeIndex;
    _linkHandling = s.linkHandling;
    _handleIntraLink = s.handleIntraLink;
    _pageAnimation = s.pageAnimation;
  }

  @override
  void dispose() {
    super.dispose();
  }

  ReaderSettingsNotifier get _notifier =>
      ref.read(readerSettingsNotifierProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: Appearance ───────────────────────────────────────
            SettingsSectionTitle(label: l10n.readerAppearance),
            const SizedBox(height: 12),

            // Reader Theme – only shown when Follow App Theme is off.
            // Chips are split into a light-theme row and a dark-theme row, each
            // horizontally scrollable and breaking out of the 24 px side padding.
            AnimatedSize(
              duration: const Duration(
                milliseconds: AppTheme.defaultAnimationDurationMs,
              ),
              curve: Curves.easeInOut,
              child: _followAppTheme
                  ? const SizedBox(height: 0, width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Recover full width by adding back the 24 px on each side.
                          final fullWidth = constraints.maxWidth + 48;

                          final lightPresets = LuminaThemePreset.lightPresets;
                          final darkPresets = LuminaThemePreset.darkPresets;

                          // Build a plain Row of chips for the given preset list.
                          Row presetRow(List<LuminaThemePreset> presets) {
                            return Row(
                              children: presets.map((preset) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: ThemeVariantChip(
                                    colorScheme: preset.colorScheme,
                                    isSelected: _themeIndex == preset.index,
                                    onTap: () {
                                      setState(
                                        () => _themeIndex = preset.index,
                                      );
                                      _notifier.setThemeIndex(preset.index);
                                    },
                                  ),
                                );
                              }).toList(),
                            );
                          }

                          // Both rows share one ScrollView so the gap between
                          // them scrolls together with the chips.
                          return SizedBox(
                            width: fullWidth,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  presetRow(lightPresets),
                                  const SizedBox(height: 16),
                                  presetRow(darkPresets),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),

            // Follow App Theme
            LabeledSwitchTile(
              label: l10n.readerFollowAppTheme,
              value: _followAppTheme,
              onChanged: (v) {
                setState(() => _followAppTheme = v);
                _notifier.setFollowAppTheme(v);
              },
            ),

            const SizedBox(height: 24),

            // ── Section 2: Typography & Layout ─────────────────────────────
            SettingsSectionTitle(label: l10n.readerTypographyLayout),
            const SizedBox(height: 16),

            // Scale
            Row(
              children: [
                SettingsSubLabel(label: l10n.readerScale),
                const Spacer(),
                Text(
                  '${_scale.toStringAsFixed(1)}x',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ReaderScaleSlider(
              value: _scale,
              onChanged: (v) {
                setState(() => _scale = v);
                _notifier.setZoom(v);
              },
            ),

            const SizedBox(height: 20),

            // Margins
            SettingsSubLabel(label: l10n.readerMargins),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: IntegerStepper(
                    label: l10n.readerMarginTop,
                    value: _topMargin,
                    min: _marginMin,
                    max: _marginMax,
                    step: _marginStep,
                    onChanged: (v) {
                      setState(() => _topMargin = v);
                      _notifier.setMarginTop(v.toDouble());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: IntegerStepper(
                    label: l10n.readerMarginBottom,
                    value: _bottomMargin,
                    min: _marginMin,
                    max: _marginMax,
                    step: _marginStep,
                    onChanged: (v) {
                      setState(() => _bottomMargin = v);
                      _notifier.setMarginBottom(v.toDouble());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: IntegerStepper(
                    label: l10n.readerMarginLeft,
                    value: _leftMargin,
                    min: _marginMin,
                    max: _marginMax,
                    step: _marginStep,
                    onChanged: (v) {
                      setState(() => _leftMargin = v);
                      _notifier.setMarginLeft(v.toDouble());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: IntegerStepper(
                    label: l10n.readerMarginRight,
                    value: _rightMargin,
                    min: _marginMin,
                    max: _marginMax,
                    step: _marginStep,
                    onChanged: (v) {
                      setState(() => _rightMargin = v);
                      _notifier.setMarginRight(v.toDouble());
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Section 3: Links ──────────────────────────────────────────
            SettingsSectionTitle(label: l10n.readerLinkHandlingSection),
            const SizedBox(height: 12),
            ReaderLinkHandlingSelector(
              value: _linkHandling,
              onChanged: (v) {
                setState(() => _linkHandling = v);
                _notifier.setLinkHandling(v);
              },
              askLabel: l10n.readerLinkHandlingAsk,
              alwaysLabel: l10n.readerLinkHandlingAlways,
              neverLabel: l10n.readerLinkHandlingNever,
            ),
            const SizedBox(height: 12),
            LabeledSwitchTile(
              label: l10n.readerHandleIntraLink,
              value: _handleIntraLink,
              icon: Icons.link_outlined,
              onChanged: (v) {
                setState(() => _handleIntraLink = v);
                _notifier.setHandleIntraLink(v);
              },
            ),

            const SizedBox(height: 24),

            // ── Section 4: Page Animation ─────────────────────────────────
            SettingsSectionTitle(label: l10n.readerPageAnimationSection),
            const SizedBox(height: 12),
            ReaderPageAnimationSelector(
              value: _pageAnimation,
              onChanged: (v) {
                setState(() => _pageAnimation = v);
                _notifier.setPageAnimation(v);
              },
              noneLabel: l10n.readerPageAnimationNone,
              slideLabel: l10n.readerPageAnimationSlide,
            ),
          ],
        ),
      ),
    );
  }
}
