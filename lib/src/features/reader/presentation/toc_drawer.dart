import 'package:lumina/src/core/theme/app_theme.dart';
import 'package:lumina/src/features/library/domain/book_manifest.dart';
import 'package:flutter/material.dart';
import '../../library/domain/shelf_book.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../../l10n/app_localizations.dart';

/// Table of Contents Drawer - Tree-structured chapter navigation
class TocDrawer extends StatefulWidget {
  final ShelfBook book;
  final List<TocItem> toc;
  final int currentChapterIndex;
  final Function(TocItem) onTocItemSelected;

  const TocDrawer({
    super.key,
    required this.book,
    required this.toc,
    required this.currentChapterIndex,
    required this.onTocItemSelected,
  });

  @override
  State<TocDrawer> createState() => _TocDrawerState();
}

class _TocDrawerState extends State<TocDrawer> {
  late final ScrollController scrollController;
  late final List<TocItem> flatChapters;

  @override
  void initState() {
    super.initState();
    flatChapters = widget.toc.expand((item) => item.safeFlatten()).toList();
    scrollController = ScrollController(
      initialScrollOffset: _calculateInitializedScrollOffset(),
    );
    _scheduleScrollToActive();
  }

  @override
  void didUpdateWidget(covariant TocDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentChapterIndex != widget.currentChapterIndex ||
        oldWidget.toc != widget.toc) {
      _scheduleScrollToActive();
    }
  }

  int _findIndex(TocItem tocItem, TocItem targetItem) {
    var index = 0;
    if (tocItem == targetItem) {
      return index;
    }
    for (final item in tocItem.children) {
      index += 1;
      final childIndex = _findIndex(item, targetItem);
      if (childIndex != -1) {
        return index + childIndex;
      }
    }
    return -1;
  }

  double _getOffset(TocItem tocItem) {
    var index = 0;
    for (final item in widget.toc) {
      final childIndex = _findIndex(item, tocItem);
      if (childIndex != -1) {
        index += childIndex;
        break;
      }
      index += 1;
    }
    return index * 56.0;
  }

  double _calculateInitializedScrollOffset() {
    final activeItem = _resolveActiveItem(
      widget.toc,
      widget.currentChapterIndex,
    );
    if (activeItem == null) return 0.0;

    final activeOffset = _getOffset(activeItem);
    var targetOffset = activeOffset - 56.0 * 4;
    if (targetOffset < 0) {
      targetOffset = 0;
    }

    return targetOffset;
  }

  void _scheduleScrollToActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offset = _calculateInitializedScrollOffset();
      scrollController.jumpTo(offset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeItem = _resolveActiveItem(
      widget.toc,
      widget.currentChapterIndex,
    );

    bool hasGrandChapters = widget.toc.any((item) => item.children.isNotEmpty);

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header - Book Cover & Metadata
            _buildHeader(context, isDark),

            // Divider
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.grey[800] : Colors.grey[300],
            ),

            // Chapter List
            Expanded(
              child: ListView(
                itemExtent: hasGrandChapters ? null : 56.0,
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  ..._buildChapterTree(context, widget.toc, isDark, activeItem),
                  SizedBox(height: 64), // Extra padding at bottom
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build drawer header with book cover and metadata
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 60,
              height: 90,
              child: BookCover(relativePath: '${widget.book.coverPath}'),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    fontFamily: AppTheme.fontFamilyContent,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.book.author,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w400,
                    fontFamily: AppTheme.fontFamilyContent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.chaptersCount(widget.book.totalChapters),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build chapter tree with proper nesting
  List<Widget> _buildChapterTree(
    BuildContext context,
    List<TocItem> toc,
    bool isDark,
    TocItem? activeItem,
  ) {
    final widgets = <Widget>[];

    int index = 0;
    for (final tocItem in toc) {
      widgets.addAll(
        _buildChapterItem(context, tocItem, index, isDark, activeItem),
      );
      index += tocItem.flatten().length;
    }

    return widgets;
  }

  /// Build a single chapter item (with children if any)
  List<Widget> _buildChapterItem(
    BuildContext context,
    TocItem tocItem,
    int startIndex,
    bool isDark,
    TocItem? activeItem,
  ) {
    final widgets = <Widget>[];
    final chapterIndex = flatChapters.indexOf(tocItem);
    final isActive = tocItem == activeItem;
    if (tocItem.children.isEmpty) {
      // Simple list tile for leaf chapters
      final tile = _buildListTile(
        context,
        tocItem,
        chapterIndex,
        isActive,
        isDark,
      );
      widgets.add(tile);
    } else {
      final shouldExpand = _shouldExpand(tocItem, activeItem);
      // Expansion tile for chapters with children
      final expansionTile = Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.only(
            left: 16.0 + (tocItem.depth * 16.0),
            right: 16.0,
          ),
          initiallyExpanded: shouldExpand,
          title: Text(
            tocItem.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
              fontFamily: AppTheme.fontFamilyContent,
            ),
          ),
          onExpansionChanged: (_) {},
          children: [
            // Build child chapters
            ...tocItem.children.expand((child) {
              final childIndex = flatChapters.indexOf(child);
              return _buildChapterItem(
                context,
                child,
                childIndex,
                isDark,
                activeItem,
              );
            }),
          ],
        ),
      );
      widgets.add(expansionTile);
    }

    return widgets;
  }

  TocItem? _resolveActiveItem(List<TocItem> toc, int currentChapterIndex) {
    if (currentChapterIndex < 0 || currentChapterIndex >= flatChapters.length) {
      return null;
    }
    return flatChapters[currentChapterIndex];
  }

  bool _shouldExpand(TocItem tocItem, TocItem? activeItem) {
    if (activeItem == null || tocItem.children.isEmpty) {
      return false;
    }
    return _isInSubtree(tocItem, activeItem);
  }

  bool _isInSubtree(TocItem root, TocItem target) {
    if (identical(root, target)) {
      return true;
    }
    for (final child in root.children) {
      if (_isInSubtree(child, target)) {
        return true;
      }
    }
    return false;
  }

  /// Build a simple list tile for a chapter
  Widget _buildListTile(
    BuildContext context,
    TocItem tocItem,
    int tocItemIndex,
    bool isActive,
    bool isDark,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.only(
        left: 16.0 + (tocItem.depth * 16.0),
        right: 16.0,
      ),
      title: Text(
        tocItem.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          color: isActive
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? Colors.grey[400] : Colors.grey[700]),
          fontFamily: AppTheme.fontFamilyContent,
        ),
      ),
      onTap: () {
        widget.onTocItemSelected(tocItem);
        Navigator.of(context).pop(); // Close drawer
      },
      trailing: isActive
          ? Icon(
              Icons.circle_outlined,
              size: 8,
              color: isDark ? Colors.white : Colors.black,
            )
          : null,
    );
  }
}
