import 'dart:convert';

import 'package:lanjut_nanti/features/content/domain/content.dart';
import 'package:lanjut_nanti/features/content/domain/content_detail.dart';
import 'package:lanjut_nanti/features/tags/domain/tag.dart';

/// The records read together for one backup operation.
///
/// The snapshot intentionally contains domain models rather than JSON maps.
/// This keeps persistence concerns and the portable wire format separate.
class BackupSnapshot {
  BackupSnapshot({
    required Iterable<Tag> tags,
    required Iterable<Content> contents,
    required Iterable<ContentDetail> contentDetails,
  }) : tags = List.unmodifiable(tags),
       contents = List.unmodifiable(contents),
       contentDetails = List.unmodifiable(contentDetails);

  final List<Tag> tags;
  final List<Content> contents;
  final List<ContentDetail> contentDetails;
}

/// Encodes the initial portable backup format.
class VersionedJsonBackupSerializer {
  static const int schemaVersion = 1;

  const VersionedJsonBackupSerializer();

  String serialize(BackupSnapshot snapshot, {required DateTime exportedAt}) {
    return jsonEncode(toMap(snapshot, exportedAt: exportedAt));
  }

  List<int> encodeUtf8(
    BackupSnapshot snapshot, {
    required DateTime exportedAt,
  }) {
    return utf8.encode(serialize(snapshot, exportedAt: exportedAt));
  }

  Map<String, Object?> toMap(
    BackupSnapshot snapshot, {
    required DateTime exportedAt,
  }) {
    return <String, Object?>{
      'schema_version': schemaVersion,
      'exported_at': _encodeTimestamp(exportedAt),
      'tags': [
        for (final tag in snapshot.tags)
          <String, Object?>{
            'id': tag.id,
            'name': tag.name,
            'created_at': _encodeTimestamp(tag.createdAt),
            'updated_at': _encodeTimestamp(tag.updatedAt),
          },
      ],
      'contents': [
        for (final content in snapshot.contents)
          <String, Object?>{
            'id': content.id,
            'name': content.name,
            'tag_id': content.tagId,
            'created_at': _encodeTimestamp(content.createdAt),
            'updated_at': _encodeTimestamp(content.updatedAt),
          },
      ],
      'content_details': [
        for (final detail in snapshot.contentDetails)
          <String, Object?>{
            'id': detail.id,
            'content_id': detail.contentId,
            'link': detail.link,
            'note': detail.note,
            'created_at': _encodeTimestamp(detail.createdAt),
            'updated_at': _encodeTimestamp(detail.updatedAt),
          },
      ],
    };
  }
}

String _encodeTimestamp(DateTime value) => value.toUtc().toIso8601String();

typedef JsonBackupSerializer = VersionedJsonBackupSerializer;
