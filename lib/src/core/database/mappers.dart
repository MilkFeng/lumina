import 'package:drift/drift.dart';

import '../../features/library/domain/book_manifest.dart';
import '../../features/library/domain/shelf_book.dart';
import '../../features/library/domain/shelf_group.dart';
import 'lumina_db.dart';

/// Converts between drift's generated row classes and the domain models, so the
/// rest of the app never sees a database type.
extension ShelfBookMapper on ShelfBook {
  /// Builds an insert/update companion. A non-zero [id] preserves the existing
  /// row (used when a caller has already fetched the book from storage).
  ShelfBooksCompanion toCompanion() => ShelfBooksCompanion(
    id: id == 0 ? const Value.absent() : Value(id),
    fileHash: Value(fileHash),
    filePath: Value(filePath),
    coverPath: Value(coverPath),
    title: Value(title),
    author: Value(author),
    authors: Value(authors),
    description: Value(description),
    subjects: Value(subjects),
    totalChapters: Value(totalChapters),
    epubVersion: Value(epubVersion),
    importDate: Value(importDate),
    direction: Value(direction),
    currentChapterIndex: Value(currentChapterIndex),
    readingProgress: Value(readingProgress),
    chapterScrollPosition: Value(chapterScrollPosition),
    lastOpenedDate: Value(lastOpenedDate),
    isFinished: Value(isFinished),
    groupName: Value(groupName),
    isDeleted: Value(isDeleted),
    updatedAt: Value(updatedAt),
    lastSyncedDate: Value(lastSyncedDate),
  );
}

extension ShelfBookRowMapper on ShelfBookRow {
  ShelfBook toDomain() => ShelfBook()
    ..id = id
    ..fileHash = fileHash
    ..filePath = filePath
    ..coverPath = coverPath
    ..title = title
    ..author = author
    ..authors = authors
    ..description = description
    ..subjects = subjects
    ..totalChapters = totalChapters
    ..epubVersion = epubVersion
    ..importDate = importDate
    ..direction = direction
    ..currentChapterIndex = currentChapterIndex
    ..readingProgress = readingProgress
    ..chapterScrollPosition = chapterScrollPosition
    ..lastOpenedDate = lastOpenedDate
    ..isFinished = isFinished
    ..groupName = groupName
    ..isDeleted = isDeleted
    ..updatedAt = updatedAt
    ..lastSyncedDate = lastSyncedDate;
}

/// Derives the insert companion for a group, treating a zero [ShelfGroup.id] as
/// "let the database assign one".
extension ShelfGroupMapper on ShelfGroup {
  ShelfGroupsCompanion toCompanion() => ShelfGroupsCompanion(
    id: id == 0 ? const Value.absent() : Value(id),
    name: Value(name),
    creationDate: Value(creationDate),
    updatedAt: Value(updatedAt),
    isDeleted: Value(isDeleted),
  );
}

extension ShelfGroupRowMapper on ShelfGroupRow {
  ShelfGroup toDomain() => ShelfGroup()
    ..id = id
    ..name = name
    ..creationDate = creationDate
    ..updatedAt = updatedAt
    ..isDeleted = isDeleted;
}

extension BookManifestMapper on BookManifest {
  BookManifestsCompanion toCompanion() => BookManifestsCompanion(
    id: id == 0 ? const Value.absent() : Value(id),
    fileHash: Value(fileHash),
    opfRootPath: Value(opfRootPath),
    spine: Value(spine),
    toc: Value(toc),
    manifest: Value(manifest),
    epubVersion: Value(epubVersion),
    lastUpdated: Value(lastUpdated),
  );
}

extension BookManifestRowMapper on BookManifestRow {
  BookManifest toDomain() => BookManifest()
    ..id = id
    ..fileHash = fileHash
    ..opfRootPath = opfRootPath
    ..spine = spine
    ..toc = toc
    ..manifest = manifest
    ..epubVersion = epubVersion
    // drift's default DateTime encoding stores Unix seconds and reads them back
    // with `isUtc: false`, so a stored UTC value comes back tagged as local.
    // Normalising to UTC preserves the absolute instant across a round-trip.
    ..lastUpdated = lastUpdated.toUtc();
}
