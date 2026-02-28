import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/about/presentation/widgets/about_app_header.dart';
import 'package:lumina/src/features/about/presentation/widgets/about_appearance_section.dart';
import 'package:lumina/src/features/about/presentation/widgets/about_info_section.dart';
import 'package:lumina/src/features/about/presentation/widgets/backup_tile.dart';
import 'package:lumina/src/features/about/presentation/widgets/clean_cache_tile.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';

/// About Screen - Shows app information, tips and credits
class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        children: [
          AboutAppHeader(version: _version),

          const SizedBox(height: 48),

          const AboutAppearanceSection(),

          const SizedBox(height: 24),

          // Library section
          AboutInfoSection(title: l10n.library, children: const [BackupTile()]),

          const SizedBox(height: 24),

          // Storage section
          AboutInfoSection(
            title: l10n.storage,
            children: [
              const CleanCacheTile(),
              AboutInfoTile(
                icon: Icons.folder_open_outlined,
                title: l10n.openStorageLocation,
                subtitle: l10n.openStorageLocationSubtitle,
                onTap: () => Platform.isAndroid
                    ? _openAndroidFolder(l10n)
                    : _openIOSFolder(l10n),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Project info section
          AboutInfoSection(
            title: l10n.projectInfo,
            children: [
              AboutInfoTile(
                icon: Icons.code_outlined,
                title: l10n.github,
                subtitle: 'github.com/MilkFeng/lumina.git',
                onTap: () =>
                    _launchUrl('https://github.com/MilkFeng/lumina.git'),
              ),
              AboutInfoTile(
                icon: Icons.person_outline_outlined,
                title: l10n.author,
                subtitle: 'Milk Feng',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Tips section
          AboutInfoSection(
            title: l10n.tips,
            children: [
              AboutTipTile(
                icon: Icons.touch_app_outlined,
                tip: l10n.tipLongPressTab,
              ),
              AboutTipTile(
                icon: Icons.keyboard_double_arrow_right_outlined,
                tip: l10n.tipLongPressNextTrack,
              ),
              AboutTipTile(
                icon: Icons.image_outlined,
                tip: l10n.longPressToViewImage,
              ),
            ],
          ),

          const SizedBox(height: 128),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAndroidFolder(AppLocalizations l10n) async {
    if (!Platform.isAndroid) {
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final String applicationId = packageInfo.packageName;
    final String authority = '$applicationId.documents';
    const String rootId = 'lumina_books_root';
    final String rootUri = 'content://$authority/root/$rootId';

    final intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      data: rootUri,
      type: 'vnd.android.document/root',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );

    try {
      await intent.launch();
    } catch (e) {
      ToastService.showError(l10n.openStorageLocationFailed(e.toString()));
    }
  }

  Future<void> _openIOSFolder(AppLocalizations l10n) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.openStorageLocation),
        content: Text(l10n.openStorageLocationIOSMessage),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}
