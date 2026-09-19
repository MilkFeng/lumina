import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/external_sources/application/external_source_browser_notifier.dart';
import 'package:lumina/src/features/external_sources/application/external_source_import_notifier.dart';
import 'package:lumina/src/features/external_sources/application/external_sources_notifier.dart';
import 'package:lumina/src/features/external_sources/domain/external_source.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_item.dart';
import 'package:lumina/src/features/external_sources/presentation/external_source_localizations.dart';
import 'package:lumina/src/features/library/presentation/widgets/import_progress_dialog.dart';

/// Browses an external source and imports books from it.
///
/// Two interactions, matching the library screen's shape:
/// - tap a folder to open it, or an EPUB to import just that one;
/// - long-press an EPUB to enter selection mode and import several at once.
///
/// Non-EPUB files are listed but not offered for import: hiding them would make
/// a folder look empty when it is not, and importing them is not something the
/// library can do.
class ExternalSourceScreen extends ConsumerStatefulWidget {
  const ExternalSourceScreen({super.key, required this.sourceId});

  /// Id of the source to open; `null` when the route carried a non-numeric id.
  final int? sourceId;

  @override
  ConsumerState<ExternalSourceScreen> createState() =>
      _ExternalSourceScreenState();
}

class _ExternalSourceScreenState extends ConsumerState<ExternalSourceScreen> {
  /// Paths of the entries selected for a batch import.
  final Set<String> _selected = {};

  bool get _isSelectionMode => _selected.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final source = ref
        .watch(externalSourcesProvider)
        .value
        ?.byId(widget.sourceId);

    if (source == null) {
      return _missingSourceScaffold(context, l10n);
    }

    final state = ref.watch(externalSourceBrowserProvider(source.id));

    return PopScope(
      // The system back gesture has to mirror the app bar's back button: it
      // climbs out of folders first, and only leaves the screen from the root.
      // Leaving `canPop` true here is what made back jump straight to the
      // library from inside a folder.
      canPop: !_isSelectionMode && !state.path.canGoUp,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Order matters: back leaves selection mode first, then the folder.
        // Otherwise a long-press would be a trap — the gesture would walk out
        // of the folder while the selection bar is still on screen.
        if (_isSelectionMode) {
          setState(_selected.clear);
        } else {
          ref.read(externalSourceBrowserProvider(source.id).notifier).goUp();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(context, l10n, source, state),
        body: RefreshIndicator(
          onRefresh: () => ref
              .read(externalSourceBrowserProvider(source.id).notifier)
              .refresh(),
          child: _buildBody(context, l10n, source, state),
        ),
        bottomNavigationBar: _isSelectionMode
            ? _ImportSelectionBar(
                count: _selected.length,
                onImport: () => _importSelected(source, state.items),
                onSelectAll: () => _selectAll(state.items),
              )
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    ExternalSource source,
    ExternalSourceBrowserState state,
  ) {
    final theme = Theme.of(context);
    final notifier = ref.read(
      externalSourceBrowserProvider(source.id).notifier,
    );
    final canGoUp = state.path.canGoUp;

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_outlined),
        tooltip: canGoUp ? l10n.externalSourceUp : null,
        onPressed: () {
          if (_isSelectionMode) {
            setState(_selected.clear);
          } else if (canGoUp) {
            notifier.goUp();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            source.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),
          // Where inside the source the user is. The title stays the source, so
          // the two never swap places while navigating.
          Text(
            state.path.packagePath,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        // Selection-mode only: reloading is pull-to-refresh, which keeps the
        // list on screen while it works instead of replacing it.
        if (_isSelectionMode)
          IconButton(
            icon: const Icon(Icons.select_all_outlined),
            tooltip: l10n.selectAll,
            onPressed: () => _selectAll(state.items),
          ),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    ExternalSource source,
    ExternalSourceBrowserState state,
  ) {
    final theme = Theme.of(context);

    // A full-page spinner only while the visible level has never loaded. A
    // reload of a level already on screen keeps its entries: the
    // pull-to-refresh spinner already says something is happening, and blanking
    // the page under it would be both redundant and jarring.
    if (!state.hasLoaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final items = state.items;

    // The empty and error states stay scrollable so pull-to-refresh keeps
    // working on them, which is exactly when a retry is wanted.
    //
    // An error only replaces the list when there is no list to keep: a refresh
    // that fails leaves the entries already on screen in place, rather than
    // throwing them away for an error the user cannot act on.
    if (state.failure case final failure? when items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 96, 32, 0),
            child: Column(
              children: [
                Text(
                  l10n.externalSourceFailureMessage(failure),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 96, 32, 0),
            child: Text(
              l10n.externalSourceFolderEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _SourceEntryRow(
          item: item,
          isSelectionMode: _isSelectionMode,
          isSelected: _selected.contains(item.path),
          onTap: () => _onEntryTap(source, item),
          onToggleSelection: () => _toggleSelection(item),
          onLongPress: () => _enterSelection(item),
        );
      },
    );
  }

  /// Handles a tap on an entry: open folders, import files.
  void _onEntryTap(ExternalSource source, ExternalSourceItem item) {
    if (_isSelectionMode) {
      _toggleSelection(item);
      return;
    }

    if (item.isDirectory) {
      ref.read(externalSourceBrowserProvider(source.id).notifier).open(item);
      return;
    }

    if (!item.isEpub) {
      ToastService.showError(
        AppLocalizations.of(context)!.externalSourceNotEpub,
      );
      return;
    }

    _import(source, [item]);
  }

  void _toggleSelection(ExternalSourceItem item) {
    if (!item.isEpub) {
      ToastService.showError(
        AppLocalizations.of(context)!.externalSourceNotEpub,
      );
      return;
    }
    setState(() {
      if (!_selected.remove(item.path)) _selected.add(item.path);
    });
  }

  void _enterSelection(ExternalSourceItem item) {
    if (!item.isEpub) return;
    _toggleSelection(item);
  }

  void _selectAll(List<ExternalSourceItem> items) {
    setState(() {
      _selected
        ..clear()
        ..addAll(items.where((item) => item.isEpub).map((item) => item.path));
    });
  }

  void _importSelected(ExternalSource source, List<ExternalSourceItem> items) {
    final selection = items
        .where((item) => _selected.contains(item.path))
        .toList(growable: false);
    if (selection.isEmpty) return;
    setState(_selected.clear);
    _import(source, selection);
  }

  /// Imports [items], showing the same progress dialog a local import uses.
  Future<void> _import(
    ExternalSource source,
    List<ExternalSourceItem> items,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final stream = ref
        .read(externalSourceImportProvider.notifier)
        .importStream(source, items);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.5),
      builder: (ctx) => ImportProgressDialog(stream: stream, l10n: l10n),
    );
  }

  /// Shown when the route names a source that does not exist (any more).
  Widget _missingSourceScaffold(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(l10n.externalSources),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            l10n.externalSourceNotFound,
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

/// The action bar shown while books are selected.
class _ImportSelectionBar extends StatelessWidget {
  const _ImportSelectionBar({
    required this.count,
    required this.onImport,
    required this.onSelectAll,
  });

  final int count;
  final VoidCallback onImport;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.externalSourceSelectedCount(count),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(onPressed: onSelectAll, child: Text(l10n.selectAll)),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onImport,
              child: Text(l10n.externalSourceImportSelected),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row of the browser: a folder, an importable book, or another file.
class _SourceEntryRow extends StatelessWidget {
  const _SourceEntryRow({
    required this.item,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onToggleSelection,
    required this.onLongPress,
  });

  final ExternalSourceItem item;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleSelection;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final subtitle = _subtitle(l10n);
    final isImportable = item.isEpub;

    // In selection mode the checkbox carries the tap: tapping the row itself
    // must not start a single-file import while a batch is being assembled.
    final leading = isSelectionMode
        ? Checkbox(
            value: isSelected,
            onChanged: isImportable ? (_) => onToggleSelection() : null,
          )
        : Icon(
            item.isDirectory
                ? Icons.folder_outlined
                : (isImportable
                      ? Icons.menu_book_outlined
                      : Icons.insert_drive_file_outlined),
            color: item.isDirectory || isImportable
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.outlineVariant,
          );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: leading,
      // Book file names are long and their tail is the informative part
      // (`… - 作者.epub`), so the title wraps instead of ellipsising after one
      // line. Two lines covers almost every real name; three would start to
      // crowd the metadata line.
      title: Text(
        item.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: item.isDirectory || isImportable
            ? null
            : TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  /// `1.2 MB · 2024-05-03 14:05`, omitting whatever the server did not report.
  String? _subtitle(AppLocalizations l10n) {
    final parts = <String>[
      if (item.isDirectory)
        l10n.externalSourceFolder
      else if (!item.isEpub)
        l10n.externalSourceNotImportable,
      if (item.size case final size?) _formatSize(size),
      if (item.lastModified case final modified?) _formatDate(modified),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// Renders a byte count the way a file manager does.
String _formatSize(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = value >= 100 || unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

/// `2024-05-03 14:05`, in the device's own time zone.
String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${pad(local.month)}-${pad(local.day)} '
      '${pad(local.hour)}:${pad(local.minute)}';
}
