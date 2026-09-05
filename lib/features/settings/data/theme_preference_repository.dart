import 'package:lanjut_nanti/core/database/app_database.dart';
import '../domain/theme_preference.dart';

abstract interface class ThemePreferenceRepository {
  Future<ThemePreference> read();
  Future<void> write(ThemePreference preference);
}

class SqliteThemePreferenceRepository implements ThemePreferenceRepository {
  SqliteThemePreferenceRepository(this.database);
  final AppDatabase database;

  @override
  Future<ThemePreference> read() async {
    final rows = database.raw.select(
      "SELECT value FROM app_settings WHERE key = 'app_theme_mode'",
    );
    return ThemePreference.parse(
      rows.isEmpty ? null : rows.single['value'] as String,
    );
  }

  @override
  Future<void> write(ThemePreference preference) async {
    database.transaction(() {
      if (preference == ThemePreference.system) {
        database.raw.execute(
          "DELETE FROM app_settings WHERE key = 'app_theme_mode'",
        );
      } else {
        database.raw.execute(
          "INSERT INTO app_settings (key, value) VALUES ('app_theme_mode', ?) "
          "ON CONFLICT(key) DO UPDATE SET value = excluded.value",
          [preference.storageValue],
        );
      }
    });
  }
}

class MemoryThemePreferenceRepository implements ThemePreferenceRepository {
  ThemePreference preference = ThemePreference.system;

  @override
  Future<ThemePreference> read() async => preference;

  @override
  Future<void> write(ThemePreference value) async {
    preference = value;
  }
}

