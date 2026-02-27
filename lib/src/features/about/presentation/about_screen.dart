import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/library/data/services/export_backup_service.dart';
import 'package:lumina/src/features/library/data/services/export_backup_service_provider.dart';
import 'package:lumina/src/features/library/data/services/storage_cleanup_service_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// About Screen - Shows app information, tips and credits
class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  String _version = '';
  bool _isCleaning = false;
  bool _isExporting = false;
  final _exportTileKey = GlobalKey();

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
        title: Text(l10n.about),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        children: [
          // App Icon and Name
          _buildAppHeader(context, l10n),

          const SizedBox(height: 48),

          // Library Section
          _buildInfoSection(
            context,
            title: l10n.library,
            children: [_buildBackupTile(context, l10n)],
          ),

          const SizedBox(height: 24),

          // Storage Section
          _buildInfoSection(
            context,
            title: l10n.storage,
            children: [
              _buildCleanCacheTile(context, l10n),
              _buildInfoTile(
                context,
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

          // Project Info Section
          _buildInfoSection(
            context,
            title: l10n.projectInfo,
            children: [
              _buildInfoTile(
                context,
                icon: Icons.code_outlined,
                title: l10n.github,
                subtitle: 'github.com/MilkFeng/lumina.git',
                onTap: () =>
                    _launchUrl('https://github.com/MilkFeng/lumina.git'),
              ),
              _buildInfoTile(
                context,
                icon: Icons.person_outline_outlined,
                title: l10n.author,
                subtitle: 'Milk Feng',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Tips Section
          _buildInfoSection(
            context,
            title: l10n.tips,
            children: [
              _buildTipTile(
                context,
                icon: Icons.touch_app_outlined,
                tip: l10n.tipLongPressTab,
              ),
              _buildTipTile(
                context,
                icon: Icons.keyboard_double_arrow_right_outlined,
                tip: l10n.tipLongPressNextTrack,
              ),
              _buildTipTile(
                context,
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

  Widget _buildAppHeader(BuildContext context, AppLocalizations l10n) {
    const appSvgPath = 'assets/icons/icon.svg';
    const logoSvgPath = 'assets/logos/logo.svg';

    return Column(
      children: [
        // App Icon
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SvgPicture.asset(appSvgPath, width: 56, height: 56),
        ),

        const SizedBox(height: 16),

        // App Name
        SvgPicture.asset(
          logoSvgPath,
          height: 20,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurface,
            BlendMode.srcIn,
          ),
        ),

        const SizedBox(height: 8),

        // Version
        if (_version.isNotEmpty)
          Text(
            'v$_version',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildTipTile(
    BuildContext context, {
    required IconData icon,
    required String tip,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary.withAlpha(153),
        size: 20,
      ),
      title: Text(
        tip,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      dense: true,
    );
  }

  Widget _buildCleanCacheTile(BuildContext context, AppLocalizations l10n) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(
        Icons.cleaning_services_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(l10n.cleanCache),
      subtitle: Text(
        l10n.cleanCacheSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: _isCleaning
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _isCleaning ? null : () => _cleanCache(context, l10n),
    );
  }

  Widget _buildBackupTile(BuildContext context, AppLocalizations l10n) {
    return ListTile(
      key: _exportTileKey,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(
        Icons.archive_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(l10n.backupLibrary),
      subtitle: Text(
        l10n.backupLibraryDescription,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: _isExporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _isExporting ? null : () => _handleExportBackup(context, ref),
    );
  }

  Future<void> _cleanCache(BuildContext context, AppLocalizations l10n) async {
    setState(() => _isCleaning = true);

    final service = ref.read(storageCleanupServiceProvider);
    await service.cleanCacheFiles();
    final deletedCount = await service.cleanOrphanFiles();
    await service.cleanShareFiles();

    await Future.delayed(const Duration(milliseconds: 200)); // For better UX

    setState(() => _isCleaning = false);

    if (!context.mounted) return;

    final message = deletedCount == 0
        ? l10n.cleanCacheSuccess
        : l10n.cleanCacheSuccessWithCount(deletedCount);

    ToastService.showSuccess(message);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Triggers a full library backup export.
  ///
  /// Shows a non-dismissible loading dialog while the export runs, then
  /// presents feedback via a [SnackBar]:
  ///   - Android success → folder path in Downloads
  ///   - iOS / other success → Share Sheet was presented by the service
  ///   - Failure → error message in red
  /// Returns the screen-space [Rect] of the export tile, used as the
  /// `sharePositionOrigin` anchor for the iOS Share Sheet popover.
  Rect? _exportTileRect() {
    final box = _exportTileKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  Future<void> _handleExportBackup(BuildContext context, WidgetRef ref) async {
    if (_isExporting) return; // Prevent multiple taps
    setState(() => _isExporting = true);

    final result = await ref
        .read(exportBackupServiceProvider)
        .exportLibraryAsFolder(sharePositionOrigin: _exportTileRect());

    // Guard against widget being unmounted while awaiting.
    if (!context.mounted) {
      _isExporting = false;
      return;
    }

    switch (result) {
      case ExportSuccess(:final path):
        final message = (Platform.isAndroid && path != null)
            ? AppLocalizations.of(context)!.backupSavedToDownloads(path)
            : AppLocalizations.of(context)!.backupShared;
        ToastService.showSuccess(message);
      case ExportFailure(:final message):
        ToastService.showError(
          AppLocalizations.of(context)!.exportFailed(message),
        );
    }

    setState(() => _isExporting = false);
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
