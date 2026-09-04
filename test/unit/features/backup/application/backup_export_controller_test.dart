import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/backup/application/backup_export_controller.dart';
import 'package:lanjut_nanti/features/backup/data/backup_snapshot_repository.dart';
import 'package:lanjut_nanti/features/backup/domain/backup_snapshot.dart';

void main() {
  final snapshot = BackupSnapshot(
    tags: const [],
    contents: const [],
    contentDetails: const [],
  );

  test(
    'publishes busy state and prevents duplicate export submission',
    () async {
      final saveCompleter = Completer<BackupFileSaveResult>();
      final gateway = _FakeBackupFileGateway(() => saveCompleter.future);
      final controller = BackupExportController(
        snapshotRepository: _FakeSnapshotRepository(snapshot),
        fileGateway: gateway,
        clock: _FixedClock(DateTime.utc(2026, 9, 4)),
      );
      addTearDown(controller.dispose);

      final first = controller.export();
      expect(controller.state.status, BackupExportStatus.busy);
      final duplicate = await controller.export();

      expect(duplicate.status, BackupExportStatus.duplicate);
      expect(gateway.calls, 1);

      saveCompleter.complete(const BackupFileSaveResult.saved());
      final result = await first;

      expect(result.status, BackupExportStatus.success);
      expect(controller.state.status, BackupExportStatus.success);
    },
  );

  test('reports cancellation without changing local data', () async {
    final gateway = _FakeBackupFileGateway(
      () async => const BackupFileSaveResult.cancelled(),
    );
    final repository = _FakeSnapshotRepository(snapshot);
    final controller = BackupExportController(
      snapshotRepository: repository,
      fileGateway: gateway,
      clock: _FixedClock(DateTime.utc(2026, 9, 4)),
    );
    addTearDown(controller.dispose);

    final result = await controller.export();

    expect(result.status, BackupExportStatus.cancelled);
    expect(controller.state.message, contains('not changed'));
    expect(repository.reads, 1);
  });

  test('reports destination failures as non-destructive errors', () async {
    final gateway = _FakeBackupFileGateway(
      () => Future<BackupFileSaveResult>.error(StateError('disk full')),
    );
    final controller = BackupExportController(
      snapshotRepository: _FakeSnapshotRepository(snapshot),
      fileGateway: gateway,
      clock: _FixedClock(DateTime.utc(2026, 9, 4)),
    );
    addTearDown(controller.dispose);

    final result = await controller.export();

    expect(result.status, BackupExportStatus.error);
    expect(controller.state.status, BackupExportStatus.error);
    expect(controller.state.message, contains('not changed'));
  });

  test(
    'passes valid UTF-8 JSON and the suggested file name to the gateway',
    () async {
      final gateway = _FakeBackupFileGateway(
        () async =>
            const BackupFileSaveResult.saved(destination: 'backup.json'),
      );
      final controller = BackupExportController(
        snapshotRepository: _FakeSnapshotRepository(snapshot),
        fileGateway: gateway,
        clock: _FixedClock(DateTime.utc(2026, 9, 4)),
        fileName: 'backup.json',
      );
      addTearDown(controller.dispose);

      await controller.export();

      expect(gateway.fileName, 'backup.json');
      expect(
        jsonDecode(utf8.decode(gateway.bytes!)),
        isA<Map<String, dynamic>>(),
      );
    },
  );
}

class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class _FakeSnapshotRepository implements BackupSnapshotRepository {
  _FakeSnapshotRepository(this.snapshot);

  final BackupSnapshot snapshot;
  int reads = 0;

  @override
  BackupSnapshot readSnapshot() {
    reads++;
    return snapshot;
  }
}

class _FakeBackupFileGateway implements BackupFileGateway {
  _FakeBackupFileGateway(this.handler);

  final Future<BackupFileSaveResult> Function() handler;
  int calls = 0;
  String? fileName;
  List<int>? bytes;

  @override
  Future<BackupFileSaveResult> save({
    required String fileName,
    required List<int> bytes,
  }) {
    calls++;
    this.fileName = fileName;
    this.bytes = bytes;
    return handler();
  }
}
