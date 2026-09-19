import 'package:flutter/material.dart';

/// A single-choice selector that looks and behaves like the other inputs in a
/// form: tapping it opens the choices directly *below* the field.
///
/// It exists because [DropdownButton] cannot be told where to put its menu.
/// `_DropdownRoute.getMenuLimits` in `material/dropdown.dart` aligns the
/// *centre of the selected item* with the centre of the button, so the menu is
/// painted from the button's own top edge downwards and covers the field and
/// its floating label. The same code forces every item to
/// [kMinInteractiveDimension] (48) while the button itself collapses to
/// `_kDenseButtonHeight` (24) under `isDense`, so a dense dropdown also has
/// items twice as tall as the field they belong to.
///
/// Here the menu is rendered by [showTypeSelectorMenu] instead, anchored to the
/// field's own rectangle through a [CompositedTransformFollower]: it opens with
/// a gap below the field, matches its width, and uses the app's surface colour
/// and corner radius instead of the elevation shadow `_DropdownMenuPainter`
/// paints.
///
/// The field itself is an [InputDecorator] — exactly the decoration a
/// [TextFormField] with the same [InputDecoration] draws, including the fill,
/// the corner radius, the floating label and the `isDense` metrics — so it
/// lines up with the other inputs in a form. It is not a [FormField]: the
/// selection has no validation state of its own, and the owner persists it on
/// change.
class TypeSelectorField<T> extends StatefulWidget {
  const TypeSelectorField({
    super.key,
    required this.value,
    required this.items,
    required this.labelText,
    required this.onChanged,
    this.enabled = true,
  });

  /// The selected value; `null` renders an empty field and opens the menu with
  /// nothing selected.
  final T? value;

  /// The choices, in display order.
  final List<TypeSelectorItem<T>> items;

  /// Rendered as the [InputDecoration.labelText] of the field.
  final String labelText;

  /// Called with the newly chosen value, never while [enabled] is false.
  final ValueChanged<T> onChanged;

  final bool enabled;

  @override
  State<TypeSelectorField<T>> createState() => _TypeSelectorFieldState<T>();
}

/// One choice in a [TypeSelectorField].
class TypeSelectorItem<T> {
  const TypeSelectorItem({required this.value, required this.label});

  final T value;
  final String label;
}

class _TypeSelectorFieldState<T> extends State<TypeSelectorField<T>> {
  /// The menu route positions itself from this link while it is laid out, so no
  /// geometry has to be measured before the route is pushed and the placement
  /// stays correct if the dialog moves between the tap and the menu's layout.
  final _anchorLink = LayerLink();

  bool _menuOpen = false;

  Future<void> _toggleMenu() async {
    if (!widget.enabled) return;

    // The rest of the dialog is disabled while the connection test runs, so a
    // menu left open by an earlier tap has to close with it.
    if (_menuOpen) {
      Navigator.of(context).pop();
      return;
    }

    // The dialog does not focus anything on open, but the user may well have
    // tapped the name field first: an open keyboard would then sit on top of
    // the menu.
    FocusScope.of(context).unfocus();

    setState(() => _menuOpen = true);
    // The route dismisses itself; the field only learns the outcome here. A
    // dismissal without a result (barrier tap, back gesture) leaves the
    // selection alone.
    final selected = await showTypeSelectorMenu<T>(
      context: context,
      anchor: _anchorLink,
      items: widget.items,
      currentValue: widget.value,
    );
    if (!mounted) return;
    setState(() => _menuOpen = false);
    if (selected != null) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.items
        .where((item) => item.value == widget.value)
        .firstOrNull;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      expanded: _menuOpen,
      label: selected?.label,
      child: CompositedTransformTarget(
        link: _anchorLink,
        child: InkWell(
          onTap: widget.enabled ? _toggleMenu : null,
          // This is a click target, not a tab stop: keeping it out of the focus
          // order leaves the caret where the user put it and never pulls the
          // keyboard up.
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            isEmpty: selected == null,
            isFocused: false,
            decoration: InputDecoration(
              labelText: widget.labelText,
              isDense: true,
              enabled: widget.enabled,
              // The arrow is the one affordance that says "this opens
              // something"; the whole field is the tap target.
              suffixIcon: Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            child: Text(
              selected?.label ?? '',
              style: theme.textTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the choice menu directly below the field anchored by [anchor].
///
/// Returns the chosen value, or `null` when the menu was dismissed without a
/// choice.
Future<T?> showTypeSelectorMenu<T>({
  required BuildContext context,
  required LayerLink anchor,
  required List<TypeSelectorItem<T>> items,
  required T? currentValue,
}) {
  return Navigator.of(context).push(
    _TypeSelectorMenuRoute<T>(
      anchor: anchor,
      items: items,
      currentValue: currentValue,
    ),
  );
}

/// The menu contents: a plain surface in the app's surface colour and corner
/// radius, with no elevation and no drop shadow.
class _TypeSelectorMenu<T> extends StatelessWidget {
  const _TypeSelectorMenu({
    required this.items,
    required this.currentValue,
    required this.onSelected,
  });

  final List<TypeSelectorItem<T>> items;
  final T? currentValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item.value == currentValue;

          return InkWell(
            onTap: () {
              // Confirms the tap before the menu closes, the way the Material
              // popup menus do.
              Feedback.forTap(context);
              onSelected(item.value);
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? cs.primary : cs.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A modal route showing [_TypeSelectorMenu] below its anchor field.
class _TypeSelectorMenuRoute<T> extends PopupRoute<T> {
  _TypeSelectorMenuRoute({
    required this.anchor,
    required this.items,
    required this.currentValue,
  });

  final LayerLink anchor;
  final List<TypeSelectorItem<T>> items;
  final T? currentValue;

  @override
  Color? get barrierColor => null;

  /// Turns on the tap-outside-to-dismiss barrier and the back gesture.
  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 140);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return SafeArea(
      child: CompositedTransformFollower(
        link: anchor,
        // The layout delegate then works in a coordinate system whose origin is
        // the field's bottom-left corner.
        targetAnchor: Alignment.bottomLeft,
        child: CustomSingleChildLayout(
          delegate: _TypeSelectorMenuLayout(anchor: anchor),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            alwaysIncludeSemantics: true,
            child: Builder(
              builder: (context) => _TypeSelectorMenu<T>(
                items: items,
                currentValue: currentValue,
                onSelected: (value) => Navigator.of(context).pop(value),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sizes the menu to its anchor field and keeps it on screen.
///
/// The delegate is laid out as a follower of the field, so its origin is the
/// field's bottom-left corner and its width is the field's width: "directly
/// below the field" is `Offset(0, _gap)`, and the field's top edge is at
/// `-_fieldSize().height`.
class _TypeSelectorMenuLayout extends SingleChildLayoutDelegate {
  const _TypeSelectorMenuLayout({required this.anchor});

  /// The gap between the field and the menu. Large enough that the menu reads
  /// as a separate surface rather than as part of the field.
  static const double _gap = 6;

  /// The margin kept clear above and below the menu so it stays dismissible.
  static const double _screenMargin = 8;

  /// The smallest useful menu; it scrolls when the screen cannot give it more.
  static const double _minimumMenuHeight = 112;

  final LayerLink anchor;

  /// The anchor field's size, or [Size.zero] before it has painted.
  ///
  /// [LayerLink.leaderSize] is the field's own size in the follower's
  /// coordinate system, written by the leader's paint pass.
  Size _fieldSize() => anchor.leaderSize ?? Size.zero;

  @override
  Size getSize(BoxConstraints constraints) =>
      Size(_fieldSize().width, constraints.maxHeight);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = _fieldSize().width;
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: (constraints.maxHeight - 2 * _screenMargin).clamp(
        _minimumMenuHeight,
        constraints.maxHeight,
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final fieldHeight = _fieldSize().height;

    // Below the field, unless the menu would run off the bottom: then it is
    // flipped above, which keeps it fully visible without ever covering the
    // field itself.
    final double top = _gap + childSize.height <= size.height - _screenMargin
        ? _gap
        : -fieldHeight - _gap - childSize.height;

    final maxTop = (size.height - childSize.height - _screenMargin).clamp(
      0.0,
      size.height,
    );
    return Offset(0, top.clamp(0.0, maxTop));
  }

  @override
  bool shouldRelayout(_TypeSelectorMenuLayout oldDelegate) => false;
}
