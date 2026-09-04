import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/app/app.dart';
import 'package:lanjut_nanti/features/backup/application/backup_export_controller.dart';
import 'package:lanjut_nanti/features/backup/application/backup_restore_controller.dart';
import 'package:lanjut_nanti/features/backup/data/backup_file_gateway.dart';

import '../support/database_test_support.dart';
import '../support/phase9_app_support.dart';

void main() {
  late Directory temporaryDirectory;
  late String sourcePath;
  late String destinationPath;
  late MutableClock sourceClock;
  late MutableClock destinationClock;
  late Phase9AppInstance source;
  late Phase9AppInstance destination;
  late _MemoryExportGateway exportGateway;
  late _MemoryImportGateway importGateway;

  setUp(() {
    temporaryDirectory = Directory.systemTemp.createTempSync(
      'lanjut_nanti_phase9_backup_',
    );
    sourcePath =
        '${temporaryDirectory.path}${Platform.pathSeparator}source.sqlite';
    destinationPath =
        '${temporaryDirectory.path}${Platform.pathSeparator}destination.sqlite';
    sourceClock = MutableClock(DateTime.utc(2026, 9, 4, 5));
    destinationClock = MutableClock(DateTime.utc(2026, 9, 4, 5));
    exportGateway = _MemoryExportGateway();
    importGateway = _MemoryImportGateway();
    source = Phase9AppInstance.open(
      databasePath: sourcePath,
      clock: sourceClock,
      idGenerator: SequenceIdGenerator([
        '11111111-1111-4111-8111-111111111111',
        '22222222-2222-4222-8222-222222222222',
        '33333333-3333-4333-8333-333333333333',
        '44444444-4444-4444-8444-444444444444',
      ]),
      exportGateway: exportGateway,
    );
    destination = Phase9AppInstance.open(
      databasePath: destinationPath,
      clock: destinationClock,
      idGenerator: SequenceIdGenerator(['old-content']),
      restoreGateway: importGateway,
    );
    _seedSource(source, sourceClock);
    destination.contentRepository.create(name: 'Old local content');
  });

  tearDown(() {
    source.dispose();
    destination.dispose();
    temporaryDirectory.deleteSync(recursive: true);
  });

  testWidgets(
    'exports then replaces another database and preserves relationships and search',
    (tester) async {
      await tester.pumpWidget(
        LanjutNantiApp(dependencies: source.dependencies),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Export backup'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-export-backup')));
      await tester.pumpAndSettle();
      expect(exportGateway.bytes, isNotNull);
      expect(jsonDecode(utf8.decode(exportGateway.bytes!)), isA<Map>());
      expect(find.text('Backup exported successfully.'), findsOneWidget);

      importGateway.bytes = exportGateway.bytes;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        LanjutNantiApp(dependencies: destination.dependencies),
      );
      await tester.pumpAndSettle();
      expect(find.text('Old local content'), findsOneWidget);

      await tester.tap(find.byTooltip('Import backup'));
      await tester.pumpAndSettle();
      expect(find.text('Replace local data?'), findsOneWidget);
      expect(find.textContaining('2 details'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm-restore-backup')));
      await tester.pumpAndSettle();

      expect(find.text('Old local content'), findsNothing);
      expect(find.text('Doraemon'), findsOneWidget);
      expect(
        find.text('Restored 1 tag, 1 content item, and 2 details.'),
        findsOneWidget,
      );
      expect(destination.tagRepository.list(), hasLength(1));
      expect(destination.contentRepository.listRecent(), hasLength(1));
      expect(
        destination.detailRepository.listForContent(_contentId),
        hasLength(2),
      );
      expect(destination.contentRepository.findById(_contentId)!.tagId, _tagId);

      await tester.enterText(
        find.byKey(const ValueKey('content-search-field')),
        'chapter two',
      );
      await tester.pumpAndSettle();
      expect(find.text('Doraemon'), findsOneWidget);
      expect(find.text('Old local content'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('content-card-$_contentId')));
      await tester.pumpAndSettle();
      expect(find.text('Manga'), findsOneWidget);
      expect(find.text('2 details'), findsOneWidget);
      expect(find.text(_latestLink), findsOneWidget);
      expect(find.text('Continue at chapter two'), findsOneWidget);
      expect(find.text('Latest'), findsOneWidget);
    },
  );
}

const _tagId = '11111111-1111-4111-8111-111111111111';
const _contentId = '22222222-2222-4222-8222-222222222222';
const _latestLink = 'https://example.com/doraemon/chapter-2';

void _seedSource(Phase9AppInstance source, MutableClock sourceClock) {
  final tag = source.tagRepository.create('Manga');
  source.contentRepository.create(name: 'Doraemon', tagId: tag.id);
  source.detailRepository.create(
    contentId: _contentId,
    link: 'https://example.com/doraemon/chapter-1',
    note: 'Continue at chapter one',
  );
  sourceClock.value = DateTime.utc(2026, 9, 5, 5);
  source.detailRepository.create(
    contentId: _contentId,
    link: _latestLink,
    note: 'Continue at chapter two',
  );
}

class _MemoryExportGateway implements BackupFileGateway {
  List<int>? bytes;

  @override
  Future<BackupFileSaveResult> save({
    required String fileName,
    required List<int> bytes,
  }) async {
    this.bytes = List.unmodifiable(bytes);
    return const BackupFileSaveResult.saved(destination: 'memory://backup');
  }
}

class _MemoryImportGateway implements BackupRestoreFileGateway {
  List<int>? bytes;

  @override
  Future<BackupFileReadResult> pick() async {
    final selected = bytes;
    if (selected == null) return const BackupFileReadResult.cancelled();
    return BackupFileReadResult.selected(selected, source: 'memory://backup');
  }
}
