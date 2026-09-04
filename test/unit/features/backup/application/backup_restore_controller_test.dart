import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lanjut_nanti/features/backup/application/backup_restore_controller.dart';
import 'package:lanjut_nanti/features/backup/data/backup_restore_repository.dart';

void main() {
  test(
    'reports validation errors without calling the replace repository',
    () async {
      final repository = _FakeRestoreRepository();
      final controller = BackupRestoreController(
        restoreRepository: repository,
        fileGateway: _FakeRestoreFileGateway(
          () async => BackupFileReadResult.selected(utf8.encode('{bad')),
        ),
      );
      addTearDown(controller.dispose);

      final result = await controller.selectAndValidate();

      expect(result.status, BackupRestoreStatus.validationError);
      expect(result.message, contains('valid JSON'));
      expect(repository.calls, 0);
      expect(controller.state.preview, isNull);
    },
  );

  test('previews a valid file and replaces only after confirmation', () async {
    final repository = _FakeRestoreRepository();
    final controller = BackupRestoreController(
      restoreRepository: repository,
      fileGateway: _FakeRestoreFileGateway(
        () async => BackupFileReadResult.selected(utf8.encode(_validJson)),
      ),
    );
    addTearDown(controller.dispose);

    final preview = await controller.selectAndValidate();
    expect(preview.status, BackupRestoreStatus.preview);
    expect(preview.tagCount, 1);
    expect(repository.calls, 0);

    final cancelled = await controller.restore();
    expect(cancelled.status, BackupRestoreStatus.cancelled);
    expect(repository.calls, 0);

    final restored = await controller.restore(confirmed: true);
    expect(restored.status, BackupRestoreStatus.success);
    expect(restored.message, contains('1 tag'));
    expect(repository.calls, 1);
    expect(controller.state.status, BackupRestoreStatus.success);
  });

  test('prevents duplicate file selection while the gateway is busy', () async {
    final completer = Completer<BackupFileReadResult>();
    final gateway = _FakeRestoreFileGateway(() => completer.future);
    final controller = BackupRestoreController(
      restoreRepository: _FakeRestoreRepository(),
      fileGateway: gateway,
    );
    addTearDown(controller.dispose);

    final first = controller.selectAndValidate();
    expect(controller.state.status, BackupRestoreStatus.busy);
    final duplicate = await controller.selectAndValidate();
    expect(duplicate.status, BackupRestoreStatus.duplicate);
    expect(gateway.calls, 1);

    completer.complete(BackupFileReadResult.selected(utf8.encode(_validJson)));
    await first;
  });

  test('maps a replacement failure to an unchanged-data error', () async {
    final repository = _FakeRestoreRepository()..error = StateError('disk');
    final controller = BackupRestoreController(
      restoreRepository: repository,
      fileGateway: _FakeRestoreFileGateway(
        () async => BackupFileReadResult.selected(utf8.encode(_validJson)),
      ),
    );
    addTearDown(controller.dispose);

    await controller.selectAndValidate();
    final result = await controller.restore(confirmed: true);

    expect(result.status, BackupRestoreStatus.error);
    expect(result.message, contains('not changed'));
  });

  test(
    'file selection cancellation does not mutate or clear local data',
    () async {
      final repository = _FakeRestoreRepository();
      final controller = BackupRestoreController(
        restoreRepository: repository,
        fileGateway: _FakeRestoreFileGateway(
          () async => const BackupFileReadResult.cancelled(),
        ),
      );
      addTearDown(controller.dispose);

      final result = await controller.selectAndValidate();

      expect(result.status, BackupRestoreStatus.cancelled);
      expect(result.message, contains('not changed'));
      expect(repository.calls, 0);
    },
  );
}

const _validJson = '''
{
  "schema_version": 1,
  "exported_at": "2026-09-04T05:00:00.000Z",
  "tags": [{
    "id": "11111111-1111-4111-8111-111111111111",
    "name": "Manga",
    "created_at": "2026-09-01T05:00:00.000Z",
    "updated_at": "2026-09-01T05:00:00.000Z"
  }],
  "contents": [{
    "id": "22222222-2222-4222-8222-222222222222",
    "name": "Doraemon",
    "tag_id": "11111111-1111-4111-8111-111111111111",
    "created_at": "2026-09-01T05:01:00.000Z",
    "updated_at": "2026-09-01T05:02:00.000Z"
  }],
  "content_details": [{
    "id": "33333333-3333-4333-8333-333333333333",
    "content_id": "22222222-2222-4222-8222-222222222222",
    "link": "https://example.com/chapter-1",
    "note": "Continue here",
    "created_at": "2026-09-01T05:03:00.000Z",
    "updated_at": "2026-09-01T05:04:00.000Z"
  }]
}
''';

class _FakeRestoreRepository implements BackupRestoreRepository {
  int calls = 0;
  Object? error;

  @override
  void replace(BackupRestorePreview preview) {
    calls++;
    if (error != null) throw error!;
  }
}

class _FakeRestoreFileGateway implements BackupRestoreFileGateway {
  _FakeRestoreFileGateway(this.handler);

  final Future<BackupFileReadResult> Function() handler;
  int calls = 0;

  @override
  Future<BackupFileReadResult> pick() {
    calls++;
    return handler();
  }
}
