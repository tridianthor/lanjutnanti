DateTime parseUtcTimestamp(String source) {
  final match = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})'
    r'(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$',
    caseSensitive: false,
  ).firstMatch(source);
  final parsed = DateTime.tryParse(source);

  if (match == null || parsed == null || !_hasValidComponents(match)) {
    throw FormatException('Invalid timestamp', source);
  }
  return parsed.toUtc();
}

bool _hasValidComponents(RegExpMatch match) {
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final hour = int.parse(match.group(4)!);
  final minute = int.parse(match.group(5)!);
  final second = int.parse(match.group(6)!);

  if (month < 1 || month > 12 || hour > 23 || minute > 59 || second > 59) {
    return false;
  }
  final daysInMonth = DateTime.utc(year, month + 1, 0).day;
  return day >= 1 && day <= daysInMonth;
}
