import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/database/sqlite_value_codec.dart';
import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/content/domain/content.dart';

abstract interface class ContentRepository {
  List<Content> getAll();

  List<Content> listRecent();

  Content? findById(String id);

  Content? getById(String id);

  Content create({required String name, String? tagId});

  Content insert(Content content);

  Content update(Content content);

  Content edit({required String id, required String name, String? tagId});

  Content assignTag({required String id, required String? tagId});

  void delete(String id);
}

class SqliteContentRepository implements ContentRepository {
  SqliteContentRepository(
    this.database, {
    Clock? clock,
    IdGenerator? idGenerator,
  }) : _clock = clock ?? const SystemClock(),
       _idGenerator = idGenerator ?? RandomIdGenerator();

  final AppDatabase database;
  final Clock _clock;
  final IdGenerator _idGenerator;

  @override
  List<Content> getAll() {
    final rows = database.raw.select('''
      SELECT id, name, tag_id, user_id, created_at, updated_at
      FROM contents
      ORDER BY updated_at DESC, created_at DESC, id DESC
    ''');
    return rows.map(_fromRow).toList();
  }

  @override
  List<Content> listRecent() => getAll();

  @override
  Content? findById(String id) {
    final rows = database.raw.select(
      '''
      SELECT id, name, tag_id, user_id, created_at, updated_at
      FROM contents
      WHERE id = ?
    ''',
      [id],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Content? getById(String id) => findById(id);

  @override
  Content create({required String name, String? tagId}) {
    return insert(
      Content.create(
        name: name,
        tagId: tagId,
        clock: _clock,
        idGenerator: _idGenerator,
      ),
    );
  }

  @override
  Content insert(Content content) {
    final normalizedName = Content.normalizeName(content.name);
    database.transaction<void>(() {
      database.raw.execute(
        '''
        INSERT INTO contents (
          id, name, tag_id, user_id, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
        [
          content.id,
          normalizedName,
          content.tagId,
          content.userId,
          encodeUtcTimestamp(content.createdAt),
          encodeUtcTimestamp(content.updatedAt),
        ],
      );
      database.raw.execute(
        '''
        INSERT INTO content_activity_floor (content_id, updated_at)
        VALUES (?, ?)
      ''',
        [content.id, encodeUtcTimestamp(content.updatedAt)],
      );
    });
    return normalizedName == content.name
        ? content
        : Content(
          id: content.id,
          name: normalizedName,
          tagId: content.tagId,
          userId: content.userId,
          createdAt: content.createdAt,
          updatedAt: content.updatedAt,
        );
  }

  @override
  Content update(Content content) {
    final normalizedName = Content.normalizeName(content.name);
    database.transaction<void>(() {
      database.raw.execute(
        '''
        UPDATE contents
        SET name = ?, tag_id = ?, user_id = ?, created_at = ?, updated_at = ?
        WHERE id = ?
      ''',
        [
          normalizedName,
          content.tagId,
          content.userId,
          encodeUtcTimestamp(content.createdAt),
          encodeUtcTimestamp(content.updatedAt),
          content.id,
        ],
      );
      if (database.raw.updatedRows == 0) {
        throw StateError('Content ${content.id} does not exist');
      }
      database.raw.execute(
        '''
        UPDATE content_activity_floor
        SET updated_at = ?
        WHERE content_id = ?
      ''',
        [encodeUtcTimestamp(content.updatedAt), content.id],
      );
    });
    return normalizedName == content.name
        ? content
        : Content(
          id: content.id,
          name: normalizedName,
          tagId: content.tagId,
          userId: content.userId,
          createdAt: content.createdAt,
          updatedAt: content.updatedAt,
        );
  }

  @override
  Content edit({required String id, required String name, String? tagId}) {
    final existing = findById(id);
    if (existing == null) {
      throw StateError('Content $id does not exist');
    }
    final normalizedName = Content.normalizeName(name);
    return update(
      Content(
        id: existing.id,
        name: normalizedName,
        tagId: tagId,
        userId: existing.userId,
        createdAt: existing.createdAt,
        updatedAt: _clock.now().toUtc(),
      ),
    );
  }

  @override
  Content assignTag({required String id, required String? tagId}) {
    final existing = findById(id);
    if (existing == null) {
      throw StateError('Content $id does not exist');
    }
    return edit(id: id, name: existing.name, tagId: tagId);
  }

  @override
  void delete(String id) {
    database.transaction<void>(() {
      database.raw.execute('DELETE FROM contents WHERE id = ?', [id]);
    });
  }

  Content _fromRow(Map<String, Object?> row) {
    return Content(
      id: row['id']! as String,
      name: row['name']! as String,
      tagId: row['tag_id'] as String?,
      userId: row['user_id'] as String?,
      createdAt: decodeUtcTimestamp(row['created_at']),
      updatedAt: decodeUtcTimestamp(row['updated_at']),
    );
  }
}

typedef SQLiteContentRepository = SqliteContentRepository;
