import 'package:lanjut_nanti/l10n/app_localizations.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/features/backup/application/backup_restore_controller.dart';
import 'package:lanjut_nanti/features/backup/data/backup_restore_repository.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/content/presentation/home_screen.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

void main() {
  late AppDatabase database;
  late ContentListController contentController;
  late BackupRestoreController restoreController;
  late _FakeRestoreRepository restoreRepository;
  late _FakeRestoreFileGateway fileGateway;

  setUp(() {
    database = AppDatabase.openInMemory();
    final contentRepository = SqliteContentRepository(database);
    final detailRepository = SqliteContentDetailRepository(database);
    final tagRepository = SqliteTagRepository(database);
    contentController = ContentListController(
      service: ContentApplicationService(
        contentRepository: contentRepository,
        detailRepository: detailRepository,
        tagRepository: tagRepository,
      ),
    );
    restoreRepository = _FakeRestoreRepository();
    fileGateway = _FakeRestoreFileGateway();
    restoreController = BackupRestoreController(
      restoreRepository: restoreRepository,
      fileGateway: fileGateway,
    );
  });

  tearDown(() {
    restoreController.dispose();
    contentController.dispose();
    database.dispose();
  });

  Widget app() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: HomeScreen(
        controller: contentController,
        backupRestoreController: restoreController,
      ),
    );
  }

  testWidgets('shows a valid preview and does not replace on cancellation', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-backup-action')));
    await tester.pumpAndSettle();

    expect(find.text('Replace local data?'), findsOneWidget);
    expect(find.textContaining('1 tag'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cancel-restore-backup')));
    await tester.pumpAndSettle();

    expect(restoreRepository.calls, 0);
  });

  testWidgets('confirms replacement and reports restored counts', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-backup-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-restore-backup')));
    await tester.pumpAndSettle();

    expect(restoreRepository.calls, 1);
    expect(
      find.text('Restored 1 tag, 1 content item, and 1 detail.'),
      findsOneWidget,
    );
  });

  testWidgets('shows validation errors without offering replacement', (
    tester,
  ) async {
    fileGateway.json = '{bad';
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-backup-action')));
    await tester.pumpAndSettle();

    expect(find.text('Backup validation failed'), findsOneWidget);
    expect(
      find.textContaining('Your saved data was not changed.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('confirm-restore-backup')), findsNothing);
    expect(restoreRepository.calls, 0);
  });
}

class _FakeRestoreFileGateway implements BackupRestoreFileGateway {
  String json = _validJson;

  @override
  Future<BackupFileReadResult> pick() async {
    return BackupFileReadResult.selected(utf8.encode(json));
  }
}

class _FakeRestoreRepository implements BackupRestoreRepository {
  int calls = 0;

  @override
  void replace(BackupRestorePreview preview) {
    calls++;
  }
}

const _validJson = '''
{
  "schema_version": 1,
  "exported_at": "2026-09-04T05:00:00.000Z",
  "tags": [{"id":"11111111-1111-4111-8111-111111111111","name":"Manga","created_at":"2026-09-01T05:00:00.000Z","updated_at":"2026-09-01T05:00:00.000Z"}],
  "contents": [{"id":"22222222-2222-4222-8222-222222222222","name":"Doraemon","tag_id":"11111111-1111-4111-8111-111111111111","created_at":"2026-09-01T05:01:00.000Z","updated_at":"2026-09-01T05:02:00.000Z"}],
  "content_details": [{"id":"33333333-3333-4333-8333-333333333333","content_id":"22222222-2222-4222-8222-222222222222","link":"https://example.com/chapter-1","note":"Continue here","created_at":"2026-09-01T05:03:00.000Z","updated_at":"2026-09-01T05:04:00.000Z"}]
}
''';
