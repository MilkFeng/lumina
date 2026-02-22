import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../application/bookshelf_notifier.dart';
import '../domain/shelf_book.dart';
import 'mixins/library_actions_mixin.dart';
import 'widgets/book_grid_item.dart';
import 'widgets/library_app_bar.dart';
import 'widgets/library_selection_bar.dart';
import 'widgets/sort_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';

/// Library Screen - Displays user's book collection with advanced bookshelf features
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with TickerProviderStateMixin, LibraryActionsMixin {
  TabController? _tabController;
  bool _isUpdatingFromState = false;
  int _lastTabIndex = 0;

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _initializeTabController(BookshelfState state) {
    final tabCount =
        2 + state.availableGroups.length; // All + Uncategorized + groups

    if (_tabController == null || _tabController!.length != tabCount) {
      final previousController = _tabController;
      previousController?.removeListener(_handleTabChange);
      _tabController = TabController(
        length: tabCount,
        vsync: this,
        initialIndex: _getTabIndexFromState(state),
      );
      _lastTabIndex = _tabController!.index;
      _tabController!.addListener(_handleTabChange);
      if (previousController != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          previousController.dispose();
        });
      }
    }
  }

  int _getTabIndexFromState(BookshelfState state) {
    if (state.filterGroupId == -1) return 1;
    if (state.filterGroupId == null) return 0;
    final index = state.availableGroups.indexWhere(
      (g) => g.id == state.filterGroupId,
    );
    return index == -1 ? 0 : index + 2;
  }

  void _handleTabChange() {
    if (_tabController == null || _isUpdatingFromState) return;
    final newIndex = _tabController!.index;
    if (newIndex == _lastTabIndex) return;
    _lastTabIndex = newIndex;

    final state = ref.read(bookshelfNotifierProvider).valueOrNull;
    if (state == null) return;

    if (newIndex == 0) {
      ref.read(bookshelfNotifierProvider.notifier).filterByGroup(null);
      return;
    }

    if (newIndex == 1) {
      ref.read(bookshelfNotifierProvider.notifier).filterByGroup(-1);
      return;
    }

    final newGroupId = state.availableGroups[newIndex - 2].id;
    if (state.filterGroupId != newGroupId) {
      ref.read(bookshelfNotifierProvider.notifier).filterByGroup(newGroupId);
    }
  }

  void _syncTabIndexWithState(BookshelfState state) {
    if (_tabController == null) return;

    final expectedIndex = _getTabIndexFromState(state);
    if (_tabController!.index != expectedIndex) {
      _isUpdatingFromState = true;
      _lastTabIndex = expectedIndex;
      _tabController!.animateTo(expectedIndex);
      Future.delayed(const Duration(milliseconds: 100), () {
        _isUpdatingFromState = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookshelfState = ref.watch(bookshelfNotifierProvider);

    final state = ref.watch(bookshelfNotifierProvider).valueOrNull;
    final isSelectionMode = state?.isSelectionMode ?? false;

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        if (isSelectionMode) {
          ref.read(bookshelfNotifierProvider.notifier).toggleSelectionMode();
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: bookshelfState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (error, stack) => Center(
                child: Text(
                  AppLocalizations.of(
                    context,
                  )!.errorLoadingLibrary(error.toString()),
                ),
              ),
              data: (state) {
                _initializeTabController(state);
                _syncTabIndexWithState(state);
                return _buildTabView(context, ref, state);
              },
            ),
            floatingActionButton: _buildFAB(context, ref),
          ),
          if (isSelectingFiles)
            Positioned.fill(
              child: Container(
                color: Theme.of(
                  context,
                ).colorScheme.scrim.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildFAB(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookshelfNotifierProvider).valueOrNull;

    if (state?.isSelectionMode ?? false) {
      return null;
    }

    return SpeedDial(
      icon: Icons.add_outlined,
      activeIcon: Icons.close_outlined,
      overlayColor: Colors.black,
      overlayOpacity: 0.4,
      spaceBetweenChildren: 12,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.folder_open_outlined),
          label: AppLocalizations.of(context)!.importFromFolder,
          onTap: () => _scanFolder(context, ref),
        ),
        SpeedDialChild(
          child: const Icon(Icons.file_present_outlined),
          label: AppLocalizations.of(context)!.importFiles,
          onTap: () => _importFiles(context, ref),
        ),
      ],
    );
  }

  // Placeholder method for scanning folder
  void _scanFolder(BuildContext context, WidgetRef ref) {
    handleScanFolder(context, ref);
  }

  // Placeholder method for importing files
  void _importFiles(BuildContext context, WidgetRef ref) {
    handleImportFiles(context, ref);
  }

  Widget _buildTabView(
    BuildContext context,
    WidgetRef ref,
    BookshelfState state,
  ) {
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return Stack(
      children: [
        NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              LibraryAppBar(
                state: state,
                tabController: _tabController!,
                onSortPressed: () => _showSortBottomSheet(context, ref, state),
                onSelectionToggle: () => ref
                    .read(bookshelfNotifierProvider.notifier)
                    .toggleSelectionMode(),
                onSelectAll: () =>
                    ref.read(bookshelfNotifierProvider.notifier).selectAll(),
                onClearSelection: () => ref
                    .read(bookshelfNotifierProvider.notifier)
                    .clearSelection(),
                onEditGroup: (group, l10n) =>
                    showEditGroupDialog(context, ref, group, l10n),
                onExportPressed: () => handleExportBackup(context, ref),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            physics: state.isSelectionMode
                ? const NeverScrollableScrollPhysics()
                : null,
            children: _buildTabViewChildren(context, ref, state),
          ),
        ),
        if (state.isSelectionMode)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LibrarySelectionBar(
              state: state,
              onMove: () => showMoveToGroup(context, ref, state),
              onDelete: () => confirmDelete(context, ref),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildTabViewChildren(
    BuildContext context,
    WidgetRef ref,
    BookshelfState state,
  ) {
    final tabs = <Widget>[];

    // "All" tab
    tabs.add(_buildTabContent(ref, state, null));
    tabs.add(_buildTabContent(ref, state, -1));

    // Group tabs
    for (final group in state.availableGroups) {
      tabs.add(_buildTabContent(ref, state, group.id));
    }

    return tabs;
  }

  Widget _buildTabContent(WidgetRef ref, BookshelfState state, int? groupId) {
    final isActiveTab = state.filterGroupId == groupId;
    final booksForTab = isActiveTab ? state.books : state.cachedBooks[groupId];
    if (booksForTab == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    // Use Builder to get the correct context inside NestedScrollView
    return Builder(
      builder: (BuildContext context) {
        return CustomScrollView(
          key: PageStorageKey<String>('tab_$groupId'),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            _buildItemsGrid(context, ref, state, booksForTab),
            if (state.isSelectionMode)
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }

  void _showSortBottomSheet(
    BuildContext context,
    WidgetRef ref,
    BookshelfState state,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SortBottomSheet(
        currentSort: state.sortBy,
        onSortSelected: (sortBy) {
          ref.read(bookshelfNotifierProvider.notifier).changeSortOrder(sortBy);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildItemsGrid(
    BuildContext context,
    WidgetRef ref,
    BookshelfState state,
    List<ShelfBook> books,
  ) {
    if (books.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noItemsInCategory,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 128),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180.0,
          childAspectRatio: 0.55,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final book = books[index];
          return BookGridItem(
            book: book,
            isSelected: state.selectedBookIds.contains(book.id),
            isSelectionMode: state.isSelectionMode,
            onLongPress: () {
              if (!state.isSelectionMode) {
                HapticFeedback.selectionClick();
                ref
                    .read(bookshelfNotifierProvider.notifier)
                    .toggleSelectionMode();
                ref
                    .read(bookshelfNotifierProvider.notifier)
                    .toggleItemSelection(book);
              }
            },
          );
        }, childCount: books.length),
      ),
    );
  }
}
