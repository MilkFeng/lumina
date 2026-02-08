// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_manifest.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBookManifestCollection on Isar {
  IsarCollection<BookManifest> get bookManifests => this.collection();
}

const BookManifestSchema = CollectionSchema(
  name: r'BookManifest',
  id: 8269213801082041246,
  properties: {
    r'epubVersion': PropertySchema(
      id: 0,
      name: r'epubVersion',
      type: IsarType.string,
    ),
    r'fileHash': PropertySchema(
      id: 1,
      name: r'fileHash',
      type: IsarType.string,
    ),
    r'lastUpdated': PropertySchema(
      id: 2,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'manifest': PropertySchema(
      id: 3,
      name: r'manifest',
      type: IsarType.objectList,
      target: r'ManifestItem',
    ),
    r'opfRootPath': PropertySchema(
      id: 4,
      name: r'opfRootPath',
      type: IsarType.string,
    ),
    r'spine': PropertySchema(
      id: 5,
      name: r'spine',
      type: IsarType.objectList,
      target: r'SpineItem',
    ),
    r'toc': PropertySchema(
      id: 6,
      name: r'toc',
      type: IsarType.objectList,
      target: r'TocItem',
    )
  },
  estimateSize: _bookManifestEstimateSize,
  serialize: _bookManifestSerialize,
  deserialize: _bookManifestDeserialize,
  deserializeProp: _bookManifestDeserializeProp,
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
    )
  },
  links: {},
  embeddedSchemas: {
    r'SpineItem': SpineItemSchema,
    r'TocItem': TocItemSchema,
    r'Href': HrefSchema,
    r'ManifestItem': ManifestItemSchema
  },
  getId: _bookManifestGetId,
  getLinks: _bookManifestGetLinks,
  attach: _bookManifestAttach,
  version: '3.1.0+1',
);

int _bookManifestEstimateSize(
  BookManifest object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.epubVersion.length * 3;
  bytesCount += 3 + object.fileHash.length * 3;
  bytesCount += 3 + object.manifest.length * 3;
  {
    final offsets = allOffsets[ManifestItem]!;
    for (var i = 0; i < object.manifest.length; i++) {
      final value = object.manifest[i];
      bytesCount += ManifestItemSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.opfRootPath.length * 3;
  bytesCount += 3 + object.spine.length * 3;
  {
    final offsets = allOffsets[SpineItem]!;
    for (var i = 0; i < object.spine.length; i++) {
      final value = object.spine[i];
      bytesCount += SpineItemSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount += 3 + object.toc.length * 3;
  {
    final offsets = allOffsets[TocItem]!;
    for (var i = 0; i < object.toc.length; i++) {
      final value = object.toc[i];
      bytesCount += TocItemSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _bookManifestSerialize(
  BookManifest object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.epubVersion);
  writer.writeString(offsets[1], object.fileHash);
  writer.writeDateTime(offsets[2], object.lastUpdated);
  writer.writeObjectList<ManifestItem>(
    offsets[3],
    allOffsets,
    ManifestItemSchema.serialize,
    object.manifest,
  );
  writer.writeString(offsets[4], object.opfRootPath);
  writer.writeObjectList<SpineItem>(
    offsets[5],
    allOffsets,
    SpineItemSchema.serialize,
    object.spine,
  );
  writer.writeObjectList<TocItem>(
    offsets[6],
    allOffsets,
    TocItemSchema.serialize,
    object.toc,
  );
}

BookManifest _bookManifestDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BookManifest();
  object.epubVersion = reader.readString(offsets[0]);
  object.fileHash = reader.readString(offsets[1]);
  object.id = id;
  object.lastUpdated = reader.readDateTime(offsets[2]);
  object.manifest = reader.readObjectList<ManifestItem>(
        offsets[3],
        ManifestItemSchema.deserialize,
        allOffsets,
        ManifestItem(),
      ) ??
      [];
  object.opfRootPath = reader.readString(offsets[4]);
  object.spine = reader.readObjectList<SpineItem>(
        offsets[5],
        SpineItemSchema.deserialize,
        allOffsets,
        SpineItem(),
      ) ??
      [];
  object.toc = reader.readObjectList<TocItem>(
        offsets[6],
        TocItemSchema.deserialize,
        allOffsets,
        TocItem(),
      ) ??
      [];
  return object;
}

P _bookManifestDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readObjectList<ManifestItem>(
            offset,
            ManifestItemSchema.deserialize,
            allOffsets,
            ManifestItem(),
          ) ??
          []) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readObjectList<SpineItem>(
            offset,
            SpineItemSchema.deserialize,
            allOffsets,
            SpineItem(),
          ) ??
          []) as P;
    case 6:
      return (reader.readObjectList<TocItem>(
            offset,
            TocItemSchema.deserialize,
            allOffsets,
            TocItem(),
          ) ??
          []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _bookManifestGetId(BookManifest object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _bookManifestGetLinks(BookManifest object) {
  return [];
}

void _bookManifestAttach(
    IsarCollection<dynamic> col, Id id, BookManifest object) {
  object.id = id;
}

extension BookManifestByIndex on IsarCollection<BookManifest> {
  Future<BookManifest?> getByFileHash(String fileHash) {
    return getByIndex(r'fileHash', [fileHash]);
  }

  BookManifest? getByFileHashSync(String fileHash) {
    return getByIndexSync(r'fileHash', [fileHash]);
  }

  Future<bool> deleteByFileHash(String fileHash) {
    return deleteByIndex(r'fileHash', [fileHash]);
  }

  bool deleteByFileHashSync(String fileHash) {
    return deleteByIndexSync(r'fileHash', [fileHash]);
  }

  Future<List<BookManifest?>> getAllByFileHash(List<String> fileHashValues) {
    final values = fileHashValues.map((e) => [e]).toList();
    return getAllByIndex(r'fileHash', values);
  }

  List<BookManifest?> getAllByFileHashSync(List<String> fileHashValues) {
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

  Future<Id> putByFileHash(BookManifest object) {
    return putByIndex(r'fileHash', object);
  }

  Id putByFileHashSync(BookManifest object, {bool saveLinks = true}) {
    return putByIndexSync(r'fileHash', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFileHash(List<BookManifest> objects) {
    return putAllByIndex(r'fileHash', objects);
  }

  List<Id> putAllByFileHashSync(List<BookManifest> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'fileHash', objects, saveLinks: saveLinks);
  }
}

extension BookManifestQueryWhereSort
    on QueryBuilder<BookManifest, BookManifest, QWhere> {
  QueryBuilder<BookManifest, BookManifest, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension BookManifestQueryWhere
    on QueryBuilder<BookManifest, BookManifest, QWhereClause> {
  QueryBuilder<BookManifest, BookManifest, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<BookManifest, BookManifest, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterWhereClause> idBetween(
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

  QueryBuilder<BookManifest, BookManifest, QAfterWhereClause> fileHashEqualTo(
      String fileHash) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'fileHash',
        value: [fileHash],
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterWhereClause>
      fileHashNotEqualTo(String fileHash) {
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
}

extension BookManifestQueryFilter
    on QueryBuilder<BookManifest, BookManifest, QFilterCondition> {
  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      epubVersionEqualTo(
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      epubVersionLessThan(
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      epubVersionBetween(
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      epubVersionEndsWith(
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      epubVersionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'epubVersion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      epubVersionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'epubVersion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      epubVersionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'epubVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      epubVersionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'epubVersion',
        value: '',
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      fileHashEqualTo(
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      fileHashGreaterThan(
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      fileHashLessThan(
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      fileHashBetween(
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      fileHashStartsWith(
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      fileHashEndsWith(
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      fileHashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fileHash',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      fileHashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fileHash',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      fileHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fileHash',
        value: '',
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      fileHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fileHash',
        value: '',
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition> idBetween(
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

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      lastUpdatedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      lastUpdatedGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      lastUpdatedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      lastUpdatedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUpdated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      manifestLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'manifest',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      manifestIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'manifest',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      manifestIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'manifest',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      manifestLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'manifest',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      manifestLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'manifest',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      manifestLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'manifest',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      opfRootPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'opfRootPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      opfRootPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'opfRootPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      opfRootPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'opfRootPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      opfRootPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'opfRootPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      opfRootPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'opfRootPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      opfRootPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'opfRootPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      opfRootPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'opfRootPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      opfRootPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'opfRootPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      opfRootPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'opfRootPath',
        value: '',
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      opfRootPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'opfRootPath',
        value: '',
      ));
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      spineLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'spine',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      spineIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'spine',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      spineIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'spine',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      spineLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'spine',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      spineLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'spine',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      spineLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'spine',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      tocLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'toc',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition> tocIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'toc',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      tocIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'toc',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      tocLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'toc',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      tocLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'toc',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      tocLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'toc',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension BookManifestQueryObject
    on QueryBuilder<BookManifest, BookManifest, QFilterCondition> {
  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition>
      manifestElement(FilterQuery<ManifestItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'manifest');
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition> spineElement(
      FilterQuery<SpineItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'spine');
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterFilterCondition> tocElement(
      FilterQuery<TocItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'toc');
    });
  }
}

extension BookManifestQueryLinks
    on QueryBuilder<BookManifest, BookManifest, QFilterCondition> {}

extension BookManifestQuerySortBy
    on QueryBuilder<BookManifest, BookManifest, QSortBy> {
  QueryBuilder<BookManifest, BookManifest, QAfterSortBy> sortByEpubVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'epubVersion', Sort.asc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy>
      sortByEpubVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'epubVersion', Sort.desc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy> sortByFileHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileHash', Sort.asc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy> sortByFileHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileHash', Sort.desc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy> sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy>
      sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy> sortByOpfRootPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'opfRootPath', Sort.asc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy>
      sortByOpfRootPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'opfRootPath', Sort.desc);
    });
  }
}

extension BookManifestQuerySortThenBy
    on QueryBuilder<BookManifest, BookManifest, QSortThenBy> {
  QueryBuilder<BookManifest, BookManifest, QAfterSortBy> thenByEpubVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'epubVersion', Sort.asc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy>
      thenByEpubVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'epubVersion', Sort.desc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy> thenByFileHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileHash', Sort.asc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy> thenByFileHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileHash', Sort.desc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy> thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy>
      thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy> thenByOpfRootPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'opfRootPath', Sort.asc);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QAfterSortBy>
      thenByOpfRootPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'opfRootPath', Sort.desc);
    });
  }
}

extension BookManifestQueryWhereDistinct
    on QueryBuilder<BookManifest, BookManifest, QDistinct> {
  QueryBuilder<BookManifest, BookManifest, QDistinct> distinctByEpubVersion(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'epubVersion', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QDistinct> distinctByFileHash(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BookManifest, BookManifest, QDistinct> distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<BookManifest, BookManifest, QDistinct> distinctByOpfRootPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'opfRootPath', caseSensitive: caseSensitive);
    });
  }
}

extension BookManifestQueryProperty
    on QueryBuilder<BookManifest, BookManifest, QQueryProperty> {
  QueryBuilder<BookManifest, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BookManifest, String, QQueryOperations> epubVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'epubVersion');
    });
  }

  QueryBuilder<BookManifest, String, QQueryOperations> fileHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileHash');
    });
  }

  QueryBuilder<BookManifest, DateTime, QQueryOperations> lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<BookManifest, List<ManifestItem>, QQueryOperations>
      manifestProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'manifest');
    });
  }

  QueryBuilder<BookManifest, String, QQueryOperations> opfRootPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'opfRootPath');
    });
  }

  QueryBuilder<BookManifest, List<SpineItem>, QQueryOperations>
      spineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'spine');
    });
  }

  QueryBuilder<BookManifest, List<TocItem>, QQueryOperations> tocProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toc');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const SpineItemSchema = Schema(
  name: r'SpineItem',
  id: 6514641446194570479,
  properties: {
    r'href': PropertySchema(
      id: 0,
      name: r'href',
      type: IsarType.string,
    ),
    r'idref': PropertySchema(
      id: 1,
      name: r'idref',
      type: IsarType.string,
    ),
    r'index': PropertySchema(
      id: 2,
      name: r'index',
      type: IsarType.long,
    ),
    r'linear': PropertySchema(
      id: 3,
      name: r'linear',
      type: IsarType.bool,
    )
  },
  estimateSize: _spineItemEstimateSize,
  serialize: _spineItemSerialize,
  deserialize: _spineItemDeserialize,
  deserializeProp: _spineItemDeserializeProp,
);

int _spineItemEstimateSize(
  SpineItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.href.length * 3;
  bytesCount += 3 + object.idref.length * 3;
  return bytesCount;
}

void _spineItemSerialize(
  SpineItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.href);
  writer.writeString(offsets[1], object.idref);
  writer.writeLong(offsets[2], object.index);
  writer.writeBool(offsets[3], object.linear);
}

SpineItem _spineItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SpineItem(
    href: reader.readStringOrNull(offsets[0]) ?? '',
    idref: reader.readStringOrNull(offsets[1]) ?? '',
    index: reader.readLongOrNull(offsets[2]) ?? 0,
    linear: reader.readBoolOrNull(offsets[3]) ?? true,
  );
  return object;
}

P _spineItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 1:
      return (reader.readStringOrNull(offset) ?? '') as P;
    case 2:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 3:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension SpineItemQueryFilter
    on QueryBuilder<SpineItem, SpineItem, QFilterCondition> {
  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> hrefEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'href',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> hrefGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'href',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> hrefLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'href',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> hrefBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'href',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> hrefStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'href',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> hrefEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'href',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> hrefContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'href',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> hrefMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'href',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> hrefIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'href',
        value: '',
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> hrefIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'href',
        value: '',
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> idrefEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idref',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> idrefGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idref',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> idrefLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idref',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> idrefBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idref',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> idrefStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idref',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> idrefEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idref',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> idrefContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idref',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> idrefMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idref',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> idrefIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idref',
        value: '',
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> idrefIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idref',
        value: '',
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> indexEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'index',
        value: value,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> indexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'index',
        value: value,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> indexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'index',
        value: value,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> indexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'index',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SpineItem, SpineItem, QAfterFilterCondition> linearEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'linear',
        value: value,
      ));
    });
  }
}

extension SpineItemQueryObject
    on QueryBuilder<SpineItem, SpineItem, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const HrefSchema = Schema(
  name: r'Href',
  id: 5929635220176271520,
  properties: {
    r'anchor': PropertySchema(
      id: 0,
      name: r'anchor',
      type: IsarType.string,
    ),
    r'hashCode': PropertySchema(
      id: 1,
      name: r'hashCode',
      type: IsarType.long,
    ),
    r'path': PropertySchema(
      id: 2,
      name: r'path',
      type: IsarType.string,
    )
  },
  estimateSize: _hrefEstimateSize,
  serialize: _hrefSerialize,
  deserialize: _hrefDeserialize,
  deserializeProp: _hrefDeserializeProp,
);

int _hrefEstimateSize(
  Href object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.anchor.length * 3;
  bytesCount += 3 + object.path.length * 3;
  return bytesCount;
}

void _hrefSerialize(
  Href object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.anchor);
  writer.writeLong(offsets[1], object.hashCode);
  writer.writeString(offsets[2], object.path);
}

Href _hrefDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Href();
  object.anchor = reader.readString(offsets[0]);
  object.path = reader.readString(offsets[2]);
  return object;
}

P _hrefDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension HrefQueryFilter on QueryBuilder<Href, Href, QFilterCondition> {
  QueryBuilder<Href, Href, QAfterFilterCondition> anchorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'anchor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> anchorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'anchor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> anchorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'anchor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> anchorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'anchor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> anchorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'anchor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> anchorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'anchor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> anchorContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'anchor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> anchorMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'anchor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> anchorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'anchor',
        value: '',
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> anchorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'anchor',
        value: '',
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> hashCodeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> hashCodeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> hashCodeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'hashCode',
        value: value,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> hashCodeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'hashCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> pathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> pathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> pathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> pathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'path',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> pathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> pathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> pathContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> pathMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'path',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> pathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'path',
        value: '',
      ));
    });
  }

  QueryBuilder<Href, Href, QAfterFilterCondition> pathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'path',
        value: '',
      ));
    });
  }
}

extension HrefQueryObject on QueryBuilder<Href, Href, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ManifestItemSchema = Schema(
  name: r'ManifestItem',
  id: 1685948688282705596,
  properties: {
    r'href': PropertySchema(
      id: 0,
      name: r'href',
      type: IsarType.object,
      target: r'Href',
    ),
    r'id': PropertySchema(
      id: 1,
      name: r'id',
      type: IsarType.string,
    ),
    r'mediaType': PropertySchema(
      id: 2,
      name: r'mediaType',
      type: IsarType.string,
    ),
    r'properties': PropertySchema(
      id: 3,
      name: r'properties',
      type: IsarType.string,
    )
  },
  estimateSize: _manifestItemEstimateSize,
  serialize: _manifestItemSerialize,
  deserialize: _manifestItemDeserialize,
  deserializeProp: _manifestItemDeserializeProp,
);

int _manifestItemEstimateSize(
  ManifestItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount +=
      3 + HrefSchema.estimateSize(object.href, allOffsets[Href]!, allOffsets);
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.mediaType.length * 3;
  {
    final value = object.properties;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _manifestItemSerialize(
  ManifestItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObject<Href>(
    offsets[0],
    allOffsets,
    HrefSchema.serialize,
    object.href,
  );
  writer.writeString(offsets[1], object.id);
  writer.writeString(offsets[2], object.mediaType);
  writer.writeString(offsets[3], object.properties);
}

ManifestItem _manifestItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ManifestItem();
  object.href = reader.readObjectOrNull<Href>(
        offsets[0],
        HrefSchema.deserialize,
        allOffsets,
      ) ??
      Href();
  object.id = reader.readString(offsets[1]);
  object.mediaType = reader.readString(offsets[2]);
  object.properties = reader.readStringOrNull(offsets[3]);
  return object;
}

P _manifestItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectOrNull<Href>(
            offset,
            HrefSchema.deserialize,
            allOffsets,
          ) ??
          Href()) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ManifestItemQueryFilter
    on QueryBuilder<ManifestItem, ManifestItem, QFilterCondition> {
  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      mediaTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      mediaTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mediaType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      mediaTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mediaType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      mediaTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mediaType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      mediaTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mediaType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      mediaTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mediaType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      mediaTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mediaType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      mediaTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mediaType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      mediaTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mediaType',
        value: '',
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      mediaTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mediaType',
        value: '',
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      propertiesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'properties',
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      propertiesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'properties',
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      propertiesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'properties',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      propertiesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'properties',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      propertiesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'properties',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      propertiesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'properties',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      propertiesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'properties',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      propertiesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'properties',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      propertiesContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'properties',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      propertiesMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'properties',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      propertiesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'properties',
        value: '',
      ));
    });
  }

  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition>
      propertiesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'properties',
        value: '',
      ));
    });
  }
}

extension ManifestItemQueryObject
    on QueryBuilder<ManifestItem, ManifestItem, QFilterCondition> {
  QueryBuilder<ManifestItem, ManifestItem, QAfterFilterCondition> href(
      FilterQuery<Href> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'href');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const TocItemSchema = Schema(
  name: r'TocItem',
  id: -3294720251377856052,
  properties: {
    r'children': PropertySchema(
      id: 0,
      name: r'children',
      type: IsarType.objectList,
      target: r'TocItem',
    ),
    r'depth': PropertySchema(
      id: 1,
      name: r'depth',
      type: IsarType.long,
    ),
    r'href': PropertySchema(
      id: 2,
      name: r'href',
      type: IsarType.object,
      target: r'Href',
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.long,
    ),
    r'label': PropertySchema(
      id: 4,
      name: r'label',
      type: IsarType.string,
    ),
    r'parentId': PropertySchema(
      id: 5,
      name: r'parentId',
      type: IsarType.long,
    ),
    r'spineIndex': PropertySchema(
      id: 6,
      name: r'spineIndex',
      type: IsarType.long,
    )
  },
  estimateSize: _tocItemEstimateSize,
  serialize: _tocItemSerialize,
  deserialize: _tocItemDeserialize,
  deserializeProp: _tocItemDeserializeProp,
);

int _tocItemEstimateSize(
  TocItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.children.length * 3;
  {
    final offsets = allOffsets[TocItem]!;
    for (var i = 0; i < object.children.length; i++) {
      final value = object.children[i];
      bytesCount += TocItemSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  bytesCount +=
      3 + HrefSchema.estimateSize(object.href, allOffsets[Href]!, allOffsets);
  bytesCount += 3 + object.label.length * 3;
  return bytesCount;
}

void _tocItemSerialize(
  TocItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObjectList<TocItem>(
    offsets[0],
    allOffsets,
    TocItemSchema.serialize,
    object.children,
  );
  writer.writeLong(offsets[1], object.depth);
  writer.writeObject<Href>(
    offsets[2],
    allOffsets,
    HrefSchema.serialize,
    object.href,
  );
  writer.writeLong(offsets[3], object.id);
  writer.writeString(offsets[4], object.label);
  writer.writeLong(offsets[5], object.parentId);
  writer.writeLong(offsets[6], object.spineIndex);
}

TocItem _tocItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TocItem();
  object.children = reader.readObjectList<TocItem>(
        offsets[0],
        TocItemSchema.deserialize,
        allOffsets,
        TocItem(),
      ) ??
      [];
  object.depth = reader.readLong(offsets[1]);
  object.href = reader.readObjectOrNull<Href>(
        offsets[2],
        HrefSchema.deserialize,
        allOffsets,
      ) ??
      Href();
  object.id = reader.readLong(offsets[3]);
  object.label = reader.readString(offsets[4]);
  object.parentId = reader.readLong(offsets[5]);
  object.spineIndex = reader.readLong(offsets[6]);
  return object;
}

P _tocItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectList<TocItem>(
            offset,
            TocItemSchema.deserialize,
            allOffsets,
            TocItem(),
          ) ??
          []) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readObjectOrNull<Href>(
            offset,
            HrefSchema.deserialize,
            allOffsets,
          ) ??
          Href()) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension TocItemQueryFilter
    on QueryBuilder<TocItem, TocItem, QFilterCondition> {
  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> childrenLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'children',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> childrenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'children',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> childrenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'children',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> childrenLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'children',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition>
      childrenLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'children',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> childrenLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'children',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> depthEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'depth',
        value: value,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> depthGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'depth',
        value: value,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> depthLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'depth',
        value: value,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> depthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'depth',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> idEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> idGreaterThan(
    int value, {
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

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> idLessThan(
    int value, {
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

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> idBetween(
    int lower,
    int upper, {
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

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> labelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> labelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> labelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> labelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'label',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> labelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> labelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> labelContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> labelMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'label',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> labelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> labelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> parentIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentId',
        value: value,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> parentIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parentId',
        value: value,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> parentIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parentId',
        value: value,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> parentIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> spineIndexEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spineIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> spineIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'spineIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> spineIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'spineIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> spineIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'spineIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TocItemQueryObject
    on QueryBuilder<TocItem, TocItem, QFilterCondition> {
  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> childrenElement(
      FilterQuery<TocItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'children');
    });
  }

  QueryBuilder<TocItem, TocItem, QAfterFilterCondition> href(
      FilterQuery<Href> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'href');
    });
  }
}
