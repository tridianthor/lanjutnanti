import 'package:lanjut_nanti/core/time/timestamp_parser.dart';

String encodeUtcTimestamp(DateTime value) => value.toUtc().toIso8601String();

DateTime decodeUtcTimestamp(Object? value) {
  if (value is! String) {
    throw StateError('SQLite timestamp is not text');
  }
  try {
    return parseUtcTimestamp(value);
  } on FormatException catch (error) {
    throw StateError('SQLite timestamp is invalid: ${error.source}');
  }
}

String? encodeNullableNote(String? note) {
  return note == null || note.trim().isEmpty ? null : note;
}
