import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/content/domain/content.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../../support/database_test_support.dart';

void main() {
  late AppDatabase database;
  late MutableClock clock;
  late SqliteContentRepository contents;

  setUp(() {
    database = AppDatabase.openInMemory();
    clock = MutableClock(DateTime.utc(2026, 9, 4, 5));
    contents = SqliteContentRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['content-1', 'content-2']),
    );
  });

  tearDown(() {
    database.dispose();
  });

  test(
    'creates and reads content with a nullable tag and reserved user ID',
    () {
      final tag = SqliteTagRepository(
        database,
        clock: clock,
        idGenerator: SequenceIdGenerator(['tag-1']),
      ).create('Manga');
      final created = contents.create(name: '  Doraemon  ', tagId: tag.id);

      expect(created.name, 'Doraemon');
      expect(created.tagId, tag.id);
      expect(contents.findById(created.id)!.createdAt, created.createdAt);

      final reserved = Content(
        id: 'content-user',
        name: 'Owned locally',
        userId: 'reserved-user',
        createdAt: clock.value,
        updatedAt: clock.value,
      );
      contents.insert(reserved);
      expect(contents.findById(reserved.id)!.userId, 'reserved-user');
    },
  );

  test('orders content by updated time, creation time, then ID descending', () {
    final timestamp = DateTime.utc(2026, 9, 4);
    contents.insert(
      Content(
        id: 'content-a',
        name: 'A',
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    contents.insert(
      Content(
        id: 'content-b',
        name: 'B',
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );

    expect(contents.getAll().map((content) => content.id), [
      'content-b',
      'content-a',
    ]);
  });

  test(
    'editing content preserves creation time and updates recent activity',
    () {
      final created = contents.create(name: 'Doraemon');
      clock.value = DateTime.utc(2026, 9, 5);

      final edited = contents.edit(id: created.id, name: '  Doraemon  ');

      expect(edited.name, 'Doraemon');
      expect(edited.createdAt, created.createdAt);
      expect(edited.updatedAt, clock.value);
    },
  );

  test('assigning or unassigning a tag updates content activity', () {
    final tags = SqliteTagRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['tag-1']),
    );
    final tag = tags.create('Manga');
    final created = contents.create(name: 'Doraemon');

    clock.value = DateTime.utc(2026, 9, 5);
    final assigned = contents.assignTag(id: created.id, tagId: tag.id);
    expect(assigned.tagId, tag.id);
    expect(assigned.updatedAt, clock.value);

    clock.value = DateTime.utc(2026, 9, 6);
    final unassigned = contents.assignTag(id: created.id, tagId: null);
    expect(unassigned.tagId, isNull);
    expect(unassigned.updatedAt, clock.value);
  });

  test(
    'rejects an unknown tag without leaving a partially inserted content',
    () {
      expect(
        () => contents.create(name: 'Doraemon', tagId: 'missing-tag'),
        throwsA(isA<SqliteException>()),
      );
      expect(contents.getAll(), isEmpty);
      expect(
        database.raw.select('SELECT * FROM content_activity_floor'),
        isEmpty,
      );
    },
  );

  test('deleting content cascades to all details in one transaction', () {
    final created = contents.create(name: 'Doraemon');
    final details = SqliteContentDetailRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['detail-1']),
    );
    details.create(
      contentId: created.id,
      link: 'https://example.com/chapter/1',
    );

    contents.delete(created.id);

    expect(contents.findById(created.id), isNull);
    expect(details.getForContent(created.id), isEmpty);
    expect(
      database.raw.select(
        'SELECT * FROM content_activity_floor WHERE content_id = ?',
        [created.id],
      ),
      isEmpty,
    );
  });

  test('committed records and relationships survive closing and reopening', () {
    final directory = Directory.systemTemp.createTempSync('lanjut-nanti-db-');
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });
    final path = '${directory.path}/app.sqlite';

    final first = AppDatabase.open(path);
    final firstClock = MutableClock(DateTime.utc(2026, 9, 4, 5));
    final tag = SqliteTagRepository(
      first,
      clock: firstClock,
      idGenerator: SequenceIdGenerator(['tag-1']),
    ).create('Manga');
    final content = SqliteContentRepository(
      first,
      clock: firstClock,
      idGenerator: SequenceIdGenerator(['content-1']),
    ).create(name: 'Doraemon', tagId: tag.id);
    SqliteContentDetailRepository(
      first,
      clock: firstClock,
      idGenerator: SequenceIdGenerator(['detail-1']),
    ).create(
      contentId: content.id,
      link: 'https://example.com/chapter/1',
      note: 'Continue here',
    );
    first.dispose();

    final reopened = AppDatabase.open(path);
    addTearDown(reopened.dispose);
    final reopenedContent = SqliteContentRepository(
      reopened,
    ).findById(content.id);
    final reopenedDetail = SqliteContentDetailRepository(
      reopened,
    ).latestForContent(content.id);

    expect(reopenedContent!.tagId, tag.id);
    expect(reopenedDetail!.note, 'Continue here');
    expect(
      reopened.raw.select('PRAGMA user_version').single['user_version'],
      AppDatabase.schemaVersion,
    );
  });
}
