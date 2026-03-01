import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
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
    super.key,
  });

  final BookshelfState state;
  final TabController tabController;
  final VoidCallback onSortPressed;
  final VoidCallback onSelectionToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final void Function(ShelfGroup group, AppLocalizations l10n) onEditGroup;

  @override
  Widget build(BuildContext context) {
    final isSelectionMode = state.isSelectionMode;
    final logoSvgPath = 'assets/logos/logo.svg';

    return SliverOverlapAbsorber(
      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
      sliver: SliverAppBar(
        pinned: true,
        floating: false,
        backgroundColor: isSelectionMode
            ? Theme.of(context).colorScheme.surfaceContainer
            : Theme.of(context).colorScheme.surface,
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
                  context.push('/settings');
                },
          child: isSelectionMode
              ? Text(
                  AppLocalizations.of(context)!.selected(state.selectedCount),
                )
              : SvgPicture.asset(
                  logoSvgPath,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                ),
        ),
        actions: [
          if (isSelectionMode)
            IconButton(
              onPressed: () {
                if (state.selectedCount == state.books.length) {
                  onClearSelection();
                } else {
                  onSelectAll();
                }
              },
              icon: Icon(
                state.selectedCount == state.books.length
                    ? Icons.deselect_outlined
                    : Icons.select_all_outlined,
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.grid_view_outlined),
              onPressed: onSortPressed,
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
                dividerColor: Colors.transparent,
              ),
      ),
    );
  }

  List<Widget> _buildTabs(BuildContext context) {
    final tabs = <Widget>[];

    // "All" tab
    tabs.add(Tab(child: Text(AppLocalizations.of(context)!.all)));

    // "Uncategorized" tab
    tabs.add(Tab(child: Text(AppLocalizations.of(context)!.uncategorized)));

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
            child: Text(group.name),
          ),
        ),
      );
    }

    return tabs;
  }
}
