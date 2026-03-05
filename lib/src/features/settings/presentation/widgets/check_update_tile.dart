import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/settings/presentation/widgets/settings_info_section.dart';
import 'package:lumina/src/features/settings/presentation/widgets/simple_markdown.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _versionUrl = 'https://lumina.milkfeng.top/version';

/// Settings tile that checks for application updates from the remote server.
class CheckUpdateTile extends StatefulWidget {
  const CheckUpdateTile({super.key});

  @override
  State<CheckUpdateTile> createState() => _CheckUpdateTileState();
}

class _CheckUpdateTileState extends State<CheckUpdateTile> {
  bool _isChecking = false;

  Future<void> _checkForUpdates() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final l10n = AppLocalizations.of(context)!;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final localVersionStr = packageInfo.version; // e.g. "0.2.2"
      final localBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // Split APKs (arm64, armeabi-v7a, x86_64) have an architecture offset
      // added to the base build number (e.g. 1001, 1002, 1003 for build 1).
      // Normalise by taking the remainder of 1000.
      final normalizedBuildNumber = localBuildNumber % 1000;

      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 10);
      final request = await httpClient.getUrl(Uri.parse(_versionUrl));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      httpClient.close();

      final jsonMap = jsonDecode(body) as Map<String, dynamic>;
      if (jsonMap['code'] != 200) {
        throw Exception('Server returned code ${jsonMap['code']}');
      }

      final data = jsonMap['data'] as Map<String, dynamic>;
      final remoteMajor = (data['majorNumber'] as num).toInt();
      final remoteMinor = (data['minorNumber'] as num).toInt();
      final remotePatch = (data['patchNumber'] as num).toInt();
      final remoteBuild = (data['buildNumber'] as num).toInt();
      final updateLog = data['updateLog'] as String? ?? '';
      final lanzouUrl = data['lanzouUrl'] as String? ?? '';
      final lanzouPassword = data['lanzouPassword'] as String? ?? '';
      final githubUrl = data['githubUrl'] as String? ?? '';

      final remoteVersionStr = '$remoteMajor.$remoteMinor.$remotePatch';

      // Parse local version string
      final localParts = localVersionStr
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final localMajor = localParts.isNotEmpty ? localParts[0] : 0;
      final localMinor = localParts.length > 1 ? localParts[1] : 0;
      final localPatch = localParts.length > 2 ? localParts[2] : 0;

      final isNewer = _isNewerVersion(
        remoteMajor,
        remoteMinor,
        remotePatch,
        remoteBuild,
        localMajor,
        localMinor,
        localPatch,
        normalizedBuildNumber,
      );

      if (!mounted) return;

      if (!isNewer) {
        ToastService.showSuccess(l10n.upToDate);
        return;
      }

      await showDialog(
        context: context,
        builder: (context) => _UpdateDialog(
          remoteVersion: 'v$remoteVersionStr+$remoteBuild',
          updateLog: updateLog,
          lanzouUrl: lanzouUrl,
          lanzouPassword: lanzouPassword,
          githubUrl: githubUrl,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final l10n2 = AppLocalizations.of(context)!;
      ToastService.showError(l10n2.updateCheckFailed);
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  bool _isNewerVersion(
    int rMaj,
    int rMin,
    int rPat,
    int rBuild,
    int lMaj,
    int lMin,
    int lPat,
    int lBuild,
  ) {
    if (rMaj != lMaj) return rMaj > lMaj;
    if (rMin != lMin) return rMin > lMin;
    if (rPat != lPat) return rPat > lPat;
    return rBuild > lBuild;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SettingsInfoTile(
      icon: Icons.system_update_outlined,
      title: l10n.checkForUpdates,
      subtitle: l10n.checkForUpdatesSubtitle,
      trailing: _isChecking
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _isChecking ? null : _checkForUpdates,
    );
  }
}

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog({
    required this.remoteVersion,
    required this.updateLog,
    required this.lanzouUrl,
    required this.lanzouPassword,
    required this.githubUrl,
  });

  final String remoteVersion;
  final String updateLog;
  final String lanzouUrl;
  final String lanzouPassword;
  final String githubUrl;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openLanzou(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (lanzouPassword.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: lanzouPassword));
      ToastService.showSuccess(l10n.passwordCopied);
    }
    await _launchUrl(lanzouUrl);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.newVersionAvailable),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                remoteVersion,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SimpleMarkdown(text: updateLog),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _openLanzou(context);
          },
          child: Text(l10n.updateViaChinaCloud),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _launchUrl(githubUrl);
          },
          child: Text(l10n.updateViaGithub),
        ),
      ],
    );
  }
}
