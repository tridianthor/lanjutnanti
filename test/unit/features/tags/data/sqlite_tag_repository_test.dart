import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../../support/database_test_support.dart';

void main() {
  late AppDatabase database;
  late MutableClock clock;
  late SqliteTagRepository tags;

  setUp(() {
    database = AppDatabase.openInMemory();
    clock = MutableClock(DateTime.utc(2026, 9, 4, 5));
    tags = SqliteTagRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['tag-1']),
    );
  });

  tearDown(() {
    database.dispose();
  });

  test('creates, reads, updates, and lists normalized tags', () {
    final created = tags.create('  Manga  ');

    expect(created.name, 'Manga');
    expect(tags.findById('tag-1')!.name, created.name);
    expect(tags.getAll().map((tag) => tag.name), ['Manga']);

    clock.value = DateTime.utc(2026, 9, 5);
    final renamed = tags.rename(id: 'tag-1', name: '  Comics  ');

    expect(renamed.name, 'Comics');
    expect(renamed.createdAt, created.createdAt);
    expect(renamed.updatedAt, clock.value);
  });

  test('enforces case-insensitive uniqueness for trimmed names', () {
    tags.create('Manga');

    expect(
      () => database.raw.execute(
        'INSERT INTO tags (id, name, created_at, updated_at) VALUES (?, ?, ?, ?)',
        [
          'tag-2',
          '  manga  ',
          '2026-09-04T05:00:00.000Z',
          '2026-09-04T05:00:00.000Z',
        ],
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('deleting a tag unassigns content and preserves the content row', () {
    final tag = tags.create('Manga');
    final contents = SqliteContentRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['content-1']),
    );
    final content = contents.create(name: 'Doraemon', tagId: tag.id);

    clock.value = DateTime.utc(2026, 9, 5);
    tags.delete(tag.id);

    final reloaded = contents.findById(content.id)!;
    expect(reloaded.tagId, isNull);
    expect(reloaded.updatedAt, clock.value);
    expect(tags.findById(tag.id), isNull);
  });

  test('rejects empty tag names before touching the database', () {
    expect(() => tags.create(' \n\t '), throwsArgumentError);
    expect(tags.getAll(), isEmpty);
  });
}
