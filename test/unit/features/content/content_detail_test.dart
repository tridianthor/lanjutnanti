import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/content/domain/content_detail.dart';

void main() {
  group('ContentDetail.create', () {
    test('trims and accepts an absolute link', () {
      final detail = _create(link: '  https://example.com/chapter/6  ');

      expect(detail.link, 'https://example.com/chapter/6');
    });

    for (final link in ['', '   ', '/chapter/6', 'chapter/6', '://broken']) {
      test('rejects invalid link "$link"', () {
        expect(() => _create(link: link), throwsArgumentError);
      });
    }

    test('normalizes a missing or whitespace-only note to null', () {
      expect(_create(link: 'https://example.com', note: null).note, isNull);
      expect(_create(link: 'https://example.com', note: ' \n\t ').note, isNull);
    });

    test('preserves non-empty note text', () {
      const note = '  Continue at chapter 6  ';

      expect(_create(link: 'https://example.com', note: note).note, note);
    });

    test('assigns one stable ID and identical UTC timestamps', () {
      final now = DateTime(2026, 9, 4, 12);

      final detail = ContentDetail.create(
        contentId: 'content-1',
        link: 'https://example.com',
        clock: _ValueClock(now),
        idGenerator: const _ValueIdGenerator('detail-42'),
      );

      expect(detail.id, 'detail-42');
      expect(detail.createdAt, now.toUtc());
      expect(detail.updatedAt, detail.createdAt);
    });
  });

  group('ContentDetail.edit', () {
    test(
      'preserves identity and creation time while sharing its update time',
      () {
        final createdAt = DateTime.utc(2025, 1, 2);
        final operationTime = DateTime(2026, 9, 4, 12);
        final original = ContentDetail(
          id: 'detail-1',
          contentId: 'content-1',
          link: 'https://example.com/old',
          note: 'Old note',
          createdAt: createdAt,
          updatedAt: DateTime.utc(2025, 2, 3),
        );

        final mutation = original.edit(
          link: '  https://example.com/new  ',
          note: '  ',
          clock: _ValueClock(operationTime),
        );

        expect(mutation.detail.id, original.id);
        expect(mutation.detail.contentId, original.contentId);
        expect(mutation.detail.createdAt, createdAt);
        expect(mutation.detail.updatedAt, operationTime.toUtc());
        expect(mutation.detail.link, 'https://example.com/new');
        expect(mutation.detail.note, isNull);
        expect(mutation.parentUpdatedAt, mutation.detail.updatedAt);
      },
    );

    test('rejects an invalid replacement link without changing the detail', () {
      final original = ContentDetail(
        id: 'detail-1',
        contentId: 'content-1',
        link: 'https://example.com/old',
        createdAt: DateTime.utc(2025),
        updatedAt: DateTime.utc(2025),
      );

      expect(
        () => original.edit(
          link: 'relative/path',
          note: null,
          clock: const _FixedClock(),
        ),
        throwsArgumentError,
      );
      expect(original.link, 'https://example.com/old');
    });
  });
}

ContentDetail _create({required String link, String? note}) {
  return ContentDetail.create(
    contentId: 'content-1',
    link: link,
    note: note,
    clock: const _FixedClock(),
    idGenerator: const _FixedIdGenerator(),
  );
}

class _FixedClock implements Clock {
  const _FixedClock();

  @override
  DateTime now() => DateTime.utc(2026);
}

class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator();

  @override
  String next() => 'detail-1';
}

class _ValueClock implements Clock {
  const _ValueClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class _ValueIdGenerator implements IdGenerator {
  const _ValueIdGenerator(this.value);

  final String value;

  @override
  String next() => value;
}
