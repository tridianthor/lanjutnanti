import 'package:lanjut_nanti/core/database/app_database.dart';
import '../domain/locale_preference.dart';

abstract interface class LocalePreferenceRepository {
  Future<LocalePreference> read();
  Future<void> write(LocalePreference preference);
}

class SqliteLocalePreferenceRepository implements LocalePreferenceRepository {
  SqliteLocalePreferenceRepository(this.database);
  final AppDatabase database;
  @override
  Future<LocalePreference> read() async {
    final rows = database.raw.select(
      "SELECT value FROM app_settings WHERE key = 'app_locale'",
    );
    return LocalePreference.parse(
      rows.isEmpty ? null : rows.single['value'] as String,
    );
  }

  @override
  Future<void> write(LocalePreference preference) async {
    database.transaction(() {
      if (preference.languageCode == null) {
        database.raw.execute(
          "DELETE FROM app_settings WHERE key = 'app_locale'",
        );
      } else {
        database.raw.execute(
          "INSERT INTO app_settings (key, value) VALUES ('app_locale', ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value",
          [preference.languageCode],
        );
      }
    });
  }
}

class MemoryLocalePreferenceRepository implements LocalePreferenceRepository {
  LocalePreference preference = LocalePreference.system;
  @override
  Future<LocalePreference> read() async => preference;
  @override
  Future<void> write(LocalePreference value) async {
    preference = value;
  }
}
