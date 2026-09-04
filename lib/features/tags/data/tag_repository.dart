import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/database/sqlite_value_codec.dart';
import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/tags/domain/tag.dart';

abstract interface class TagRepository {
  List<Tag> getAll();

  List<Tag> list();

  Tag? findById(String id);

  Tag? getById(String id);

  Tag create(String name);

  Tag insert(Tag tag);

  Tag update(Tag tag);

  Tag rename({required String id, required String name});

  void delete(String id);
}

class SqliteTagRepository implements TagRepository {
  SqliteTagRepository(this.database, {Clock? clock, IdGenerator? idGenerator})
    : _clock = clock ?? const SystemClock(),
      _idGenerator = idGenerator ?? RandomIdGenerator();

  final AppDatabase database;
  final Clock _clock;
  final IdGenerator _idGenerator;

  @override
  List<Tag> getAll() {
    final rows = database.raw.select('''
      SELECT id, name, created_at, updated_at
      FROM tags
      ORDER BY name COLLATE NOCASE ASC, id ASC
    ''');
    return rows.map(_fromRow).toList();
  }

  @override
  List<Tag> list() => getAll();

  @override
  Tag? findById(String id) {
    final rows = database.raw.select(
      '''
      SELECT id, name, created_at, updated_at
      FROM tags
      WHERE id = ?
    ''',
      [id],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Tag? getById(String id) => findById(id);

  @override
  Tag create(String name) {
    return insert(
      Tag.create(name: name, clock: _clock, idGenerator: _idGenerator),
    );
  }

  @override
  Tag insert(Tag tag) {
    final normalizedName = Tag.normalizeName(tag.name);
    database.raw.execute(
      '''
      INSERT INTO tags (id, name, created_at, updated_at)
      VALUES (?, ?, ?, ?)
    ''',
      [
        tag.id,
        normalizedName,
        encodeUtcTimestamp(tag.createdAt),
        encodeUtcTimestamp(tag.updatedAt),
      ],
    );
    return normalizedName == tag.name
        ? tag
        : Tag(
          id: tag.id,
          name: normalizedName,
          createdAt: tag.createdAt,
          updatedAt: tag.updatedAt,
        );
  }

  @override
  Tag update(Tag tag) {
    final normalizedName = Tag.normalizeName(tag.name);
    database.raw.execute(
      '''
      UPDATE tags
      SET name = ?, created_at = ?, updated_at = ?
      WHERE id = ?
    ''',
      [
        normalizedName,
        encodeUtcTimestamp(tag.createdAt),
        encodeUtcTimestamp(tag.updatedAt),
        tag.id,
      ],
    );
    if (database.raw.updatedRows == 0) {
      throw StateError('Tag ${tag.id} does not exist');
    }
    return normalizedName == tag.name
        ? tag
        : Tag(
          id: tag.id,
          name: normalizedName,
          createdAt: tag.createdAt,
          updatedAt: tag.updatedAt,
        );
  }

  @override
  Tag rename({required String id, required String name}) {
    final existing = findById(id);
    if (existing == null) {
      throw StateError('Tag $id does not exist');
    }
    final normalizedName = Tag.normalizeName(name);
    final updated = Tag(
      id: existing.id,
      name: normalizedName,
      createdAt: existing.createdAt,
      updatedAt: _clock.now().toUtc(),
    );
    return update(updated);
  }

  @override
  void delete(String id) {
    final updatedAt = encodeUtcTimestamp(_clock.now());
    database.transaction<void>(() {
      database.raw.execute(
        '''
        UPDATE content_activity_floor
        SET updated_at = ?
        WHERE content_id IN (
          SELECT id FROM contents WHERE tag_id = ?
        )
      ''',
        [updatedAt, id],
      );
      database.raw.execute(
        '''
        UPDATE contents
        SET tag_id = NULL, updated_at = ?
        WHERE tag_id = ?
      ''',
        [updatedAt, id],
      );
      database.raw.execute('DELETE FROM tags WHERE id = ?', [id]);
    });
  }

  Tag _fromRow(Map<String, Object?> row) {
    return Tag(
      id: row['id']! as String,
      name: row['name']! as String,
      createdAt: decodeUtcTimestamp(row['created_at']),
      updatedAt: decodeUtcTimestamp(row['updated_at']),
    );
  }
}

typedef SQLiteTagRepository = SqliteTagRepository;
