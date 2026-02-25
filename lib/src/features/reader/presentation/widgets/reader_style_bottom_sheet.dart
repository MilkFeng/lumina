import 'package:flutter/material.dart';
import 'package:lumina/l10n/app_localizations.dart';

/// Enum representing the reader's color theme when not following the system.
enum ReaderThemeMode { light, dark }

/// Bottom sheet for configuring reader typography, layout, and appearance.
class ReaderStyleBottomSheet extends StatefulWidget {
  // ── Initial values ──────────────────────────────────────────────────────────
  final double initialScale;
  final int initialTopMargin;
  final int initialBottomMargin;
  final int initialLeftMargin;
  final int initialRightMargin;
  final bool initialFollowSystemTheme;
  final ReaderThemeMode initialReaderTheme;

  // ── Callbacks ───────────────────────────────────────────────────────────────
  final ValueChanged<double> onScaleChanged;
  final ValueChanged<int> onTopMarginChanged;
  final ValueChanged<int> onBottomMarginChanged;
  final ValueChanged<int> onLeftMarginChanged;
  final ValueChanged<int> onRightMarginChanged;
  final ValueChanged<bool> onFollowSystemThemeChanged;
  final ValueChanged<ReaderThemeMode> onReaderThemeChanged;

  const ReaderStyleBottomSheet({
    super.key,
    this.initialScale = 1.0,
    this.initialTopMargin = 0,
    this.initialBottomMargin = 0,
    this.initialLeftMargin = 0,
    this.initialRightMargin = 0,
    this.initialFollowSystemTheme = true,
    this.initialReaderTheme = ReaderThemeMode.light,
    required this.onScaleChanged,
    required this.onTopMarginChanged,
    required this.onBottomMarginChanged,
    required this.onLeftMarginChanged,
    required this.onRightMarginChanged,
    required this.onFollowSystemThemeChanged,
    required this.onReaderThemeChanged,
  });

  @override
  State<ReaderStyleBottomSheet> createState() => _ReaderStyleBottomSheetState();
}

class _ReaderStyleBottomSheetState extends State<ReaderStyleBottomSheet> {
  late double _scale;
  late int _topMargin;
  late int _bottomMargin;
  late int _leftMargin;
  late int _rightMargin;
  late bool _followSystemTheme;
  late ReaderThemeMode _readerTheme;

  static const int _marginMin = 0;
  static const int _marginMax = 64;
  static const int _marginStep = 2;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
    _topMargin = widget.initialTopMargin;
    _bottomMargin = widget.initialBottomMargin;
    _leftMargin = widget.initialLeftMargin;
    _rightMargin = widget.initialRightMargin;
    _followSystemTheme = widget.initialFollowSystemTheme;
    _readerTheme = widget.initialReaderTheme;
  }

  void _handleValueChanged<T>(
    T newValue,
    ValueChanged<T> callback,
    bool Function(T) checker,
  ) {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (checker(newValue)) {
        callback(newValue);
      }
    });
  }

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
            // ── Section 1: Typography & Layout ─────────────────────────────
            _SectionTitle(label: l10n.readerTypographyLayout),
            const SizedBox(height: 16),

            // Scale
            _SubLabel(label: l10n.readerScale),
            const SizedBox(height: 4),
            _ScaleSlider(
              value: _scale,
              onChanged: (v) {
                setState(() => _scale = v);
                _handleValueChanged<double>(
                  v,
                  widget.onScaleChanged,
                  (val) => val == _scale,
                );
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
                      _handleValueChanged<int>(
                        v,
                        widget.onTopMarginChanged,
                        (val) => val == _topMargin,
                      );
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
                      _handleValueChanged<int>(
                        v,
                        widget.onBottomMarginChanged,
                        (val) => val == _bottomMargin,
                      );
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
                      _handleValueChanged<int>(
                        v,
                        widget.onLeftMarginChanged,
                        (val) => val == _leftMargin,
                      );
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
                      _handleValueChanged<int>(
                        v,
                        widget.onRightMarginChanged,
                        (val) => val == _rightMargin,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Section 2: Appearance ───────────────────────────────────────
            _SectionTitle(label: l10n.readerAppearance),
            const SizedBox(height: 12),

            // Follow System Theme
            _FollowSystemSwitch(
              label: l10n.readerFollowSystemTheme,
              value: _followSystemTheme,
              onChanged: (v) {
                setState(() => _followSystemTheme = v);
                widget.onFollowSystemThemeChanged(v);
              },
            ),

            // Reader Theme – only shown when Follow System is off
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: _followSystemTheme
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _OptionChip(
                            icon: Icons.light_mode_outlined,
                            label: l10n.readerThemeLight,
                            isSelected: _readerTheme == ReaderThemeMode.light,
                            onTap: () {
                              setState(
                                () => _readerTheme = ReaderThemeMode.light,
                              );
                              widget.onReaderThemeChanged(
                                ReaderThemeMode.light,
                              );
                            },
                          ),
                          _OptionChip(
                            icon: Icons.dark_mode_outlined,
                            label: l10n.readerThemeDark,
                            isSelected: _readerTheme == ReaderThemeMode.dark,
                            onTap: () {
                              setState(
                                () => _readerTheme = ReaderThemeMode.dark,
                              );
                              widget.onReaderThemeChanged(ReaderThemeMode.dark);
                            },
                          ),
                        ],
                      ),
                    ),
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
        fontWeight: FontWeight.w500,
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
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.7);
    return Row(
      children: [
        Text(
          'A',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
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
        Text(
          'A',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
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
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
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
                disabledColor: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: value < max ? () => onChanged(value + step) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                visualDensity: VisualDensity.compact,
                color: colorScheme.primary,
                disabledColor: colorScheme.onSurface.withValues(alpha: 0.3),
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

/// Custom rounded-rectangle chip (mirrors StyleBottomSheet's _OptionChip).
class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.mirrorIcon = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Horizontally mirrors the icon (reserved for future use).
  final bool mirrorIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = isSelected
        ? colorScheme.primaryContainer.withValues(alpha: 0.15)
        : colorScheme.surfaceContainerHighest;

    final borderColor = isSelected
        ? colorScheme.primary.withValues(alpha: 0.5)
        : colorScheme.secondary.withValues(alpha: 0.3);

    final contentColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Transform.scale(
                scaleX: mirrorIcon ? -1 : 1,
                child: Icon(icon, size: 18, color: contentColor),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: contentColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
