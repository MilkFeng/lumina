import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import '../../../core/services/toast_service.dart';
import '../application/library_notifier.dart';
import '../application/bookshelf_notifier.dart';
import '../domain/shelf_book.dart';
import '../domain/shelf_group.dart';
import 'widgets/batch_import_dialog.dart';
import 'widgets/book_grid_item.dart';
import 'widgets/group_selection_dialog.dart';
import 'widgets/sort_bottom_sheet.dart';
import '../../../../l10n/app_localizations.dart';

/// Library Screen - Displays user's book collection with advanced bookshelf features
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with TickerProviderStateMixin {
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
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: bookshelfState.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
    );
  }

  Widget? _buildFAB(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookshelfNotifierProvider).valueOrNull;

    if (state?.isSelectionMode ?? false) {
      // Show selection actions FAB
      return null; // We'll use bottom bar for selection actions
    }

    return FloatingActionButton(
      onPressed: () => _handleImportFiles(context, ref),
      child: const Icon(Icons.add_outlined),
    );
  }

  Widget _buildTabView(
    BuildContext context,
    WidgetRef ref,
    BookshelfState state,
  ) {
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [_buildSliverAppBar(context, ref, state)];
          },
          body: TabBarView(
            controller: _tabController,
            physics: state.isSelectionMode
                ? const NeverScrollableScrollPhysics()
                : null,
            children: _buildTabViewChildren(context, ref, state),
          ),
        ),
        // Selection mode bottom bar
        if (state.isSelectionMode)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildSelectionBar(context, ref, state),
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

  Widget _buildSliverAppBar(
    BuildContext context,
    WidgetRef ref,
    BookshelfState state,
  ) {
    final isSelectionMode = state.isSelectionMode;

    return SliverOverlapAbsorber(
      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
      sliver: SliverAppBar(
        pinned: true,
        floating: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close_outlined),
                onPressed: () {
                  ref
                      .read(bookshelfNotifierProvider.notifier)
                      .toggleSelectionMode();
                },
              )
            : null,
        title: GestureDetector(
          onTap: isSelectionMode
              ? null
              : () {
                  context.push('/about');
                },
          child: Text(
            isSelectionMode
                ? AppLocalizations.of(context)!.selected(state.selectedCount)
                : AppLocalizations.of(context)!.appName,
          ),
        ),
        actions: [
          if (isSelectionMode)
            TextButton(
              onPressed: () {
                if (state.selectedCount == state.books.length) {
                  ref.read(bookshelfNotifierProvider.notifier).clearSelection();
                } else {
                  ref.read(bookshelfNotifierProvider.notifier).selectAll();
                }
              },
              child: Text(
                state.selectedCount == state.books.length
                    ? AppLocalizations.of(context)!.deselectAll
                    : AppLocalizations.of(context)!.selectAll,
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.sort_rounded),
              onPressed: () => _showSortBottomSheet(context, ref, state),
              tooltip: AppLocalizations.of(context)!.sort,
            ),
          ],
        ],
        bottom: isSelectionMode
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: _buildTabs(context, ref, state),
                indicatorSize: TabBarIndicatorSize.label,
              ),
      ),
    );
  }

  List<Widget> _buildTabs(
    BuildContext context,
    WidgetRef ref,
    BookshelfState state,
  ) {
    final tabs = <Widget>[];
    // "All" tab
    tabs.add(
      Tab(
        child: Text(
          AppLocalizations.of(context)!.all,
          style: AppTheme.contentTextStyle,
        ),
      ),
    );
    tabs.add(
      Tab(
        child: Text(
          AppLocalizations.of(context)!.uncategorized,
          style: AppTheme.contentTextStyle,
        ),
      ),
    );

    // Group tabs
    for (final group in state.availableGroups) {
      tabs.add(
        Tab(
          child: GestureDetector(
            onLongPress: () {
              HapticFeedback.selectionClick();
              final l10n = AppLocalizations.of(context)!;
              _showEditGroupDialog(context, ref, group, l10n);
            },
            behavior: HitTestBehavior.opaque,
            child: Text(group.name, style: AppTheme.contentTextStyle),
          ),
        ),
      );
    }

    return tabs;
  }

  Future<void> _showEditGroupDialog(
    BuildContext context,
    WidgetRef ref,
    ShelfGroup group,
    AppLocalizations l10n,
  ) async {
    var draftName = group.name;
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.editCategory,
          style: AppTheme.contentTextStyle,
        ),
        content: TextFormField(
          initialValue: group.name,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.categoryName,
          ),
          onChanged: (value) => draftName = value,
          onFieldSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ref
                  .read(bookshelfNotifierProvider.notifier)
                  .deleteGroup(group.id);
              if (context.mounted) {
                if (result) {
                  ToastService.showSuccess(l10n.categoryDeleted(group.name));
                } else {
                  ToastService.showError(l10n.failedToDeleteCategory);
                }
              }
            },
            child: Text(l10n.delete),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, draftName.trim()),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != group.name) {
      await ref
          .read(bookshelfNotifierProvider.notifier)
          .renameGroup(group.id, result);
    }
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

  Widget _buildSelectionBar(
    BuildContext context,
    WidgetRef ref,
    BookshelfState state,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildActionButton(
                context,
                icon: Icons.drive_file_move_outlined,
                label: AppLocalizations.of(context)!.move,
                onPressed: state.hasSelection
                    ? () => _showMoveToGroup(context, ref, state)
                    : null,
              ),
              _buildActionButton(
                context,
                icon: Icons.delete_outlined,
                label: AppLocalizations.of(context)!.delete,
                onPressed: state.hasSelection
                    ? () => _confirmDelete(context, ref)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withAlpha(77),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: enabled
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withAlpha(77),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMoveToGroup(
    BuildContext context,
    WidgetRef ref,
    BookshelfState state,
  ) async {
    const createGroupResult = -2;

    final l10n = AppLocalizations.of(context)!;

    var result = await showDialog<int?>(
      context: context,
      builder: (context) => GroupSelectionDialog(
        groups: state.availableGroups,
        createGroupResult: createGroupResult,
      ),
    );
    String? newName;

    if (result == createGroupResult) {
      if (!context.mounted) return;
      final name = await _promptForGroupName(context);
      if (!context.mounted) return;
      if (name != null && name.trim().isNotEmpty) {
        final groupId = await ref
            .read(bookshelfNotifierProvider.notifier)
            .createGroup(name);
        if (!context.mounted) return;

        if (groupId == null) {
          if (state is AsyncError) {
            ToastService.showError(l10n.failedToCreateCategory);
          }
          return;
        } else {
          ToastService.showSuccess(l10n.categoryCreated(name));
        }

        result = groupId;
        newName = name;
      } else {
        ToastService.showError(l10n.categoryNameCannotBeEmpty);
        return;
      }
    }

    if (result != null) {
      final targetGroupId = result == -1 ? null : result;
      final success = await ref
          .read(bookshelfNotifierProvider.notifier)
          .moveSelectedItems(targetGroupId);
      if (!context.mounted) return;
      {
        if (success) {
          var targetName = l10n.categoryName;
          if (targetGroupId == null) {
            targetName = l10n.uncategorized;
          } else {
            if (newName != null) {
              targetName = newName;
            } else {
              for (final group in state.availableGroups) {
                if (group.id == targetGroupId) {
                  targetName = group.name;
                  break;
                }
              }
            }
          }
          ToastService.showSuccess(l10n.movedTo(targetName));
        } else {
          ToastService.showError(l10n.failedToMove);
        }
      }
    }
  }

  Future<String?> _promptForGroupName(BuildContext context) async {
    var draftName = '';
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.newCategory),
        content: TextField(
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.categoryName,
          ),
          onChanged: (value) => draftName = value,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
          style: AppTheme.contentTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, draftName.trim()),
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
    return (result?.trim().isNotEmpty ?? false) ? result : null;
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteBooks),
        content: Text(AppLocalizations.of(context)!.deleteBooksConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(bookshelfNotifierProvider.notifier)
          .deleteSelected();
      if (context.mounted) {
        if (success) {
          ToastService.showSuccess(AppLocalizations.of(context)!.deleted);
        } else {
          ToastService.showError(AppLocalizations.of(context)!.failedToDelete);
        }
      }
    }
  }

  Future<void> _handleImportFiles(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final selectedPaths = result.paths.whereType<String>();
      final files = selectedPaths.map(File.new).toList();

      if (files.isEmpty) {
        if (context.mounted) {
          ToastService.showError(AppLocalizations.of(context)!.fileAccessError);
        }
        return;
      }

      final stream = ref
          .read(libraryNotifierProvider.notifier)
          .importMultipleBooks(files);

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Theme.of(
          context,
        ).colorScheme.scrim.withValues(alpha: 0.5),
        builder: (ctx) => BatchImportDialog(progressStream: stream),
      );

      FilePicker.platform.clearTemporaryFiles();

      if (context.mounted) {
        ref.read(bookshelfNotifierProvider.notifier).refresh();
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(
          AppLocalizations.of(context)!.importFailed(e.toString()),
        );
      }
    }
  }
}
