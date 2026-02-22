import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/src/core/theme/app_theme.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../application/bookshelf_notifier.dart';
import '../../domain/shelf_group.dart';

/// AppBar widget for the Library screen with tabs and action buttons.
class LibraryAppBar extends StatelessWidget {
  const LibraryAppBar({
    required this.state,
    required this.tabController,
    required this.onSortPressed,
    required this.onSelectionToggle,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onEditGroup,
    required this.onExportPressed,
    super.key,
  });

  final BookshelfState state;
  final TabController tabController;
  final VoidCallback onSortPressed;
  final VoidCallback onSelectionToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final void Function(ShelfGroup group, AppLocalizations l10n) onEditGroup;
  final VoidCallback onExportPressed;

  @override
  Widget build(BuildContext context) {
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
                onPressed: onSelectionToggle,
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
                  onClearSelection();
                } else {
                  onSelectAll();
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
              icon: const Icon(Icons.save_alt_outlined),
              onPressed: onExportPressed,
              tooltip: 'Backup library',
            ),
            IconButton(
              icon: const Icon(Icons.sort_rounded),
              onPressed: onSortPressed,
              tooltip: AppLocalizations.of(context)!.sort,
            ),
          ],
        ],
        bottom: isSelectionMode
            ? null
            : TabBar(
                controller: tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: _buildTabs(context),
                indicatorSize: TabBarIndicatorSize.label,
              ),
      ),
    );
  }

  List<Widget> _buildTabs(BuildContext context) {
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

    // "Uncategorized" tab
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
              onEditGroup(group, l10n);
            },
            behavior: HitTestBehavior.opaque,
            child: Text(group.name, style: AppTheme.contentTextStyle),
          ),
        ),
      );
    }

    return tabs;
  }
}
