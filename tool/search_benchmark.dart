import 'dart:io';

import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

void main() {
  final database = AppDatabase.openInMemory();
  final repository = SqliteContentRepository(database);
  final detailRepository = SqliteContentDetailRepository(database);
  final tagRepository = SqliteTagRepository(database);
  final service = ContentApplicationService(
    contentRepository: repository,
    detailRepository: detailRepository,
    tagRepository: tagRepository,
  );

  database.transaction<void>(() {
    for (var index = 0; index < 10; index++) {
      database.raw.execute(
        '''
        INSERT INTO tags (id, name, created_at, updated_at)
        VALUES (?, ?, ?, ?)
      ''',
        [
          'tag-$index',
          'Tag $index',
          '2026-09-04T00:00:00.000Z',
          '2026-09-04T00:00:00.000Z',
        ],
      );
    }
    for (var index = 0; index < 10000; index++) {
      final contentId = 'content-$index';
      database.raw.execute(
        '''
        INSERT INTO contents (id, name, tag_id, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?)
      ''',
        [
          contentId,
          'Content $index',
          'tag-${index % 10}',
          '2026-09-04T00:00:00.000Z',
          '2026-09-04T00:00:00.000Z',
        ],
      );
      database.raw.execute(
        '''
        INSERT INTO content_activity_floor (content_id, updated_at)
        VALUES (?, ?)
      ''',
        [contentId, '2026-09-04T00:00:00.000Z'],
      );
    }
    for (var index = 0; index < 50000; index++) {
      final contentId = 'content-${index % 10000}';
      database.raw.execute(
        '''
        INSERT INTO content_details (
          id, content_id, link, note, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
        [
          'detail-$index',
          contentId,
          'https://example.com/$index',
          index % 100 == 0 ? 'Target note $index' : 'Checkpoint $index',
          '2026-09-04T00:00:00.000Z',
          '2026-09-04T00:00:00.000Z',
        ],
      );
    }
  });

  final profile = Stopwatch()..start();
  final profileContents = repository.listRecent();
  final contentReadMs = profile.elapsedMicroseconds / 1000;
  final profileTags = tagRepository.list();
  final tagReadMs = profile.elapsedMicroseconds / 1000 - contentReadMs;
  final profileDetails = detailRepository.latestForContents(
    profileContents.map((content) => content.id),
  );
  final detailReadMs =
      profile.elapsedMicroseconds / 1000 - contentReadMs - tagReadMs;
  for (final content in profileContents) {
    ContentListItem(
      content: content,
      tag:
          content.tagId == null
              ? null
              : profileTags.where((tag) => tag.id == content.tagId).firstOrNull,
      latestDetail: profileDetails[content.id],
    );
  }
  final projectionMs =
      profile.elapsedMicroseconds / 1000 -
      contentReadMs -
      tagReadMs -
      detailReadMs;
  stdout.writeln(
    'profile list: contents=${contentReadMs.toStringAsFixed(2)} ms '
    'tags=${tagReadMs.toStringAsFixed(2)} ms '
    'details=${detailReadMs.toStringAsFixed(2)} ms '
    'projection=${projectionMs.toStringAsFixed(2)} ms',
  );

  for (final query in ['', '9999', 'target note', 'tag 7']) {
    service.search(query);
    final stopwatch = Stopwatch()..start();
    final results = service.search(query);
    stopwatch.stop();
    stdout.writeln(
      'query=${query.toString().padRight(12)} '
      'results=${results.length.toString().padLeft(5)} '
      'elapsed=${stopwatch.elapsedMicroseconds / 1000} ms',
    );
  }

  database.dispose();
}
