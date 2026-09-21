import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../application/bookshelf_notifier.dart';
import '../../data/shelf_book_repository.dart';

/// The library's view-mode and sort action: the "tune" icon in the app bar,
/// with a Material menu of the available choices hanging off it.
///
/// The panel is not left to the menu's own alignment. It is a fixed width and is
/// placed on open so that its top-right corner sits on the icon's top-right
/// corner rather than against the screen edge, and it is drawn the way the rest
/// of the app is — a flat surface with the app's corner radius and a hairline
/// outline instead of a shadow. It opens and closes with the Material menu
/// animation.
///
/// The menu opens on the press itself — not on the release — and the gesture
/// stays with the finger: dragging walks the highlight from entry to entry and
/// releasing over one chooses it, which is how Material menus have always
/// behaved.
///
/// Nothing about the press is timed, because the panel is drawn over the button:
/// where a release lands already says what it means. Releasing over an entry
/// chooses it and the menu goes with it; releasing on the panel — or on the icon,
/// whose corner the panel's corner sits on — leaves the menu up for a second tap;
/// and releasing anywhere else dismisses the menu, as does pressing off the panel.
///
/// A press off the panel does that and nothing else: it takes the menu down, and
/// whatever it landed on — a book, a tab, the shelf — is left alone. An open menu
/// is the only thing on screen a press is talking to, so the first press after it
/// is spent dismissing it rather than being spent on both at once.
///
/// The gesture is tracked here rather than by the menu because the panel is
/// drawn in an overlay above the icon: the listener keeps receiving the pointer
/// after the panel has appeared, and the entries are located through their own
/// keys as the finger moves over them. The press is also claimed from the
/// bookshelf's scroll view, which would otherwise scroll under the menu and
/// take the menu down with it. The panel is hung over the icon rather than
/// below it, so a press only becomes a choice once the finger has left the
/// button.
class StyleMenuButton extends StatefulWidget {
  const StyleMenuButton({
    required this.currentSort,
    required this.currentViewMode,
    required this.onSortSelected,
    required this.onViewModeSelected,
    super.key,
  });

  /// Sort order in effect, marked by the menu.
  final ShelfBookSortBy currentSort;

  /// View mode in effect, marked by the menu.
  final ViewMode currentViewMode;

  final ValueChanged<ShelfBookSortBy> onSortSelected;
  final ValueChanged<ViewMode> onViewModeSelected;

  @override
  State<StyleMenuButton> createState() => _StyleMenuButtonState();
}

/// The entries the menu lists, in the order they appear.
enum _StyleMenuEntryId {
  viewCompact,
  viewRelaxed,
  sortRecentlyAdded,
  sortRecentlyRead,
  sortTitleAsc,
  sortTitleDesc,
  sortAuthorAsc,
  sortAuthorDesc,
  sortProgress,
}

class _StyleMenuButtonState extends State<StyleMenuButton> {
  /// The width of the panel, and the number the panel's placement is computed
  /// from: the menu has to know how wide it is before it is laid out in order to
  /// put its top-right corner on the icon's.
  static const double _kMenuWidth = 220;

  /// The padding between the panel's edge and its entries. Material's own menu
  /// padding is the same 8, but it is set here so that the panel's bounds — the
  /// bounds a release is tested against — are known rather than assumed.
  static const double _kMenuPadding = 8;

  /// View-mode entries, listed above the divider.
  static const List<_StyleMenuEntryId> _viewEntries = [
    _StyleMenuEntryId.viewCompact,
    _StyleMenuEntryId.viewRelaxed,
  ];

  /// Sort entries, listed below the divider.
  static const List<_StyleMenuEntryId> _sortEntries = [
    _StyleMenuEntryId.sortRecentlyAdded,
    _StyleMenuEntryId.sortRecentlyRead,
    _StyleMenuEntryId.sortTitleAsc,
    _StyleMenuEntryId.sortTitleDesc,
    _StyleMenuEntryId.sortAuthorAsc,
    _StyleMenuEntryId.sortAuthorDesc,
    _StyleMenuEntryId.sortProgress,
  ];

  final MenuController _menuController = MenuController();

  /// One key per entry, used to find the entry the finger is over.
  final Map<_StyleMenuEntryId, GlobalKey> _entryKeys = {
    for (final entry in _StyleMenuEntryId.values) entry: GlobalKey(),
  };

  /// The button: the menu's position is measured from its top-left, and a press
  /// that has not left it counts as not having reached the menu.
  final GlobalKey _anchorKey = GlobalKey();

  /// The glyph inside the button, which is what the panel is lined up against:
  /// the button is a touch target with the glyph centred inside it, and the two
  /// corners are not the same corner.
  final GlobalKey _iconKey = GlobalKey();

  /// Pointer the current press belongs to, while it is still down. Only a press
  /// that starts on the icon can choose an entry: a press on the panel belongs
  /// to the panel.
  int? _pressedPointer;

  /// Entry the finger is over, or null while it is anywhere else.
  _StyleMenuEntryId? _draggedEntry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MenuAnchor(
      controller: _menuController,
      // Material menus animate both ways: the panel grows out of its top edge
      // while its entries fade in one after another, and it shrinks back the
      // same way when it closes.
      animated: true,
      // The press that dismisses the menu stops at the menu: the shelf under the
      // panel is left out of it, so tapping past an open menu closes the menu
      // and opens nothing. This is what declares the press handled — the menu
      // closes as the press arrives and the press goes no further — and it
      // covers dragging as well as tapping, so a press that sets out to scroll
      // the shelf first sends the menu away.
      consumeOutsideTap: true,
      // Without this the panel is left free to shrink back to the width of its
      // own labels, and the fixed width the placement below is computed from
      // would not hold.
      crossAxisUnconstrained: false,
      style: MenuStyle(
        // A fixed width is what lets the panel's top-right corner be put on the
        // icon's: the position passed on open is computed from it.
        fixedSize: const WidgetStatePropertyAll<Size?>(
          Size.fromWidth(_kMenuWidth),
        ),
        padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
          EdgeInsets.symmetric(vertical: _kMenuPadding),
        ),
        // The app's surfaces are flat and unshadowed, so the menu is separated
        // from the shelf underneath by a hairline rather than by elevation, and
        // it takes the same corner radius the rest of the app uses.
        elevation: const WidgetStatePropertyAll<double>(0),
        shape: WidgetStatePropertyAll<OutlinedBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        side: WidgetStatePropertyAll<BorderSide>(
          BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      // The entries outlive the panel they are drawn in, so a highlight left
      // over from a press that ended some other way is cleared as the menu
      // comes back. The menu also closes on its own — when the anchor scrolls
      // out of view, say — and that arrives from a layout phase, where there is
      // nothing left to repaint and rebuilding would be illegal.
      onOpen: () => _setDraggedEntry(null),
      menuChildren: [
        for (final entry in _viewEntries) _buildEntry(context, entry),
        // The two groups the sheet used to label: the view mode on top, the
        // sort order below.
        const Divider(height: 17),
        for (final entry in _sortEntries) _buildEntry(context, entry),
      ],
      builder: (context, controller, child) => RawGestureDetector(
        // The icon lives inside the bookshelf's scroll view, and a finger
        // sliding off the button would otherwise be claimed by that scroll view:
        // the shelf would scroll under the menu, and an open menu closes the
        // moment an ancestor scrollable starts scrolling. Settling the arena on
        // the press itself keeps the drag with the menu.
        gestures: <Type, GestureRecognizerFactory>{
          EagerGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                EagerGestureRecognizer.new,
                (instance) {},
              ),
        },
        child: Listener(
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          child: IconButton(
            key: _anchorKey,
            icon: Icon(Icons.tune_outlined, key: _iconKey),
            onPressed: _handleButtonPressed,
          ),
        ),
      ),
    );
  }

  Widget _buildEntry(BuildContext context, _StyleMenuEntryId id) {
    final entry = _entryFor(context, id);

    return SizedBox(
      // The panel is a fixed width, so each entry is stretched across it: the
      // highlight then covers the row rather than stopping at the label, and
      // the check marks line up along the right edge.
      width: double.infinity,
      child: MenuItemButton(
        key: _entryKeys[id],
        // A menu item's highlight is an ink feature driven by the pointer events
        // the item itself receives, and a finger dragging across the panel never
        // touched this item — so the highlight is painted as the item's own
        // background instead, in the color Material gives a pressed item.
        style: _draggedEntry == id
            ? ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color?>(
                  Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              )
            : null,
        leadingIcon: entry.mirrorIcon
            ? Transform.scale(scaleX: -1, child: Icon(entry.icon))
            : Icon(entry.icon),
        trailingIcon: entry.isSelected ? const Icon(Icons.done) : null,
        onPressed: entry.onSelected,
        child: Text(entry.label),
      ),
    );
  }

  /// Opens the menu with its top-right corner on the icon's own top-right
  /// corner.
  ///
  /// The position the menu takes is measured from the button, but the corner
  /// that belongs on the icon is the glyph's rather than the button's: the
  /// button is a 48px touch target with the glyph centred inside it, so lining
  /// the panel up with the target leaves it hanging out past the icon.
  ///
  /// If either has not been laid out yet the menu is opened without a position,
  /// which falls back to the alignment Material would use on its own.
  void _openMenu() {
    final Rect? anchor = _rectOf(_anchorKey);
    final Rect? icon = _rectOf(_iconKey);
    if (anchor == null || icon == null) {
      _menuController.open();
      return;
    }

    // The glyph's top-right corner, in the coordinate space the menu's position
    // is measured in — the button's top-left.
    final Offset corner = icon.topRight - anchor.topLeft;
    _menuController.open(position: Offset(corner.dx - _kMenuWidth, corner.dy));
  }

  /// Opens the menu on the press, so that the finger which opened it can carry
  /// straight on onto an entry and choose it without ever lifting.
  void _handlePointerDown(PointerDownEvent event) {
    _pressedPointer = event.pointer;
    if (_menuController.isOpen) {
      // A press on the sliver of button the panel does not cover, while the
      // menu is already up: there is nothing to open, and the release will not
      // dismiss it either.
      return;
    }

    _openMenu();
  }

  /// Walks the highlight to the entry the finger has reached.
  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _pressedPointer) {
      return;
    }

    final entry = _entryAt(event.position);
    if (entry == _draggedEntry) {
      return;
    }
    // A tick per entry the finger crosses: the panel is under the finger rather
    // than in front of the eyes, so the highlight has to be felt as well.
    _setDraggedEntry(entry);
  }

  /// Chooses the entry the finger is lifted on, or dismisses the menu if the
  /// finger came up off it.
  ///
  /// The icon counts as part of the menu, because the panel's corner is the
  /// icon's corner: a press that goes straight back up — a tap on the icon —
  /// leaves the menu standing, ready to be used.
  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _pressedPointer) {
      return;
    }
    _pressedPointer = null;

    final entry = _entryAt(event.position);
    _setDraggedEntry(null);

    if (entry != null) {
      _menuController.close();
      _entryFor(context, entry).onSelected();
      return;
    }

    if (!_isOverPanel(event.position) && !_isOnIcon(event.position)) {
      _menuController.close();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _pressedPointer) {
      return;
    }
    _pressedPointer = null;
    _setDraggedEntry(null);
  }

  /// The button's own activation, which is the path a keyboard or a screen
  /// reader takes. A pointer press never comes through here: the eager
  /// recognizer claims it, and the pointer callbacks above decide what it means.
  void _handleButtonPressed() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _openMenu();
    }
  }

  void _setDraggedEntry(_StyleMenuEntryId? entry) {
    if (entry == _draggedEntry) {
      return;
    }
    // A pointer route outlives the widget when the app bar is rebuilt mid
    // press; there is no highlight left to move by then.
    if (!mounted) {
      return;
    }
    setState(() => _draggedEntry = entry);
  }

  /// Whether [globalPosition] is still on the button, which the panel is drawn
  /// over. A press there has not set out for the menu yet, so it chooses
  /// nothing: without this an unsteady tap just below the icon would land on
  /// whichever entry happens to lie under it. The button, not the icon — the
  /// touch target is wider than the glyph it carries.
  bool _isOnButton(Offset globalPosition) {
    final Rect? anchor = _rectOf(_anchorKey);
    return anchor != null && anchor.contains(globalPosition);
  }

  /// Whether [globalPosition] is on the icon itself, which the panel's corner
  /// sits on. The icon is part of the menu: its own corner and the panel's are
  /// the same corner.
  bool _isOnIcon(Offset globalPosition) {
    final Rect? icon = _rectOf(_iconKey);
    return icon != null && icon.contains(globalPosition);
  }

  /// Whether [globalPosition] is over the panel.
  ///
  /// Every entry is stretched across the panel and they sit next to each other,
  /// so one of them gives the panel's width and the first and last give its
  /// height; the panel's own padding is what the entries are inset by, and is
  /// set here rather than left to the theme so that these bounds are known.
  bool _isOverPanel(Offset globalPosition) {
    final Rect? top = _rectOf(_entryKeys[_viewEntries.first]!);
    final Rect? bottom = _rectOf(_entryKeys[_sortEntries.last]!);
    if (top == null || bottom == null) {
      return false;
    }
    return Rect.fromLTRB(
      top.left,
      top.top - _kMenuPadding,
      top.right,
      bottom.bottom + _kMenuPadding,
    ).contains(globalPosition);
  }

  /// The entry [globalPosition] is over, or null when the finger is on none.
  ///
  /// An entry is only as wide as its own label, so the finger is tested against
  /// each entry's own height but against the widest of them horizontally —
  /// which is the width of the panel. A finger that is still on the button
  /// counts as on none of them: the panel covers the button, so it lies over the
  /// first entries geometrically without having reached the menu.
  _StyleMenuEntryId? _entryAt(Offset globalPosition) {
    if (_isOnButton(globalPosition)) {
      return null;
    }

    Rect? panel;
    final List<MapEntry<_StyleMenuEntryId, Rect>> rows = [];

    for (final id in _StyleMenuEntryId.values) {
      final Rect? row = _rectOf(_entryKeys[id]!);
      if (row == null) {
        continue;
      }
      rows.add(MapEntry<_StyleMenuEntryId, Rect>(id, row));
      panel = panel?.expandToInclude(row) ?? row;
    }

    if (panel == null || !panel.contains(globalPosition)) {
      return null;
    }

    for (final row in rows) {
      final Rect bounds = row.value;
      if (globalPosition.dy >= bounds.top &&
          globalPosition.dy < bounds.bottom) {
        return row.key;
      }
    }
    return null;
  }

  /// The on-screen rectangle of the widget behind [key], or null while it is
  /// not laid out — which is what the entries of a closed menu are.
  Rect? _rectOf(GlobalKey key) {
    final RenderObject? renderObject = key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  /// The row an entry stands for: what it shows, and what choosing it does.
  _StyleMenuEntry _entryFor(BuildContext context, _StyleMenuEntryId id) {
    final l10n = AppLocalizations.of(context)!;

    return switch (id) {
      _StyleMenuEntryId.viewCompact => _StyleMenuEntry(
        label: l10n.viewModeCompact,
        icon: Icons.grid_on_outlined,
        isSelected: widget.currentViewMode == ViewMode.compact,
        onSelected: () => widget.onViewModeSelected(ViewMode.compact),
      ),
      _StyleMenuEntryId.viewRelaxed => _StyleMenuEntry(
        label: l10n.viewModeRelaxed,
        icon: Icons.grid_view_outlined,
        isSelected: widget.currentViewMode == ViewMode.relaxed,
        onSelected: () => widget.onViewModeSelected(ViewMode.relaxed),
      ),
      _StyleMenuEntryId.sortRecentlyAdded => _StyleMenuEntry(
        label: l10n.recentlyAdded,
        icon: Icons.access_time_outlined,
        isSelected: widget.currentSort == ShelfBookSortBy.recentlyAdded,
        onSelected: () => widget.onSortSelected(ShelfBookSortBy.recentlyAdded),
      ),
      _StyleMenuEntryId.sortRecentlyRead => _StyleMenuEntry(
        label: l10n.recentlyRead,
        icon: Icons.auto_stories_outlined,
        isSelected: widget.currentSort == ShelfBookSortBy.recentlyRead,
        onSelected: () => widget.onSortSelected(ShelfBookSortBy.recentlyRead),
      ),
      _StyleMenuEntryId.sortTitleAsc => _StyleMenuEntry(
        label: l10n.titleAZ,
        icon: Icons.sort_by_alpha_outlined,
        isSelected: widget.currentSort == ShelfBookSortBy.titleAsc,
        onSelected: () => widget.onSortSelected(ShelfBookSortBy.titleAsc),
      ),
      _StyleMenuEntryId.sortTitleDesc => _StyleMenuEntry(
        label: l10n.titleZA,
        icon: Icons.sort_by_alpha_outlined,
        isSelected: widget.currentSort == ShelfBookSortBy.titleDesc,
        onSelected: () => widget.onSortSelected(ShelfBookSortBy.titleDesc),
        mirrorIcon: true,
      ),
      _StyleMenuEntryId.sortAuthorAsc => _StyleMenuEntry(
        label: l10n.authorAZ,
        icon: Icons.person_outline_outlined,
        isSelected: widget.currentSort == ShelfBookSortBy.authorAsc,
        onSelected: () => widget.onSortSelected(ShelfBookSortBy.authorAsc),
      ),
      _StyleMenuEntryId.sortAuthorDesc => _StyleMenuEntry(
        label: l10n.authorZA,
        icon: Icons.person_outline_outlined,
        isSelected: widget.currentSort == ShelfBookSortBy.authorDesc,
        onSelected: () => widget.onSortSelected(ShelfBookSortBy.authorDesc),
        mirrorIcon: true,
      ),
      _StyleMenuEntryId.sortProgress => _StyleMenuEntry(
        label: l10n.readingProgress,
        icon: Icons.show_chart_outlined,
        isSelected: widget.currentSort == ShelfBookSortBy.progress,
        onSelected: () => widget.onSortSelected(ShelfBookSortBy.progress),
      ),
    };
  }
}

/// One row of the menu: what it shows and what choosing it does.
class _StyleMenuEntry {
  const _StyleMenuEntry({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
    this.mirrorIcon = false,
  });

  final String label;
  final IconData icon;

  /// Whether this entry is the choice in effect, which is what the check mark
  /// in the menu marks.
  final bool isSelected;

  final VoidCallback onSelected;

  /// Horizontally mirrors the icon (used for the Z-A variants).
  final bool mirrorIcon;
}
