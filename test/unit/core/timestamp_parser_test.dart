import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/time/timestamp_parser.dart';

void main() {
  test('parses Z and offset ISO 8601 timestamps as UTC', () {
    expect(
      parseUtcTimestamp('2026-09-04T05:00:00Z'),
      DateTime.utc(2026, 9, 4, 5),
    );
    expect(
      parseUtcTimestamp('2026-09-04T12:00:00+07:00'),
      DateTime.utc(2026, 9, 4, 5),
    );
  });

  for (final source in [
    '',
    'not-a-timestamp',
    '2026-09-04',
    '2026-09-04T12:00:00',
    '2026-13-99T12:00:00Z',
  ]) {
    test('rejects malformed or timezone-less timestamp "$source"', () {
      expect(() => parseUtcTimestamp(source), throwsFormatException);
    });
  }
}
