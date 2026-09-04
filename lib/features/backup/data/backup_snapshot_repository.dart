import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/database/sqlite_value_codec.dart';
import 'package:lanjut_nanti/features/backup/domain/backup_snapshot.dart';
import 'package:lanjut_nanti/features/content/domain/content.dart';
import 'package:lanjut_nanti/features/content/domain/content_detail.dart';
import 'package:lanjut_nanti/features/tags/domain/tag.dart';

abstract interface class BackupSnapshotRepository {
  BackupSnapshot readSnapshot();
}

/// Reads all backupable records inside one deferred SQLite transaction.
class SqliteBackupSnapshotRepository implements BackupSnapshotRepository {
  const SqliteBackupSnapshotRepository(this.database);

  final AppDatabase database;

  @override
  BackupSnapshot readSnapshot() {
    return database.readTransaction(() {
      final tags =
          database.raw
              .select('''
        SELECT id, name, created_at, updated_at
        FROM tags
        ORDER BY name COLLATE NOCASE ASC, id ASC
      ''')
              .map(_tagFromRow)
              .toList();
      final contents =
          database.raw
              .select('''
        SELECT id, name, tag_id, user_id, created_at, updated_at
        FROM contents
        ORDER BY updated_at DESC, created_at DESC, id DESC
      ''')
              .map(_contentFromRow)
              .toList();
      final details =
          database.raw
              .select('''
        SELECT id, content_id, link, note, created_at, updated_at
        FROM content_details
        ORDER BY content_id ASC, updated_at DESC, created_at DESC, id DESC
      ''')
              .map(_detailFromRow)
              .toList();

      return BackupSnapshot(
        tags: tags,
        contents: contents,
        contentDetails: details,
      );
    });
  }
}

Tag _tagFromRow(Map<String, Object?> row) {
  return Tag(
    id: row['id']! as String,
    name: row['name']! as String,
    createdAt: decodeUtcTimestamp(row['created_at']),
    updatedAt: decodeUtcTimestamp(row['updated_at']),
  );
}

Content _contentFromRow(Map<String, Object?> row) {
  return Content(
    id: row['id']! as String,
    name: row['name']! as String,
    tagId: row['tag_id'] as String?,
    userId: row['user_id'] as String?,
    createdAt: decodeUtcTimestamp(row['created_at']),
    updatedAt: decodeUtcTimestamp(row['updated_at']),
  );
}

ContentDetail _detailFromRow(Map<String, Object?> row) {
  return ContentDetail(
    id: row['id']! as String,
    contentId: row['content_id']! as String,
    link: row['link']! as String,
    note: row['note'] as String?,
    createdAt: decodeUtcTimestamp(row['created_at']),
    updatedAt: decodeUtcTimestamp(row['updated_at']),
  );
}

typedef SQLiteBackupSnapshotRepository = SqliteBackupSnapshotRepository;
