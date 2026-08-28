import 'dart:convert';

import 'package:drift/drift.dart';

/// A single ordered element inside a service (song or other item).
///
/// Mirrors `ServiceElement` from `@hosanna/shared`. Stored as JSON inside the
/// `services` table's `elements` column.
class ServiceElement {
  const ServiceElement({
    required this.id,
    required this.type,
    required this.title,
    this.content,
    this.position,
    this.songId,
    this.notes,
    this.passage,
    this.duration,
  });

  final String id;
  final String type;
  final String title;
  final String? content;
  final int? position;
  final String? songId;
  final String? notes;
  final String? passage;
  final int? duration;

  factory ServiceElement.fromJson(Map<String, dynamic> json) {
    return ServiceElement(
      id: (json['id'] ?? '') as String,
      type: (json['type'] ?? 'custom') as String,
      title: (json['title'] ?? '') as String,
      content: json['content'] as String?,
      position: (json['position'] as num?)?.toInt(),
      songId: json['songId'] as String?,
      notes: json['notes'] as String?,
      passage: json['passage'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        if (content != null) 'content': content,
        if (position != null) 'position': position,
        if (songId != null) 'songId': songId,
        if (notes != null) 'notes': notes,
        if (passage != null) 'passage': passage,
        if (duration != null) 'duration': duration,
      };
}

/// Converts `List<String>` (song tags) to/from a JSON-encoded text column.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    final decoded = jsonDecode(fromDb);
    if (decoded is! List) return const [];
    return decoded.whereType<String>().toList();
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// Converts `List<ServiceElement>` to/from a JSON-encoded text column.
class ServiceElementListConverter
    extends TypeConverter<List<ServiceElement>, String> {
  const ServiceElementListConverter();

  @override
  List<ServiceElement> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    final decoded = jsonDecode(fromDb);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => ServiceElement.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  String toSql(List<ServiceElement> value) =>
      jsonEncode(value.map((e) => e.toJson()).toList());
}

/// Columns shared by every replicated table.
///
/// `isDeleted` is the soft-delete (trash) flag; `dirty` marks rows that were
/// changed locally and still need to be pushed. `purgeAt` is the server's
/// hard-delete timestamp for trashed rows.
mixin SyncMetadata on Table {
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  TextColumn get purgeAt => text().nullable()();
}

@TableIndex(name: 'songs_folder_idx', columns: {#folderId})
@TableIndex(name: 'songs_updated_idx', columns: {#updatedAt})
@DataClassName('SongRow')
class Songs extends Table with SyncMetadata {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  TextColumn get content => text()();
  TextColumn get folderId => text().nullable()();
  TextColumn get path => text()();
  TextColumn get tags =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  IntColumn get songNumber =>
      integer().nullable().named('song_number')();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {path},
      ];
}

@TableIndex(name: 'folders_parent_idx', columns: {#parentId})
@DataClassName('FolderRow')
class Folders extends Table with SyncMetadata {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().withDefault(const Constant('default'))();
  TextColumn get icon => text().withDefault(const Constant('default'))();
  TextColumn get parentId => text().nullable()();
  IntColumn get songCount => integer().withDefault(const Constant(0))();
  IntColumn get folderCount => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'services_date_idx', columns: {#date})
@DataClassName('ServiceRow')
class Services extends Table with SyncMetadata {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get date => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get elements => text()
      .map(const ServiceElementListConverter())
      .withDefault(const Constant('[]'))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
