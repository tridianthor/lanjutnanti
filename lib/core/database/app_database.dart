import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart' as sqlite_open;
import 'package:sqlite3/sqlite3.dart';

/// The SQLite connection and schema owner for the application.
class AppDatabase {
  AppDatabase._(this.raw) {
    _enableForeignKeys();
    _migrate();
  }

  factory AppDatabase.openInMemory() {
    _configureLinuxSqliteLoader();
    return AppDatabase._(sqlite3.openInMemory());
  }

  factory AppDatabase.open(String path) {
    _configureLinuxSqliteLoader();
    return AppDatabase._(sqlite3.open(path));
  }

  factory AppDatabase.fromRaw(Database database) {
    _configureLinuxSqliteLoader();
    return AppDatabase._(database);
  }

  final Database raw;

  static const schemaVersion = 1;

  T transaction<T>(T Function() action) {
    raw.execute('BEGIN IMMEDIATE');
    try {
      final result = action();
      raw.execute('COMMIT');
      return result;
    } catch (error, stackTrace) {
      try {
        raw.execute('ROLLBACK');
      } catch (_) {
        // Preserve the original database error if rollback itself fails.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void dispose() => raw.dispose();

  void _enableForeignKeys() {
    raw.execute('PRAGMA foreign_keys = ON');
    final enabled = raw.select('PRAGMA foreign_keys').single['foreign_keys'];
    if (enabled != 1) {
      throw StateError('SQLite foreign-key enforcement could not be enabled');
    }
  }

  void _migrate() {
    final currentVersion =
        raw.select('PRAGMA user_version').single['user_version'] as int;

    if (currentVersion > schemaVersion) {
      throw StateError(
        'Database schema version $currentVersion is newer than supported '
        'version $schemaVersion',
      );
    }

    if (currentVersion == 0) {
      transaction<void>(() {
        for (final statement in _schemaVersion1Statements) {
          raw.execute(statement);
        }
        raw.execute('PRAGMA user_version = $schemaVersion');
      });
    }
  }
}

const _schemaVersion1Statements = [
  '''
  CREATE TABLE tags (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL CHECK (length(trim(name)) > 0),
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE contents (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL CHECK (length(trim(name)) > 0),
    tag_id TEXT,
    user_id TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE SET NULL
  )
  ''',
  '''
  CREATE TABLE content_details (
    id TEXT PRIMARY KEY NOT NULL,
    content_id TEXT NOT NULL,
    link TEXT NOT NULL CHECK (length(trim(link)) > 0),
    note TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (content_id) REFERENCES contents(id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE content_activity_floor (
    content_id TEXT PRIMARY KEY NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (content_id) REFERENCES contents(id) ON DELETE CASCADE
  )
  ''',
  'CREATE UNIQUE INDEX idx_tags_name_nocase '
      'ON tags(lower(trim(name)))',
  'CREATE INDEX idx_contents_tag_id ON contents(tag_id)',
  'CREATE INDEX idx_contents_recent_activity '
      'ON contents(updated_at DESC, created_at DESC, id DESC)',
  'CREATE INDEX idx_contents_name ON contents(name COLLATE NOCASE)',
  'CREATE INDEX idx_content_details_content_id ON content_details(content_id)',
  'CREATE INDEX idx_content_details_latest '
      'ON content_details(content_id, updated_at DESC, created_at DESC, id DESC)',
  'CREATE INDEX idx_content_details_note ON content_details(note COLLATE NOCASE)',
];

bool _linuxSqliteLoaderConfigured = false;

void _configureLinuxSqliteLoader() {
  if (!Platform.isLinux || _linuxSqliteLoaderConfigured) return;

  sqlite_open.open.overrideFor(sqlite_open.OperatingSystem.linux, () {
    final process = DynamicLibrary.executable();
    if (process.providesSymbol('sqlite3_version')) return process;

    try {
      return DynamicLibrary.open('libsqlite3.so');
    } on ArgumentError {
      return DynamicLibrary.open('libsqlite3.so.0');
    }
  });
  _linuxSqliteLoaderConfigured = true;
}
