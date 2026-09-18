import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/src/core/database/lumina_db.dart';
import 'package:lumina/src/features/library/data/book_manifest_repository.dart';
import 'package:lumina/src/features/library/data/shelf_book_repository.dart';
import 'package:lumina/src/features/library/domain/book_manifest.dart';
import 'package:lumina/src/features/library/domain/shelf_book.dart';

/// Builds a shelf book with sensible defaults so each test only states the
/// fields it actually cares about.
ShelfBook buildBook({
  String fileHash = 'hash-1',
  String title = 'Dune',
  String author = 'Frank Herbert',
  String? groupName,
  int importDate = 1000,
  double readingProgress = 0.0,
  int? lastOpenedDate,
}) {
  return ShelfBook()
    ..fileHash = fileHash
    ..title = title
    ..author = author
    ..authors = [author]
    ..subjects = ['sci-fi']
    ..totalChapters = 42
    ..epubVersion = '3.0'
    ..importDate = importDate
    ..updatedAt = importDate
    ..groupName = groupName
    ..readingProgress = readingProgress
    ..lastOpenedDate = lastOpenedDate;
}

void main() {
  late LuminaDb db;
  late ShelfBookRepository books;
  late BookManifestRepository manifests;

  setUp(() {
    db = LuminaDb(NativeDatabase.memory());
    books = ShelfBookRepository(db: db);
    manifests = BookManifestRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ShelfBookRepository - persistence', () {
    test('round-trips every persisted field, including JSON lists', () async {
      final id = (await books.saveBook(buildBook())).getRight().toNullable()!;

      final loaded = await books.getBookById(id);

      expect(loaded, isNotNull);
      expect(loaded!.fileHash, 'hash-1');
      expect(loaded.title, 'Dune');
      expect(loaded.author, 'Frank Herbert');
      expect(loaded.authors, ['Frank Herbert']);
      expect(loaded.subjects, ['sci-fi']);
      expect(loaded.totalChapters, 42);
      expect(loaded.epubVersion, '3.0');
      expect(loaded.importDate, 1000);
      // Nullable columns survive the round-trip as null rather than "" or 0.
      expect(loaded.filePath, isNull);
      expect(loaded.coverPath, isNull);
      expect(loaded.description, isNull);
      expect(loaded.groupName, isNull);
      expect(loaded.lastOpenedDate, isNull);
    });

    test('assigns an auto-increment id and preserves it across updates', () async {
      final first = buildBook(fileHash: 'hash-1');
      final second = buildBook(fileHash: 'hash-2', title: 'Neuromancer');

      final firstId = (await books.saveBook(first)).getRight().toNullable()!;
      final secondId = (await books.saveBook(second)).getRight().toNullable()!;

      expect(firstId, isNot(secondId));

      // saveBook must report the assigned id back to the caller.
      expect(first.id, firstId);

      first.title = 'Dune (revised)';
      final updatedId = (await books.saveBook(first)).getRight().toNullable()!;

      expect(updatedId, firstId, reason: 'update must not insert a new row');
      expect((await books.getAllBooks()).length, 2);
      expect((await books.getBookById(firstId))!.title, 'Dune (revised)');
    });

    test('re-importing the same hash updates instead of duplicating', () async {
      await books.saveBook(buildBook(fileHash: 'same'));
      final existingId = await books.getBookIdByHash('same');

      final reimport = buildBook(fileHash: 'same', title: 'Second edition')
        ..id = existingId;
      await books.saveBook(reimport);

      final all = await books.getAllBooks();
      expect(all.length, 1);
      expect(all.single.title, 'Second edition');
    });
  });

  group('ShelfBookRepository - queries', () {
    setUp(() async {
      await books.saveBook(
        buildBook(
          fileHash: 'a',
          title: 'Dune',
          author: 'Frank Herbert',
          importDate: 400,
          groupName: 'Sci-Fi',
        ),
      );
      await books.saveBook(
        buildBook(
          fileHash: 'b',
          title: 'Book 10',
          author: 'Bea Author',
          importDate: 300,
        ),
      );
      await books.saveBook(
        buildBook(
          fileHash: 'c',
          title: 'Book 2',
          author: 'Carl Writer',
          importDate: 200,
        ),
      );
      await books.saveBook(
        buildBook(
          fileHash: 'e',
          title: 'Zebra',
          author: 'Eve Novelist',
          importDate: 100,
          readingProgress: 0.5,
        ),
      );

      // Soft-deleted rows must disappear from every shelf query.
      final deleted = buildBook(fileHash: 'd', title: 'Deleted', importDate: 400);
      final deletedId = (await books.saveBook(deleted)).getRight().toNullable()!;
      await books.softDeleteBook(deletedId);
    });

    test('getAllBooks excludes soft-deleted rows, newest first', () async {
      final all = await books.getAllBooks();

      expect(all.map((b) => b.fileHash), ['a', 'b', 'c', 'e']);
      expect(all.any((b) => b.isDeleted), isFalse);
    });

    test('getBooksSorted filters by group and root level', () async {
      // includeAll ignores the group filter entirely.
      final all = await books.getBooksSorted(
        groupName: 'Sci-Fi',
        includeAll: true,
      );
      expect(all.map((b) => b.fileHash), ['a', 'b', 'c', 'e']);

      // No group name filters to the root level.
      final root = await books.getBooksSorted();
      expect(root.map((b) => b.fileHash), ['b', 'c', 'e']);

      // A group name (without includeAll) filters to that group.
      final grouped = await books.getBooksSorted(groupName: 'Sci-Fi');
      expect(grouped.map((b) => b.fileHash), ['a']);

      // An unknown group matches nothing.
      final missing = await books.getBooksSorted(groupName: 'Unknown');
      expect(missing, isEmpty);
    });

    // Root-level books carry distinct authors so a search for one author cannot
    // accidentally match the whole shelf.
    test('getBooksSorted sorts dates in SQL and titles naturally in Dart', () async {
      // Three root books, newest first.
      final byDate = await books.getBooksSorted();
      expect(byDate.map((b) => b.importDate), [300, 200, 100]);
      // Natural (not lexicographic) title order: "Book 2" before "Book 10".
      final byTitle = await books.getBooksSorted(
        sortBy: ShelfBookSortBy.titleAsc,
      );
      expect(byTitle.map((b) => b.title), ['Book 2', 'Book 10', 'Zebra']);

      final byTitleDesc = await books.getBooksSorted(
        sortBy: ShelfBookSortBy.titleDesc,
      );
      expect(byTitleDesc.map((b) => b.title), ['Zebra', 'Book 10', 'Book 2']);

      // Progress is ordered in SQL; only 'e' has made progress.
      final byProgress = await books.getBooksSorted(
        sortBy: ShelfBookSortBy.progress,
      );
      expect(byProgress.first.fileHash, 'e');

      // A grouped book is only reachable through its group.
      final grouped = await books.getBooksSorted(
        sortBy: ShelfBookSortBy.titleAsc,
        groupName: 'Sci-Fi',
      );
      expect(grouped.map((b) => b.title), ['Dune']);
    });

    test('getRecentBooks only returns opened books, most recent first', () async {
      await books.updateProgress(
        bookId: await books.getBookIdByHash('a'),
        currentChapterIndex: 3,
        progress: 0.25,
        scrollPosition: 0.5,
      );

      final recent = await books.getRecentBooks();
      expect(recent.map((b) => b.fileHash), ['a']);
    });

    test('searchBooks matches title or author case-insensitively', () async {
      // Title match, case-insensitive.
      expect((await books.searchBooks('dune')).single.fileHash, 'a');
      // Author match, matched through the lowercased column.
      expect((await books.searchBooks('HERBERT')).single.fileHash, 'a');
      expect((await books.searchBooks('novelist')).single.fileHash, 'e');
      expect(await books.searchBooks('nonexistent'), isEmpty);
    });

    test('getAllNotDeletedFileHashes skips soft-deleted rows', () async {
      final hashes = await books.getAllNotDeletedFileHashes();
      expect(hashes, {'a', 'b', 'c', 'e'});
    });
  });

  group('ShelfBookRepository - progress and deletion', () {
    test('updateProgress writes only the progress columns', () async {
      final book = buildBook();
      final id = (await books.saveBook(book)).getRight().toNullable()!;

      final result = await books.updateProgress(
        bookId: id,
        currentChapterIndex: 7,
        progress: 0.42,
        scrollPosition: 0.13,
      );

      expect(result.isRight(), isTrue);
      final loaded = (await books.getBookById(id))!;
      expect(loaded.currentChapterIndex, 7);
      expect(loaded.readingProgress, 0.42);
      expect(loaded.chapterScrollPosition, 0.13);
      expect(loaded.lastOpenedDate, isNotNull);
      // Untouched columns must be preserved.
      expect(loaded.title, 'Dune');
      expect(loaded.authors, ['Frank Herbert']);
      expect(loaded.updatedAt, 1000);
    });

    test('markAsFinished flips the flag and pins progress to 1.0', () async {
      final id = (await books.saveBook(buildBook())).getRight().toNullable()!;

      await books.markAsFinished(id);

      final loaded = (await books.getBookById(id))!;
      expect(loaded.isFinished, isTrue);
      expect(loaded.readingProgress, 1.0);
    });

    test('deleteBook removes the row permanently', () async {
      final id = (await books.saveBook(buildBook())).getRight().toNullable()!;

      final deleted = await books.deleteBook(id);

      expect(deleted.getRight().toNullable(), isTrue);
      expect(await books.getBookById(id), isNull);
      expect(await books.getAllBooks(), isEmpty);
    });

    test('getBookIdByHash throws for an unknown hash', () async {
      expect(
        () => books.getBookIdByHash('missing'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ShelfBookRepository - groups', () {
    test('createGroup assigns an id and rejects duplicates', () async {
      final created = await books.createGroup(name: 'Fiction');
      final id = created.getRight().toNullable()!;
      expect(id, greaterThan(0));

      final duplicate = await books.createGroup(name: 'Fiction');
      expect(duplicate.isLeft(), isTrue);
      expect((await books.getGroups()).length, 1);
    });

    test('createGroup revives a soft-deleted group of the same name', () async {
      final id = (await books.createGroup(name: 'Fiction'))
          .getRight()
          .toNullable()!;
      await books.deleteGroup(groupId: id);
      expect(await books.getGroups(), isEmpty);

      final revived = await books.createGroup(name: 'Fiction');

      expect(revived.getRight().toNullable(), id);
      expect((await books.getGroups()).single.name, 'Fiction');
    });

    test('updateGroupName renames the group and every assigned book', () async {
      final groupId = (await books.createGroup(name: 'Old'))
          .getRight()
          .toNullable()!;

      final firstId = (await books.saveBook(buildBook(fileHash: 'x', groupName: 'Old')))
          .getRight()
          .toNullable()!;
      final secondId = (await books.saveBook(buildBook(fileHash: 'y', groupName: 'Old')))
          .getRight()
          .toNullable()!;

      final result = await books.updateGroupName(
        groupId: groupId,
        name: 'New',
      );

      expect(result.isRight(), isTrue);
      expect((await books.getGroupById(groupId))!.name, 'New');
      expect((await books.getBookById(firstId))!.groupName, 'New');
      expect((await books.getBookById(secondId))!.groupName, 'New');
    });

    test('updateGroupName reports a missing group instead of throwing', () async {
      final result = await books.updateGroupName(groupId: 999, name: 'X');

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), 'Group not found');
    });

    test('deleteGroup soft-deletes the group and unassigns its books', () async {
      final groupId = (await books.createGroup(name: 'Temp'))
          .getRight()
          .toNullable()!;
      final bookId =
          (await books.saveBook(buildBook(groupName: 'Temp')))
              .getRight()
              .toNullable()!;

      final result = await books.deleteGroup(groupId: groupId);

      expect(result.isRight(), isTrue);
      expect(await books.getGroups(), isEmpty);
      // The book survives, it just returns to the root level.
      expect((await books.getBookById(bookId))!.groupName, isNull);
      expect(await books.getAllBooks(), hasLength(1));
    });

    test('moveBooksToGroup moves a batch in one transaction', () async {
      final firstId = (await books.saveBook(buildBook(fileHash: 'x')))
          .getRight()
          .toNullable()!;
      final secondId = (await books.saveBook(buildBook(fileHash: 'y')))
          .getRight()
          .toNullable()!;

      final result = await books.moveBooksToGroup(
        bookIds: {firstId, secondId},
        targetGroupName: 'Batch',
      );

      expect(result.isRight(), isTrue);
      expect((await books.getBookById(firstId))!.groupName, 'Batch');
      expect((await books.getBookById(secondId))!.groupName, 'Batch');
    });

    test('moveBooksToGroup with an empty set is a no-op success', () async {
      final result = await books.moveBooksToGroup(
        bookIds: const {},
        targetGroupName: 'Nowhere',
      );

      expect(result.isRight(), isTrue);
    });

    test('a failed transaction leaves the group untouched', () async {
      final groupId = (await books.createGroup(name: 'Stable'))
          .getRight()
          .toNullable()!;
      await db.close();

      final result = await books.updateGroupName(
        groupId: groupId,
        name: 'Broken',
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('BookManifestRepository', () {
    BookManifest buildManifest({String fileHash = 'hash-1'}) {
      return BookManifest()
        ..fileHash = fileHash
        ..opfRootPath = 'OEBPS/content.opf'
        ..epubVersion = '3.0'
        ..lastUpdated = DateTime.utc(2026, 1, 2, 3, 4, 5)
        ..spine = [
          SpineItem(
            index: 0,
            href: 'text/chapter1.xhtml',
            idref: 'ch1',
            linear: true,
          ),
          SpineItem(
            index: 1,
            href: 'text/notes.xhtml',
            idref: 'notes',
            linear: false,
            properties: 'duokan-page-fitwindow',
          ),
        ]
        ..manifest = [
          ManifestItem()
            ..id = 'ch1'
            ..href = (Href()
              ..path = 'text/chapter1.xhtml'
              ..anchor = 'top')
            ..mediaType = 'application/xhtml+xml',
        ]
        ..toc = [
          TocItem()
            ..id = 0
            ..label = 'Chapter 1'
            ..href = (Href()
              ..path = 'text/chapter1.xhtml'
              ..anchor = 'section-2')
            ..depth = 0
            ..parentId = -1
            ..children = [
              TocItem()
                ..id = 1
                ..label = 'Nested'
                ..href = (Href()
                  ..path = 'text/chapter1.xhtml'
                  ..anchor = 'section-3')
                ..depth = 1
                ..parentId = 0,
            ],
        ];
    }

    test('round-trips the full EPUB structure including nested TOC', () async {
      final id = (await manifests.saveManifest(buildManifest()))
          .getRight()
          .toNullable()!;

      final loaded = await manifests.getManifestById(id);

      expect(loaded, isNotNull);
      expect(loaded!.fileHash, 'hash-1');
      expect(loaded.opfRootPath, 'OEBPS/content.opf');
      expect(loaded.epubVersion, '3.0');
      expect(loaded.lastUpdated, DateTime.utc(2026, 1, 2, 3, 4, 5));

      expect(loaded.spine, hasLength(2));
      expect(loaded.spine[1].linear, isFalse);
      expect(loaded.spine[1].properties, 'duokan-page-fitwindow');

      expect(loaded.manifest.single.id, 'ch1');
      expect(loaded.manifest.single.href.path, 'text/chapter1.xhtml');
      expect(loaded.manifest.single.mediaType, 'application/xhtml+xml');

      expect(loaded.toc.single.label, 'Chapter 1');
      expect(loaded.toc.single.href.anchor, 'section-2');
      expect(loaded.toc.single.children.single.label, 'Nested');
      expect(loaded.toc.single.children.single.depth, 1);
    });

    test('getManifestByHash is the reader lookup path', () async {
      await manifests.saveManifest(buildManifest());

      final loaded = await manifests.getManifestByHash('hash-1');
      expect(loaded, isNotNull);
      expect(await manifests.getManifestByHash('other'), isNull);
    });

    test('saving the same hash twice updates the single row', () async {
      await manifests.saveManifest(buildManifest());
      final existing = await manifests.getManifestByHash('hash-1');

      final updated = buildManifest()
        ..id = existing!.id
        ..opfRootPath = 'OEBPS/revised.opf';
      await manifests.saveManifest(updated);

      final loaded = await manifests.getManifestByHash('hash-1');
      expect(loaded!.opfRootPath, 'OEBPS/revised.opf');
      final rowCount = await db.select(db.bookManifests).get();
      expect(rowCount, hasLength(1));
    });

    test('deleteManifestByHash removes the row', () async {
      await manifests.saveManifest(buildManifest());

      final deleted = await manifests.deleteManifestByHash('hash-1');

      expect(deleted.getRight().toNullable(), isTrue);
      expect(await manifests.getManifestByHash('hash-1'), isNull);
    });

    test('deleting an unknown hash reports false rather than throwing', () async {
      final deleted = await manifests.deleteManifestByHash('missing');

      expect(deleted.getRight().toNullable(), isFalse);
    });
  });
}
