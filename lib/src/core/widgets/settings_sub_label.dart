import 'package:flutter/material.dart';

/// A secondary label used beneath a section title to describe a sub-group of
/// controls (e.g. "Scale", "Margins").
///
/// Renders [label] in the theme's `onSurfaceVariant` colour at 13 sp.
class SettingsSubLabel extends StatelessWidget {
  const SettingsSubLabel({super.key, required this.label});

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
