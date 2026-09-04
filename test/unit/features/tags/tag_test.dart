import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/tags/domain/tag.dart';

void main() {
  group('Tag.create', () {
    test('trims its name and exposes a case-insensitive comparison key', () {
      final tag = Tag.create(
        name: '  MaNgA  ',
        clock: const _FixedClock(),
        idGenerator: const _FixedIdGenerator(),
      );

      expect(tag.name, 'MaNgA');
      expect(tag.comparisonKey, 'manga');
    });

    for (final input in ['', '   ', '\n\t']) {
      test(
        'rejects an empty tag name represented by ${input.length} chars',
        () {
          expect(
            () => Tag.create(
              name: input,
              clock: const _FixedClock(),
              idGenerator: const _FixedIdGenerator(),
            ),
            throwsArgumentError,
          );
        },
      );
    }

    test('assigns one stable ID and identical UTC timestamps', () {
      final now = DateTime(2026, 9, 4, 12);

      final tag = Tag.create(
        name: 'Manga',
        clock: _ValueClock(now),
        idGenerator: const _ValueIdGenerator('tag-42'),
      );

      expect(tag.id, 'tag-42');
      expect(tag.createdAt, now.toUtc());
      expect(tag.updatedAt, tag.createdAt);
    });
  });
}

class _FixedClock implements Clock {
  const _FixedClock();

  @override
  DateTime now() => DateTime.utc(2026);
}

class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator();

  @override
  String next() => 'tag-1';
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
