import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/toast_service.dart';
import '../application/sync_notifier.dart';
import '../domain/sync_config.dart';
import 'dart:async';
import '../../../../l10n/app_localizations.dart';

/// WebDAV Sync Settings Screen
class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remoteFolderController = TextEditingController(text: 'LuminaReader/');

  bool _obscurePassword = true;
  bool _isTestingConnection = false;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    // Add listeners for auto-save
    _serverUrlController.addListener(_scheduleAutoSave);
    _usernameController.addListener(_scheduleAutoSave);
    _passwordController.addListener(_scheduleAutoSave);
    _remoteFolderController.addListener(_scheduleAutoSave);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _remoteFolderController.dispose();
    super.dispose();
  }

  /// Schedule auto-save after user stops typing (debounce)
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), () {
      _autoSaveConfiguration();
    });
  }

  /// Auto-save configuration
  Future<void> _autoSaveConfiguration() async {
    // Only save if all fields are filled
    if (_serverUrlController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _remoteFolderController.text.trim().isEmpty) {
      return;
    }

    // Validate URLs before saving
    final serverUrl = _serverUrlController.text.trim();
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      return;
    }

    final config = SyncConfig(
      serverUrl: serverUrl,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      remoteFolderPath: _remoteFolderController.text.trim(),
    );

    await ref.read(syncNotifierProvider.notifier).saveConfig(config);
  }

  void _loadExistingConfig(SyncConfig config) {
    _serverUrlController.text = config.serverUrl;
    _usernameController.text = config.username;
    _passwordController.text = config.password;
    _remoteFolderController.text = config.remoteFolderPath;
    _isTestingConnection = false;
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.webdavSync),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_outlined),
            tooltip: AppLocalizations.of(context)!.experimentalFeature,
            onPressed: () => _showExperimentalWarning(context),
          ),
        ],
      ),
      body: syncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            AppLocalizations.of(context)!.errorWithDetails(error.toString()),
          ),
        ),
        data: (state) {
          // Load existing config if available
          if (state is SyncConfigured && _serverUrlController.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadExistingConfig(state.config);
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildServerSettings(),
                  const SizedBox(height: 24),
                  _buildActionButtons(state),
                  if (state is SyncConfigured && !_isTestingConnection) ...[
                    const SizedBox(height: 16),
                    _buildSyncInfo(state.config),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServerSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.serverSettings,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serverUrlController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.serverUrl,
                hintText: AppLocalizations.of(context)!.serverUrlHint,
                prefixIcon: const Icon(Icons.language_outlined),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.serverUrlRequired;
                }
                if (!value.startsWith('http://') &&
                    !value.startsWith('https://')) {
                  return AppLocalizations.of(context)!.urlMustStartWith;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.username,
                prefixIcon: const Icon(Icons.person_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.usernameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.password,
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.passwordRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _remoteFolderController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.remoteFolderPath,
                hintText: AppLocalizations.of(context)!.remoteFolderHint,
                prefixIcon: const Icon(Icons.folder_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.folderPathRequired;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(SyncState state) {
    final isSyncing = state is SyncInProgress;

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: isSyncing || _isTestingConnection
                ? null
                : _testConnection,
            icon: _isTestingConnection
                ? null
                : const Icon(Icons.network_check_outlined),
            label: Text(
              _isTestingConnection
                  ? AppLocalizations.of(context)!.testing
                  : AppLocalizations.of(context)!.testConnection,
            ),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncInfo(SyncConfig config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.syncInformation,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              AppLocalizations.of(context)!.lastSync,
              _formatDate(config.lastSyncDate),
            ),
            if (config.lastSyncError != null)
              _buildInfoRow(
                AppLocalizations.of(context)!.lastError,
                config.lastSyncError!,
                isError: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isError ? Theme.of(context).colorScheme.error : null,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppLocalizations.of(context)!.never;
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return AppLocalizations.of(context)!.justNow;
    if (diff.inHours < 1) {
      return AppLocalizations.of(context)!.minutesAgo(diff.inMinutes);
    }
    if (diff.inDays < 1) {
      return AppLocalizations.of(context)!.hoursAgo(diff.inHours);
    }
    if (diff.inDays < 7) {
      return AppLocalizations.of(context)!.daysAgo(diff.inDays);
    }

    return '${date.month}/${date.day}/${date.year}';
  }

  void _showExperimentalWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_outlined,
          size: 48,
          color: Colors.orange,
        ),
        title: Text(AppLocalizations.of(context)!.experimentalFeature),
        content: Text(AppLocalizations.of(context)!.experimentalFeatureWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.iKnow),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      ToastService.showError(
        AppLocalizations.of(context)!.fillAllRequiredFields,
      );
      return;
    }

    setState(() {
      _isTestingConnection = true;
    });

    try {
      final success = await ref
          .read(syncNotifierProvider.notifier)
          .testConnection(
            serverUrl: _serverUrlController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            remoteFolderPath: _remoteFolderController.text.trim(),
          );

      if (mounted) {
        if (success.isRight()) {
          ToastService.showSuccess(
            AppLocalizations.of(context)!.connectionSuccessful,
          );
        } else {
          ToastService.showError(
            AppLocalizations.of(context)!.connectionFailed(
              ref.read(syncNotifierProvider).valueOrNull is SyncFailure
                  ? (ref.read(syncNotifierProvider).valueOrNull as SyncFailure)
                        .userMessage
                  : '',
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
        });
      }
    }
  }
}
