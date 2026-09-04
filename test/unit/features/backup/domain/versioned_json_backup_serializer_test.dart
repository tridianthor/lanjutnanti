import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/features/content/domain/content.dart';
import 'package:lanjut_nanti/features/content/domain/content_detail.dart';
import 'package:lanjut_nanti/features/backup/domain/backup_snapshot.dart';
import 'package:lanjut_nanti/features/tags/domain/tag.dart';

void main() {
  test('serializes the schema-version-1 backup shape', () {
    final snapshot = BackupSnapshot(
      tags: [
        Tag(
          id: 'tag-1',
          name: 'Manga',
          createdAt: DateTime.utc(2026, 9, 1),
          updatedAt: DateTime.utc(2026, 9, 2),
        ),
      ],
      contents: [
        Content(
          id: 'content-1',
          name: 'Doraemon',
          tagId: 'tag-1',
          createdAt: DateTime.utc(2026, 9, 1),
          updatedAt: DateTime.utc(2026, 9, 2),
        ),
      ],
      contentDetails: [
        ContentDetail(
          id: 'detail-1',
          contentId: 'content-1',
          link: 'https://example.com/chapter/1',
          note: 'Continue from chapter 1',
          createdAt: DateTime.utc(2026, 9, 1),
          updatedAt: DateTime.utc(2026, 9, 2),
        ),
      ],
    );

    final json = VersionedJsonBackupSerializer().serialize(
      snapshot,
      exportedAt: DateTime.utc(2026, 9, 4, 5, 6, 7),
    );
    final decoded = jsonDecode(json) as Map<String, dynamic>;

    expect(decoded['schema_version'], 1);
    expect(decoded['exported_at'], '2026-09-04T05:06:07.000Z');
    expect(decoded['tags'], isA<List<dynamic>>());
    expect(decoded['contents'], isA<List<dynamic>>());
    expect(decoded['content_details'], isA<List<dynamic>>());
    expect(decoded['tags'].single['id'], 'tag-1');
    expect(decoded['contents'].single['tag_id'], 'tag-1');
    expect(decoded['content_details'].single['content_id'], 'content-1');
  });

  test('normalizes every timestamp to an ISO 8601 UTC string', () {
    final snapshot = BackupSnapshot(
      tags: [
        Tag(
          id: 'tag-1',
          name: 'Manga',
          createdAt: DateTime.parse('2026-09-01T09:00:00+07:00'),
          updatedAt: DateTime.parse('2026-09-02T09:00:00+07:00'),
        ),
      ],
      contents: [
        Content(
          id: 'content-1',
          name: 'Doraemon',
          createdAt: DateTime.parse('2026-09-01T09:05:00+07:00'),
          updatedAt: DateTime.parse('2026-09-02T09:05:00+07:00'),
        ),
      ],
      contentDetails: [
        ContentDetail(
          id: 'detail-1',
          contentId: 'content-1',
          link: 'https://example.com',
          createdAt: DateTime.parse('2026-09-01T09:10:00+07:00'),
          updatedAt: DateTime.parse('2026-09-02T09:10:00+07:00'),
        ),
      ],
    );

    final document = VersionedJsonBackupSerializer().toMap(
      snapshot,
      exportedAt: DateTime.parse('2026-09-04T12:00:00+07:00'),
    );

    expect(document['exported_at'], '2026-09-04T05:00:00.000Z');
    final tag = (document['tags'] as List<dynamic>).single;
    final content = (document['contents'] as List<dynamic>).single;
    final detail = (document['content_details'] as List<dynamic>).single;
    expect(tag['created_at'], endsWith('Z'));
    expect(content['updated_at'], endsWith('Z'));
    expect(detail['created_at'], endsWith('Z'));
  });

  test('omits reserved ownership and credential fields', () {
    final snapshot = BackupSnapshot(
      tags: const [],
      contents: [
        Content(
          id: 'content-private',
          name: 'Private content',
          userId: 'user-secret',
          createdAt: DateTime.utc(2026, 9, 1),
          updatedAt: DateTime.utc(2026, 9, 1),
        ),
      ],
      contentDetails: const [],
    );

    final json = VersionedJsonBackupSerializer().serialize(
      snapshot,
      exportedAt: DateTime.utc(2026, 9, 4),
    );
    final content =
        (jsonDecode(json) as Map<String, dynamic>)['contents'].single
            as Map<String, dynamic>;

    expect(content.containsKey('user_id'), isFalse);
    expect(json, isNot(contains('users')));
    expect(json, isNot(contains('credentials')));
    expect(json, isNot(contains('tokens')));
    expect(json, isNot(contains('user-secret')));
  });

  test('preserves null relationships, null notes, and UTF-8 text', () {
    final snapshot = BackupSnapshot(
      tags: const [],
      contents: [
        Content(
          id: 'content-unicode',
          name: '読む 📚',
          tagId: null,
          createdAt: DateTime.utc(2026, 9, 1),
          updatedAt: DateTime.utc(2026, 9, 1),
        ),
      ],
      contentDetails: [
        ContentDetail(
          id: 'detail-null-note',
          contentId: 'content-unicode',
          link: 'https://example.com/日本語',
          note: null,
          createdAt: DateTime.utc(2026, 9, 1),
          updatedAt: DateTime.utc(2026, 9, 1),
        ),
      ],
    );

    final serializer = VersionedJsonBackupSerializer();
    final bytes = serializer.encodeUtf8(
      snapshot,
      exportedAt: DateTime.utc(2026, 9, 4),
    );
    final document = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

    final content = (document['contents'] as List<dynamic>).single;
    final detail = (document['content_details'] as List<dynamic>).single;
    expect(content['tag_id'], isNull);
    expect(detail['note'], isNull);
    expect(content['name'], '読む 📚');
    expect(detail['link'], contains('日本語'));
  });
}
