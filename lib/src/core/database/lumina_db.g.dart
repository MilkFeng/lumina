// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lumina_db.dart';

// ignore_for_file: type=lint
class $ShelfBooksTable extends ShelfBooks
    with TableInfo<$ShelfBooksTable, ShelfBookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShelfBooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> authors =
      GeneratedColumn<String>(
        'authors',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($ShelfBooksTable.$converterauthors);
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> subjects =
      GeneratedColumn<String>(
        'subjects',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($ShelfBooksTable.$convertersubjects);
  static const VerificationMeta _totalChaptersMeta = const VerificationMeta(
    'totalChapters',
  );
  @override
  late final GeneratedColumn<int> totalChapters = GeneratedColumn<int>(
    'total_chapters',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _epubVersionMeta = const VerificationMeta(
    'epubVersion',
  );
  @override
  late final GeneratedColumn<String> epubVersion = GeneratedColumn<String>(
    'epub_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importDateMeta = const VerificationMeta(
    'importDate',
  );
  @override
  late final GeneratedColumn<int> importDate = GeneratedColumn<int>(
    'import_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<int> direction = GeneratedColumn<int>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentChapterIndexMeta =
      const VerificationMeta('currentChapterIndex');
  @override
  late final GeneratedColumn<int> currentChapterIndex = GeneratedColumn<int>(
    'current_chapter_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _readingProgressMeta = const VerificationMeta(
    'readingProgress',
  );
  @override
  late final GeneratedColumn<double> readingProgress = GeneratedColumn<double>(
    'reading_progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterScrollPositionMeta =
      const VerificationMeta('chapterScrollPosition');
  @override
  late final GeneratedColumn<double> chapterScrollPosition =
      GeneratedColumn<double>(
        'chapter_scroll_position',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastOpenedDateMeta = const VerificationMeta(
    'lastOpenedDate',
  );
  @override
  late final GeneratedColumn<int> lastOpenedDate = GeneratedColumn<int>(
    'last_opened_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFinishedMeta = const VerificationMeta(
    'isFinished',
  );
  @override
  late final GeneratedColumn<bool> isFinished = GeneratedColumn<bool>(
    'is_finished',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_finished" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedDateMeta = const VerificationMeta(
    'lastSyncedDate',
  );
  @override
  late final GeneratedColumn<int> lastSyncedDate = GeneratedColumn<int>(
    'last_synced_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileHash,
    filePath,
    coverPath,
    title,
    author,
    authors,
    description,
    subjects,
    totalChapters,
    epubVersion,
    importDate,
    direction,
    currentChapterIndex,
    readingProgress,
    chapterScrollPosition,
    lastOpenedDate,
    isFinished,
    groupName,
    isDeleted,
    updatedAt,
    lastSyncedDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shelf_books';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShelfBookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    } else if (isInserting) {
      context.missing(_fileHashMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('total_chapters')) {
      context.handle(
        _totalChaptersMeta,
        totalChapters.isAcceptableOrUnknown(
          data['total_chapters']!,
          _totalChaptersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalChaptersMeta);
    }
    if (data.containsKey('epub_version')) {
      context.handle(
        _epubVersionMeta,
        epubVersion.isAcceptableOrUnknown(
          data['epub_version']!,
          _epubVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_epubVersionMeta);
    }
    if (data.containsKey('import_date')) {
      context.handle(
        _importDateMeta,
        importDate.isAcceptableOrUnknown(data['import_date']!, _importDateMeta),
      );
    } else if (isInserting) {
      context.missing(_importDateMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('current_chapter_index')) {
      context.handle(
        _currentChapterIndexMeta,
        currentChapterIndex.isAcceptableOrUnknown(
          data['current_chapter_index']!,
          _currentChapterIndexMeta,
        ),
      );
    }
    if (data.containsKey('reading_progress')) {
      context.handle(
        _readingProgressMeta,
        readingProgress.isAcceptableOrUnknown(
          data['reading_progress']!,
          _readingProgressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_readingProgressMeta);
    }
    if (data.containsKey('chapter_scroll_position')) {
      context.handle(
        _chapterScrollPositionMeta,
        chapterScrollPosition.isAcceptableOrUnknown(
          data['chapter_scroll_position']!,
          _chapterScrollPositionMeta,
        ),
      );
    }
    if (data.containsKey('last_opened_date')) {
      context.handle(
        _lastOpenedDateMeta,
        lastOpenedDate.isAcceptableOrUnknown(
          data['last_opened_date']!,
          _lastOpenedDateMeta,
        ),
      );
    }
    if (data.containsKey('is_finished')) {
      context.handle(
        _isFinishedMeta,
        isFinished.isAcceptableOrUnknown(data['is_finished']!, _isFinishedMeta),
      );
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_synced_date')) {
      context.handle(
        _lastSyncedDateMeta,
        lastSyncedDate.isAcceptableOrUnknown(
          data['last_synced_date']!,
          _lastSyncedDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShelfBookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShelfBookRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      authors: $ShelfBooksTable.$converterauthors.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}authors'],
        )!,
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      subjects: $ShelfBooksTable.$convertersubjects.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}subjects'],
        )!,
      ),
      totalChapters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_chapters'],
      )!,
      epubVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epub_version'],
      )!,
      importDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}import_date'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}direction'],
      )!,
      currentChapterIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_chapter_index'],
      )!,
      readingProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reading_progress'],
      )!,
      chapterScrollPosition: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}chapter_scroll_position'],
      ),
      lastOpenedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_opened_date'],
      ),
      isFinished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_finished'],
      )!,
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      lastSyncedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_date'],
      ),
    );
  }

  @override
  $ShelfBooksTable createAlias(String alias) {
    return $ShelfBooksTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterauthors =
      const StringListConverter();
  static TypeConverter<List<String>, String> $convertersubjects =
      const StringListConverter();
}

class ShelfBookRow extends DataClass implements Insertable<ShelfBookRow> {
  /// Auto-increment primary key. Kept as [IntColumn] so existing ids stay valid
  /// when a row is updated through [ShelfBookRow].
  final int id;

  /// SHA-256 hash of the original EPUB file (unique identifier).
  final String fileHash;

  /// Absolute path to the compressed .epub file.
  /// Null while a synced book is still waiting for download.
  final String? filePath;

  /// Absolute path to the extracted cover image.
  final String? coverPath;
  final String title;
  final String author;

  /// All authors as a JSON array.
  final List<String> authors;
  final String? description;

  /// Subject tags/genres as a JSON array.
  final List<String> subjects;
  final int totalChapters;
  final String epubVersion;

  /// Import timestamp (milliseconds since epoch).
  final int importDate;

  /// Reading direction from the spine: 0 = LTR, 1 = RTL.
  final int direction;
  final int currentChapterIndex;

  /// Overall reading progress (0.0 to 1.0).
  final double readingProgress;

  /// Scroll position within the current chapter (0.0 to 1.0).
  final double? chapterScrollPosition;

  /// Last time the book was opened (milliseconds since epoch).
  final int? lastOpenedDate;
  final bool isFinished;

  /// Group name for organizing books; null means root level.
  final String? groupName;

  /// Soft delete flag (for trash/sync safety).
  final bool isDeleted;

  /// Last modification timestamp (milliseconds since epoch).
  final int updatedAt;

  /// Sync status: null = never synced, timestamp = last sync time.
  final int? lastSyncedDate;
  const ShelfBookRow({
    required this.id,
    required this.fileHash,
    this.filePath,
    this.coverPath,
    required this.title,
    required this.author,
    required this.authors,
    this.description,
    required this.subjects,
    required this.totalChapters,
    required this.epubVersion,
    required this.importDate,
    required this.direction,
    required this.currentChapterIndex,
    required this.readingProgress,
    this.chapterScrollPosition,
    this.lastOpenedDate,
    required this.isFinished,
    this.groupName,
    required this.isDeleted,
    required this.updatedAt,
    this.lastSyncedDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_hash'] = Variable<String>(fileHash);
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    map['title'] = Variable<String>(title);
    map['author'] = Variable<String>(author);
    {
      map['authors'] = Variable<String>(
        $ShelfBooksTable.$converterauthors.toSql(authors),
      );
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    {
      map['subjects'] = Variable<String>(
        $ShelfBooksTable.$convertersubjects.toSql(subjects),
      );
    }
    map['total_chapters'] = Variable<int>(totalChapters);
    map['epub_version'] = Variable<String>(epubVersion);
    map['import_date'] = Variable<int>(importDate);
    map['direction'] = Variable<int>(direction);
    map['current_chapter_index'] = Variable<int>(currentChapterIndex);
    map['reading_progress'] = Variable<double>(readingProgress);
    if (!nullToAbsent || chapterScrollPosition != null) {
      map['chapter_scroll_position'] = Variable<double>(chapterScrollPosition);
    }
    if (!nullToAbsent || lastOpenedDate != null) {
      map['last_opened_date'] = Variable<int>(lastOpenedDate);
    }
    map['is_finished'] = Variable<bool>(isFinished);
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || lastSyncedDate != null) {
      map['last_synced_date'] = Variable<int>(lastSyncedDate);
    }
    return map;
  }

  ShelfBooksCompanion toCompanion(bool nullToAbsent) {
    return ShelfBooksCompanion(
      id: Value(id),
      fileHash: Value(fileHash),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      title: Value(title),
      author: Value(author),
      authors: Value(authors),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      subjects: Value(subjects),
      totalChapters: Value(totalChapters),
      epubVersion: Value(epubVersion),
      importDate: Value(importDate),
      direction: Value(direction),
      currentChapterIndex: Value(currentChapterIndex),
      readingProgress: Value(readingProgress),
      chapterScrollPosition: chapterScrollPosition == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterScrollPosition),
      lastOpenedDate: lastOpenedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedDate),
      isFinished: Value(isFinished),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
      isDeleted: Value(isDeleted),
      updatedAt: Value(updatedAt),
      lastSyncedDate: lastSyncedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedDate),
    );
  }

  factory ShelfBookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShelfBookRow(
      id: serializer.fromJson<int>(json['id']),
      fileHash: serializer.fromJson<String>(json['fileHash']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String>(json['author']),
      authors: serializer.fromJson<List<String>>(json['authors']),
      description: serializer.fromJson<String?>(json['description']),
      subjects: serializer.fromJson<List<String>>(json['subjects']),
      totalChapters: serializer.fromJson<int>(json['totalChapters']),
      epubVersion: serializer.fromJson<String>(json['epubVersion']),
      importDate: serializer.fromJson<int>(json['importDate']),
      direction: serializer.fromJson<int>(json['direction']),
      currentChapterIndex: serializer.fromJson<int>(
        json['currentChapterIndex'],
      ),
      readingProgress: serializer.fromJson<double>(json['readingProgress']),
      chapterScrollPosition: serializer.fromJson<double?>(
        json['chapterScrollPosition'],
      ),
      lastOpenedDate: serializer.fromJson<int?>(json['lastOpenedDate']),
      isFinished: serializer.fromJson<bool>(json['isFinished']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lastSyncedDate: serializer.fromJson<int?>(json['lastSyncedDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fileHash': serializer.toJson<String>(fileHash),
      'filePath': serializer.toJson<String?>(filePath),
      'coverPath': serializer.toJson<String?>(coverPath),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String>(author),
      'authors': serializer.toJson<List<String>>(authors),
      'description': serializer.toJson<String?>(description),
      'subjects': serializer.toJson<List<String>>(subjects),
      'totalChapters': serializer.toJson<int>(totalChapters),
      'epubVersion': serializer.toJson<String>(epubVersion),
      'importDate': serializer.toJson<int>(importDate),
      'direction': serializer.toJson<int>(direction),
      'currentChapterIndex': serializer.toJson<int>(currentChapterIndex),
      'readingProgress': serializer.toJson<double>(readingProgress),
      'chapterScrollPosition': serializer.toJson<double?>(
        chapterScrollPosition,
      ),
      'lastOpenedDate': serializer.toJson<int?>(lastOpenedDate),
      'isFinished': serializer.toJson<bool>(isFinished),
      'groupName': serializer.toJson<String?>(groupName),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lastSyncedDate': serializer.toJson<int?>(lastSyncedDate),
    };
  }

  ShelfBookRow copyWith({
    int? id,
    String? fileHash,
    Value<String?> filePath = const Value.absent(),
    Value<String?> coverPath = const Value.absent(),
    String? title,
    String? author,
    List<String>? authors,
    Value<String?> description = const Value.absent(),
    List<String>? subjects,
    int? totalChapters,
    String? epubVersion,
    int? importDate,
    int? direction,
    int? currentChapterIndex,
    double? readingProgress,
    Value<double?> chapterScrollPosition = const Value.absent(),
    Value<int?> lastOpenedDate = const Value.absent(),
    bool? isFinished,
    Value<String?> groupName = const Value.absent(),
    bool? isDeleted,
    int? updatedAt,
    Value<int?> lastSyncedDate = const Value.absent(),
  }) => ShelfBookRow(
    id: id ?? this.id,
    fileHash: fileHash ?? this.fileHash,
    filePath: filePath.present ? filePath.value : this.filePath,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    title: title ?? this.title,
    author: author ?? this.author,
    authors: authors ?? this.authors,
    description: description.present ? description.value : this.description,
    subjects: subjects ?? this.subjects,
    totalChapters: totalChapters ?? this.totalChapters,
    epubVersion: epubVersion ?? this.epubVersion,
    importDate: importDate ?? this.importDate,
    direction: direction ?? this.direction,
    currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
    readingProgress: readingProgress ?? this.readingProgress,
    chapterScrollPosition: chapterScrollPosition.present
        ? chapterScrollPosition.value
        : this.chapterScrollPosition,
    lastOpenedDate: lastOpenedDate.present
        ? lastOpenedDate.value
        : this.lastOpenedDate,
    isFinished: isFinished ?? this.isFinished,
    groupName: groupName.present ? groupName.value : this.groupName,
    isDeleted: isDeleted ?? this.isDeleted,
    updatedAt: updatedAt ?? this.updatedAt,
    lastSyncedDate: lastSyncedDate.present
        ? lastSyncedDate.value
        : this.lastSyncedDate,
  );
  ShelfBookRow copyWithCompanion(ShelfBooksCompanion data) {
    return ShelfBookRow(
      id: data.id.present ? data.id.value : this.id,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      authors: data.authors.present ? data.authors.value : this.authors,
      description: data.description.present
          ? data.description.value
          : this.description,
      subjects: data.subjects.present ? data.subjects.value : this.subjects,
      totalChapters: data.totalChapters.present
          ? data.totalChapters.value
          : this.totalChapters,
      epubVersion: data.epubVersion.present
          ? data.epubVersion.value
          : this.epubVersion,
      importDate: data.importDate.present
          ? data.importDate.value
          : this.importDate,
      direction: data.direction.present ? data.direction.value : this.direction,
      currentChapterIndex: data.currentChapterIndex.present
          ? data.currentChapterIndex.value
          : this.currentChapterIndex,
      readingProgress: data.readingProgress.present
          ? data.readingProgress.value
          : this.readingProgress,
      chapterScrollPosition: data.chapterScrollPosition.present
          ? data.chapterScrollPosition.value
          : this.chapterScrollPosition,
      lastOpenedDate: data.lastOpenedDate.present
          ? data.lastOpenedDate.value
          : this.lastOpenedDate,
      isFinished: data.isFinished.present
          ? data.isFinished.value
          : this.isFinished,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastSyncedDate: data.lastSyncedDate.present
          ? data.lastSyncedDate.value
          : this.lastSyncedDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShelfBookRow(')
          ..write('id: $id, ')
          ..write('fileHash: $fileHash, ')
          ..write('filePath: $filePath, ')
          ..write('coverPath: $coverPath, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('authors: $authors, ')
          ..write('description: $description, ')
          ..write('subjects: $subjects, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('epubVersion: $epubVersion, ')
          ..write('importDate: $importDate, ')
          ..write('direction: $direction, ')
          ..write('currentChapterIndex: $currentChapterIndex, ')
          ..write('readingProgress: $readingProgress, ')
          ..write('chapterScrollPosition: $chapterScrollPosition, ')
          ..write('lastOpenedDate: $lastOpenedDate, ')
          ..write('isFinished: $isFinished, ')
          ..write('groupName: $groupName, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedDate: $lastSyncedDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    fileHash,
    filePath,
    coverPath,
    title,
    author,
    authors,
    description,
    subjects,
    totalChapters,
    epubVersion,
    importDate,
    direction,
    currentChapterIndex,
    readingProgress,
    chapterScrollPosition,
    lastOpenedDate,
    isFinished,
    groupName,
    isDeleted,
    updatedAt,
    lastSyncedDate,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShelfBookRow &&
          other.id == this.id &&
          other.fileHash == this.fileHash &&
          other.filePath == this.filePath &&
          other.coverPath == this.coverPath &&
          other.title == this.title &&
          other.author == this.author &&
          other.authors == this.authors &&
          other.description == this.description &&
          other.subjects == this.subjects &&
          other.totalChapters == this.totalChapters &&
          other.epubVersion == this.epubVersion &&
          other.importDate == this.importDate &&
          other.direction == this.direction &&
          other.currentChapterIndex == this.currentChapterIndex &&
          other.readingProgress == this.readingProgress &&
          other.chapterScrollPosition == this.chapterScrollPosition &&
          other.lastOpenedDate == this.lastOpenedDate &&
          other.isFinished == this.isFinished &&
          other.groupName == this.groupName &&
          other.isDeleted == this.isDeleted &&
          other.updatedAt == this.updatedAt &&
          other.lastSyncedDate == this.lastSyncedDate);
}

class ShelfBooksCompanion extends UpdateCompanion<ShelfBookRow> {
  final Value<int> id;
  final Value<String> fileHash;
  final Value<String?> filePath;
  final Value<String?> coverPath;
  final Value<String> title;
  final Value<String> author;
  final Value<List<String>> authors;
  final Value<String?> description;
  final Value<List<String>> subjects;
  final Value<int> totalChapters;
  final Value<String> epubVersion;
  final Value<int> importDate;
  final Value<int> direction;
  final Value<int> currentChapterIndex;
  final Value<double> readingProgress;
  final Value<double?> chapterScrollPosition;
  final Value<int?> lastOpenedDate;
  final Value<bool> isFinished;
  final Value<String?> groupName;
  final Value<bool> isDeleted;
  final Value<int> updatedAt;
  final Value<int?> lastSyncedDate;
  const ShelfBooksCompanion({
    this.id = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.filePath = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.authors = const Value.absent(),
    this.description = const Value.absent(),
    this.subjects = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.epubVersion = const Value.absent(),
    this.importDate = const Value.absent(),
    this.direction = const Value.absent(),
    this.currentChapterIndex = const Value.absent(),
    this.readingProgress = const Value.absent(),
    this.chapterScrollPosition = const Value.absent(),
    this.lastOpenedDate = const Value.absent(),
    this.isFinished = const Value.absent(),
    this.groupName = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastSyncedDate = const Value.absent(),
  });
  ShelfBooksCompanion.insert({
    this.id = const Value.absent(),
    required String fileHash,
    this.filePath = const Value.absent(),
    this.coverPath = const Value.absent(),
    required String title,
    required String author,
    required List<String> authors,
    this.description = const Value.absent(),
    required List<String> subjects,
    required int totalChapters,
    required String epubVersion,
    required int importDate,
    required int direction,
    this.currentChapterIndex = const Value.absent(),
    required double readingProgress,
    this.chapterScrollPosition = const Value.absent(),
    this.lastOpenedDate = const Value.absent(),
    this.isFinished = const Value.absent(),
    this.groupName = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required int updatedAt,
    this.lastSyncedDate = const Value.absent(),
  }) : fileHash = Value(fileHash),
       title = Value(title),
       author = Value(author),
       authors = Value(authors),
       subjects = Value(subjects),
       totalChapters = Value(totalChapters),
       epubVersion = Value(epubVersion),
       importDate = Value(importDate),
       direction = Value(direction),
       readingProgress = Value(readingProgress),
       updatedAt = Value(updatedAt);
  static Insertable<ShelfBookRow> custom({
    Expression<int>? id,
    Expression<String>? fileHash,
    Expression<String>? filePath,
    Expression<String>? coverPath,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? authors,
    Expression<String>? description,
    Expression<String>? subjects,
    Expression<int>? totalChapters,
    Expression<String>? epubVersion,
    Expression<int>? importDate,
    Expression<int>? direction,
    Expression<int>? currentChapterIndex,
    Expression<double>? readingProgress,
    Expression<double>? chapterScrollPosition,
    Expression<int>? lastOpenedDate,
    Expression<bool>? isFinished,
    Expression<String>? groupName,
    Expression<bool>? isDeleted,
    Expression<int>? updatedAt,
    Expression<int>? lastSyncedDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileHash != null) 'file_hash': fileHash,
      if (filePath != null) 'file_path': filePath,
      if (coverPath != null) 'cover_path': coverPath,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (authors != null) 'authors': authors,
      if (description != null) 'description': description,
      if (subjects != null) 'subjects': subjects,
      if (totalChapters != null) 'total_chapters': totalChapters,
      if (epubVersion != null) 'epub_version': epubVersion,
      if (importDate != null) 'import_date': importDate,
      if (direction != null) 'direction': direction,
      if (currentChapterIndex != null)
        'current_chapter_index': currentChapterIndex,
      if (readingProgress != null) 'reading_progress': readingProgress,
      if (chapterScrollPosition != null)
        'chapter_scroll_position': chapterScrollPosition,
      if (lastOpenedDate != null) 'last_opened_date': lastOpenedDate,
      if (isFinished != null) 'is_finished': isFinished,
      if (groupName != null) 'group_name': groupName,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastSyncedDate != null) 'last_synced_date': lastSyncedDate,
    });
  }

  ShelfBooksCompanion copyWith({
    Value<int>? id,
    Value<String>? fileHash,
    Value<String?>? filePath,
    Value<String?>? coverPath,
    Value<String>? title,
    Value<String>? author,
    Value<List<String>>? authors,
    Value<String?>? description,
    Value<List<String>>? subjects,
    Value<int>? totalChapters,
    Value<String>? epubVersion,
    Value<int>? importDate,
    Value<int>? direction,
    Value<int>? currentChapterIndex,
    Value<double>? readingProgress,
    Value<double?>? chapterScrollPosition,
    Value<int?>? lastOpenedDate,
    Value<bool>? isFinished,
    Value<String?>? groupName,
    Value<bool>? isDeleted,
    Value<int>? updatedAt,
    Value<int?>? lastSyncedDate,
  }) {
    return ShelfBooksCompanion(
      id: id ?? this.id,
      fileHash: fileHash ?? this.fileHash,
      filePath: filePath ?? this.filePath,
      coverPath: coverPath ?? this.coverPath,
      title: title ?? this.title,
      author: author ?? this.author,
      authors: authors ?? this.authors,
      description: description ?? this.description,
      subjects: subjects ?? this.subjects,
      totalChapters: totalChapters ?? this.totalChapters,
      epubVersion: epubVersion ?? this.epubVersion,
      importDate: importDate ?? this.importDate,
      direction: direction ?? this.direction,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      readingProgress: readingProgress ?? this.readingProgress,
      chapterScrollPosition:
          chapterScrollPosition ?? this.chapterScrollPosition,
      lastOpenedDate: lastOpenedDate ?? this.lastOpenedDate,
      isFinished: isFinished ?? this.isFinished,
      groupName: groupName ?? this.groupName,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedDate: lastSyncedDate ?? this.lastSyncedDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (authors.present) {
      map['authors'] = Variable<String>(
        $ShelfBooksTable.$converterauthors.toSql(authors.value),
      );
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (subjects.present) {
      map['subjects'] = Variable<String>(
        $ShelfBooksTable.$convertersubjects.toSql(subjects.value),
      );
    }
    if (totalChapters.present) {
      map['total_chapters'] = Variable<int>(totalChapters.value);
    }
    if (epubVersion.present) {
      map['epub_version'] = Variable<String>(epubVersion.value);
    }
    if (importDate.present) {
      map['import_date'] = Variable<int>(importDate.value);
    }
    if (direction.present) {
      map['direction'] = Variable<int>(direction.value);
    }
    if (currentChapterIndex.present) {
      map['current_chapter_index'] = Variable<int>(currentChapterIndex.value);
    }
    if (readingProgress.present) {
      map['reading_progress'] = Variable<double>(readingProgress.value);
    }
    if (chapterScrollPosition.present) {
      map['chapter_scroll_position'] = Variable<double>(
        chapterScrollPosition.value,
      );
    }
    if (lastOpenedDate.present) {
      map['last_opened_date'] = Variable<int>(lastOpenedDate.value);
    }
    if (isFinished.present) {
      map['is_finished'] = Variable<bool>(isFinished.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lastSyncedDate.present) {
      map['last_synced_date'] = Variable<int>(lastSyncedDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShelfBooksCompanion(')
          ..write('id: $id, ')
          ..write('fileHash: $fileHash, ')
          ..write('filePath: $filePath, ')
          ..write('coverPath: $coverPath, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('authors: $authors, ')
          ..write('description: $description, ')
          ..write('subjects: $subjects, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('epubVersion: $epubVersion, ')
          ..write('importDate: $importDate, ')
          ..write('direction: $direction, ')
          ..write('currentChapterIndex: $currentChapterIndex, ')
          ..write('readingProgress: $readingProgress, ')
          ..write('chapterScrollPosition: $chapterScrollPosition, ')
          ..write('lastOpenedDate: $lastOpenedDate, ')
          ..write('isFinished: $isFinished, ')
          ..write('groupName: $groupName, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastSyncedDate: $lastSyncedDate')
          ..write(')'))
        .toString();
  }
}

class $ShelfGroupsTable extends ShelfGroups
    with TableInfo<$ShelfGroupsTable, ShelfGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShelfGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _creationDateMeta = const VerificationMeta(
    'creationDate',
  );
  @override
  late final GeneratedColumn<int> creationDate = GeneratedColumn<int>(
    'creation_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    creationDate,
    updatedAt,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shelf_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShelfGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('creation_date')) {
      context.handle(
        _creationDateMeta,
        creationDate.isAcceptableOrUnknown(
          data['creation_date']!,
          _creationDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_creationDateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShelfGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShelfGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      creationDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}creation_date'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $ShelfGroupsTable createAlias(String alias) {
    return $ShelfGroupsTable(attachedDatabase, alias);
  }
}

class ShelfGroupRow extends DataClass implements Insertable<ShelfGroupRow> {
  /// Auto-increment primary key.
  final int id;

  /// Display name for the folder.
  final String name;

  /// Creation timestamp (milliseconds since epoch).
  final int creationDate;

  /// Last update timestamp (milliseconds since epoch).
  final int updatedAt;

  /// Soft delete flag for sync safety.
  final bool isDeleted;
  const ShelfGroupRow({
    required this.id,
    required this.name,
    required this.creationDate,
    required this.updatedAt,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['creation_date'] = Variable<int>(creationDate);
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ShelfGroupsCompanion toCompanion(bool nullToAbsent) {
    return ShelfGroupsCompanion(
      id: Value(id),
      name: Value(name),
      creationDate: Value(creationDate),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory ShelfGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShelfGroupRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      creationDate: serializer.fromJson<int>(json['creationDate']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'creationDate': serializer.toJson<int>(creationDate),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  ShelfGroupRow copyWith({
    int? id,
    String? name,
    int? creationDate,
    int? updatedAt,
    bool? isDeleted,
  }) => ShelfGroupRow(
    id: id ?? this.id,
    name: name ?? this.name,
    creationDate: creationDate ?? this.creationDate,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  ShelfGroupRow copyWithCompanion(ShelfGroupsCompanion data) {
    return ShelfGroupRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      creationDate: data.creationDate.present
          ? data.creationDate.value
          : this.creationDate,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShelfGroupRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('creationDate: $creationDate, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, creationDate, updatedAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShelfGroupRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.creationDate == this.creationDate &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class ShelfGroupsCompanion extends UpdateCompanion<ShelfGroupRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> creationDate;
  final Value<int> updatedAt;
  final Value<bool> isDeleted;
  const ShelfGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.creationDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
  });
  ShelfGroupsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int creationDate,
    required int updatedAt,
    this.isDeleted = const Value.absent(),
  }) : name = Value(name),
       creationDate = Value(creationDate),
       updatedAt = Value(updatedAt);
  static Insertable<ShelfGroupRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? creationDate,
    Expression<int>? updatedAt,
    Expression<bool>? isDeleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (creationDate != null) 'creation_date': creationDate,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
    });
  }

  ShelfGroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? creationDate,
    Value<int>? updatedAt,
    Value<bool>? isDeleted,
  }) {
    return ShelfGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      creationDate: creationDate ?? this.creationDate,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (creationDate.present) {
      map['creation_date'] = Variable<int>(creationDate.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShelfGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('creationDate: $creationDate, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }
}

class $BookManifestsTable extends BookManifests
    with TableInfo<$BookManifestsTable, BookManifestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookManifestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _opfRootPathMeta = const VerificationMeta(
    'opfRootPath',
  );
  @override
  late final GeneratedColumn<String> opfRootPath = GeneratedColumn<String>(
    'opf_root_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<SpineItem>, String> spine =
      GeneratedColumn<String>(
        'spine',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<SpineItem>>($BookManifestsTable.$converterspine);
  @override
  late final GeneratedColumnWithTypeConverter<List<TocItem>, String> toc =
      GeneratedColumn<String>(
        'toc',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<TocItem>>($BookManifestsTable.$convertertoc);
  @override
  late final GeneratedColumnWithTypeConverter<List<ManifestItem>, String>
  manifest = GeneratedColumn<String>(
    'manifest',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<ManifestItem>>($BookManifestsTable.$convertermanifest);
  static const VerificationMeta _epubVersionMeta = const VerificationMeta(
    'epubVersion',
  );
  @override
  late final GeneratedColumn<String> epubVersion = GeneratedColumn<String>(
    'epub_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedMeta = const VerificationMeta(
    'lastUpdated',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdated = GeneratedColumn<DateTime>(
    'last_updated',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileHash,
    opfRootPath,
    spine,
    toc,
    manifest,
    epubVersion,
    lastUpdated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_manifests';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookManifestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    } else if (isInserting) {
      context.missing(_fileHashMeta);
    }
    if (data.containsKey('opf_root_path')) {
      context.handle(
        _opfRootPathMeta,
        opfRootPath.isAcceptableOrUnknown(
          data['opf_root_path']!,
          _opfRootPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_opfRootPathMeta);
    }
    if (data.containsKey('epub_version')) {
      context.handle(
        _epubVersionMeta,
        epubVersion.isAcceptableOrUnknown(
          data['epub_version']!,
          _epubVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_epubVersionMeta);
    }
    if (data.containsKey('last_updated')) {
      context.handle(
        _lastUpdatedMeta,
        lastUpdated.isAcceptableOrUnknown(
          data['last_updated']!,
          _lastUpdatedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookManifestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookManifestRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      )!,
      opfRootPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opf_root_path'],
      )!,
      spine: $BookManifestsTable.$converterspine.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}spine'],
        )!,
      ),
      toc: $BookManifestsTable.$convertertoc.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}toc'],
        )!,
      ),
      manifest: $BookManifestsTable.$convertermanifest.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}manifest'],
        )!,
      ),
      epubVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epub_version'],
      )!,
      lastUpdated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated'],
      )!,
    );
  }

  @override
  $BookManifestsTable createAlias(String alias) {
    return $BookManifestsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<SpineItem>, String> $converterspine =
      const SpineListConverter();
  static TypeConverter<List<TocItem>, String> $convertertoc =
      const TocListConverter();
  static TypeConverter<List<ManifestItem>, String> $convertermanifest =
      const ManifestListConverter();
}

class BookManifestRow extends DataClass implements Insertable<BookManifestRow> {
  /// Auto-increment primary key.
  final int id;

  /// SHA-256 hash of the original EPUB file, linking back to `ShelfBooks`.
  final String fileHash;

  /// Path to the OPF file within the ZIP, e.g. `OEBPS/content.opf`.
  final String opfRootPath;

  /// Linear reading order from the OPF spine, stored as a JSON array.
  final List<SpineItem> spine;

  /// Nested navigation tree parsed from NCX (EPUB 2) or NAV (EPUB 3),
  /// stored as a JSON array.
  final List<TocItem> toc;

  /// Manifest entries (id → resource path) used for CSS/image/font resolution,
  /// stored as a JSON array.
  final List<ManifestItem> manifest;

  /// EPUB version, e.g. `2.0` or `3.0`.
  final String epubVersion;

  /// Timestamp when the manifest was last updated.
  final DateTime lastUpdated;
  const BookManifestRow({
    required this.id,
    required this.fileHash,
    required this.opfRootPath,
    required this.spine,
    required this.toc,
    required this.manifest,
    required this.epubVersion,
    required this.lastUpdated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_hash'] = Variable<String>(fileHash);
    map['opf_root_path'] = Variable<String>(opfRootPath);
    {
      map['spine'] = Variable<String>(
        $BookManifestsTable.$converterspine.toSql(spine),
      );
    }
    {
      map['toc'] = Variable<String>(
        $BookManifestsTable.$convertertoc.toSql(toc),
      );
    }
    {
      map['manifest'] = Variable<String>(
        $BookManifestsTable.$convertermanifest.toSql(manifest),
      );
    }
    map['epub_version'] = Variable<String>(epubVersion);
    map['last_updated'] = Variable<DateTime>(lastUpdated);
    return map;
  }

  BookManifestsCompanion toCompanion(bool nullToAbsent) {
    return BookManifestsCompanion(
      id: Value(id),
      fileHash: Value(fileHash),
      opfRootPath: Value(opfRootPath),
      spine: Value(spine),
      toc: Value(toc),
      manifest: Value(manifest),
      epubVersion: Value(epubVersion),
      lastUpdated: Value(lastUpdated),
    );
  }

  factory BookManifestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookManifestRow(
      id: serializer.fromJson<int>(json['id']),
      fileHash: serializer.fromJson<String>(json['fileHash']),
      opfRootPath: serializer.fromJson<String>(json['opfRootPath']),
      spine: serializer.fromJson<List<SpineItem>>(json['spine']),
      toc: serializer.fromJson<List<TocItem>>(json['toc']),
      manifest: serializer.fromJson<List<ManifestItem>>(json['manifest']),
      epubVersion: serializer.fromJson<String>(json['epubVersion']),
      lastUpdated: serializer.fromJson<DateTime>(json['lastUpdated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fileHash': serializer.toJson<String>(fileHash),
      'opfRootPath': serializer.toJson<String>(opfRootPath),
      'spine': serializer.toJson<List<SpineItem>>(spine),
      'toc': serializer.toJson<List<TocItem>>(toc),
      'manifest': serializer.toJson<List<ManifestItem>>(manifest),
      'epubVersion': serializer.toJson<String>(epubVersion),
      'lastUpdated': serializer.toJson<DateTime>(lastUpdated),
    };
  }

  BookManifestRow copyWith({
    int? id,
    String? fileHash,
    String? opfRootPath,
    List<SpineItem>? spine,
    List<TocItem>? toc,
    List<ManifestItem>? manifest,
    String? epubVersion,
    DateTime? lastUpdated,
  }) => BookManifestRow(
    id: id ?? this.id,
    fileHash: fileHash ?? this.fileHash,
    opfRootPath: opfRootPath ?? this.opfRootPath,
    spine: spine ?? this.spine,
    toc: toc ?? this.toc,
    manifest: manifest ?? this.manifest,
    epubVersion: epubVersion ?? this.epubVersion,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
  BookManifestRow copyWithCompanion(BookManifestsCompanion data) {
    return BookManifestRow(
      id: data.id.present ? data.id.value : this.id,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      opfRootPath: data.opfRootPath.present
          ? data.opfRootPath.value
          : this.opfRootPath,
      spine: data.spine.present ? data.spine.value : this.spine,
      toc: data.toc.present ? data.toc.value : this.toc,
      manifest: data.manifest.present ? data.manifest.value : this.manifest,
      epubVersion: data.epubVersion.present
          ? data.epubVersion.value
          : this.epubVersion,
      lastUpdated: data.lastUpdated.present
          ? data.lastUpdated.value
          : this.lastUpdated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookManifestRow(')
          ..write('id: $id, ')
          ..write('fileHash: $fileHash, ')
          ..write('opfRootPath: $opfRootPath, ')
          ..write('spine: $spine, ')
          ..write('toc: $toc, ')
          ..write('manifest: $manifest, ')
          ..write('epubVersion: $epubVersion, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fileHash,
    opfRootPath,
    spine,
    toc,
    manifest,
    epubVersion,
    lastUpdated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookManifestRow &&
          other.id == this.id &&
          other.fileHash == this.fileHash &&
          other.opfRootPath == this.opfRootPath &&
          other.spine == this.spine &&
          other.toc == this.toc &&
          other.manifest == this.manifest &&
          other.epubVersion == this.epubVersion &&
          other.lastUpdated == this.lastUpdated);
}

class BookManifestsCompanion extends UpdateCompanion<BookManifestRow> {
  final Value<int> id;
  final Value<String> fileHash;
  final Value<String> opfRootPath;
  final Value<List<SpineItem>> spine;
  final Value<List<TocItem>> toc;
  final Value<List<ManifestItem>> manifest;
  final Value<String> epubVersion;
  final Value<DateTime> lastUpdated;
  const BookManifestsCompanion({
    this.id = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.opfRootPath = const Value.absent(),
    this.spine = const Value.absent(),
    this.toc = const Value.absent(),
    this.manifest = const Value.absent(),
    this.epubVersion = const Value.absent(),
    this.lastUpdated = const Value.absent(),
  });
  BookManifestsCompanion.insert({
    this.id = const Value.absent(),
    required String fileHash,
    required String opfRootPath,
    required List<SpineItem> spine,
    required List<TocItem> toc,
    required List<ManifestItem> manifest,
    required String epubVersion,
    required DateTime lastUpdated,
  }) : fileHash = Value(fileHash),
       opfRootPath = Value(opfRootPath),
       spine = Value(spine),
       toc = Value(toc),
       manifest = Value(manifest),
       epubVersion = Value(epubVersion),
       lastUpdated = Value(lastUpdated);
  static Insertable<BookManifestRow> custom({
    Expression<int>? id,
    Expression<String>? fileHash,
    Expression<String>? opfRootPath,
    Expression<String>? spine,
    Expression<String>? toc,
    Expression<String>? manifest,
    Expression<String>? epubVersion,
    Expression<DateTime>? lastUpdated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileHash != null) 'file_hash': fileHash,
      if (opfRootPath != null) 'opf_root_path': opfRootPath,
      if (spine != null) 'spine': spine,
      if (toc != null) 'toc': toc,
      if (manifest != null) 'manifest': manifest,
      if (epubVersion != null) 'epub_version': epubVersion,
      if (lastUpdated != null) 'last_updated': lastUpdated,
    });
  }

  BookManifestsCompanion copyWith({
    Value<int>? id,
    Value<String>? fileHash,
    Value<String>? opfRootPath,
    Value<List<SpineItem>>? spine,
    Value<List<TocItem>>? toc,
    Value<List<ManifestItem>>? manifest,
    Value<String>? epubVersion,
    Value<DateTime>? lastUpdated,
  }) {
    return BookManifestsCompanion(
      id: id ?? this.id,
      fileHash: fileHash ?? this.fileHash,
      opfRootPath: opfRootPath ?? this.opfRootPath,
      spine: spine ?? this.spine,
      toc: toc ?? this.toc,
      manifest: manifest ?? this.manifest,
      epubVersion: epubVersion ?? this.epubVersion,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (opfRootPath.present) {
      map['opf_root_path'] = Variable<String>(opfRootPath.value);
    }
    if (spine.present) {
      map['spine'] = Variable<String>(
        $BookManifestsTable.$converterspine.toSql(spine.value),
      );
    }
    if (toc.present) {
      map['toc'] = Variable<String>(
        $BookManifestsTable.$convertertoc.toSql(toc.value),
      );
    }
    if (manifest.present) {
      map['manifest'] = Variable<String>(
        $BookManifestsTable.$convertermanifest.toSql(manifest.value),
      );
    }
    if (epubVersion.present) {
      map['epub_version'] = Variable<String>(epubVersion.value);
    }
    if (lastUpdated.present) {
      map['last_updated'] = Variable<DateTime>(lastUpdated.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookManifestsCompanion(')
          ..write('id: $id, ')
          ..write('fileHash: $fileHash, ')
          ..write('opfRootPath: $opfRootPath, ')
          ..write('spine: $spine, ')
          ..write('toc: $toc, ')
          ..write('manifest: $manifest, ')
          ..write('epubVersion: $epubVersion, ')
          ..write('lastUpdated: $lastUpdated')
          ..write(')'))
        .toString();
  }
}

abstract class _$LuminaDb extends GeneratedDatabase {
  _$LuminaDb(QueryExecutor e) : super(e);
  $LuminaDbManager get managers => $LuminaDbManager(this);
  late final $ShelfBooksTable shelfBooks = $ShelfBooksTable(this);
  late final $ShelfGroupsTable shelfGroups = $ShelfGroupsTable(this);
  late final $BookManifestsTable bookManifests = $BookManifestsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    shelfBooks,
    shelfGroups,
    bookManifests,
  ];
}

typedef $$ShelfBooksTableCreateCompanionBuilder =
    ShelfBooksCompanion Function({
      Value<int> id,
      required String fileHash,
      Value<String?> filePath,
      Value<String?> coverPath,
      required String title,
      required String author,
      required List<String> authors,
      Value<String?> description,
      required List<String> subjects,
      required int totalChapters,
      required String epubVersion,
      required int importDate,
      required int direction,
      Value<int> currentChapterIndex,
      required double readingProgress,
      Value<double?> chapterScrollPosition,
      Value<int?> lastOpenedDate,
      Value<bool> isFinished,
      Value<String?> groupName,
      Value<bool> isDeleted,
      required int updatedAt,
      Value<int?> lastSyncedDate,
    });
typedef $$ShelfBooksTableUpdateCompanionBuilder =
    ShelfBooksCompanion Function({
      Value<int> id,
      Value<String> fileHash,
      Value<String?> filePath,
      Value<String?> coverPath,
      Value<String> title,
      Value<String> author,
      Value<List<String>> authors,
      Value<String?> description,
      Value<List<String>> subjects,
      Value<int> totalChapters,
      Value<String> epubVersion,
      Value<int> importDate,
      Value<int> direction,
      Value<int> currentChapterIndex,
      Value<double> readingProgress,
      Value<double?> chapterScrollPosition,
      Value<int?> lastOpenedDate,
      Value<bool> isFinished,
      Value<String?> groupName,
      Value<bool> isDeleted,
      Value<int> updatedAt,
      Value<int?> lastSyncedDate,
    });

class $$ShelfBooksTableFilterComposer
    extends Composer<_$LuminaDb, $ShelfBooksTable> {
  $$ShelfBooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get authors => $composableBuilder(
    column: $table.authors,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get subjects => $composableBuilder(
    column: $table.subjects,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epubVersion => $composableBuilder(
    column: $table.epubVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importDate => $composableBuilder(
    column: $table.importDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentChapterIndex => $composableBuilder(
    column: $table.currentChapterIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get readingProgress => $composableBuilder(
    column: $table.readingProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get chapterScrollPosition => $composableBuilder(
    column: $table.chapterScrollPosition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastOpenedDate => $composableBuilder(
    column: $table.lastOpenedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFinished => $composableBuilder(
    column: $table.isFinished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedDate => $composableBuilder(
    column: $table.lastSyncedDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShelfBooksTableOrderingComposer
    extends Composer<_$LuminaDb, $ShelfBooksTable> {
  $$ShelfBooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authors => $composableBuilder(
    column: $table.authors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjects => $composableBuilder(
    column: $table.subjects,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epubVersion => $composableBuilder(
    column: $table.epubVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importDate => $composableBuilder(
    column: $table.importDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentChapterIndex => $composableBuilder(
    column: $table.currentChapterIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get readingProgress => $composableBuilder(
    column: $table.readingProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get chapterScrollPosition => $composableBuilder(
    column: $table.chapterScrollPosition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastOpenedDate => $composableBuilder(
    column: $table.lastOpenedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFinished => $composableBuilder(
    column: $table.isFinished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedDate => $composableBuilder(
    column: $table.lastSyncedDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShelfBooksTableAnnotationComposer
    extends Composer<_$LuminaDb, $ShelfBooksTable> {
  $$ShelfBooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get authors =>
      $composableBuilder(column: $table.authors, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get subjects =>
      $composableBuilder(column: $table.subjects, builder: (column) => column);

  GeneratedColumn<int> get totalChapters => $composableBuilder(
    column: $table.totalChapters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get epubVersion => $composableBuilder(
    column: $table.epubVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get importDate => $composableBuilder(
    column: $table.importDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get currentChapterIndex => $composableBuilder(
    column: $table.currentChapterIndex,
    builder: (column) => column,
  );

  GeneratedColumn<double> get readingProgress => $composableBuilder(
    column: $table.readingProgress,
    builder: (column) => column,
  );

  GeneratedColumn<double> get chapterScrollPosition => $composableBuilder(
    column: $table.chapterScrollPosition,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastOpenedDate => $composableBuilder(
    column: $table.lastOpenedDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFinished => $composableBuilder(
    column: $table.isFinished,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lastSyncedDate => $composableBuilder(
    column: $table.lastSyncedDate,
    builder: (column) => column,
  );
}

class $$ShelfBooksTableTableManager
    extends
        RootTableManager<
          _$LuminaDb,
          $ShelfBooksTable,
          ShelfBookRow,
          $$ShelfBooksTableFilterComposer,
          $$ShelfBooksTableOrderingComposer,
          $$ShelfBooksTableAnnotationComposer,
          $$ShelfBooksTableCreateCompanionBuilder,
          $$ShelfBooksTableUpdateCompanionBuilder,
          (
            ShelfBookRow,
            BaseReferences<_$LuminaDb, $ShelfBooksTable, ShelfBookRow>,
          ),
          ShelfBookRow,
          PrefetchHooks Function()
        > {
  $$ShelfBooksTableTableManager(_$LuminaDb db, $ShelfBooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShelfBooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShelfBooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShelfBooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fileHash = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<List<String>> authors = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<List<String>> subjects = const Value.absent(),
                Value<int> totalChapters = const Value.absent(),
                Value<String> epubVersion = const Value.absent(),
                Value<int> importDate = const Value.absent(),
                Value<int> direction = const Value.absent(),
                Value<int> currentChapterIndex = const Value.absent(),
                Value<double> readingProgress = const Value.absent(),
                Value<double?> chapterScrollPosition = const Value.absent(),
                Value<int?> lastOpenedDate = const Value.absent(),
                Value<bool> isFinished = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> lastSyncedDate = const Value.absent(),
              }) => ShelfBooksCompanion(
                id: id,
                fileHash: fileHash,
                filePath: filePath,
                coverPath: coverPath,
                title: title,
                author: author,
                authors: authors,
                description: description,
                subjects: subjects,
                totalChapters: totalChapters,
                epubVersion: epubVersion,
                importDate: importDate,
                direction: direction,
                currentChapterIndex: currentChapterIndex,
                readingProgress: readingProgress,
                chapterScrollPosition: chapterScrollPosition,
                lastOpenedDate: lastOpenedDate,
                isFinished: isFinished,
                groupName: groupName,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                lastSyncedDate: lastSyncedDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fileHash,
                Value<String?> filePath = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                required String title,
                required String author,
                required List<String> authors,
                Value<String?> description = const Value.absent(),
                required List<String> subjects,
                required int totalChapters,
                required String epubVersion,
                required int importDate,
                required int direction,
                Value<int> currentChapterIndex = const Value.absent(),
                required double readingProgress,
                Value<double?> chapterScrollPosition = const Value.absent(),
                Value<int?> lastOpenedDate = const Value.absent(),
                Value<bool> isFinished = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required int updatedAt,
                Value<int?> lastSyncedDate = const Value.absent(),
              }) => ShelfBooksCompanion.insert(
                id: id,
                fileHash: fileHash,
                filePath: filePath,
                coverPath: coverPath,
                title: title,
                author: author,
                authors: authors,
                description: description,
                subjects: subjects,
                totalChapters: totalChapters,
                epubVersion: epubVersion,
                importDate: importDate,
                direction: direction,
                currentChapterIndex: currentChapterIndex,
                readingProgress: readingProgress,
                chapterScrollPosition: chapterScrollPosition,
                lastOpenedDate: lastOpenedDate,
                isFinished: isFinished,
                groupName: groupName,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                lastSyncedDate: lastSyncedDate,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShelfBooksTable, ShelfBookRow>(table),
                  BaseReferences<_$LuminaDb, $ShelfBooksTable, ShelfBookRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShelfBooksTableProcessedTableManager =
    ProcessedTableManager<
      _$LuminaDb,
      $ShelfBooksTable,
      ShelfBookRow,
      $$ShelfBooksTableFilterComposer,
      $$ShelfBooksTableOrderingComposer,
      $$ShelfBooksTableAnnotationComposer,
      $$ShelfBooksTableCreateCompanionBuilder,
      $$ShelfBooksTableUpdateCompanionBuilder,
      (
        ShelfBookRow,
        BaseReferences<_$LuminaDb, $ShelfBooksTable, ShelfBookRow>,
      ),
      ShelfBookRow,
      PrefetchHooks Function()
    >;
typedef $$ShelfGroupsTableCreateCompanionBuilder =
    ShelfGroupsCompanion Function({
      Value<int> id,
      required String name,
      required int creationDate,
      required int updatedAt,
      Value<bool> isDeleted,
    });
typedef $$ShelfGroupsTableUpdateCompanionBuilder =
    ShelfGroupsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> creationDate,
      Value<int> updatedAt,
      Value<bool> isDeleted,
    });

class $$ShelfGroupsTableFilterComposer
    extends Composer<_$LuminaDb, $ShelfGroupsTable> {
  $$ShelfGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creationDate => $composableBuilder(
    column: $table.creationDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShelfGroupsTableOrderingComposer
    extends Composer<_$LuminaDb, $ShelfGroupsTable> {
  $$ShelfGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creationDate => $composableBuilder(
    column: $table.creationDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShelfGroupsTableAnnotationComposer
    extends Composer<_$LuminaDb, $ShelfGroupsTable> {
  $$ShelfGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get creationDate => $composableBuilder(
    column: $table.creationDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$ShelfGroupsTableTableManager
    extends
        RootTableManager<
          _$LuminaDb,
          $ShelfGroupsTable,
          ShelfGroupRow,
          $$ShelfGroupsTableFilterComposer,
          $$ShelfGroupsTableOrderingComposer,
          $$ShelfGroupsTableAnnotationComposer,
          $$ShelfGroupsTableCreateCompanionBuilder,
          $$ShelfGroupsTableUpdateCompanionBuilder,
          (
            ShelfGroupRow,
            BaseReferences<_$LuminaDb, $ShelfGroupsTable, ShelfGroupRow>,
          ),
          ShelfGroupRow,
          PrefetchHooks Function()
        > {
  $$ShelfGroupsTableTableManager(_$LuminaDb db, $ShelfGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShelfGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShelfGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShelfGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> creationDate = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
              }) => ShelfGroupsCompanion(
                id: id,
                name: name,
                creationDate: creationDate,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int creationDate,
                required int updatedAt,
                Value<bool> isDeleted = const Value.absent(),
              }) => ShelfGroupsCompanion.insert(
                id: id,
                name: name,
                creationDate: creationDate,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShelfGroupsTable, ShelfGroupRow>(table),
                  BaseReferences<_$LuminaDb, $ShelfGroupsTable, ShelfGroupRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShelfGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$LuminaDb,
      $ShelfGroupsTable,
      ShelfGroupRow,
      $$ShelfGroupsTableFilterComposer,
      $$ShelfGroupsTableOrderingComposer,
      $$ShelfGroupsTableAnnotationComposer,
      $$ShelfGroupsTableCreateCompanionBuilder,
      $$ShelfGroupsTableUpdateCompanionBuilder,
      (
        ShelfGroupRow,
        BaseReferences<_$LuminaDb, $ShelfGroupsTable, ShelfGroupRow>,
      ),
      ShelfGroupRow,
      PrefetchHooks Function()
    >;
typedef $$BookManifestsTableCreateCompanionBuilder =
    BookManifestsCompanion Function({
      Value<int> id,
      required String fileHash,
      required String opfRootPath,
      required List<SpineItem> spine,
      required List<TocItem> toc,
      required List<ManifestItem> manifest,
      required String epubVersion,
      required DateTime lastUpdated,
    });
typedef $$BookManifestsTableUpdateCompanionBuilder =
    BookManifestsCompanion Function({
      Value<int> id,
      Value<String> fileHash,
      Value<String> opfRootPath,
      Value<List<SpineItem>> spine,
      Value<List<TocItem>> toc,
      Value<List<ManifestItem>> manifest,
      Value<String> epubVersion,
      Value<DateTime> lastUpdated,
    });

class $$BookManifestsTableFilterComposer
    extends Composer<_$LuminaDb, $BookManifestsTable> {
  $$BookManifestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opfRootPath => $composableBuilder(
    column: $table.opfRootPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<SpineItem>, List<SpineItem>, String>
  get spine => $composableBuilder(
    column: $table.spine,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<TocItem>, List<TocItem>, String>
  get toc => $composableBuilder(
    column: $table.toc,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<List<ManifestItem>, List<ManifestItem>, String>
  get manifest => $composableBuilder(
    column: $table.manifest,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get epubVersion => $composableBuilder(
    column: $table.epubVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookManifestsTableOrderingComposer
    extends Composer<_$LuminaDb, $BookManifestsTable> {
  $$BookManifestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opfRootPath => $composableBuilder(
    column: $table.opfRootPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get spine => $composableBuilder(
    column: $table.spine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toc => $composableBuilder(
    column: $table.toc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manifest => $composableBuilder(
    column: $table.manifest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epubVersion => $composableBuilder(
    column: $table.epubVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookManifestsTableAnnotationComposer
    extends Composer<_$LuminaDb, $BookManifestsTable> {
  $$BookManifestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<String> get opfRootPath => $composableBuilder(
    column: $table.opfRootPath,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<SpineItem>, String> get spine =>
      $composableBuilder(column: $table.spine, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<TocItem>, String> get toc =>
      $composableBuilder(column: $table.toc, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<ManifestItem>, String> get manifest =>
      $composableBuilder(column: $table.manifest, builder: (column) => column);

  GeneratedColumn<String> get epubVersion => $composableBuilder(
    column: $table.epubVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUpdated => $composableBuilder(
    column: $table.lastUpdated,
    builder: (column) => column,
  );
}

class $$BookManifestsTableTableManager
    extends
        RootTableManager<
          _$LuminaDb,
          $BookManifestsTable,
          BookManifestRow,
          $$BookManifestsTableFilterComposer,
          $$BookManifestsTableOrderingComposer,
          $$BookManifestsTableAnnotationComposer,
          $$BookManifestsTableCreateCompanionBuilder,
          $$BookManifestsTableUpdateCompanionBuilder,
          (
            BookManifestRow,
            BaseReferences<_$LuminaDb, $BookManifestsTable, BookManifestRow>,
          ),
          BookManifestRow,
          PrefetchHooks Function()
        > {
  $$BookManifestsTableTableManager(_$LuminaDb db, $BookManifestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookManifestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookManifestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookManifestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fileHash = const Value.absent(),
                Value<String> opfRootPath = const Value.absent(),
                Value<List<SpineItem>> spine = const Value.absent(),
                Value<List<TocItem>> toc = const Value.absent(),
                Value<List<ManifestItem>> manifest = const Value.absent(),
                Value<String> epubVersion = const Value.absent(),
                Value<DateTime> lastUpdated = const Value.absent(),
              }) => BookManifestsCompanion(
                id: id,
                fileHash: fileHash,
                opfRootPath: opfRootPath,
                spine: spine,
                toc: toc,
                manifest: manifest,
                epubVersion: epubVersion,
                lastUpdated: lastUpdated,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fileHash,
                required String opfRootPath,
                required List<SpineItem> spine,
                required List<TocItem> toc,
                required List<ManifestItem> manifest,
                required String epubVersion,
                required DateTime lastUpdated,
              }) => BookManifestsCompanion.insert(
                id: id,
                fileHash: fileHash,
                opfRootPath: opfRootPath,
                spine: spine,
                toc: toc,
                manifest: manifest,
                epubVersion: epubVersion,
                lastUpdated: lastUpdated,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookManifestsTable, BookManifestRow>(table),
                  BaseReferences<
                    _$LuminaDb,
                    $BookManifestsTable,
                    BookManifestRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookManifestsTableProcessedTableManager =
    ProcessedTableManager<
      _$LuminaDb,
      $BookManifestsTable,
      BookManifestRow,
      $$BookManifestsTableFilterComposer,
      $$BookManifestsTableOrderingComposer,
      $$BookManifestsTableAnnotationComposer,
      $$BookManifestsTableCreateCompanionBuilder,
      $$BookManifestsTableUpdateCompanionBuilder,
      (
        BookManifestRow,
        BaseReferences<_$LuminaDb, $BookManifestsTable, BookManifestRow>,
      ),
      BookManifestRow,
      PrefetchHooks Function()
    >;

class $LuminaDbManager {
  final _$LuminaDb _db;
  $LuminaDbManager(this._db);
  $$ShelfBooksTableTableManager get shelfBooks =>
      $$ShelfBooksTableTableManager(_db, _db.shelfBooks);
  $$ShelfGroupsTableTableManager get shelfGroups =>
      $$ShelfGroupsTableTableManager(_db, _db.shelfGroups);
  $$BookManifestsTableTableManager get bookManifests =>
      $$BookManifestsTableTableManager(_db, _db.bookManifests);
}
