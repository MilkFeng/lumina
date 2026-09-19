import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/features/external_sources/application/external_sources_notifier.dart';

/// Screen reached from the home screen's "import from …" menu entry.
///
/// Browsing and importing from a source is not implemented yet; this screen
/// exists so the navigation, the route and the source lookup are already in
/// place, and names the source it resolved to.
class ExternalSourceScreen extends ConsumerWidget {
  const ExternalSourceScreen({super.key, required this.sourceId});

  /// Id of the source to open; `null` when the route carried a non-numeric id,
  /// which resolves to the "no longer exists" state.
  final int? sourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final id = sourceId;
    final source = id == null
        ? null
        : (ref.watch(externalSourcesProvider).value ?? const [])
              .where((source) => source.id == id)
              .firstOrNull;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          source == null
              ? l10n.externalSources
              : l10n.externalSourceScreenTitle(source.name),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            source == null
                ? l10n.externalSourceNotFound
                : l10n.externalSourceScreenPlaceholder,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
