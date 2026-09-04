import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/database/sqlite_value_codec.dart';
import 'package:lanjut_nanti/features/backup/domain/backup_restore.dart';

/// Observable points in the replacement transaction.
///
/// The hook exists for deterministic failure tests and is not used by the
/// production composition root.
enum BackupRestoreStage {
  clearDetails,
  clearContents,
  clearTags,
  insertTags,
  insertContents,
  insertDetails,
  normalizeActivity,
}

typedef BackupRestoreStageHook = void Function(BackupRestoreStage stage);

abstract interface class BackupRestoreRepository {
  void replace(BackupRestorePreview preview);
}

/// Replaces the three backupable tables and their activity floors in one
/// foreign-key-safe transaction.
class SqliteBackupRestoreRepository implements BackupRestoreRepository {
  const SqliteBackupRestoreRepository(this.database, {this.stageHook});

  final AppDatabase database;
  final BackupRestoreStageHook? stageHook;

  @override
  void replace(BackupRestorePreview preview) {
    database.transaction<void>(() {
      _runStage(BackupRestoreStage.clearDetails);
      database.raw.execute('DELETE FROM content_details');

      _runStage(BackupRestoreStage.clearContents);
      database.raw.execute('DELETE FROM contents');

      _runStage(BackupRestoreStage.clearTags);
      database.raw.execute('DELETE FROM tags');

      _runStage(BackupRestoreStage.insertTags);
      for (final tag in preview.tags) {
        database.raw.execute(
          '''
          INSERT INTO tags (id, name, created_at, updated_at)
          VALUES (?, ?, ?, ?)
        ''',
          [
            tag.id,
            tag.name,
            encodeUtcTimestamp(tag.createdAt),
            encodeUtcTimestamp(tag.updatedAt),
          ],
        );
      }

      _runStage(BackupRestoreStage.insertContents);
      for (final content in preview.contents) {
        database.raw.execute(
          '''
          INSERT INTO contents (
            id, name, tag_id, user_id, created_at, updated_at
          ) VALUES (?, ?, ?, NULL, ?, ?)
        ''',
          [
            content.id,
            content.name,
            content.tagId,
            encodeUtcTimestamp(content.createdAt),
            encodeUtcTimestamp(content.updatedAt),
          ],
        );
        database.raw.execute(
          '''
          INSERT INTO content_activity_floor (content_id, updated_at)
          VALUES (?, ?)
        ''',
          [
            content.id,
            encodeUtcTimestamp(preview.contentActivityFloor(content.id)),
          ],
        );
      }

      _runStage(BackupRestoreStage.insertDetails);
      for (final detail in preview.contentDetails) {
        database.raw.execute(
          '''
          INSERT INTO content_details (
            id, content_id, link, note, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
          [
            detail.id,
            detail.contentId,
            detail.link,
            detail.note,
            encodeUtcTimestamp(detail.createdAt),
            encodeUtcTimestamp(detail.updatedAt),
          ],
        );
      }

      _runStage(BackupRestoreStage.normalizeActivity);
      for (final content in preview.contents) {
        database.raw.execute(
          'UPDATE contents SET updated_at = ? WHERE id = ?',
          [encodeUtcTimestamp(content.updatedAt), content.id],
        );
      }
    });
  }

  void restore(BackupRestorePreview preview) => replace(preview);

  void _runStage(BackupRestoreStage stage) => stageHook?.call(stage);
}

typedef SQLiteBackupRestoreRepository = SqliteBackupRestoreRepository;
typedef BackupReplaceRepository = BackupRestoreRepository;
