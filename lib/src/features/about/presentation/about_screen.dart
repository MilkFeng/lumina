import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// About Screen - Shows app information, tips and credits
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
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
        title: Text(l10n.about),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        children: [
          // App Icon and Name
          _buildAppHeader(context, l10n),

          const SizedBox(height: 48),

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
                icon: Icons.sync_outlined,
                tip: l10n.tipLongPressSync,
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
        Text(
          l10n.appName,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        // Version
        if (_version.isNotEmpty)
          Text(
            'v$_version',
            style: AppTheme.contentTextStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
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
              fontWeight: FontWeight.w600,
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
        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
      ),
      title: Text(
        title,
        style: AppTheme.contentTextStyle.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.contentTextStyle.copyWith(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
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
        style: AppTheme.contentTextStyle.copyWith(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
        ),
      ),
      dense: true,
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
