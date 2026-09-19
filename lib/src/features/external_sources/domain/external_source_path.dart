import 'external_source_item.dart';

/// One level of the folder stack inside an external source.
///
/// The root is a normal level with an empty [name] and [path], so that every
/// level of the stack — including the root — has somewhere to hold the entries
/// its listing returned.
class ExternalSourceLevel {
  const ExternalSourceLevel({
    required this.name,
    required this.path,
    required this.items,
  });

  /// Folder name, shown as the title of the level it opened. Empty at the root.
  final String name;

  /// Folder path relative to the source root. Empty at the root.
  final String path;

  /// Entries at this level, as returned by the adapter.
  final List<ExternalSourceItem> items;
}

/// The root level: the source's own base path.
const ExternalSourceLevel kSourceRootLevel = ExternalSourceLevel(
  name: '',
  path: '',
  items: [],
);

/// Where the browser currently is inside one external source.
///
/// A stack of already-fetched levels rather than a single path, because going up
/// has to restore the level that was below: re-listing the parent on every back
/// press would turn folder navigation into a network round trip per step.
///
/// [levels] is empty only before the root has been listed for the first time;
/// after that the root is always `levels.first` and the visible level is
/// `levels.last`. Whether the visible level's entries are still in flight is
/// tracked by the state that owns this path, not here: an empty [items] list is
/// a legitimate result (an empty folder) and must not be mistaken for loading.
class ExternalSourcePath {
  const ExternalSourcePath({this.levels = const []});

  final List<ExternalSourceLevel> levels;

  /// Path of the level currently shown, or `''` for the root.
  String get path => levels.isEmpty ? '' : levels.last.path;

  /// Name of the folder currently shown, or `null` at the root.
  String? get folderName {
    if (levels.isEmpty) return null;
    final name = levels.last.name;
    return name.isEmpty ? null : name;
  }

  /// Entries at the level currently shown.
  List<ExternalSourceItem> get items =>
      levels.isEmpty ? const [] : levels.last.items;

  /// Whether going up is possible.
  bool get canGoUp => levels.length > 1;

  /// `a / b` form of the whole stack, for a tooltip.
  ///
  /// The root level contributes nothing: its name is empty, and a leading
  /// separator would read as a folder that does not exist.
  String get displayPath => levels
      .map((level) => level.name)
      .where((name) => name.isNotEmpty)
      .join(' / ');

  /// This stack with the root's listing attached.
  ExternalSourcePath withRoot(List<ExternalSourceItem> items) {
    return ExternalSourcePath(
      levels: [
        ExternalSourceLevel(name: '', path: '', items: items),
        ...levels.skip(1),
      ],
    );
  }

  /// This stack with [items] as the current level's entries.
  ExternalSourcePath replacingItems(List<ExternalSourceItem> items) {
    if (levels.isEmpty) return withRoot(items);
    return ExternalSourcePath(
      levels: [...levels.take(levels.length - 1), _replaceLastItems(items)],
    );
  }

  /// This stack with [item] pushed on top.
  ExternalSourcePath pushed(ExternalSourceItem item) {
    return ExternalSourcePath(
      levels: [
        ...(levels.isEmpty ? const [kSourceRootLevel] : levels),
        ExternalSourceLevel(name: item.name, path: item.path, items: const []),
      ],
    );
  }

  /// This stack with the innermost level removed, never popping the root.
  ExternalSourcePath popped() {
    if (levels.length <= 1) {
      return ExternalSourcePath(
        levels: levels.isEmpty ? const [] : [levels.first],
      );
    }
    return ExternalSourcePath(levels: levels.sublist(0, levels.length - 1));
  }

  ExternalSourceLevel _replaceLastItems(List<ExternalSourceItem> items) {
    final last = levels.last;
    return ExternalSourceLevel(name: last.name, path: last.path, items: items);
  }
}
