import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/reader/domain/reader_settings.dart';
import '../../application/reader_settings_notifier.dart';

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
  late bool _followSystemTheme;
  late ReaderSettingThemeMode _themeMode;

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
    _followSystemTheme = s.followSystemTheme;
    _themeMode = s.themeMode;
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
            _SectionTitle(label: l10n.readerAppearance),
            const SizedBox(height: 12),

            // Reader Theme – only shown when Follow System is off
            AnimatedSize(
              duration: const Duration(
                milliseconds: AppTheme.defaultAnimationDurationMs,
              ),
              curve: Curves.easeInOut,
              child: _followSystemTheme
                  ? const SizedBox(height: 0, width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            _ThemeOptionChip(
                              colorScheme: AppTheme.colorSchemeForBrightness(
                                Brightness.light,
                              ),
                              isSelected:
                                  _themeMode == ReaderSettingThemeMode.light,
                              onTap: () {
                                setState(
                                  () =>
                                      _themeMode = ReaderSettingThemeMode.light,
                                );
                                _notifier.setThemeMode(
                                  ReaderSettingThemeMode.light,
                                );
                              },
                            ),
                            _ThemeOptionChip(
                              colorScheme: AppTheme.colorSchemeForBrightness(
                                Brightness.dark,
                              ),
                              isSelected:
                                  _themeMode == ReaderSettingThemeMode.dark,
                              onTap: () {
                                setState(
                                  () =>
                                      _themeMode = ReaderSettingThemeMode.dark,
                                );
                                _notifier.setThemeMode(
                                  ReaderSettingThemeMode.dark,
                                );
                              },
                            ),
                            _ThemeOptionChip(
                              colorScheme: AppTheme.eyeCareColorScheme,
                              isSelected:
                                  _themeMode == ReaderSettingThemeMode.eyeCare,
                              onTap: () {
                                setState(
                                  () => _themeMode =
                                      ReaderSettingThemeMode.eyeCare,
                                );
                                _notifier.setThemeMode(
                                  ReaderSettingThemeMode.eyeCare,
                                );
                              },
                            ),
                            _ThemeOptionChip(
                              colorScheme: AppTheme.darkEyeCareColorScheme,
                              isSelected:
                                  _themeMode ==
                                  ReaderSettingThemeMode.darkEyeCare,
                              onTap: () {
                                setState(
                                  () => _themeMode =
                                      ReaderSettingThemeMode.darkEyeCare,
                                );
                                _notifier.setThemeMode(
                                  ReaderSettingThemeMode.darkEyeCare,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Follow System Theme
            _FollowSystemSwitch(
              label: l10n.readerFollowSystemTheme,
              value: _followSystemTheme,
              onChanged: (v) {
                setState(() => _followSystemTheme = v);
                _notifier.setFollowSystemTheme(v);
              },
            ),

            const SizedBox(height: 24),

            // ── Section 2: Typography & Layout ─────────────────────────────
            _SectionTitle(label: l10n.readerTypographyLayout),
            const SizedBox(height: 16),

            // Scale
            _SubLabel(label: l10n.readerScale),
            const SizedBox(height: 4),
            _ScaleSlider(
              value: _scale,
              onChanged: (v) {
                setState(() => _scale = v);
                _notifier.setZoom(v);
              },
            ),

            const SizedBox(height: 20),

            // Margins
            _SubLabel(label: l10n.readerMargins),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MarginStepper(
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
                  child: _MarginStepper(
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
                  child: _MarginStepper(
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
                  child: _MarginStepper(
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
          ],
        ),
      ),
    );
  }
}

// ── Private helper widgets ─────────────────────────────────────────────────────

/// Grey section-title label.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Smaller sub-label used within a section (e.g. "Scale", "Margins").
class _SubLabel extends StatelessWidget {
  const _SubLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Scale slider with a small "A" on the left and a large "A" on the right.
class _ScaleSlider extends StatelessWidget {
  const _ScaleSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Text('A', style: TextStyle(fontSize: 12, color: color)),
        Expanded(
          child: Slider(
            value: value,
            min: 0.5,
            max: 2.5,
            divisions: 20,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
        ),
        Text('A', style: TextStyle(fontSize: 22, color: color)),
      ],
    );
  }
}

/// Compact stepper used for each margin value.
class _MarginStepper extends StatelessWidget {
  const _MarginStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: value > min ? () => onChanged(value - step) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                visualDensity: VisualDensity.compact,
                color: colorScheme.primary,
                disabledColor: colorScheme.onSurfaceVariant,
              ),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: value < max ? () => onChanged(value + step) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                visualDensity: VisualDensity.compact,
                color: colorScheme.primary,
                disabledColor: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Row-style toggle for "Follow System Theme" with a Switch on the right.
class _FollowSystemSwitch extends StatelessWidget {
  const _FollowSystemSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.brightness_auto_outlined,
            size: 18,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ThemeOptionChip extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionChip({
    required this.colorScheme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          isSelected ? Icons.check : Icons.text_format_outlined,
          size: 32,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
