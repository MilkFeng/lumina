import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../application/bookshelf_notifier.dart';
import '../../domain/shelf_group.dart';

/// AppBar widget for the Library screen with tabs and action buttons.
class LibraryAppBar extends StatefulWidget {
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
  State<LibraryAppBar> createState() => _LibraryAppBarState();
}

class _LibraryAppBarState extends State<LibraryAppBar>
    with SingleTickerProviderStateMixin {
  // The intrinsic height of a Flutter TabBar.
  static const double _kTabBarHeight = 48.0;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      // Start fully visible when not in selection mode.
      value: widget.state.isSelectionMode ? 0.0 : 1.0,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(LibraryAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.isSelectionMode != oldWidget.state.isSelectionMode) {
      if (widget.state.isSelectionMode) {
        _controller.reverse(); // collapse TabBar
      } else {
        _controller.forward(); // expand TabBar
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelectionMode = widget.state.isSelectionMode;
    final logoSvgPath = 'assets/logos/logo.svg';

    // Rebuild the SliverAppBar on every animation tick so that
    // bottom.preferredSize.height shrinks/grows smoothly.
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedHeight = _kTabBarHeight * _animation.value;

        return SliverOverlapAbsorber(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          sliver: SliverAppBar(
            pinned: true,
            floating: false,
            // Lerp between surface (normal) and surfaceContainer (selection).
            // _animation.value: 1.0 = normal, 0.0 = selection mode.
            backgroundColor: Color.lerp(
              Theme.of(context).colorScheme.surfaceContainer,
              Theme.of(context).colorScheme.surface,
              _animation.value,
            ),
            leading: isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.close_outlined),
                    onPressed: widget.onSelectionToggle,
                  )
                : null,
            title: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isSelectionMode ? null : () => context.push('/settings'),
              child: isSelectionMode
                  ? Text(
                      AppLocalizations.of(
                        context,
                      )!.selected(widget.state.selectedCount),
                    )
                  : IconButton(
                      padding: EdgeInsets.only(
                        left: 0,
                        right: 32,
                        top: 16,
                        bottom: 16,
                      ),
                      alignment: Alignment.centerLeft,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () => context.push('/settings'),
                      icon: SvgPicture.asset(
                        logoSvgPath,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurface,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
            ),
            actions: [
              if (isSelectionMode)
                IconButton(
                  onPressed: () {
                    if (widget.state.selectedCount ==
                        widget.state.books.length) {
                      widget.onClearSelection();
                    } else {
                      widget.onSelectAll();
                    }
                  },
                  icon: Icon(
                    widget.state.selectedCount == widget.state.books.length
                        ? Icons.deselect_outlined
                        : Icons.select_all_outlined,
                  ),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.tune_outlined),
                  onPressed: widget.onSortPressed,
                ),
              ],
            ],
            // Always supply a bottom widget so the SliverAppBar height
            // transitions smoothly rather than jumping between two states.
            bottom: _AnimatedTabBarWrapper(
              height: animatedHeight,
              opacity: _animation.value,
              child: TabBar(
                controller: widget.tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: _buildTabs(context),
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Theme.of(context).colorScheme.primaryFixed,
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTabs(BuildContext context) {
    final tabs = <Widget>[];

    tabs.add(Tab(child: Text(AppLocalizations.of(context)!.all)));
    tabs.add(Tab(child: Text(AppLocalizations.of(context)!.uncategorized)));

    for (final group in widget.state.availableGroups) {
      tabs.add(
        Tab(
          child: GestureDetector(
            onLongPress: () {
              HapticFeedback.selectionClick();
              final l10n = AppLocalizations.of(context)!;
              widget.onEditGroup(group, l10n);
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

/// A [PreferredSizeWidget] wrapper that reports an animated [height] to
/// [SliverAppBar] and fades/clips the inner [child] accordingly.
class _AnimatedTabBarWrapper extends StatelessWidget
    implements PreferredSizeWidget {
  const _AnimatedTabBarWrapper({
    required this.height,
    required this.opacity,
    required this.child,
  });

  final double height;
  final double opacity;
  final Widget child;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Align(
        alignment: Alignment.topCenter,
        child: Opacity(opacity: opacity, child: child),
      ),
    );
  }
}
