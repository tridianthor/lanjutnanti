import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/features/settings/data/locale_preference_repository.dart';
import 'package:lanjut_nanti/features/settings/domain/locale_preference.dart';

void main() {
  test(
    'persists overrides across reopen and deletes system override',
    () async {
      final dir = Directory.systemTemp.createTempSync('locale-test');
      addTearDown(() => dir.deleteSync(recursive: true));
      var db = AppDatabase.open('${dir.path}/app.sqlite');
      var repo = SqliteLocalePreferenceRepository(db);
      expect(await repo.read(), LocalePreference.system);
      await repo.write(LocalePreference.indonesian);
      db.dispose();
      db = AppDatabase.open('${dir.path}/app.sqlite');
      addTearDown(db.dispose);
      repo = SqliteLocalePreferenceRepository(db);
      expect(await repo.read(), LocalePreference.indonesian);
      await repo.write(LocalePreference.english);
      expect(await repo.read(), LocalePreference.english);
      await repo.write(LocalePreference.system);
      expect(db.raw.select('SELECT * FROM app_settings'), isEmpty);
      expect(await repo.read(), LocalePreference.system);
    },
  );
  test('invalid reads and failed writes preserve stored preference', () async {
    final db = AppDatabase.openInMemory();
    addTearDown(db.dispose);
    final repo = SqliteLocalePreferenceRepository(db);
    db.raw.execute("INSERT INTO app_settings VALUES ('app_locale', 'fr')");
    await expectLater(repo.read(), throwsFormatException);
    db.raw.execute(
      "CREATE TRIGGER reject_locale BEFORE UPDATE ON app_settings BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(
      repo.write(LocalePreference.indonesian),
      throwsA(anything),
    );
    expect(
      db.raw.select('SELECT value FROM app_settings').single['value'],
      'fr',
    );
  });
}
