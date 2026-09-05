import 'dart:convert';
import 'package:lanjut_nanti/features/backup/application/backup_restore_controller.dart';
import 'package:lanjut_nanti/features/backup/data/backup_restore_repository.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/l10n/app_localizations.dart';
import 'package:lanjut_nanti/core/database/app_database.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/backup/application/backup_export_controller.dart';
import 'package:lanjut_nanti/features/backup/data/backup_snapshot_repository.dart';
import 'package:lanjut_nanti/features/content/presentation/home_screen.dart';

class PendingGateway implements BackupFileGateway {
  final pending = Completer<BackupFileSaveResult>();
  @override
  Future<BackupFileSaveResult> save({
    required String fileName,
    required List<int> bytes,
  }) => pending.future;
}

void main() {
  testWidgets(
    'export outcome uses current locale during and after pending save',
    (tester) async {
      final db = AppDatabase.openInMemory();
      final gateway = PendingGateway();
      final controller = BackupExportController(
        snapshotRepository: SqliteBackupSnapshotRepository(db),
        fileGateway: gateway,
        clock: const SystemClock(),
      );
      addTearDown(controller.dispose);
      addTearDown(db.dispose);
      tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(backupExportController: controller),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('export-backup-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-export-backup')));
      await tester.pump();
      tester.binding.platformDispatcher.localesTestValue = [const Locale('id')];
      await tester.pump();
      gateway.pending.complete(const BackupFileSaveResult.saved());
      await tester.pumpAndSettle();
      expect(find.text('Cadangan berhasil diekspor.'), findsOneWidget);
      tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
      await tester.pumpAndSettle();
      expect(find.text('Backup exported successfully.'), findsOneWidget);
    },
  );
  testWidgets(
    'restore validation translates exact issue paths in an open dialog',
    (tester) async {
      final db = AppDatabase.openInMemory();
      final controller = BackupRestoreController(
        restoreRepository: SqliteBackupRestoreRepository(db),
        fileGateway: InvalidGateway(),
      );
      addTearDown(controller.dispose);
      addTearDown(db.dispose);
      tester.binding.platformDispatcher.localesTestValue = [const Locale('id')];
      addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(backupRestoreController: controller),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('import-backup-action')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('file: Berkas bukan JSON yang valid.'),
        findsOneWidget,
      );
      tester.binding.platformDispatcher.localesTestValue = [const Locale('en')];
      await tester.pumpAndSettle();
      expect(
        find.textContaining('file: The file is not valid JSON.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('restore preview and committed result show localized counts', (
    tester,
  ) async {
    final db = AppDatabase.openInMemory();
    final gateway =
        InvalidGateway()
          ..source =
              '{"schema_version":1,"exported_at":"2026-09-05T00:00:00Z","tags":[],"contents":[],"content_details":[]}';
    final controller = BackupRestoreController(
      restoreRepository: SqliteBackupRestoreRepository(db),
      fileGateway: gateway,
    );
    addTearDown(controller.dispose);
    addTearDown(db.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(backupRestoreController: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-backup-action')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'Cadangan valid ini berisi 0 tag, 0 konten, dan 0 detail.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('confirm-restore-backup')));
    await tester.pumpAndSettle();
    expect(
      find.text('Memulihkan 0 tag, 0 konten, dan 0 detail.'),
      findsOneWidget,
    );
  });
}

class InvalidGateway implements BackupRestoreFileGateway {
  String source = '{bad';
  @override
  Future<BackupFileReadResult> pick() async =>
      BackupFileReadResult.selected(utf8.encode(source));
}
