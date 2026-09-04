import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/features/backup/data/backup_restore_repository.dart';
import 'package:lanjut_nanti/features/backup/data/backup_snapshot_repository.dart';
import 'package:lanjut_nanti/features/backup/domain/backup_snapshot.dart';
import 'package:lanjut_nanti/features/backup/domain/backup_restore.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

import '../../../../support/database_test_support.dart';

void main() {
  test('replaces all records atomically and keeps imported content local', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.dispose);
    final clock = MutableClock(DateTime.utc(2026, 9, 4));
    final tags = SqliteTagRepository(database, clock: clock);
    final contents = SqliteContentRepository(database, clock: clock);
    final details = SqliteContentDetailRepository(database, clock: clock);
    final oldTag = tags.create('Old');
    final oldContent = contents.create(name: 'Old content', tagId: oldTag.id);
    details.create(contentId: oldContent.id, link: 'https://old.example');

    final preview = _preview();
    SqliteBackupRestoreRepository(database).replace(preview);

    final snapshot = SqliteBackupSnapshotRepository(database).readSnapshot();
    expect(snapshot.tags.map((tag) => tag.name), ['Manga']);
    expect(snapshot.contents.map((content) => content.name), ['Doraemon']);
    expect(snapshot.contents.single.userId, isNull);
    expect(snapshot.contents.single.tagId, snapshot.tags.single.id);
    expect(snapshot.contentDetails.map((detail) => detail.id), [
      '33333333-3333-4333-8333-333333333333',
    ]);
    expect(snapshot.contents.single.updatedAt, DateTime.utc(2026, 9, 1, 5, 4));
    expect(
      database.raw
          .select('SELECT COUNT(*) AS count FROM content_activity_floor')
          .single['count'],
      1,
    );
  });

  test(
    'round trips a populated database through the versioned JSON format',
    () {
      final source = AppDatabase.openInMemory();
      final destination = AppDatabase.openInMemory();
      addTearDown(source.dispose);
      addTearDown(destination.dispose);
      final clock = MutableClock(DateTime.utc(2026, 9, 1, 5));
      final sourceTags = SqliteTagRepository(source, clock: clock);
      final sourceContents = SqliteContentRepository(source, clock: clock);
      final sourceDetails = SqliteContentDetailRepository(source, clock: clock);
      final tag = sourceTags.create('Manga');
      final content = sourceContents.create(name: 'Doraemon', tagId: tag.id);
      sourceDetails.create(
        contentId: content.id,
        link: 'https://example.com/chapter-1',
        note: 'First checkpoint',
      );
      clock.value = DateTime.utc(2026, 9, 2, 5);
      sourceDetails.create(
        contentId: content.id,
        link: 'https://example.com/chapter-2',
        note: 'Latest checkpoint',
      );

      final original = SqliteBackupSnapshotRepository(source).readSnapshot();
      final json = const VersionedJsonBackupSerializer().serialize(
        original,
        exportedAt: DateTime.utc(2026, 9, 4),
      );
      final validation = const BackupRestoreValidator().validateJson(json);
      expect(validation.isValid, isTrue);

      SqliteBackupRestoreRepository(destination).replace(validation.preview!);
      final restored =
          SqliteBackupSnapshotRepository(destination).readSnapshot();
      final latest = SqliteContentDetailRepository(
        destination,
      ).latestForContent(content.id);

      expect(_snapshotJson(restored), _snapshotJson(original));
      expect(latest?.link, 'https://example.com/chapter-2');
      expect(restored.contents.single.userId, isNull);
    },
  );

  test('retains the content activity floor after restored detail deletion', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.dispose);
    SqliteBackupRestoreRepository(database).replace(_preview());

    final details = SqliteContentDetailRepository(database);
    details.delete('33333333-3333-4333-8333-333333333333');

    final content = SqliteContentRepository(
      database,
    ).findById('22222222-2222-4222-8222-222222222222');
    expect(content?.updatedAt, DateTime.utc(2026, 9, 1, 5, 2));
  });

  for (final stage in BackupRestoreStage.values) {
    test('rolls back existing data when $stage fails', () {
      final database = AppDatabase.openInMemory();
      addTearDown(database.dispose);
      final clock = MutableClock(DateTime.utc(2026, 9, 4));
      final tags = SqliteTagRepository(database, clock: clock);
      final contents = SqliteContentRepository(database, clock: clock);
      final details = SqliteContentDetailRepository(database, clock: clock);
      final oldTag = tags.create('Old');
      final oldContent = contents.create(name: 'Old content', tagId: oldTag.id);
      details.create(
        contentId: oldContent.id,
        link: 'https://old.example',
        note: 'Keep me',
      );
      final before = SqliteBackupSnapshotRepository(database).readSnapshot();

      final repository = SqliteBackupRestoreRepository(
        database,
        stageHook: (current) {
          if (current == stage) throw StateError('injected $stage failure');
        },
      );

      expect(() => repository.replace(_preview()), throwsStateError);
      final after = SqliteBackupSnapshotRepository(database).readSnapshot();
      expect(_snapshotJson(after), _snapshotJson(before));
    });
  }
}

BackupRestorePreview _preview() {
  final result = const BackupRestoreValidator().validateJson(
    jsonEncode({
      'schema_version': 1,
      'exported_at': '2026-09-04T05:00:00.000Z',
      'tags': [
        {
          'id': '11111111-1111-4111-8111-111111111111',
          'name': 'Manga',
          'created_at': '2026-09-01T05:00:00.000Z',
          'updated_at': '2026-09-01T05:00:00.000Z',
        },
      ],
      'contents': [
        {
          'id': '22222222-2222-4222-8222-222222222222',
          'name': 'Doraemon',
          'tag_id': '11111111-1111-4111-8111-111111111111',
          'user_id': 'ignore-me',
          'created_at': '2026-09-01T05:01:00.000Z',
          'updated_at': '2026-09-01T05:02:00.000Z',
        },
      ],
      'content_details': [
        {
          'id': '33333333-3333-4333-8333-333333333333',
          'content_id': '22222222-2222-4222-8222-222222222222',
          'link': 'https://example.com/chapter-1',
          'note': 'Continue here',
          'created_at': '2026-09-01T05:03:00.000Z',
          'updated_at': '2026-09-01T05:04:00.000Z',
        },
      ],
    }),
  );
  return result.preview!;
}

String _snapshotJson(dynamic snapshot) {
  return jsonEncode({
    'tags': [
      for (final tag in snapshot.tags)
        [
          tag.id,
          tag.name,
          tag.createdAt.toIso8601String(),
          tag.updatedAt.toIso8601String(),
        ],
    ],
    'contents': [
      for (final content in snapshot.contents)
        [
          content.id,
          content.name,
          content.tagId,
          content.userId,
          content.createdAt.toIso8601String(),
          content.updatedAt.toIso8601String(),
        ],
    ],
    'details': [
      for (final detail in snapshot.contentDetails)
        [
          detail.id,
          detail.contentId,
          detail.link,
          detail.note,
          detail.createdAt.toIso8601String(),
          detail.updatedAt.toIso8601String(),
        ],
    ],
  });
}
