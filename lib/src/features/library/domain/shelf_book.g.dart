// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shelf_book.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetShelfBookCollection on Isar {
  IsarCollection<ShelfBook> get shelfBooks => this.collection();
}

const ShelfBookSchema = CollectionSchema(
  name: r'ShelfBook',
  id: 5434802515745280230,
  properties: {
    r'author': PropertySchema(
      id: 0,
      name: r'author',
      type: IsarType.string,
    ),
    r'authors': PropertySchema(
      id: 1,
      name: r'authors',
      type: IsarType.stringList,
    ),
    r'chapterScrollPosition': PropertySchema(
      id: 2,
      name: r'chapterScrollPosition',
      type: IsarType.double,
    ),
    r'coverPath': PropertySchema(
      id: 3,
      name: r'coverPath',
      type: IsarType.string,
    ),
    r'currentChapterIndex': PropertySchema(
      id: 4,
      name: r'currentChapterIndex',
      type: IsarType.long,
    ),
    r'description': PropertySchema(
      id: 5,
      name: r'description',
      type: IsarType.string,
    ),
    r'direction': PropertySchema(
      id: 6,
      name: r'direction',
      type: IsarType.long,
    ),
    r'epubVersion': PropertySchema(
      id: 7,
      name: r'epubVersion',
      type: IsarType.string,
    ),
    r'fileHash': PropertySchema(
      id: 8,
      name: r'fileHash',
      type: IsarType.string,
    ),
    r'filePath': PropertySchema(
      id: 9,
      name: r'filePath',
      type: IsarType.string,
    ),
    r'groupName': PropertySchema(
      id: 10,
      name: r'groupName',
      type: IsarType.string,
    ),
    r'importDate': PropertySchema(
      id: 11,
      name: r'importDate',
      type: IsarType.long,
    ),
    r'isDeleted': PropertySchema(
      id: 12,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isFinished': PropertySchema(
      id: 13,
      name: r'isFinished',
      type: IsarType.bool,
    ),
    r'lastOpenedDate': PropertySchema(
      id: 14,
      name: r'lastOpenedDate',
      type: IsarType.long,
    ),
    r'lastSyncedDate': PropertySchema(
      id: 15,
      name: r'lastSyncedDate',
      type: IsarType.long,
    ),
    r'readingProgress': PropertySchema(
      id: 16,
      name: r'readingProgress',
      type: IsarType.double,
    ),
    r'subjects': PropertySchema(
      id: 17,
      name: r'subjects',
      type: IsarType.stringList,
    ),
    r'title': PropertySchema(
      id: 18,
      name: r'title',
      type: IsarType.string,
    ),
    r'totalChapters': PropertySchema(
      id: 19,
      name: r'totalChapters',
      type: IsarType.long,
    ),
    r'updatedAt': PropertySchema(
      id: 20,
      name: r'updatedAt',
      type: IsarType.long,
    )
  },
  estimateSize: _shelfBookEstimateSize,
  serialize: _shelfBookSerialize,
  deserialize: _shelfBookDeserialize,
  deserializeProp: _shelfBookDeserializeProp,
  idName: r'id',
  indexes: {
    r'fileHash': IndexSchema(
      id: -5944002318434853925,
      name: r'fileHash',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'fileHash',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'title': IndexSchema(
      id: -7636685945352118059,
      name: r'title',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'title',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'author': IndexSchema(
      id: 1831044620441877526,
      name: r'author',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'author',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'importDate': IndexSchema(
      id: 7960976230929175791,
      name: r'importDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'importDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'currentChapterIndex': IndexSchema(
      id: 694918216961997113,
      name: r'currentChapterIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'currentChapterIndex',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'readingProgress': IndexSchema(
      id: 3054802519379953801,
      name: r'readingProgress',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'readingProgress',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'lastOpenedDate': IndexSchema(
      id: -1466225661336453896,
      name: r'lastOpenedDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastOpenedDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'groupName': IndexSchema(
      id: -6302961014654519938,
      name: r'groupName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'groupName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'isDeleted': IndexSchema(
      id: -786475870904832312,
      name: r'isDeleted',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isDeleted',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'updatedAt': IndexSchema(
      id: -6238191080293565125,
      name: r'updatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _shelfBookGetId,
  getLinks: _shelfBookGetLinks,
  attach: _shelfBookAttach,
  version: '3.1.0+1',
);

int _shelfBookEstimateSize(
  ShelfBook object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.author.length * 3;
  bytesCount += 3 + object.authors.length * 3;
  {
    for (var i = 0; i < object.authors.length; i++) {
      final value = object.authors[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.coverPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.epubVersion.length * 3;
  bytesCount += 3 + object.fileHash.length * 3;
  {
    final value = object.filePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.groupName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.subjects.length * 3;
  {
    for (var i = 0; i < object.subjects.length; i++) {
      final value = object.subjects[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _shelfBookSerialize(
  ShelfBook object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.author);
  writer.writeStringList(offsets[1], object.authors);
  writer.writeDouble(offsets[2], object.chapterScrollPosition);
  writer.writeString(offsets[3], object.coverPath);
  writer.writeLong(offsets[4], object.currentChapterIndex);
  writer.writeString(offsets[5], object.description);
  writer.writeLong(offsets[6], object.direction);
  writer.writeString(offsets[7], object.epubVersion);
  writer.writeString(offsets[8], object.fileHash);
  writer.writeString(offsets[9], object.filePath);
  writer.writeString(offsets[10], object.groupName);
  writer.writeLong(offsets[11], object.importDate);
  writer.writeBool(offsets[12], object.isDeleted);
  writer.writeBool(offsets[13], object.isFinished);
  writer.writeLong(offsets[14], object.lastOpenedDate);
  writer.writeLong(offsets[15], object.lastSyncedDate);
  writer.writeDouble(offsets[16], object.readingProgress);
  writer.writeStringList(offsets[17], object.subjects);
  writer.writeString(offsets[18], object.title);
  writer.writeLong(offsets[19], object.totalChapters);
  writer.writeLong(offsets[20], object.updatedAt);
}

ShelfBook _shelfBookDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ShelfBook();
  object.author = reader.readString(offsets[0]);
  object.authors = reader.readStringList(offsets[1]) ?? [];
  object.chapterScrollPosition = reader.readDoubleOrNull(offsets[2]);
  object.coverPath = reader.readStringOrNull(offsets[3]);
  object.currentChapterIndex = reader.readLong(offsets[4]);
  object.description = reader.readStringOrNull(offsets[5]);
  object.direction = reader.readLong(offsets[6]);
  object.epubVersion = reader.readString(offsets[7]);
  object.fileHash = reader.readString(offsets[8]);
  object.filePath = reader.readStringOrNull(offsets[9]);
  object.groupName = reader.readStringOrNull(offsets[10]);
  object.id = id;
  object.importDate = reader.readLong(offsets[11]);
  object.isDeleted = reader.readBool(offsets[12]);
  object.isFinished = reader.readBool(offsets[13]);
  object.lastOpenedDate = reader.readLongOrNull(offsets[14]);
  object.lastSyncedDate = reader.readLongOrNull(offsets[15]);
  object.readingProgress = reader.readDouble(offsets[16]);
  object.subjects = reader.readStringList(offsets[17]) ?? [];
  object.title = reader.readString(offsets[18]);
  object.totalChapters = reader.readLong(offsets[19]);
  object.updatedAt = reader.readLong(offsets[20]);
  return object;
}

P _shelfBookDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readBool(offset)) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    case 15:
      return (reader.readLongOrNull(offset)) as P;
    case 16:
      return (reader.readDouble(offset)) as P;
    case 17:
      return (reader.readStringList(offset) ?? []) as P;
    case 18:
      return (reader.readString(offset)) as P;
    case 19:
      return (reader.readLong(offset)) as P;
    case 20:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _shelfBookGetId(ShelfBook object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _shelfBookGetLinks(ShelfBook object) {
  return [];
}

void _shelfBookAttach(IsarCollection<dynamic> col, Id id, ShelfBook object) {
  object.id = id;
}

extension ShelfBookByIndex on IsarCollection<ShelfBook> {
  Future<ShelfBook?> getByFileHash(String fileHash) {
    return getByIndex(r'fileHash', [fileHash]);
  }

  ShelfBook? getByFileHashSync(String fileHash) {
    return getByIndexSync(r'fileHash', [fileHash]);
  }

  Future<bool> deleteByFileHash(String fileHash) {
    return deleteByIndex(r'fileHash', [fileHash]);
  }

  bool deleteByFileHashSync(String fileHash) {
    return deleteByIndexSync(r'fileHash', [fileHash]);
  }

  Future<List<ShelfBook?>> getAllByFileHash(List<String> fileHashValues) {
    final values = fileHashValues.map((e) => [e]).toList();
    return getAllByIndex(r'fileHash', values);
  }

  List<ShelfBook?> getAllByFileHashSync(List<String> fileHashValues) {
    final values = fileHashValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'fileHash', values);
  }

  Future<int> deleteAllByFileHash(List<String> fileHashValues) {
    final values = fileHashValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'fileHash', values);
  }

  int deleteAllByFileHashSync(List<String> fileHashValues) {
    final values = fileHashValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'fileHash', values);
  }

  Future<Id> putByFileHash(ShelfBook object) {
    return putByIndex(r'fileHash', object);
  }

  Id putByFileHashSync(ShelfBook object, {bool saveLinks = true}) {
    return putByIndexSync(r'fileHash', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFileHash(List<ShelfBook> objects) {
    return putAllByIndex(r'fileHash', objects);
  }

  List<Id> putAllByFileHashSync(List<ShelfBook> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'fileHash', objects, saveLinks: saveLinks);
  }
}

extension ShelfBookQueryWhereSort
    on QueryBuilder<ShelfBook, ShelfBook, QWhere> {
  QueryBuilder<ShelfBook, ShelfBook, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhere> anyImportDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'importDate'),
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhere> anyCurrentChapterIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'currentChapterIndex'),
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhere> anyReadingProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'readingProgress'),
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhere> anyLastOpenedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastOpenedDate'),
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhere> anyIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isDeleted'),
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhere> anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }
}

extension ShelfBookQueryWhere
    on QueryBuilder<ShelfBook, ShelfBook, QWhereClause> {
  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> fileHashEqualTo(
      String fileHash) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fileHash',
        value: [fileHash],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> fileHashNotEqualTo(
      String fileHash) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileHash',
              lower: [],
              upper: [fileHash],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileHash',
              lower: [fileHash],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileHash',
              lower: [fileHash],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'fileHash',
              lower: [],
              upper: [fileHash],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> titleEqualTo(
      String title) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'title',
        value: [title],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> titleNotEqualTo(
      String title) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [title],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'title',
              lower: [],
              upper: [title],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> authorEqualTo(
      String author) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'author',
        value: [author],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> authorNotEqualTo(
      String author) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'author',
              lower: [],
              upper: [author],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'author',
              lower: [author],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'author',
              lower: [author],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'author',
              lower: [],
              upper: [author],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> importDateEqualTo(
      int importDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'importDate',
        value: [importDate],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> importDateNotEqualTo(
      int importDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'importDate',
              lower: [],
              upper: [importDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'importDate',
              lower: [importDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'importDate',
              lower: [importDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'importDate',
              lower: [],
              upper: [importDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> importDateGreaterThan(
    int importDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'importDate',
        lower: [importDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> importDateLessThan(
    int importDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'importDate',
        lower: [],
        upper: [importDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> importDateBetween(
    int lowerImportDate,
    int upperImportDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'importDate',
        lower: [lowerImportDate],
        includeLower: includeLower,
        upper: [upperImportDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause>
      currentChapterIndexEqualTo(int currentChapterIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'currentChapterIndex',
        value: [currentChapterIndex],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause>
      currentChapterIndexNotEqualTo(int currentChapterIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'currentChapterIndex',
              lower: [],
              upper: [currentChapterIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'currentChapterIndex',
              lower: [currentChapterIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'currentChapterIndex',
              lower: [currentChapterIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'currentChapterIndex',
              lower: [],
              upper: [currentChapterIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause>
      currentChapterIndexGreaterThan(
    int currentChapterIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'currentChapterIndex',
        lower: [currentChapterIndex],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause>
      currentChapterIndexLessThan(
    int currentChapterIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'currentChapterIndex',
        lower: [],
        upper: [currentChapterIndex],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause>
      currentChapterIndexBetween(
    int lowerCurrentChapterIndex,
    int upperCurrentChapterIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'currentChapterIndex',
        lower: [lowerCurrentChapterIndex],
        includeLower: includeLower,
        upper: [upperCurrentChapterIndex],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> readingProgressEqualTo(
      double readingProgress) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'readingProgress',
        value: [readingProgress],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause>
      readingProgressNotEqualTo(double readingProgress) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'readingProgress',
              lower: [],
              upper: [readingProgress],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'readingProgress',
              lower: [readingProgress],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'readingProgress',
              lower: [readingProgress],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'readingProgress',
              lower: [],
              upper: [readingProgress],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause>
      readingProgressGreaterThan(
    double readingProgress, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'readingProgress',
        lower: [readingProgress],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> readingProgressLessThan(
    double readingProgress, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'readingProgress',
        lower: [],
        upper: [readingProgress],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> readingProgressBetween(
    double lowerReadingProgress,
    double upperReadingProgress, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'readingProgress',
        lower: [lowerReadingProgress],
        includeLower: includeLower,
        upper: [upperReadingProgress],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> lastOpenedDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastOpenedDate',
        value: [null],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause>
      lastOpenedDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastOpenedDate',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> lastOpenedDateEqualTo(
      int? lastOpenedDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastOpenedDate',
        value: [lastOpenedDate],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause>
      lastOpenedDateNotEqualTo(int? lastOpenedDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastOpenedDate',
              lower: [],
              upper: [lastOpenedDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastOpenedDate',
              lower: [lastOpenedDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastOpenedDate',
              lower: [lastOpenedDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastOpenedDate',
              lower: [],
              upper: [lastOpenedDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause>
      lastOpenedDateGreaterThan(
    int? lastOpenedDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastOpenedDate',
        lower: [lastOpenedDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> lastOpenedDateLessThan(
    int? lastOpenedDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastOpenedDate',
        lower: [],
        upper: [lastOpenedDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> lastOpenedDateBetween(
    int? lowerLastOpenedDate,
    int? upperLastOpenedDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastOpenedDate',
        lower: [lowerLastOpenedDate],
        includeLower: includeLower,
        upper: [upperLastOpenedDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> groupNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'groupName',
        value: [null],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> groupNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'groupName',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> groupNameEqualTo(
      String? groupName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'groupName',
        value: [groupName],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> groupNameNotEqualTo(
      String? groupName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupName',
              lower: [],
              upper: [groupName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupName',
              lower: [groupName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupName',
              lower: [groupName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupName',
              lower: [],
              upper: [groupName],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> isDeletedEqualTo(
      bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isDeleted',
        value: [isDeleted],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> isDeletedNotEqualTo(
      bool isDeleted) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [],
              upper: [isDeleted],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [isDeleted],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [isDeleted],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isDeleted',
              lower: [],
              upper: [isDeleted],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> updatedAtEqualTo(
      int updatedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'updatedAt',
        value: [updatedAt],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> updatedAtNotEqualTo(
      int updatedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [updatedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'updatedAt',
              lower: [],
              upper: [updatedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> updatedAtGreaterThan(
    int updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [updatedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> updatedAtLessThan(
    int updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [],
        upper: [updatedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterWhereClause> updatedAtBetween(
    int lowerUpdatedAt,
    int upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'updatedAt',
        lower: [lowerUpdatedAt],
        includeLower: includeLower,
        upper: [upperUpdatedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ShelfBookQueryFilter
    on QueryBuilder<ShelfBook, ShelfBook, QFilterCondition> {
  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> authorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> authorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> authorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> authorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'author',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> authorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> authorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> authorContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'author',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> authorMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'author',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> authorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'author',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> authorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'author',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'authors',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'authors',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'authors',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'authors',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'authors',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'authors',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'authors',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'authors',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'authors',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'authors',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'authors',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> authorsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'authors',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'authors',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'authors',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'authors',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      authorsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'authors',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      chapterScrollPositionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'chapterScrollPosition',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      chapterScrollPositionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'chapterScrollPosition',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      chapterScrollPositionEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chapterScrollPosition',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      chapterScrollPositionGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chapterScrollPosition',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      chapterScrollPositionLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chapterScrollPosition',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      chapterScrollPositionBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chapterScrollPosition',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> coverPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'coverPath',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      coverPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'coverPath',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> coverPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coverPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      coverPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'coverPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> coverPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'coverPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> coverPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'coverPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> coverPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'coverPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> coverPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'coverPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> coverPathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'coverPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> coverPathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'coverPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> coverPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coverPath',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      coverPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'coverPath',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      currentChapterIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentChapterIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      currentChapterIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentChapterIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      currentChapterIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentChapterIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      currentChapterIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentChapterIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> descriptionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> descriptionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> directionEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'direction',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      directionGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'direction',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> directionLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'direction',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> directionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'direction',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> epubVersionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'epubVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      epubVersionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'epubVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> epubVersionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'epubVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> epubVersionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'epubVersion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      epubVersionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'epubVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> epubVersionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'epubVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> epubVersionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'epubVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> epubVersionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'epubVersion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      epubVersionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'epubVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      epubVersionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'epubVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> fileHashEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> fileHashGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fileHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> fileHashLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fileHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> fileHashBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fileHash',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> fileHashStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fileHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> fileHashEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fileHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> fileHashContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fileHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> fileHashMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fileHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> fileHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileHash',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      fileHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fileHash',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> filePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'filePath',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      filePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'filePath',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> filePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> filePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> filePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> filePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'filePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> filePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> filePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> filePathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> filePathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> filePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      filePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> groupNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'groupName',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      groupNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'groupName',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> groupNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      groupNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> groupNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> groupNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'groupName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> groupNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> groupNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> groupNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> groupNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'groupName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> groupNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupName',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      groupNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'groupName',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> importDateEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'importDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      importDateGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'importDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> importDateLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'importDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> importDateBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'importDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> isDeletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> isFinishedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFinished',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      lastOpenedDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastOpenedDate',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      lastOpenedDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastOpenedDate',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      lastOpenedDateEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastOpenedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      lastOpenedDateGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastOpenedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      lastOpenedDateLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastOpenedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      lastOpenedDateBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastOpenedDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      lastSyncedDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncedDate',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      lastSyncedDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncedDate',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      lastSyncedDateEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      lastSyncedDateGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      lastSyncedDateLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      lastSyncedDateBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncedDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      readingProgressEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'readingProgress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      readingProgressGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'readingProgress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      readingProgressLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'readingProgress',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      readingProgressBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'readingProgress',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subjects',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subjects',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subjects',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subjects',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'subjects',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'subjects',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'subjects',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'subjects',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subjects',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'subjects',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subjects',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> subjectsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subjects',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subjects',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subjects',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subjects',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      subjectsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'subjects',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> titleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> titleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      totalChaptersEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalChapters',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      totalChaptersGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalChapters',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      totalChaptersLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalChapters',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      totalChaptersBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalChapters',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> updatedAtEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition>
      updatedAtGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> updatedAtLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterFilterCondition> updatedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ShelfBookQueryObject
    on QueryBuilder<ShelfBook, ShelfBook, QFilterCondition> {}

extension ShelfBookQueryLinks
    on QueryBuilder<ShelfBook, ShelfBook, QFilterCondition> {}

extension ShelfBookQuerySortBy on QueryBuilder<ShelfBook, ShelfBook, QSortBy> {
  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByAuthor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByAuthorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy>
      sortByChapterScrollPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterScrollPosition', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy>
      sortByChapterScrollPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterScrollPosition', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByCoverPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverPath', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByCoverPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverPath', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByCurrentChapterIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentChapterIndex', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy>
      sortByCurrentChapterIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentChapterIndex', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByEpubVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'epubVersion', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByEpubVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'epubVersion', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByFileHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileHash', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByFileHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileHash', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByImportDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importDate', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByImportDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importDate', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByIsFinished() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFinished', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByIsFinishedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFinished', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByLastOpenedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpenedDate', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByLastOpenedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpenedDate', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByLastSyncedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedDate', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByLastSyncedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedDate', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByReadingProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingProgress', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByReadingProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingProgress', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByTotalChapters() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalChapters', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByTotalChaptersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalChapters', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ShelfBookQuerySortThenBy
    on QueryBuilder<ShelfBook, ShelfBook, QSortThenBy> {
  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByAuthor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByAuthorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'author', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy>
      thenByChapterScrollPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterScrollPosition', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy>
      thenByChapterScrollPositionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapterScrollPosition', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByCoverPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverPath', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByCoverPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverPath', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByCurrentChapterIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentChapterIndex', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy>
      thenByCurrentChapterIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentChapterIndex', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByDirectionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'direction', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByEpubVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'epubVersion', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByEpubVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'epubVersion', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByFileHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileHash', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByFileHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileHash', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByImportDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importDate', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByImportDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'importDate', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByIsFinished() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFinished', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByIsFinishedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFinished', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByLastOpenedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpenedDate', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByLastOpenedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpenedDate', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByLastSyncedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedDate', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByLastSyncedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedDate', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByReadingProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingProgress', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByReadingProgressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readingProgress', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByTotalChapters() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalChapters', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByTotalChaptersDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalChapters', Sort.desc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension ShelfBookQueryWhereDistinct
    on QueryBuilder<ShelfBook, ShelfBook, QDistinct> {
  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByAuthor(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'author', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByAuthors() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'authors');
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct>
      distinctByChapterScrollPosition() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chapterScrollPosition');
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByCoverPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'coverPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct>
      distinctByCurrentChapterIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentChapterIndex');
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByDirection() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'direction');
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByEpubVersion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'epubVersion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByFileHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByFilePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByGroupName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByImportDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'importDate');
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByIsFinished() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFinished');
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByLastOpenedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastOpenedDate');
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByLastSyncedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedDate');
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByReadingProgress() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'readingProgress');
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctBySubjects() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subjects');
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByTotalChapters() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalChapters');
    });
  }

  QueryBuilder<ShelfBook, ShelfBook, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension ShelfBookQueryProperty
    on QueryBuilder<ShelfBook, ShelfBook, QQueryProperty> {
  QueryBuilder<ShelfBook, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ShelfBook, String, QQueryOperations> authorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'author');
    });
  }

  QueryBuilder<ShelfBook, List<String>, QQueryOperations> authorsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'authors');
    });
  }

  QueryBuilder<ShelfBook, double?, QQueryOperations>
      chapterScrollPositionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chapterScrollPosition');
    });
  }

  QueryBuilder<ShelfBook, String?, QQueryOperations> coverPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coverPath');
    });
  }

  QueryBuilder<ShelfBook, int, QQueryOperations> currentChapterIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentChapterIndex');
    });
  }

  QueryBuilder<ShelfBook, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<ShelfBook, int, QQueryOperations> directionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'direction');
    });
  }

  QueryBuilder<ShelfBook, String, QQueryOperations> epubVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'epubVersion');
    });
  }

  QueryBuilder<ShelfBook, String, QQueryOperations> fileHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileHash');
    });
  }

  QueryBuilder<ShelfBook, String?, QQueryOperations> filePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filePath');
    });
  }

  QueryBuilder<ShelfBook, String?, QQueryOperations> groupNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupName');
    });
  }

  QueryBuilder<ShelfBook, int, QQueryOperations> importDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'importDate');
    });
  }

  QueryBuilder<ShelfBook, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<ShelfBook, bool, QQueryOperations> isFinishedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFinished');
    });
  }

  QueryBuilder<ShelfBook, int?, QQueryOperations> lastOpenedDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastOpenedDate');
    });
  }

  QueryBuilder<ShelfBook, int?, QQueryOperations> lastSyncedDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedDate');
    });
  }

  QueryBuilder<ShelfBook, double, QQueryOperations> readingProgressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readingProgress');
    });
  }

  QueryBuilder<ShelfBook, List<String>, QQueryOperations> subjectsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subjects');
    });
  }

  QueryBuilder<ShelfBook, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<ShelfBook, int, QQueryOperations> totalChaptersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalChapters');
    });
  }

  QueryBuilder<ShelfBook, int, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
