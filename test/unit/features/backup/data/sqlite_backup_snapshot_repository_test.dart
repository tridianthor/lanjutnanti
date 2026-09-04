import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/features/backup/data/backup_snapshot_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

import '../../../../support/database_test_support.dart';

void main() {
  test('reads tags, contents, and details as one export snapshot', () {
    final database = AppDatabase.openInMemory();
    addTearDown(database.dispose);
    final clock = MutableClock(DateTime.utc(2026, 9, 4));
    final tags = SqliteTagRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['tag-1']),
    );
    final contents = SqliteContentRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['content-1']),
    );
    final details = SqliteContentDetailRepository(
      database,
      clock: clock,
      idGenerator: SequenceIdGenerator(['detail-1']),
    );

    final tag = tags.create('Manga');
    final content = contents.create(name: 'Doraemon', tagId: tag.id);
    details.create(
      contentId: content.id,
      link: 'https://example.com/chapter/1',
      note: 'Continue here',
    );

    final snapshot = SqliteBackupSnapshotRepository(database).readSnapshot();

    expect(snapshot.tags.map((value) => value.id), ['tag-1']);
    expect(snapshot.contents.map((value) => value.id), ['content-1']);
    expect(snapshot.contents.single.tagId, 'tag-1');
    expect(snapshot.contentDetails.map((value) => value.id), ['detail-1']);
    expect(snapshot.contentDetails.single.contentId, 'content-1');
    expect(snapshot.contentDetails.single.note, 'Continue here');
  });
}
