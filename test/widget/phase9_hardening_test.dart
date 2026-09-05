import 'package:lanjut_nanti/l10n/app_localizations.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/backup/application/backup_export_controller.dart';
import 'package:lanjut_nanti/features/backup/application/backup_restore_controller.dart';
import 'package:lanjut_nanti/features/backup/data/backup_restore_repository.dart';
import 'package:lanjut_nanti/features/backup/data/backup_snapshot_repository.dart';
import 'package:lanjut_nanti/features/content/application/content_application_service.dart';
import 'package:lanjut_nanti/features/content/application/content_list_controller.dart';
import 'package:lanjut_nanti/features/content/data/content_detail_repository.dart';
import 'package:lanjut_nanti/features/content/data/content_repository.dart';
import 'package:lanjut_nanti/features/content/presentation/home_screen.dart';
import 'package:lanjut_nanti/features/tags/data/tag_repository.dart';

void main() {
  late AppDatabase database;
  late ContentListController contentController;
  BackupExportController? exportController;
  BackupRestoreController? restoreController;

  setUp(() {
    exportController = null;
    restoreController = null;
    database = AppDatabase.openInMemory();
    contentController = ContentListController(
      service: ContentApplicationService(
        contentRepository: SqliteContentRepository(database),
        detailRepository: SqliteContentDetailRepository(database),
        tagRepository: SqliteTagRepository(database),
      ),
    );
  });

  tearDown(() {
    contentController.dispose();
    exportController?.dispose();
    restoreController?.dispose();
    database.dispose();
  });

  testWidgets('export cancellation and destination failure are recoverable', (
    tester,
  ) async {
    final gateway = _ExportGateway();
    exportController = BackupExportController(
      snapshotRepository: SqliteBackupSnapshotRepository(database),
      fileGateway: gateway,
      clock: _FixedClock(DateTime.utc(2026, 9, 4)),
    );
    await tester.pumpWidget(_app(contentController, export: exportController));
    await tester.pumpAndSettle();

    gateway.result = const BackupFileSaveResult.cancelled();
    await _confirmExport(tester);
    expect(
      find.text('Export cancelled. Your saved data was not changed.'),
      findsOneWidget,
    );

    gateway.error = StateError('disk full');
    await _confirmExport(tester);
    expect(
      find.text('Could not export backup. Your saved data was not changed.'),
      findsOneWidget,
    );
  });

  testWidgets('import cancellation and validation failure are recoverable', (
    tester,
  ) async {
    final gateway = _ImportGateway();
    restoreController = BackupRestoreController(
      restoreRepository: _RecordingRestoreRepository(),
      fileGateway: gateway,
    );
    await tester.pumpWidget(
      _app(contentController, restore: restoreController),
    );
    await tester.pumpAndSettle();

    gateway.result = const BackupFileReadResult.cancelled();
    await tester.tap(find.byKey(const ValueKey('settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-backup-action')));
    await tester.pumpAndSettle();
    expect(
      find.text('Import cancelled. Your saved data was not changed.'),
      findsOneWidget,
    );

    gateway.result = BackupFileReadResult.selected(utf8.encode('{bad'));
    await tester.tap(find.byKey(const ValueKey('import-backup-action')));
    await tester.pumpAndSettle();
    expect(find.text('Backup validation failed'), findsOneWidget);
    expect(find.byKey(const ValueKey('confirm-restore-backup')), findsNothing);
  });

  testWidgets('export busy state blocks duplicate submission in the UI', (
    tester,
  ) async {
    final completer = Completer<BackupFileSaveResult>();
    final gateway = _ExportGateway(pending: completer.future);
    exportController = BackupExportController(
      snapshotRepository: SqliteBackupSnapshotRepository(database),
      fileGateway: gateway,
      clock: _FixedClock(DateTime.utc(2026, 9, 4)),
    );
    await tester.pumpWidget(_app(contentController, export: exportController));
    await tester.pumpAndSettle();

    await _confirmExport(tester, settle: false);
    await tester.pump();
    final action = tester.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('export-backup-action')),
    );
    expect(action.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final duplicate = await exportController!.export();
    expect(duplicate.status, BackupExportStatus.duplicate);
    completer.complete(const BackupFileSaveResult.saved());
    await tester.pumpAndSettle();
  });

  testWidgets('import busy state blocks duplicate file selection in the UI', (
    tester,
  ) async {
    final completer = Completer<BackupFileReadResult>();
    final gateway = _ImportGateway(pending: completer.future);
    restoreController = BackupRestoreController(
      restoreRepository: _RecordingRestoreRepository(),
      fileGateway: gateway,
    );
    await tester.pumpWidget(
      _app(contentController, restore: restoreController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-backup-action')));
    await tester.pump();
    final action = tester.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('import-backup-action')),
    );
    expect(action.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final duplicate = await restoreController!.selectAndValidate();
    expect(duplicate.status, BackupRestoreStatus.duplicate);
    completer.complete(const BackupFileReadResult.cancelled());
    await tester.pumpAndSettle();
  });

  testWidgets('restore busy state remains visible while replacement commits', (
    tester,
  ) async {
    final gateway = _ImportGateway(
      result: BackupFileReadResult.selected(utf8.encode(_validJson)),
    );
    restoreController = BackupRestoreController(
      restoreRepository: _RecordingRestoreRepository(),
      fileGateway: gateway,
    );
    await tester.pumpWidget(
      _app(contentController, restore: restoreController),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-backup-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-restore-backup')));
    await tester.pump();

    final action = tester.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('import-backup-action')),
    );
    expect(action.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('database failure shows a retryable non-partial state', (
    tester,
  ) async {
    database.dispose();
    await tester.pumpWidget(_app(contentController));
    await tester.pumpAndSettle();

    expect(find.text('Could not load content'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.textContaining('saved data was not changed'), findsOneWidget);
  });
}

Widget _app(
  ContentListController contentController, {
  BackupExportController? export,
  BackupRestoreController? restore,
}) {
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
      backupExportController: export,
      backupRestoreController: restore,
    ),
  );
}

Future<void> _confirmExport(WidgetTester tester, {bool settle = true}) async {
  if (find.byKey(const ValueKey('settings-action')).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const ValueKey('settings-action')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const ValueKey('export-backup-action')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('confirm-export-backup')));
  if (settle) await tester.pumpAndSettle();
}

class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class _ExportGateway implements BackupFileGateway {
  _ExportGateway({this.pending});

  Future<BackupFileSaveResult>? pending;
  BackupFileSaveResult result = const BackupFileSaveResult.saved();
  Object? error;

  @override
  Future<BackupFileSaveResult> save({
    required String fileName,
    required List<int> bytes,
  }) {
    final pending = this.pending;
    if (pending != null) return pending;
    final error = this.error;
    if (error != null) return Future<BackupFileSaveResult>.error(error);
    return Future.value(result);
  }
}

class _ImportGateway implements BackupRestoreFileGateway {
  _ImportGateway({this.pending, BackupFileReadResult? result})
    : result = result ?? const BackupFileReadResult.cancelled();

  Future<BackupFileReadResult>? pending;
  BackupFileReadResult result = const BackupFileReadResult.cancelled();

  @override
  Future<BackupFileReadResult> pick() => pending ?? Future.value(result);
}

class _RecordingRestoreRepository implements BackupRestoreRepository {
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
  "tags": [],
  "contents": [],
  "content_details": []
}
''';
