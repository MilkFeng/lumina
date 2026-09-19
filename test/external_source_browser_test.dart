import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/src/features/external_sources/application/external_source_import_notifier.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_failure.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_item.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_path.dart';

/// Unit tests for the external source browser's navigation model and the
/// import pipeline's pure helpers.
///
/// The browser's network and database halves need a provider container and a
/// live Isar; what is covered here is the bookkeeping that decides which folder
/// is shown and which files are importable, which is where the bugs were.
void main() {
  ExternalSourceItem file(String name, [String? path]) =>
      ExternalSourceItem(name: name, path: path ?? name, isDirectory: false);

  ExternalSourceItem folder(String name) =>
      ExternalSourceItem(name: name, path: name, isDirectory: true);

  group('ExternalSourcePath', () {
    test('starts empty, at the root, with nothing to go back to', () {
      const path = ExternalSourcePath();

      expect(path.levels, isEmpty);
      expect(path.path, '');
      expect(path.items, isEmpty);
      expect(path.canGoUp, isFalse);
      expect(path.packagePath, '/');
    });

    test('holds the root listing as the first level', () {
      final path = const ExternalSourcePath().withRoot([file('a.epub')]);

      expect(path.path, '');
      expect(path.packagePath, '/');
      expect(path.items.single.name, 'a.epub');
      expect(path.canGoUp, isFalse);
    });

    test('replaces the root listing when it is re-fetched', () {
      final first = const ExternalSourcePath().withRoot([file('old.epub')]);
      final second = first.withRoot([file('new.epub')]);

      expect(second.levels, hasLength(1));
      expect(second.items.single.name, 'new.epub');
    });

    test('pushes a folder and reports it as current', () {
      final root = const ExternalSourcePath().withRoot([folder('books')]);
      final inside = root.pushed(folder('books'));

      expect(inside.path, 'books');
      expect(inside.packagePath, '/books');
      expect(inside.canGoUp, isTrue);
      // Pushed levels start empty; the listing fills them in.
      expect(inside.items, isEmpty);
    });

    test('pushing onto an unlisted root still keeps a root level', () {
      final inside = const ExternalSourcePath().pushed(folder('books'));

      expect(inside.levels.first.path, '');
      expect(inside.levels, hasLength(2));
    });

    test('fills in the level that was pushed', () {
      final inside = const ExternalSourcePath()
          .withRoot([folder('books')])
          .pushed(folder('books'))
          .replacingItems([file('book.epub', 'books/book.epub')]);

      expect(inside.items.single.path, 'books/book.epub');
      expect(inside.path, 'books');
    });

    test('replacing items on an unlisted stack attaches a root level', () {
      final path = const ExternalSourcePath().replacingItems([file('a.epub')]);

      expect(path.levels, hasLength(1));
      expect(path.items.single.name, 'a.epub');
    });

    test('goes back up and restores the parent entries without refetching', () {
      final root = const ExternalSourcePath().withRoot([
        folder('books'),
        file('root.epub'),
      ]);
      final inside = root.pushed(folder('books')).replacingItems([
        file('book.epub', 'books/book.epub'),
      ]);

      final back = inside.popped();

      expect(back.path, '');
      expect(back.canGoUp, isFalse);
      // The parent's entries survived the round trip.
      expect(back.items.map((item) => item.name), ['books', 'root.epub']);
    });

    test('never pops the root', () {
      final root = const ExternalSourcePath().withRoot([file('a.epub')]);

      expect(root.popped().levels, hasLength(1));
      expect(root.popped().items.single.name, 'a.epub');
    });

    test('tracks a multi-level path', () {
      final deep = const ExternalSourcePath()
          .withRoot([folder('a')])
          .pushed(folder('a'))
          .replacingItems([folder('b')])
          .pushed(folder('b'))
          .replacingItems([file('c.epub', 'a/b/c.epub')]);

      expect(deep.path, 'b');
      expect(deep.packagePath, '/a/b');

      final up = deep.popped();
      expect(up.path, 'a');
      expect(up.items.single.name, 'b');
      expect(up.canGoUp, isTrue);

      final root = up.popped();
      expect(root.path, '');
      expect(root.canGoUp, isFalse);
    });
  });

  group('ExternalSourceImportNotifier.extensionOf', () {
    test('keeps the entry extension', () {
      expect(
        ExternalSourceImportNotifier.extensionOf(file('My Book.epub')),
        '.epub',
      );
      expect(ExternalSourceImportNotifier.extensionOf(file('a.EPUB')), '.EPUB');
      expect(
        ExternalSourceImportNotifier.extensionOf(file('a.b.epub')),
        '.epub',
      );
    });

    test('falls back to .epub when the name has no extension', () {
      expect(
        ExternalSourceImportNotifier.extensionOf(file('noextension')),
        '.epub',
      );
      expect(
        ExternalSourceImportNotifier.extensionOf(file('.hidden')),
        '.epub',
      );
      expect(
        ExternalSourceImportNotifier.extensionOf(file('trailing.')),
        '.epub',
      );
    });

    test('refuses to treat a path separator as part of the extension', () {
      // Defensive: the cache file name must not be able to escape its directory.
      expect(
        ExternalSourceImportNotifier.extensionOf(file('a.epub/../../x')),
        '.epub',
      );
    });
  });

  group('ExternalSourceImportNotifier.describeFailure', () {
    test('uses the failure kind alone when there is no extra detail', () {
      expect(
        ExternalSourceImportNotifier.describeFailure(
          ExternalSourceFailure.notFound(),
        ),
        'notFound',
      );
    });

    test('appends the HTTP status', () {
      expect(
        ExternalSourceImportNotifier.describeFailure(
          ExternalSourceFailure.status(500),
        ),
        'status (HTTP 500)',
      );
    });

    test('appends the platform detail', () {
      expect(
        ExternalSourceImportNotifier.describeFailure(
          ExternalSourceFailure.network('Connection refused'),
        ),
        'network: Connection refused',
      );
    });
  });
}
