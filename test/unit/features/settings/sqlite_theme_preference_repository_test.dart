import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/features/settings/data/theme_preference_repository.dart';
import 'package:lanjut_nanti/features/settings/domain/theme_preference.dart';

void main() {
  test('persists overrides across reopen and deletes system override', () async {
    final dir = Directory.systemTemp.createTempSync('theme-test');
    addTearDown(() => dir.deleteSync(recursive: true));
    var db = AppDatabase.open('${dir.path}/app.sqlite');
    var repo = SqliteThemePreferenceRepository(db);
    expect(await repo.read(), ThemePreference.system);
    await repo.write(ThemePreference.dark);
    db.dispose();
    db = AppDatabase.open('${dir.path}/app.sqlite');
    addTearDown(db.dispose);
    repo = SqliteThemePreferenceRepository(db);
    expect(await repo.read(), ThemePreference.dark);
    await repo.write(ThemePreference.light);
    expect(await repo.read(), ThemePreference.light);
    await repo.write(ThemePreference.system);
    expect(
      db.raw.select("SELECT * FROM app_settings WHERE key = 'app_theme_mode'"),
      isEmpty,
    );
    expect(await repo.read(), ThemePreference.system);
  });

  test('invalid reads and failed writes preserve stored preference', () async {
    final db = AppDatabase.openInMemory();
    addTearDown(db.dispose);
    final repo = SqliteThemePreferenceRepository(db);
    db.raw.execute(
      "INSERT INTO app_settings VALUES ('app_theme_mode', 'invalid_mode')",
    );
    await expectLater(repo.read(), throwsFormatException);
    db.raw.execute(
      "CREATE TRIGGER reject_theme BEFORE UPDATE ON app_settings BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(repo.write(ThemePreference.light), throwsA(anything));
    expect(
      db.raw
          .select(
            "SELECT value FROM app_settings WHERE key = 'app_theme_mode'",
          )
          .single['value'],
      'invalid_mode',
    );
  });
}

