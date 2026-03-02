import 'package:flutter/material.dart';

/// A primary section heading used in settings and configuration screens.
///
/// Renders [label] in the theme's primary colour at 14 sp.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle({super.key, required this.label});

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
