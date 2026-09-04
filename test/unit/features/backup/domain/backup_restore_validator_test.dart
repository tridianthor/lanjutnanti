import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/features/backup/domain/backup_restore.dart';

void main() {
  test('validates a backup into an immutable preview', () {
    final result = const BackupRestoreValidator().validateJson(
      jsonEncode({
        'schema_version': 1,
        'exported_at': '2026-09-04T05:00:00.000Z',
        'tags': [
          {
            'id': '11111111-1111-4111-8111-111111111111',
            'name': ' Manga ',
            'created_at': '2026-09-01T05:00:00.000Z',
            'updated_at': '2026-09-01T05:00:00.000Z',
          },
        ],
        'contents': [
          {
            'id': '22222222-2222-4222-8222-222222222222',
            'name': ' Doraemon ',
            'tag_id': '11111111-1111-4111-8111-111111111111',
            'user_id': 'should-not-be-restored',
            'created_at': '2026-09-01T05:01:00.000Z',
            'updated_at': '2026-09-01T05:02:00.000Z',
          },
        ],
        'content_details': [
          {
            'id': '33333333-3333-4333-8333-333333333333',
            'content_id': '22222222-2222-4222-8222-222222222222',
            'link': ' https://example.com/chapter-1 ',
            'note': ' Continue here ',
            'created_at': '2026-09-01T05:03:00.000Z',
            'updated_at': '2026-09-01T05:04:00.000Z',
          },
        ],
      }),
    );

    expect(result.isValid, isTrue);
    final preview = result.preview!;
    expect(preview.tags.single.name, 'Manga');
    expect(preview.contents.single.name, 'Doraemon');
    expect(preview.contents.single.userId, isNull);
    expect(preview.contentDetails.single.link, 'https://example.com/chapter-1');
    expect(preview.contentDetails.single.note, ' Continue here ');
    expect(preview.contents.single.updatedAt, DateTime.utc(2026, 9, 1, 5, 4));
    expect(preview.tagCount, 1);
    expect(preview.contentCount, 1);
    expect(preview.detailCount, 1);
  });

  test('rejects malformed JSON and non-object top levels', () {
    const validator = BackupRestoreValidator();

    final malformed = validator.validateJson('{not json');
    final array = validator.validateJson('[]');

    expect(malformed.isValid, isFalse);
    expect(malformed.issues.single.message, contains('valid JSON'));
    expect(array.isValid, isFalse);
    expect(array.issues.single.path, r'$');
    expect(array.issues.single.message, contains('JSON object'));
  });

  test('rejects unsupported versions and missing or incorrect collections', () {
    final result = const BackupRestoreValidator().validateJson(
      jsonEncode({
        'schema_version': 2,
        'exported_at': 'not-a-timestamp',
        'tags': {},
        'contents': [],
      }),
    );

    expect(result.isValid, isFalse);
    expect(
      result.issues.map((issue) => issue.path),
      containsAll(['schema_version', 'exported_at', 'tags', 'content_details']),
    );
  });

  test(
    'rejects invalid fields, IDs, links, timestamps, and optional types',
    () {
      final result = const BackupRestoreValidator().validateJson(
        jsonEncode({
          'schema_version': 1,
          'exported_at': '2026-09-04T05:00:00.000Z',
          'tags': [
            {
              'id': 'tag-1',
              'name': 'Manga',
              'created_at': '2026-09-01T05:00:00.000Z',
              'updated_at': '2026-09-01T05:00:00.000Z',
            },
          ],
          'contents': [
            {
              'id': '22222222-2222-4222-8222-222222222222',
              'name': 'Doraemon',
              'tag_id': 7,
              'created_at': '2026-09-01T05:01:00.000Z',
              'updated_at': '2026-09-01T99:01:00.000Z',
            },
          ],
          'content_details': [
            {
              'id': '33333333-3333-4333-8333-333333333333',
              'content_id': '22222222-2222-4222-8222-222222222222',
              'link': '/relative/path',
              'note': 42,
              'created_at': '2026-09-01T05:03:00.000Z',
              'updated_at': '2026-09-01T05:04:00.000Z',
            },
          ],
        }),
      );

      expect(result.isValid, isFalse);
      expect(
        result.issues.map((issue) => issue.path),
        containsAll([
          'tags[0].id',
          'contents[0].tag_id',
          'contents[0].updated_at',
          'content_details[0].link',
          'content_details[0].note',
        ]),
      );
    },
  );

  test(
    'rejects duplicate IDs, duplicate tag names, and unknown references',
    () {
      final result = const BackupRestoreValidator().validateJson(
        jsonEncode({
          'schema_version': 1,
          'exported_at': '2026-09-04T05:00:00.000Z',
          'tags': [
            _tag(id: '11111111-1111-4111-8111-111111111111', name: 'Manga'),
            _tag(id: '22222222-2222-4222-8222-222222222222', name: ' manga '),
          ],
          'contents': [
            _content(
              id: '11111111-1111-4111-8111-111111111111',
              tagId: '99999999-9999-4999-8999-999999999999',
            ),
          ],
          'content_details': [
            _detail(
              id: '33333333-3333-4333-8333-333333333333',
              contentId: '99999999-9999-4999-8999-999999999999',
            ),
          ],
        }),
      );

      expect(result.isValid, isFalse);
      expect(
        result.issues.map((issue) => issue.path),
        containsAll([
          'contents[0].id',
          'contents[0].tag_id',
          'content_details[0].content_id',
          'tags',
        ]),
      );
    },
  );

  test('keeps preview collections and activity floors immutable', () {
    final result = const BackupRestoreValidator().validateJson(
      jsonEncode(_document()),
    );

    final preview = result.preview!;
    expect(() => preview.tags.add(preview.tags.single), throwsUnsupportedError);
    expect(
      () => preview.contentActivityFloors['new'] = DateTime.utc(2026),
      throwsUnsupportedError,
    );
  });
}

Map<String, dynamic> _document() {
  return {
    'schema_version': 1,
    'exported_at': '2026-09-04T05:00:00.000Z',
    'tags': [_tag(id: '11111111-1111-4111-8111-111111111111', name: 'Manga')],
    'contents': [
      _content(
        id: '22222222-2222-4222-8222-222222222222',
        tagId: '11111111-1111-4111-8111-111111111111',
      ),
    ],
    'content_details': [
      _detail(
        id: '33333333-3333-4333-8333-333333333333',
        contentId: '22222222-2222-4222-8222-222222222222',
      ),
    ],
  };
}

Map<String, dynamic> _tag({required String id, required String name}) {
  return {
    'id': id,
    'name': name,
    'created_at': '2026-09-01T05:00:00.000Z',
    'updated_at': '2026-09-01T05:00:00.000Z',
  };
}

Map<String, dynamic> _content({required String id, String? tagId}) {
  return {
    'id': id,
    'name': 'Doraemon',
    'tag_id': tagId,
    'created_at': '2026-09-01T05:01:00.000Z',
    'updated_at': '2026-09-01T05:02:00.000Z',
  };
}

Map<String, dynamic> _detail({required String id, required String contentId}) {
  return {
    'id': id,
    'content_id': contentId,
    'link': 'https://example.com/chapter-1',
    'note': 'Continue here',
    'created_at': '2026-09-01T05:03:00.000Z',
    'updated_at': '2026-09-01T05:04:00.000Z',
  };
}
