import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.openInMemory();
  });

  tearDown(() {
    database.dispose();
  });

  test('creates the version 2 relational schema with foreign keys enabled', () {
    final tables =
        database.raw
            .select('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name IN ('tags', 'contents', 'content_details')
      ORDER BY name
    ''')
            .map((row) => row['name'])
            .toList();

    expect(
      database.raw.select('PRAGMA user_version').single['user_version'],
      2,
    );
    expect(tables, ['content_details', 'contents', 'tags']);
    expect(
      database.raw.select('PRAGMA foreign_keys').single['foreign_keys'],
      1,
    );
  });

  test('creates device settings outside content tables', () {
    expect(
      database.raw.select(
        "SELECT name FROM sqlite_master WHERE name = 'app_settings'",
      ),
      hasLength(1),
    );
  });

  test('adds indexes for relationships and deterministic recent activity', () {
    final indexes =
        database.raw
            .select('''
          SELECT name
          FROM sqlite_master
          WHERE type = 'index'
          ORDER BY name
        ''')
            .map((row) => row['name'])
            .toList();

    expect(
      indexes,
      containsAll([
        'idx_contents_tag_id',
        'idx_contents_recent_activity',
        'idx_content_details_content_id',
        'idx_content_details_latest',
        'idx_content_details_note',
        'idx_contents_name',
      ]),
    );
  });

  test(
    'migration harness reopens an existing version 1 database unchanged',
    () {
      final directory = Directory.systemTemp.createTempSync('lanjut-nanti-db-');
      addTearDown(() {
        if (directory.existsSync()) directory.deleteSync(recursive: true);
      });
      final path = '${directory.path}/app.sqlite';

      final initial = AppDatabase.open(path);
      initial.raw.execute('''
      INSERT INTO tags (id, name, created_at, updated_at)
      VALUES ('tag-1', 'Manga', '2026-09-04T05:00:00.000Z', '2026-09-04T05:00:00.000Z')
    ''');
      initial.dispose();

      final raw = sqlite3.open(path);
      final reopened = AppDatabase.fromRaw(raw);
      addTearDown(reopened.dispose);

      expect(
        reopened.raw.select('PRAGMA user_version').single['user_version'],
        2,
      );
      expect(
        reopened.raw.select('SELECT name FROM tags').single['name'],
        'Manga',
      );
    },
  );
}
