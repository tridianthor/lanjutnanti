import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/features/settings/domain/locale_preference.dart';

void main() {
  test('parses only supported overrides and absence', () {
    expect(LocalePreference.parse(null), LocalePreference.system);
    expect(LocalePreference.parse('en'), LocalePreference.english);
    expect(LocalePreference.parse('id'), LocalePreference.indonesian);
    for (final invalid in ['', 'fr', 'id_ID']) {
      expect(() => LocalePreference.parse(invalid), throwsFormatException);
    }
  });
}
