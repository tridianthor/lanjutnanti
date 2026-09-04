import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/content/domain/content.dart';

void main() {
  group('Content.create', () {
    test('trims the content name', () {
      final content = Content.create(
        name: '  Doraemon  ',
        clock: _FixedClock(DateTime.utc(2026)),
        idGenerator: const _FixedIdGenerator('content-1'),
      );

      expect(content.name, 'Doraemon');
    });

    for (final input in ['', '   ', '\n\t']) {
      test(
        'rejects an empty content name represented by ${input.length} chars',
        () {
          expect(
            () => Content.create(
              name: input,
              clock: _FixedClock(DateTime.utc(2026)),
              idGenerator: const _FixedIdGenerator('content-1'),
            ),
            throwsArgumentError,
          );
        },
      );
    }

    test('assigns one stable ID and one UTC creation instant', () {
      final first = DateTime(2026, 9, 4, 12);
      final clock = _AdvancingClock([
        first,
        first.add(const Duration(seconds: 1)),
      ]);

      final content = Content.create(
        name: 'Doraemon',
        clock: clock,
        idGenerator: const _FixedIdGenerator('content-42'),
      );

      expect(content.id, 'content-42');
      expect(content.tagId, isNull);
      expect(content.createdAt, first.toUtc());
      expect(content.updatedAt, content.createdAt);
      expect(clock.callCount, 1);
    });
  });
}

class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator(this.value);

  final String value;

  @override
  String next() => value;
}

class _AdvancingClock implements Clock {
  _AdvancingClock(this.values);

  final List<DateTime> values;
  int callCount = 0;

  @override
  DateTime now() => values[callCount++];
}
