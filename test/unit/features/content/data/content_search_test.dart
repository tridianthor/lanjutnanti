import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

import '../../../../support/database_test_support.dart';

void main() {
  late AppDatabase database;
  late MutableClock clock;
  late SqliteContentRepository contents;
  late SqliteContentDetailRepository details;
  late SqliteTagRepository tags;

  setUp(() {
    database = AppDatabase.openInMemory();
    clock = MutableClock(DateTime.utc(2026, 9, 4));
    contents = SqliteContentRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator([
        'content-doraemon',
        'content-cooking',
        'content-book',
      ]),
    );
    details = SqliteContentDetailRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator([
        'detail-first',
        'detail-second',
        'detail-link-only',
      ]),
    );
    tags = SqliteTagRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['tag-manga', 'tag-book']),
    );
  });

  tearDown(() => database.dispose());

  test('empty query returns every content in recent activity order', () {
    final doraemon = contents.create(name: 'Doraemon');
    clock.value = DateTime.utc(2026, 9, 5);
    final cooking = contents.create(name: 'Cooking show');
    clock.value = DateTime.utc(2026, 9, 6);
    final book = contents.create(name: 'A book');

    expect(contents.search().map((content) => content.id), [
      book.id,
      cooking.id,
      doraemon.id,
    ]);
  });

  test('matching results retain descending recent activity order', () {
    final older = contents.create(name: 'Match older');
    clock.value = DateTime.utc(2026, 9, 5);
    final newer = contents.create(name: 'Match newer');

    expect(contents.search(query: 'match').map((content) => content.id), [
      newer.id,
      older.id,
    ]);
  });

  test('matches content names and assigned tag names case-insensitively', () {
    final manga = tags.create('Manga');
    final doraemon = contents.create(name: 'Doraemon', tagId: manga.id);
    final cooking = contents.create(name: 'Cooking show');

    expect(contents.search(query: 'DORA').map((content) => content.id), [
      doraemon.id,
    ]);
    expect(contents.search(query: ' manga ').map((content) => content.id), [
      doraemon.id,
    ]);
    expect(contents.search(query: 'COOK').map((content) => content.id), [
      cooking.id,
    ]);
  });

  test(
    'matches a note on any detail, excludes links, and deduplicates content',
    () {
      final doraemon = contents.create(name: 'Doraemon');
      details.create(
        contentId: doraemon.id,
        link: 'https://example.com/first',
        note: 'Already watched chapter one',
      );
      details.create(
        contentId: doraemon.id,
        link: 'https://example.com/final-chapter',
        note: 'Continue at the final chapter',
      );
      final linkOnly = contents.create(name: 'Link only');
      details.create(
        contentId: linkOnly.id,
        link: 'https://example.com/final-chapter',
      );

      expect(contents.search(query: 'FINAL').map((content) => content.id), [
        doraemon.id,
      ]);
      expect(contents.search(query: 'example.com'), isEmpty);
    },
  );

  test('treats wildcard characters in a query as literal text', () {
    contents.create(name: 'One hundred percent');
    contents.create(name: 'Underscore_name');

    expect(contents.search(query: '%'), isEmpty);
    expect(contents.search(query: '_').map((content) => content.name), [
      'Underscore_name',
    ]);
  });

  test(
    'can restrict results to one assigned tag independently of text search',
    () {
      final manga = tags.create('Manga');
      final book = tags.create('Book');
      final mangaContent = contents.create(
        name: 'Shared name',
        tagId: manga.id,
      );
      contents.create(name: 'Shared name', tagId: book.id);

      expect(contents.search(tagId: manga.id).map((content) => content.id), [
        mangaContent.id,
      ]);
      expect(
        contents
            .search(query: 'shared', tagId: manga.id)
            .map((content) => content.id),
        [mangaContent.id],
      );
    },
  );
}
