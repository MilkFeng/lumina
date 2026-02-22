import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../domain/shelf_book.dart';
import '../domain/shelf_group.dart';
import '../data/shelf_book_repository.dart';
import '../data/repositories/shelf_book_repository_provider.dart';
import '../data/services/epub_import_service_provider.dart';
import '../data/services/epub_import_service.dart';

part 'bookshelf_notifier.g.dart';

/// How densely books are shown in the grid.
enum ViewMode { compact, relaxed }

/// State for bookshelf view (sorting, grouping, selection)
class BookshelfState {
  final List<ShelfBook> books;
  final ShelfBookSortBy sortBy;
  final ViewMode viewMode;
  final int? currentGroupId; // Navigation: which folder we're inside
  final int?
  filterGroupId; // Filter: show books from specific group (null = all)
  final Set<int> selectedBookIds;
  final Set<int> selectedGroupIds;
  final bool isSelectionMode;
  final List<ShelfGroup> availableGroups;
  final Map<int?, List<ShelfBook>> cachedBooks;
  final List<int?> cacheOrder;

  BookshelfState.bookshelfState({
    required this.books,
    this.sortBy = ShelfBookSortBy.recentlyAdded,
    this.viewMode = ViewMode.relaxed,
    this.currentGroupId,
    this.filterGroupId,
    this.selectedBookIds = const {},
    this.selectedGroupIds = const {},
    this.isSelectionMode = false,
    this.availableGroups = const [],
    this.cachedBooks = const {},
    this.cacheOrder = const [],
  });

  BookshelfState copyWith({
    List<ShelfBook>? books,
    ShelfBookSortBy? sortBy,
    ViewMode? viewMode,
    int? currentGroupId,
    int? filterGroupId,
    Set<int>? selectedBookIds,
    Set<int>? selectedGroupIds,
    bool? isSelectionMode,
    List<ShelfGroup>? availableGroups,
    Map<int?, List<ShelfBook>>? cachedBooks,
    List<int?>? cacheOrder,
    bool clearGroup = false,
    bool clearFilter = false,
  }) {
    return BookshelfState.bookshelfState(
      books: books ?? this.books,
      sortBy: sortBy ?? this.sortBy,
      viewMode: viewMode ?? this.viewMode,
      currentGroupId: clearGroup
          ? null
          : (currentGroupId ?? this.currentGroupId),
      filterGroupId: clearFilter ? null : (filterGroupId ?? this.filterGroupId),
      selectedBookIds: selectedBookIds ?? this.selectedBookIds,
      selectedGroupIds: selectedGroupIds ?? this.selectedGroupIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      availableGroups: availableGroups ?? this.availableGroups,
      cachedBooks: cachedBooks ?? this.cachedBooks,
      cacheOrder: cacheOrder ?? this.cacheOrder,
    );
  }

  int get selectedCount => selectedBookIds.length + selectedGroupIds.length;
  bool get hasSelection => selectedCount > 0;
}

/// Notifier for managing bookshelf operations with dependency injection
@riverpod
class BookshelfNotifier extends _$BookshelfNotifier {
  static const int _maxCachedTabs = 8;
  static const String _sortOrderKey = 'bookshelf_sort_order';
  static const String _viewModeKey = 'bookshelf_view_mode';

  // Cached SharedPreferences instance, set during build.
  SharedPreferences? _prefs;

  // Access repositories via providers (lazy initialization)
  ShelfBookRepository get _repository => ref.read(shelfBookRepositoryProvider);
  EpubImportService get _importService => ref.read(epubImportServiceProvider);

  @override
  Future<BookshelfState> build() async {
    // Load SharedPreferences and restore the previously saved sort order.
    _prefs = await ref.read(sharedPreferencesProvider.future);
    final savedSortName = _prefs?.getString(_sortOrderKey);
    final savedSort = savedSortName != null
        ? ShelfBookSortBy.values.firstWhere(
            (e) => e.name == savedSortName,
            orElse: () => ShelfBookSortBy.recentlyAdded,
          )
        : ShelfBookSortBy.recentlyAdded;
    final savedViewModeName = _prefs?.getString(_viewModeKey);
    final savedViewMode = savedViewModeName != null
        ? ViewMode.values.firstWhere(
            (e) => e.name == savedViewModeName,
            orElse: () => ViewMode.relaxed,
          )
        : ViewMode.relaxed;
    return await _loadBooks(sortBy: savedSort, viewMode: savedViewMode);
  }

  /// Load folders + books with current filters
  Future<BookshelfState> _loadBooks({
    ShelfBookSortBy? sortBy,
    ViewMode? viewMode,
    int? groupId,
    int? filterGroupId,
    bool clearGroup = false,
    bool clearFilter = false,
  }) async {
    final currentState =
        state.valueOrNull ?? BookshelfState.bookshelfState(books: []);

    final actualSortBy = sortBy ?? currentState.sortBy;
    final actualViewMode = viewMode ?? currentState.viewMode;
    final actualGroupId = clearGroup
        ? null
        : (groupId ?? currentState.currentGroupId);
    final actualFilterGroupId = clearFilter
        ? null
        : (filterGroupId ?? currentState.filterGroupId);

    // Get group name for filtering
    String? filterGroupName;
    if (actualFilterGroupId != null && actualFilterGroupId != -1) {
      final group = await _repository.getGroupById(actualFilterGroupId);
      filterGroupName = group?.name;
    }

    final shouldFilterByGroup =
        actualFilterGroupId != null || actualGroupId != null;
    final books = await _repository.getBooksSorted(
      sortBy: actualSortBy,
      groupName: actualFilterGroupId == -1 ? null : filterGroupName,
      includeAll: !shouldFilterByGroup,
    );
    final allGroups = await _repository.getAllGroups();
    final updatedCache = Map<int?, List<ShelfBook>>.from(
      currentState.cachedBooks,
    );
    final cacheKey = shouldFilterByGroup ? actualFilterGroupId : null;
    updatedCache[cacheKey] = books;
    final updatedOrder = _touchCacheKey(currentState.cacheOrder, cacheKey);
    _trimCache(updatedCache, updatedOrder);

    return BookshelfState.bookshelfState(
      books: books,
      sortBy: actualSortBy,
      viewMode: actualViewMode,
      currentGroupId: actualGroupId,
      filterGroupId: actualFilterGroupId,
      availableGroups: allGroups,
      selectedBookIds: currentState.selectedBookIds,
      selectedGroupIds: currentState.selectedGroupIds,
      isSelectionMode: currentState.isSelectionMode,
      cachedBooks: updatedCache,
      cacheOrder: updatedOrder,
    );
  }

  /// Change sort order and persist the selection.
  Future<void> changeSortOrder(ShelfBookSortBy sortBy) async {
    // Persist asynchronously – fire and forget, no need to await.
    _prefs?.setString(_sortOrderKey, sortBy.name);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadBooks(sortBy: sortBy));
  }

  /// Change view mode and persist the selection.
  void changeViewMode(ViewMode mode) {
    _prefs?.setString(_viewModeKey, mode.name);
    final currentState = state.valueOrNull;
    if (currentState == null) return;
    state = AsyncValue.data(currentState.copyWith(viewMode: mode));
  }

  /// Filter by group (null = show all books)
  Future<void> filterByGroup(int? groupId) async {
    state = await AsyncValue.guard(
      () => _loadBooks(filterGroupId: groupId, clearFilter: groupId == null),
    );
  }

  /// Enter a group (folder)
  Future<void> enterGroup(int groupId) async {
    state = const AsyncValue.loading();
    // Clear filter when navigating into a group
    state = await AsyncValue.guard(
      () => _loadBooks(groupId: groupId, clearFilter: true),
    );
  }

  /// Go back to root (simplified - no nesting)
  Future<void> goBack() async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.currentGroupId == null) {
      return;
    }

    state = const AsyncValue.loading();
    // Clear group and filter when navigating back
    state = await AsyncValue.guard(
      () => _loadBooks(groupId: null, clearFilter: true),
    );
  }

  /// Create a new group (flat structure, no nesting)
  Future<int?> createGroup(String name) async {
    final result = await _repository.createGroup(name: name);
    if (result.isLeft()) {
      return null;
    }

    await refresh();

    final newGroupId = result.getRight().toNullable()!;
    return newGroupId;
  }

  /// Toggle selection mode
  void toggleSelectionMode() {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    if (currentState.isSelectionMode) {
      // Exit selection mode and clear selections
      state = AsyncValue.data(
        currentState.copyWith(
          isSelectionMode: false,
          selectedBookIds: {},
          selectedGroupIds: {},
        ),
      );
    } else {
      // Enter selection mode
      state = AsyncValue.data(currentState.copyWith(isSelectionMode: true));
    }
  }

  /// Toggle item selection
  void toggleItemSelection(ShelfBook book) {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.isSelectionMode) return;

    final newSelection = Set<int>.from(currentState.selectedBookIds);
    if (newSelection.contains(book.id)) {
      newSelection.remove(book.id);
    } else {
      newSelection.add(book.id);
    }
    state = AsyncValue.data(
      currentState.copyWith(selectedBookIds: newSelection),
    );
  }

  /// Select all books
  void selectAll() {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final bookIds = <int>{};
    final groupIds = <int>{};
    for (final book in currentState.books) {
      bookIds.add(book.id);
    }
    state = AsyncValue.data(
      currentState.copyWith(
        selectedBookIds: bookIds,
        selectedGroupIds: groupIds,
        isSelectionMode: true,
      ),
    );
  }

  /// Clear selection
  void clearSelection() {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data(
      currentState.copyWith(selectedBookIds: {}, selectedGroupIds: {}),
    );
  }

  /// Move selected items to a target group (null = root)
  Future<bool> moveSelectedItems(int? targetGroupId) async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasSelection) return false;

    try {
      // Get target group name
      String? targetGroupName;
      if (targetGroupId != null) {
        final group = await _repository.getGroupById(targetGroupId);
        targetGroupName = group?.name;
      }

      if (currentState.selectedBookIds.isNotEmpty) {
        await _repository.moveBooksToGroup(
          bookIds: currentState.selectedBookIds,
          targetGroupName: targetGroupName,
        );
      }

      // Note: Group moving is removed (flat structure)
      // Groups selected will simply be ignored

      // Reload items and clear selection
      state = const AsyncValue.loading();
      final newState = await _loadBooks();
      state = AsyncValue.data(
        newState.copyWith(
          selectedBookIds: {},
          selectedGroupIds: {},
          isSelectionMode: false,
        ),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete selected books
  Future<bool> deleteSelected() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasSelection) return false;

    try {
      for (final bookId in currentState.selectedBookIds) {
        final book = await _repository.getBookById(bookId);
        if (book == null) {
          return false;
        }

        // Delete using import service (handles files + database)
        final deleteResult = await _importService.deleteBook(book);
        if (deleteResult.isLeft()) {
          return false;
        }
      }

      // Reload items and clear selection
      state = const AsyncValue.loading();
      final newState = await _loadBooks();
      state = AsyncValue.data(
        newState.copyWith(
          selectedBookIds: {},
          selectedGroupIds: {},
          isSelectionMode: false,
        ),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Refresh books
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadBooks());
  }

  Future<bool> reloadQuietly() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return true;

    try {
      // Use filterGroupId if set, otherwise use currentGroupId
      final isUncategorized = currentState.filterGroupId == -1;
      final effectiveGroupId = isUncategorized
          ? null
          : (currentState.filterGroupId ?? currentState.currentGroupId);

      // Get group name for filtering
      String? filterGroupName;
      if (effectiveGroupId != null) {
        final group = await _repository.getGroupById(effectiveGroupId);
        filterGroupName = group?.name;
      }

      final books = await _repository.getBooksSorted(
        sortBy: currentState.sortBy,
        groupName: filterGroupName,
        includeAll: effectiveGroupId == null && !isUncategorized,
      );
      final allGroups = await _repository.getAllGroups();
      final updatedCache = Map<int?, List<ShelfBook>>.from(
        currentState.cachedBooks,
      );
      final cacheKey = isUncategorized ? -1 : effectiveGroupId;
      updatedCache[cacheKey] = books;
      final updatedOrder = _touchCacheKey(currentState.cacheOrder, cacheKey);
      _trimCache(updatedCache, updatedOrder);

      state = AsyncValue.data(
        currentState.copyWith(
          books: books,
          availableGroups: allGroups,
          cachedBooks: updatedCache,
          cacheOrder: updatedOrder,
        ),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> renameGroup(int groupId, String name) async {
    if (name.trim().isEmpty) return false;
    try {
      final result = await _repository.updateGroupName(
        groupId: groupId,
        name: name.trim(),
      );
      if (result.isRight()) {
        state = await AsyncValue.guard(() => _loadBooks());
      }
      return result.isRight();
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteGroup(int groupId) async {
    try {
      final result = await _repository.deleteGroup(groupId: groupId);
      if (result.isLeft()) return false;

      final currentState = state.valueOrNull;
      final clearFilter = currentState?.filterGroupId == groupId;
      final clearGroup = currentState?.currentGroupId == groupId;
      final newState = await _loadBooks(
        clearFilter: clearFilter,
        clearGroup: clearGroup,
      );
      final updatedCache = Map<int?, List<ShelfBook>>.from(newState.cachedBooks)
        ..remove(groupId);
      final updatedOrder = List<int?>.from(newState.cacheOrder)
        ..remove(groupId);
      state = AsyncValue.data(
        newState.copyWith(cachedBooks: updatedCache, cacheOrder: updatedOrder),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  List<int?> _touchCacheKey(List<int?> order, int? key) {
    final updated = List<int?>.from(order);
    updated.remove(key);
    updated.add(key);
    return updated;
  }

  void _trimCache(Map<int?, List<ShelfBook>> cache, List<int?> order) {
    while (order.length > _maxCachedTabs) {
      final removedKey = order.removeAt(0);
      cache.remove(removedKey);
    }
  }
}
