import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/core/utils/byte_size.dart';
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
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref
                  .read(externalSourceBrowserProvider(source.id).notifier)
                  .refresh(),
              child: _buildBody(context, l10n, source, state),
            ),
            // The bar is part of the body rather than `bottomNavigationBar` so
            // it can slide in and out; a Scaffold slot would only appear and
            // disappear. It starts a full bar-height below the bottom edge,
            // which covers the safe-area inset it carries.
            AnimatedPositioned(
              duration: const Duration(
                milliseconds: AppTheme.defaultAnimationDurationMs,
              ),
              curve: Curves.easeInOut,
              left: 0,
              right: 0,
              bottom: _isSelectionMode
                  ? 0
                  : -(_ImportSelectionBar.height +
                        MediaQuery.of(context).padding.bottom),
              child: _ImportSelectionBar(
                count: _selected.length,
                onImport: () => _importSelected(source, state.items),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppLocalizations l10n,
    ExternalSource source,
    ExternalSourceBrowserState state,
  ) {
    final notifier = ref.read(
      externalSourceBrowserProvider(source.id).notifier,
    );
    final canGoUp = state.path.canGoUp;

    // Selection mode recolours the bar. The bookshelf uses `surfaceContainer`
    // for this, but this theme's surface containers are all but identical to the
    // background — `surface` is `#FFFFFF` and `surfaceContainer` is `#FCFCFB`, a
    // 3/255 step that is invisible in practice — so this takes the far end of the
    // ramp, which is the only step that actually reads. The selection bar uses
    // the same value, so the two read as one mode.
    return _AnimatedBackgroundAppBar(
      isSelectionMode: _isSelectionMode,
      appBar: AppBar(
        // While selecting, the leading button leaves selection mode rather than
        // navigating — hence the close icon, which says so without a tooltip.
        leading: IconButton(
          icon: Icon(
            _isSelectionMode ? Icons.close_outlined : Icons.arrow_back_outlined,
          ),
          tooltip: _isSelectionMode
              ? l10n.cancel
              : (canGoUp ? l10n.externalSourceUp : null),
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
        title: _buildAppBarTitle(context, source, state),
        actions: _buildAppBarActions(l10n, state),
      ),
    );
  }

  Widget _buildAppBarTitle(
    BuildContext context,
    ExternalSource source,
    ExternalSourceBrowserState state,
  ) {
    final theme = Theme.of(context);
    return Column(
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
    );
  }

  List<Widget> _buildAppBarActions(
    AppLocalizations l10n,
    ExternalSourceBrowserState state,
  ) {
    // Select-all flips to its opposite once nothing is left to add. Computed
    // from the EPUB entries only: folders and other files can never be selected,
    // so counting them would make the state unreachable in any folder that holds
    // more than books.
    final selectable = state.items.where((item) => item.isEpub).toList();
    final allSelected =
        selectable.isNotEmpty &&
        selectable.every((item) => _selected.contains(item.path));

    return [
      // Only while selecting. Outside selection mode there are no app-bar
      // actions at all: reloading is pull-to-refresh, which leaves the list on
      // screen instead of replacing it.
      if (_isSelectionMode)
        IconButton(
          icon: Icon(
            allSelected ? Icons.deselect_outlined : Icons.select_all_outlined,
          ),
          tooltip: allSelected
              ? l10n.externalSourceDeselectAll
              : l10n.selectAll,
          onPressed: () =>
              allSelected ? setState(_selected.clear) : _selectAll(state.items),
        ),
    ];
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
      // Clears the selection bar when it slides in, so the last entry stays
      // reachable instead of sitting under an opaque overlay.
      padding: const EdgeInsets.only(bottom: 128),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _SourceEntryRow(
          item: item,
          isSelectionMode: _isSelectionMode,
          isSelected: _selected.contains(item.path),
          onTap: () => _onEntryTap(source, item),
          // Only books can be selected, so only they get a tappable icon.
          onIconTap: item.isEpub ? () => _toggleSelection(item) : null,
        );
      },
    );
  }

  /// Handles a tap on a row's body: open folders, import files.
  ///
  /// While selecting, the body toggles the entry too — the icon is how
  /// selection mode is *entered*, but once it is on, both halves of the row
  /// behave the same way.
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

  /// Adds or removes [item] from the selection, entering selection mode the
  /// first time.
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

  /// Selects every importable entry in [items].
  ///
  /// Folders and other files are skipped, so the resulting selection is exactly
  /// what an import would act on.
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
///
/// Only the count and the import action: select-all lives in the app bar, where
/// a single control can flip between selecting and clearing.
///
/// Built like the bookshelf's selection bar — opaque `surfaceContainer` over the
/// full height it slides through, so the list never shows underneath it — but it
/// holds a button rather than icon actions, hence the shorter height.
class _ImportSelectionBar extends StatelessWidget {
  const _ImportSelectionBar({required this.count, required this.onImport});

  /// Matches the height the sliding animation reserves for this bar.
  static const double height = AppTheme.kBottomAppBarHeight;

  final int count;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      height: height + MediaQuery.of(context).padding.bottom,
      // Same colour the app bar settles on in selection mode.
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.externalSourceSelectedCount(count),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              FilledButton(
                onPressed: onImport,
                child: Text(l10n.externalSourceImportSelected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An [AppBar] whose background cross-fades when selection mode is entered or
/// left.
///
/// Exists because `AppBar`'s own background animation only runs while it scrolls
/// under the status bar; a plain property change jumps. The bar is kept
/// transparent and the colour is animated in its `flexibleSpace`, which already
/// spans the status-bar inset and sits behind the toolbar — so the content is
/// built once per rebuild rather than once per animation frame.
class _AnimatedBackgroundAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _AnimatedBackgroundAppBar({
    required this.isSelectionMode,
    required this.appBar,
  });

  final bool isSelectionMode;

  /// The bar to paint the background behind, minus its `backgroundColor` and
  /// `flexibleSpace`.
  final AppBar appBar;

  static const Duration _duration = Duration(
    milliseconds: AppTheme.defaultAnimationDurationMs,
  );

  @override
  Size get preferredSize => appBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        end: isSelectionMode
            ? theme.colorScheme.surfaceContainer
            : theme.scaffoldBackgroundColor,
      ),
      duration: _duration,
      curve: Curves.easeInOut,
      builder: (context, color, _) => AppBar(
        backgroundColor: color,
        leading: appBar.leading,
        automaticallyImplyLeading: appBar.automaticallyImplyLeading,
        title: appBar.title,
        actions: appBar.actions,
        flexibleSpace: appBar.flexibleSpace,
        bottom: appBar.bottom,
        elevation: appBar.elevation,
        scrolledUnderElevation: appBar.scrolledUnderElevation,
        centerTitle: appBar.centerTitle,
        toolbarOpacity: appBar.toolbarOpacity,
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
    required this.onIconTap,
  });

  final ExternalSourceItem item;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;

  /// Toggles selection for this entry, or `null` when it cannot be selected
  /// (folders, and files that are not EPUBs).
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final subtitle = _subtitle(l10n);
    final isImportable = item.isEpub;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _buildLeading(theme, isImportable, l10n),
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
    );
  }

  /// Side of the square every leading widget occupies.
  ///
  /// Both variants use it, so the glyphs cannot drift apart in size or position:
  /// the tappable one gets its tap target from this box, and the plain one is
  /// simply centred in an identical box.
  static const double _leadingExtent = 40;

  /// The leading icon of the row: the entry's kind (folder, EPUB, other file),
  /// as plain as it has always been.
  ///
  /// For an EPUB it is also the selection control — tapping it selects that
  /// book, which is what turns selection mode on. The icon itself never changes
  /// shape; being selected shows as a filled tinted disc behind it, so the row
  /// keeps saying *what* the entry is while indicating that it is picked.
  ///
  /// Folders and non-EPUB files keep a plain, inert icon: they cannot be
  /// imported, so there is nothing to select. While selecting they are greyed a
  /// step further, to read as "not available in this mode" rather than merely
  /// not-chosen.
  Widget _buildLeading(
    ThemeData theme,
    bool isImportable,
    AppLocalizations l10n,
  ) {
    final icon = Icon(
      item.isDirectory
          ? Icons.folder_outlined
          : (isImportable
                ? Icons.menu_book_outlined
                : Icons.insert_drive_file_outlined),
      color: switch ((item.isDirectory, isImportable, isSelected)) {
        // Selected books are tinted to match the disc behind them.
        (false, true, true) => theme.colorScheme.onPrimaryContainer,
        // Importable but unselected.
        (false, true, false) => theme.colorScheme.onSurfaceVariant,
        // Folders take part in the navigation, so they keep full contrast when
        // not selecting and step back while a selection is being assembled.
        (true, _, _) =>
          isSelectionMode
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.onSurfaceVariant,
        // Anything else in the listing, which was never selectable.
        _ => theme.colorScheme.outlineVariant,
      },
    );

    if (!isImportable) {
      return SizedBox(
        width: _leadingExtent,
        height: _leadingExtent,
        child: Center(child: icon),
      );
    }

    return Tooltip(
      message: isSelected
          ? l10n.externalSourceDeselect
          : l10n.externalSourceSelect,
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onIconTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: _leadingExtent,
            height: _leadingExtent,
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }

  /// `1.2 MB · 2024-05-03 14:05`, omitting whatever the server did not report.
  String? _subtitle(AppLocalizations l10n) {
    final parts = <String>[
      if (item.isDirectory)
        l10n.externalSourceFolder
      else if (!item.isEpub)
        l10n.externalSourceNotImportable,
      if (item.size case final size?) formatByteSize(size),
      if (item.lastModified case final modified?) _formatDate(modified),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// `2024-05-03 14:05`, in the device's own time zone.
String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  String pad(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${pad(local.month)}-${pad(local.day)} '
      '${pad(local.hour)}:${pad(local.minute)}';
}
