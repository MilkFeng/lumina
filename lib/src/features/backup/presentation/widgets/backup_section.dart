import 'package:flutter/material.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/widgets/settings_section.dart';
import 'package:lumina/src/features/backup/presentation/widgets/backup_tile.dart';
import 'package:lumina/src/features/backup/presentation/widgets/restore_tile.dart';

/// The "Library" card of the settings screen: export the current library to a
/// backup folder, or replace it with a previously exported one.
///
/// Backing up is the backup feature's own concern, so this section ships with
/// the feature and the settings screen only embeds it.
class BackupSection extends StatelessWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SettingsInfoSection(
      title: l10n.library,
      children: const [BackupTile(), RestoreTile()],
    );
  }
}
