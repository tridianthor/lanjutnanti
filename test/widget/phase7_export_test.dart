import 'package:lanjut_nanti/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/features/backup/application/backup_export_controller.dart';
import 'package:lanjut_nanti/features/backup/data/backup_snapshot_repository.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/content/presentation/home_screen.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

import '../support/database_test_support.dart';

void main() {
  late AppDatabase database;
  late BackupExportController exportController;
  late _FakeBackupFileGateway gateway;
  late ContentListController contentController;

  setUp(() {
    database = AppDatabase.openInMemory();
    final clock = MutableClock(DateTime.utc(2026, 9, 4));
    final contentRepository = SqliteContentRepository(database, clock: clock);
    final detailRepository = SqliteContentDetailRepository(
      database,
      clock: clock,
    );
    final tagRepository = SqliteTagRepository(database, clock: clock);
    final controller = ContentListController(
      service: ContentApplicationService(
        contentRepository: contentRepository,
        detailRepository: detailRepository,
        tagRepository: tagRepository,
      ),
    );
    gateway = _FakeBackupFileGateway();
    exportController = BackupExportController(
      snapshotRepository: SqliteBackupSnapshotRepository(database),
      fileGateway: gateway,
      clock: clock,
    );
    contentController = controller;
  });

  tearDown(() {
    contentController.dispose();
    exportController.dispose();
    database.dispose();
  });

  Widget app() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomeScreen(
        controller: contentController,
        backupExportController: exportController,
      ),
    );
  }

  testWidgets('export confirmation warns about private backup access', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Export backup'));
    await tester.pumpAndSettle();

    expect(find.text('Export backup?'), findsOneWidget);
    expect(
      find.text(
        'This backup may contain private links and notes. The destination '
        'you choose controls who can access the file.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('cancel-export-backup')));
    await tester.pumpAndSettle();

    expect(gateway.calls, 0);
    expect(find.text('Export backup?'), findsNothing);
  });

  testWidgets('confirming export sends the backup and reports success', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Export backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-export-backup')));
    await tester.pumpAndSettle();

    expect(gateway.calls, 1);
    expect(find.text('Backup exported successfully.'), findsOneWidget);
  });
}

class _FakeBackupFileGateway implements BackupFileGateway {
  int calls = 0;

  @override
  Future<BackupFileSaveResult> save({
    required String fileName,
    required List<int> bytes,
  }) async {
    calls++;
    return const BackupFileSaveResult.saved();
  }
}
