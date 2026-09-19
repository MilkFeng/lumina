import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/core/widgets/settings_section.dart';
import 'package:lumina/src/features/external_sources/application/external_sources_notifier.dart';
import 'package:lumina/src/features/external_sources/domain/external_source.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_type.dart';
import 'package:lumina/src/features/external_sources/presentation/external_source_localizations.dart';
import 'package:lumina/src/features/external_sources/presentation/widgets/external_source_editor_dialog.dart';

/// The "External Sources" section of the settings screen.
///
/// Composed the same way [FontsSection] is: the feature ships the section and
/// the settings screen only embeds it, so the list, the editor and the
/// connectivity test all stay inside the feature.
class ExternalSourcesSection extends ConsumerWidget {
  const ExternalSourcesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sources = ref.watch(externalSourcesProvider).value ?? const [];

    return SettingsInfoSection(
      title: l10n.externalSources,
      children: [
        if (sources.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              l10n.noExternalSources,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...sources.map((source) => _ExternalSourceTile(source: source)),
        _AddExternalSourceTile(
          suggestedType: ref
              .watch(externalSourceRegistryProvider)
              .supportedTypes
              .first,
        ),
      ],
    );
  }
}

/// One configured source: tapping the row opens the editor, and the two trailing
/// buttons test the connection and delete the source.
class _ExternalSourceTile extends ConsumerStatefulWidget {
  const _ExternalSourceTile({required this.source});

  final ExternalSource source;

  @override
  ConsumerState<_ExternalSourceTile> createState() =>
      _ExternalSourceTileState();
}

class _ExternalSourceTileState extends ConsumerState<_ExternalSourceTile> {
  /// A connection test is a network round trip, so the buttons are disabled
  /// while one is in flight — and the trailing slot shows a spinner instead of
  /// the test button, which is the only thing that explains the wait.
  bool _testing = false;

  ExternalSource get source => widget.source;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final type = externalSourceTypeOf(source);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(
        Icons.cloud_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(source.name),
      subtitle: Text(
        type == null
            ? l10n.externalSourceErrorUnknown
            : l10n.externalSourceTypeName(type),
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: _testing
          ? null
          : () => ExternalSourceEditorDialog.show(
              context,
              EditExternalSource(source),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_testing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.network_check_outlined),
              color: theme.colorScheme.onSurfaceVariant,
              tooltip: l10n.externalSourceTestConnection,
              onPressed: _testConnection,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: theme.colorScheme.error,
            tooltip: l10n.delete,
            onPressed: _testing ? null : _confirmDelete,
          ),
        ],
      ),
    );
  }

  /// Tests a stored source and reports the outcome.
  ///
  /// The result is always a toast, never a dialog: this is a check the user
  /// asked for, not a form they have to complete.
  Future<void> _testConnection() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _testing = true);
    ToastService.showInfo(l10n.externalSourceTesting);

    try {
      final failure = await ref
          .read(externalSourcesProvider.notifier)
          .testConnection(source);

      if (failure == null) {
        ToastService.showSuccess(l10n.externalSourceTestSuccess);
      } else {
        ToastService.showError(l10n.externalSourceFailureMessage(failure));
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.externalSourceDeleteConfirm),
        content: Text(l10n.externalSourceDeleteConfirmText(source.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ref
        .read(externalSourcesProvider.notifier)
        .delete(source);

    result.match(
      (failure) =>
          ToastService.showError(l10n.externalSourceFailureMessage(failure)),
      (_) => ToastService.showSuccess(l10n.externalSourceDeleted(source.name)),
    );
  }
}

/// The trailing "Add external source" row.
class _AddExternalSourceTile extends ConsumerWidget {
  const _AddExternalSourceTile({required this.suggestedType});

  /// Type the editor opens on. There is one type today; the field exists so the
  /// tile does not have to assume which one once there are more.
  final ExternalSourceType suggestedType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(
        Icons.add_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(l10n.addExternalSource),
      subtitle: Text(
        l10n.addExternalSourceSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () => _create(context, ref),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    // The default name has to be unique, so it is derived from the names in use
    // rather than from a counter kept somewhere.
    final name = await ref
        .read(externalSourcesProvider.notifier)
        .suggestName((number) => l10n.externalSourceDefaultName(number));
    if (!context.mounted) return;

    await ExternalSourceEditorDialog.show(
      context,
      NewExternalSource(initialName: name, type: suggestedType),
    );
  }
}
