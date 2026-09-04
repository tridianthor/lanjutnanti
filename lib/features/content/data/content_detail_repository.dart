import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/database/sqlite_value_codec.dart';
import 'package:lanjut_nanti/core/ids/id_generator.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/content/domain/content_detail.dart';

abstract interface class ContentDetailRepository {
  List<ContentDetail> getForContent(String contentId);

  List<ContentDetail> listForContent(String contentId);

  ContentDetail? findById(String id);

  ContentDetail? getById(String id);

  ContentDetail? latestForContent(String contentId);

  ContentDetail create({
    required String contentId,
    required String link,
    String? note,
  });

  ContentDetail insert(ContentDetail detail);

  ContentDetail update(ContentDetail detail);

  ContentDetail edit({required String id, required String link, String? note});

  void delete(String id);
}

class SqliteContentDetailRepository implements ContentDetailRepository {
  SqliteContentDetailRepository(
    this.database, {
    Clock? clock,
    IdGenerator? idGenerator,
  }) : _clock = clock ?? const SystemClock(),
       _idGenerator = idGenerator ?? RandomIdGenerator();

  final AppDatabase database;
  final Clock _clock;
  final IdGenerator _idGenerator;

  @override
  List<ContentDetail> getForContent(String contentId) {
    final rows = database.raw.select(
      '''
      SELECT id, content_id, link, note, created_at, updated_at
      FROM content_details
      WHERE content_id = ?
      ORDER BY updated_at DESC, created_at DESC, id DESC
    ''',
      [contentId],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  List<ContentDetail> listForContent(String contentId) =>
      getForContent(contentId);

  @override
  ContentDetail? findById(String id) {
    final rows = database.raw.select(
      '''
      SELECT id, content_id, link, note, created_at, updated_at
      FROM content_details
      WHERE id = ?
    ''',
      [id],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  ContentDetail? getById(String id) => findById(id);

  @override
  ContentDetail? latestForContent(String contentId) {
    final rows = database.raw.select(
      '''
      SELECT id, content_id, link, note, created_at, updated_at
      FROM content_details
      WHERE content_id = ?
      ORDER BY updated_at DESC, created_at DESC, id DESC
      LIMIT 1
    ''',
      [contentId],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  ContentDetail create({
    required String contentId,
    required String link,
    String? note,
  }) {
    return insert(
      ContentDetail.create(
        contentId: contentId,
        link: link,
        note: note,
        clock: _clock,
        idGenerator: _idGenerator,
      ),
    );
  }

  @override
  ContentDetail insert(ContentDetail detail) {
    final normalizedLink = ContentDetail.normalizeLink(detail.link);
    final normalizedNote = ContentDetail.normalizeNote(detail.note);
    final updatedAt = encodeUtcTimestamp(detail.updatedAt);
    database.transaction<void>(() {
      database.raw.execute(
        '''
        INSERT INTO content_details (
          id, content_id, link, note, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
        [
          detail.id,
          detail.contentId,
          normalizedLink,
          normalizedNote,
          encodeUtcTimestamp(detail.createdAt),
          updatedAt,
        ],
      );
      database.raw.execute(
        '''
        UPDATE contents SET updated_at = ? WHERE id = ?
      ''',
        [updatedAt, detail.contentId],
      );
    });
    return detail;
  }

  @override
  ContentDetail update(ContentDetail detail) {
    final existing = findById(detail.id);
    if (existing == null) {
      throw StateError('Detail ${detail.id} does not exist');
    }
    if (existing.contentId != detail.contentId) {
      throw ArgumentError.value(
        detail.contentId,
        'contentId',
        'cannot be changed for an existing detail',
      );
    }
    final normalizedLink = ContentDetail.normalizeLink(detail.link);
    final normalizedNote = ContentDetail.normalizeNote(detail.note);
    final updatedAt = encodeUtcTimestamp(detail.updatedAt);
    database.transaction<void>(() {
      database.raw.execute(
        '''
        UPDATE content_details
        SET content_id = ?, link = ?, note = ?, created_at = ?, updated_at = ?
        WHERE id = ?
      ''',
        [
          detail.contentId,
          normalizedLink,
          normalizedNote,
          encodeUtcTimestamp(detail.createdAt),
          updatedAt,
          detail.id,
        ],
      );
      database.raw.execute(
        '''
        UPDATE contents SET updated_at = ? WHERE id = ?
      ''',
        [updatedAt, detail.contentId],
      );
    });
    return detail;
  }

  @override
  ContentDetail edit({required String id, required String link, String? note}) {
    final existing = findById(id);
    if (existing == null) {
      throw StateError('Detail $id does not exist');
    }
    return update(existing.edit(link: link, note: note, clock: _clock).detail);
  }

  @override
  void delete(String id) {
    database.transaction<void>(() {
      final detail = findById(id);
      if (detail == null) return;

      database.raw.execute('DELETE FROM content_details WHERE id = ?', [id]);
      final latest = latestForContent(detail.contentId);
      final floorRow = database.raw.select(
        '''
        SELECT updated_at
        FROM content_activity_floor
        WHERE content_id = ?
      ''',
        [detail.contentId],
      );
      final floor =
          floorRow.isEmpty
              ? null
              : decodeUtcTimestamp(floorRow.first['updated_at']);
      final detailActivity = latest?.updatedAt;
      final activity = _latestOf(detailActivity, floor);

      if (activity == null) {
        throw StateError('Content ${detail.contentId} has no activity floor');
      }
      database.raw.execute(
        '''
        UPDATE contents SET updated_at = ? WHERE id = ?
      ''',
        [encodeUtcTimestamp(activity), detail.contentId],
      );
    });
  }

  ContentDetail _fromRow(Map<String, Object?> row) {
    return ContentDetail(
      id: row['id']! as String,
      contentId: row['content_id']! as String,
      link: row['link']! as String,
      note: row['note'] as String?,
      createdAt: decodeUtcTimestamp(row['created_at']),
      updatedAt: decodeUtcTimestamp(row['updated_at']),
    );
  }
}

DateTime? _latestOf(DateTime? first, DateTime? second) {
  if (first == null) return second;
  if (second == null) return first;
  return first.isAfter(second) ? first : second;
}

typedef SQLiteContentDetailRepository = SqliteContentDetailRepository;
