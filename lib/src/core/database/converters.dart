import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:lumina/src/features/library/domain/book_manifest.dart';

/// Encodes a `List<String>` as a JSON array in a single TEXT column.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List<dynamic>).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// JSON helpers for the embedded EPUB structure stored inside `BookManifests`.
///
/// The same shapes are used by [BookManifestJson], so a database round-trip and
/// a backup export/import round-trip produce identical JSON.
class BookManifestJson {
  const BookManifestJson._();

  static String encodeSpine(List<SpineItem> spine) =>
      jsonEncode(spine.map(spineItemToJson).toList());

  static List<SpineItem> decodeSpine(String json) =>
      (jsonDecode(json) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(spineItemFromJson)
          .toList();

  static String encodeManifest(List<ManifestItem> manifest) =>
      jsonEncode(manifest.map(manifestItemToJson).toList());

  static List<ManifestItem> decodeManifest(String json) =>
      (jsonDecode(json) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(manifestItemFromJson)
          .toList();

  static String encodeToc(List<TocItem> toc) =>
      jsonEncode(toc.map(tocItemToJson).toList());

  static List<TocItem> decodeToc(String json) =>
      (jsonDecode(json) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(tocItemFromJson)
          .toList();

  static Map<String, dynamic> spineItemToJson(SpineItem s) => {
    'index': s.index,
    'href': s.href,
    'idref': s.idref,
    'linear': s.linear,
    'properties': s.properties,
  };

  static SpineItem spineItemFromJson(Map<String, dynamic> json) => SpineItem(
    index: json['index'] as int,
    // In SpineItem `href` is a plain String, not an [Href].
    href: json['href'] as String,
    idref: json['idref'] as String,
    linear: json['linear'] as bool? ?? true,
    properties: json['properties'] as String?,
  );

  static Map<String, dynamic> hrefToJson(Href h) => {
    'path': h.path,
    'anchor': h.anchor,
  };

  static Href hrefFromJson(Map<String, dynamic> json) =>
      Href()
        ..path = json['path'] as String
        ..anchor = json['anchor'] as String? ?? 'top';

  static Map<String, dynamic> manifestItemToJson(ManifestItem item) => {
    'id': item.id,
    'href': hrefToJson(item.href),
    'mediaType': item.mediaType,
    'properties': item.properties,
  };

  static ManifestItem manifestItemFromJson(Map<String, dynamic> json) =>
      ManifestItem()
        ..id = json['id'] as String
        ..href = hrefFromJson(json['href'] as Map<String, dynamic>)
        ..mediaType = json['mediaType'] as String
        ..properties = json['properties'] as String?;

  static Map<String, dynamic> tocItemToJson(TocItem t) => {
    'id': t.id,
    'label': t.label,
    'href': hrefToJson(t.href),
    'depth': t.depth,
    'spineIndex': t.spineIndex,
    'parentId': t.parentId,
    'children': t.children.map(tocItemToJson).toList(),
  };

  static TocItem tocItemFromJson(Map<String, dynamic> json) =>
      TocItem()
        ..id = json['id'] as int
        ..label = json['label'] as String
        ..href = hrefFromJson(json['href'] as Map<String, dynamic>)
        ..depth = json['depth'] as int
        ..spineIndex = json['spineIndex'] as int? ?? -1
        ..parentId = json['parentId'] as int
        ..children = (json['children'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(tocItemFromJson)
            .toList();
}

/// Stores the EPUB spine as a JSON array.
class SpineListConverter extends TypeConverter<List<SpineItem>, String> {
  const SpineListConverter();

  @override
  List<SpineItem> fromSql(String fromDb) => BookManifestJson.decodeSpine(fromDb);

  @override
  String toSql(List<SpineItem> value) => BookManifestJson.encodeSpine(value);
}

/// Stores the EPUB manifest (id → resource path) as a JSON array.
class ManifestListConverter extends TypeConverter<List<ManifestItem>, String> {
  const ManifestListConverter();

  @override
  List<ManifestItem> fromSql(String fromDb) =>
      BookManifestJson.decodeManifest(fromDb);

  @override
  String toSql(List<ManifestItem> value) =>
      BookManifestJson.encodeManifest(value);
}

/// Stores the (recursive) TOC tree as a JSON array.
class TocListConverter extends TypeConverter<List<TocItem>, String> {
  const TocListConverter();

  @override
  List<TocItem> fromSql(String fromDb) => BookManifestJson.decodeToc(fromDb);

  @override
  String toSql(List<TocItem> value) => BookManifestJson.encodeToc(value);
}
