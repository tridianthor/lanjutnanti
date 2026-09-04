import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/content/domain/content_detail.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../../support/database_test_support.dart';

void main() {
  late AppDatabase database;
  late MutableClock clock;
  late SqliteContentRepository contents;
  late SqliteContentDetailRepository details;

  setUp(() {
    database = AppDatabase.openInMemory();
    clock = MutableClock(DateTime.utc(2026, 9, 4));
    contents = SqliteContentRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['content-1', 'content-2']),
    );
    details = SqliteContentDetailRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['detail-1', 'detail-2']),
    );
  });

  tearDown(() {
    database.dispose();
  });

  test('creates a detail and propagates its operation time to the parent', () {
    final content = contents.create(name: 'Doraemon');
    clock.value = DateTime.utc(2026, 9, 5, 5);

    final detail = details.create(
      contentId: content.id,
      link: '  https://example.com/chapter/6  ',
      note: '  Continue at chapter 6  ',
    );

    expect(detail.link, 'https://example.com/chapter/6');
    expect(detail.note, '  Continue at chapter 6  ');
    expect(details.findById(detail.id)!.updatedAt, clock.value);
    expect(contents.findById(content.id)!.updatedAt, clock.value);
  });

  test('returns deterministic latest-first history and latest detail', () {
    final content = contents.create(name: 'Doraemon');
    final timestamp = DateTime.utc(2026, 9, 5);
    details.insert(
      ContentDetail(
        id: 'detail-a',
        contentId: content.id,
        link: 'https://example.com/a',
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    details.insert(
      ContentDetail(
        id: 'detail-b',
        contentId: content.id,
        link: 'https://example.com/b',
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );

    expect(details.getForContent(content.id).map((detail) => detail.id), [
      'detail-b',
      'detail-a',
    ]);
    expect(details.latestForContent(content.id)!.id, 'detail-b');
  });

  test('reads the latest detail for multiple contents as one projection', () {
    final firstContent = contents.create(name: 'First');
    final secondContent = contents.create(name: 'Second');
    final firstDetail = details.create(
      contentId: firstContent.id,
      link: 'https://example.com/first',
    );
    final secondDetail = details.create(
      contentId: secondContent.id,
      link: 'https://example.com/second',
    );

    final latest = details.latestForContents([
      secondContent.id,
      firstContent.id,
      firstContent.id,
    ]);

    expect(latest.keys, containsAll([firstContent.id, secondContent.id]));
    expect(latest[firstContent.id]!.id, firstDetail.id);
    expect(latest[secondContent.id]!.id, secondDetail.id);
  });

  test(
    'editing an older detail preserves creation time and makes it latest',
    () {
      final content = contents.create(name: 'Doraemon');
      final first = details.create(
        contentId: content.id,
        link: 'https://example.com/first',
      );
      clock.value = DateTime.utc(2026, 9, 5);
      final second = details.create(
        contentId: content.id,
        link: 'https://example.com/second',
      );
      clock.value = DateTime.utc(2026, 9, 6);

      final edited = details.edit(
        id: first.id,
        link: 'https://example.com/edited',
        note: 'Updated older checkpoint',
      );

      expect(edited.createdAt, first.createdAt);
      expect(edited.updatedAt, clock.value);
      expect(details.latestForContent(content.id)!.id, first.id);
      expect(details.getForContent(content.id).map((detail) => detail.id), [
        first.id,
        second.id,
      ]);
      expect(contents.findById(content.id)!.updatedAt, clock.value);
    },
  );

  test(
    'deleting the latest detail recalculates activity from remaining detail',
    () {
      final content = contents.create(name: 'Doraemon');
      clock.value = DateTime.utc(2026, 9, 5);
      final first = details.create(
        contentId: content.id,
        link: 'https://example.com/first',
      );
      clock.value = DateTime.utc(2026, 9, 6);
      final second = details.create(
        contentId: content.id,
        link: 'https://example.com/second',
      );

      details.delete(second.id);

      expect(details.latestForContent(content.id)!.id, first.id);
      expect(contents.findById(content.id)!.updatedAt, first.updatedAt);
    },
  );

  test(
    'deleting the last detail retains the content own-edit activity floor',
    () {
      final content = contents.create(name: 'Doraemon');
      clock.value = DateTime.utc(2026, 9, 5);
      final detail = details.create(
        contentId: content.id,
        link: 'https://example.com/first',
      );
      clock.value = DateTime.utc(2026, 9, 6);
      contents.edit(id: content.id, name: 'Doraemon revised');
      clock.value = DateTime.utc(2026, 9, 7);

      details.delete(detail.id);

      expect(
        contents.findById(content.id)!.updatedAt,
        DateTime.utc(2026, 9, 6),
      );
    },
  );

  test('rejects a detail for a missing content without partial data', () {
    expect(
      () => details.create(
        contentId: 'missing-content',
        link: 'https://example.com',
      ),
      throwsA(isA<SqliteException>()),
    );
    expect(database.raw.select('SELECT * FROM content_details'), isEmpty);
  });

  test(
    'normalizes whitespace-only notes when persisting a supplied detail',
    () {
      final content = contents.create(name: 'Doraemon');
      details.insert(
        ContentDetail(
          id: 'detail-manual',
          contentId: content.id,
          link: 'https://example.com',
          note: ' \n\t ',
          createdAt: clock.value,
          updatedAt: clock.value,
        ),
      );

      expect(details.latestForContent(content.id)!.note, isNull);
    },
  );
}
