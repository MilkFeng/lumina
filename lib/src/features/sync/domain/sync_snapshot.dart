/// WebDAV Sync Snapshot Data Models
/// Represents the JSON structure stored on WebDAV server
library;

/// Root snapshot structure
class SyncSnapshot {
  final SnapshotMeta meta;
  final List<SnapshotGroup> groups;
  final List<SnapshotBook> books;

  SyncSnapshot({required this.meta, required this.groups, required this.books});

  /// Parse from JSON
  factory SyncSnapshot.fromJson(Map<String, dynamic> json) {
    return SyncSnapshot(
      meta: SnapshotMeta.fromJson(json['meta'] as Map<String, dynamic>),
      groups: (json['groups'] as List<dynamic>)
          .map((e) => SnapshotGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      books: (json['books'] as List<dynamic>)
          .map((e) => SnapshotBook.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'meta': meta.toJson(),
      'groups': groups.map((e) => e.toJson()).toList(),
      'books': books.map((e) => e.toJson()).toList(),
    };
  }

  /// Create empty snapshot
  factory SyncSnapshot.empty({
    required String deviceId,
    required String appVersion,
  }) {
    return SyncSnapshot(
      meta: SnapshotMeta(
        version: 1,
        generatedAt: DateTime.now().millisecondsSinceEpoch,
        deviceId: deviceId,
        appVersion: appVersion,
      ),
      groups: [],
      books: [],
    );
  }
}

/// Snapshot metadata
class SnapshotMeta {
  final int version;
  final int generatedAt;
  final String deviceId;
  final String appVersion;

  SnapshotMeta({
    required this.version,
    required this.generatedAt,
    required this.deviceId,
    required this.appVersion,
  });

  factory SnapshotMeta.fromJson(Map<String, dynamic> json) {
    return SnapshotMeta(
      version: json['version'] as int,
      generatedAt: json['generatedAt'] as int,
      deviceId: json['deviceId'] as String,
      appVersion: json['appVersion'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'generatedAt': generatedAt,
      'deviceId': deviceId,
      'appVersion': appVersion,
    };
  }
}

/// Snapshot group entry
class SnapshotGroup {
  final String name;
  final int creationDate;
  final int updatedAt;
  final bool isDeleted;

  SnapshotGroup({
    required this.name,
    required this.creationDate,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory SnapshotGroup.fromJson(Map<String, dynamic> json) {
    return SnapshotGroup(
      name: json['name'] as String,
      creationDate: json['creationDate'] as int,
      updatedAt: json['updatedAt'] as int,
      isDeleted: json['isDeleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'creationDate': creationDate,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,
    };
  }
}

/// Snapshot book entry
class SnapshotBook {
  final String fileHash;
  final String? groupName;

  final String title;
  final String author;
  final List<String> authors;
  final String? description;
  final List<String> subjects;
  final int totalChapters;
  final String epubVersion;

  final int importDate;
  final int? lastOpenedDate;

  final int currentChapterIndex;
  final double readingProgress;
  final double? chapterScrollPosition;
  final bool isFinished;

  final int updatedAt;
  final bool isDeleted;

  SnapshotBook({
    required this.fileHash,
    this.groupName,
    required this.title,
    required this.author,
    required this.authors,
    this.description,
    required this.subjects,
    required this.totalChapters,
    required this.epubVersion,
    required this.importDate,
    this.lastOpenedDate,
    required this.currentChapterIndex,
    required this.readingProgress,
    this.chapterScrollPosition,
    required this.isFinished,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory SnapshotBook.fromJson(Map<String, dynamic> json) {
    return SnapshotBook(
      fileHash: json['fileHash'] as String,
      groupName: json['groupName'] as String?,
      title: json['title'] as String,
      author: json['author'] as String,
      authors: (json['authors'] as List<dynamic>).cast<String>(),
      description: json['description'] as String?,
      subjects: (json['subjects'] as List<dynamic>).cast<String>(),
      totalChapters: json['totalChapters'] as int,
      epubVersion: json['epubVersion'] as String,
      importDate: json['importDate'] as int,
      lastOpenedDate: json['lastOpenedDate'] as int?,
      currentChapterIndex: json['currentChapterIndex'] as int,
      readingProgress: (json['readingProgress'] as num).toDouble(),
      chapterScrollPosition: json['chapterScrollPosition'] != null
          ? (json['chapterScrollPosition'] as num).toDouble()
          : null,
      isFinished: json['isFinished'] as bool,
      updatedAt: json['updatedAt'] as int,
      isDeleted: json['isDeleted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileHash': fileHash,
      'groupName': groupName,
      'title': title,
      'author': author,
      'authors': authors,
      'description': description,
      'subjects': subjects,
      'totalChapters': totalChapters,
      'epubVersion': epubVersion,
      'importDate': importDate,
      'lastOpenedDate': lastOpenedDate,
      'currentChapterIndex': currentChapterIndex,
      'readingProgress': readingProgress,
      'chapterScrollPosition': chapterScrollPosition,
      'isFinished': isFinished,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,
    };
  }
}
