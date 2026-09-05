import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/features/settings/domain/theme_preference.dart';

void main() {
  test(
    'parses supported theme modes and defaults to system when null or system',
    () {
      expect(ThemePreference.parse(null), ThemePreference.system);
      expect(ThemePreference.parse('system'), ThemePreference.system);
      expect(ThemePreference.parse('light'), ThemePreference.light);
      expect(ThemePreference.parse('dark'), ThemePreference.dark);
      for (final invalid in ['', 'blue', 'dark_mode', 'LIGHT']) {
        expect(() => ThemePreference.parse(invalid), throwsFormatException);
      }
    },
  );

  test('exposes correct storage values', () {
    expect(ThemePreference.system.storageValue, 'system');
    expect(ThemePreference.light.storageValue, 'light');
    expect(ThemePreference.dark.storageValue, 'dark');
  });
}

