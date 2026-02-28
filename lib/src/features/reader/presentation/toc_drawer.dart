import 'package:flutter/material.dart';
import 'package:lumina/src/features/library/domain/book_manifest.dart';
import '../../library/domain/shelf_book.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../../l10n/app_localizations.dart';

/// Helper class to represent a visible row in the flattened list
class _TocRowItem {
  final TocItem item;
  final int depth;
  final bool isExpanded;
  final bool hasChildren;

  _TocRowItem({
    required this.item,
    required this.depth,
    required this.isExpanded,
    required this.hasChildren,
  });
}

class TocDrawer extends StatefulWidget {
  final ShelfBook book;
  final List<TocItem> toc;
  final Set<TocItem> activeTocItems;
  final Function(TocItem) onTocItemSelected;
  final Function() onCoverTap;
  final ThemeData themeData;

  const TocDrawer({
    super.key,
    required this.book,
    required this.toc,
    required this.activeTocItems,
    required this.onTocItemSelected,
    required this.onCoverTap,
    required this.themeData,
  });

  @override
  State<TocDrawer> createState() => _TocDrawerState();
}

class _TocDrawerState extends State<TocDrawer> {
  final ScrollController _scrollController = ScrollController();

  // State: Set of expanded item IDs (assuming TocItem has a unique 'id' or we use 'label')
  // Using identity hashCode as fallback if no ID exists, but ideally TocItem should have a unique ID.
  final Set<TocItem> _expandedItems = {};

  // Cache: The flattened list of visible items
  List<_TocRowItem> _visibleItems = [];

  @override
  void initState() {
    super.initState();
    _initExpansionState();
    _regenerateVisibleItems();

    // Schedule initial scroll only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToFirstActive();
    });
  }

  @override
  void didUpdateWidget(covariant TocDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If TOC structure changed, reset everything
    if (widget.toc != oldWidget.toc) {
      _expandedItems.clear();
      _initExpansionState();
      _regenerateVisibleItems();
    }
    // If only active items changed, maybe auto-expand and scroll
    else if (widget.activeTocItems != oldWidget.activeTocItems) {
      // Optional: Auto-expand to show active item if it's hidden
      bool expandedChanged = _autoExpandParents();

      if (expandedChanged) {
        _regenerateVisibleItems();
      } else {
        // If structure didn't change (no new expansion), we just need to repaint.
        // setState is called automatically by framework when didUpdateWidget returns,
        // but since _visibleItems is cached, we don't need to do anything heavy.
      }

      // Don't auto-scroll on every minor update while user is reading,
      // only if the Drawer was just opened (handled in initState)
      // or explicitly requested.
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize expansion: Auto-expand path to active items
  void _initExpansionState() {
    _autoExpandParents();
  }

  /// Ensures parents of active items are expanded
  bool _autoExpandParents() {
    bool changed = false;
    if (widget.activeTocItems.isEmpty) return false;

    // Helper to find path to active item
    bool findAndExpand(TocItem current, TocItem target) {
      if (current == target) return true;

      for (final child in current.children) {
        if (findAndExpand(child, target)) {
          // If child contains target, expand current
          if (!_expandedItems.contains(current)) {
            _expandedItems.add(current);
            changed = true;
          }
          return true;
        }
      }
      return false;
    }

    for (final root in widget.toc) {
      for (final active in widget.activeTocItems) {
        findAndExpand(root, active);
      }
    }
    return changed;
  }

  /// Flatten the tree into a list, respecting expansion state
  void _regenerateVisibleItems() {
    final newItems = <_TocRowItem>[];

    void traverse(List<TocItem> items, int depth) {
      for (final item in items) {
        final isExpanded = _expandedItems.contains(item);
        final hasChildren = item.children.isNotEmpty;

        newItems.add(
          _TocRowItem(
            item: item,
            depth: depth,
            isExpanded: isExpanded,
            hasChildren: hasChildren,
          ),
        );

        if (hasChildren && isExpanded) {
          traverse(item.children, depth + 1);
        }
      }
    }

    traverse(widget.toc, 0);

    setState(() {
      _visibleItems = newItems;
    });
  }

  void _toggleExpansion(TocItem item) {
    if (_expandedItems.contains(item)) {
      _expandedItems.remove(item);
    } else {
      _expandedItems.add(item);
    }
    _regenerateVisibleItems();
  }

  void _scrollToFirstActive() {
    if (widget.activeTocItems.isEmpty || _visibleItems.isEmpty) return;

    // Find index in the FLAT list
    final index = _visibleItems.indexWhere(
      (row) => widget.activeTocItems.contains(row.item),
    );

    if (index != -1 && _scrollController.hasClients) {
      // Estimate offset: index * itemHeight
      // 56.0 is the fixed extent height
      final offset = (index * 56.0) - (56.0 * 4); // Center it a bit
      _scrollController.jumpTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeData.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: widget.themeData.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            Expanded(
              // Optimization: ListView.builder only builds items on screen
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _visibleItems.length + 1, // +1 for bottom padding
                itemExtent:
                    56.0, // Fixed height significantly boosts performance
                itemBuilder: (context, index) {
                  if (index == _visibleItems.length) {
                    return const SizedBox(height: 56); // Bottom padding
                  }

                  final row = _visibleItems[index];
                  return _buildRowItem(context, row, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem(BuildContext context, _TocRowItem row, bool isDark) {
    final item = row.item;
    final isActive = widget.activeTocItems.contains(item);

    // Indentation calculation
    final double paddingLeft = 16.0 + (row.depth * 16.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (row.hasChildren) {
            _toggleExpansion(item);
          } else {
            widget.onTocItemSelected(item);
            Navigator.of(context).pop();
          }
        },
        child: Container(
          height: 56.0,
          padding: EdgeInsets.only(left: paddingLeft, right: 16.0),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              // Expansion Icon (Chevron)
              if (row.hasChildren)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    row.isExpanded
                        ? Icons.expand_more_outlined
                        : Icons.chevron_right_outlined,
                    size: 20,
                    color: widget.themeData.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                // Placeholder to align text if desired, or remove for compact look
                const SizedBox(width: 28),

              // Label
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: widget.themeData.textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? widget.themeData.colorScheme.onSurface
                        : widget.themeData.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // Active Indicator
              if (isActive)
                Icon(
                  Icons.circle_outlined,
                  size: 8,
                  color: widget.themeData.colorScheme.onSurface,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.themeData.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: widget.themeData.colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          widget.onCoverTap();
          Navigator.of(context).pop();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover
            SizedBox(
              width: 60,
              height: 90,
              child: Theme(
                data: widget.themeData,
                child: BookCover(
                  relativePath: '${widget.book.coverPath}',
                  radius: BorderRadius.circular(4),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Book Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.book.title,
                    style: widget.themeData.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.book.author.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.book.author,
                      style: widget.themeData.textTheme.bodySmall?.copyWith(
                        color: widget.themeData.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.chaptersCount(widget.book.totalChapters),
                    style: widget.themeData.textTheme.bodySmall?.copyWith(
                      color: widget.themeData.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
