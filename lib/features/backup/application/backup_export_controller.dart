import 'package:flutter/foundation.dart';
import 'package:lanjut_nanti/core/errors/application_failure.dart';
import 'package:lanjut_nanti/core/time/clock.dart';
import 'package:lanjut_nanti/features/backup/data/backup_file_gateway.dart';
import 'package:lanjut_nanti/features/backup/data/backup_snapshot_repository.dart';
import 'package:lanjut_nanti/features/backup/domain/backup_snapshot.dart';

export 'package:lanjut_nanti/features/backup/data/backup_file_gateway.dart';

enum BackupExportStatus { idle, busy, success, cancelled, error, duplicate }

class BackupExportState {
  const BackupExportState({
    this.status = BackupExportStatus.idle,
    this.message,
    this.destination,
    this.failure,
  });

  final BackupExportStatus status;
  final String? message;
  final String? destination;
  final ApplicationFailure? failure;

  bool get isBusy => status == BackupExportStatus.busy;
  bool get isSuccess => status == BackupExportStatus.success;
  bool get isCancelled => status == BackupExportStatus.cancelled;
  bool get hasError => status == BackupExportStatus.error;
}

class BackupExportResult {
  const BackupExportResult({
    required this.status,
    this.message,
    this.destination,
    this.failure,
  });

  final BackupExportStatus status;
  final String? message;
  final String? destination;
  final ApplicationFailure? failure;
}

/// Coordinates snapshot, serialization, and destination selection for export.
class BackupExportController extends ChangeNotifier {
  BackupExportController({
    required BackupSnapshotRepository snapshotRepository,
    required BackupFileGateway fileGateway,
    required Clock clock,
    VersionedJsonBackupSerializer serializer =
        const VersionedJsonBackupSerializer(),
    this.fileName = defaultFileName,
  }) : _snapshotRepository = snapshotRepository,
       _fileGateway = fileGateway,
       _clock = clock,
       _serializer = serializer;

  static const defaultFileName = 'lanjut-nanti-backup.json';

  final BackupSnapshotRepository _snapshotRepository;
  final BackupFileGateway _fileGateway;
  final Clock _clock;
  final VersionedJsonBackupSerializer _serializer;
  final String fileName;

  BackupExportState _state = const BackupExportState();

  BackupExportState get state => _state;

  Future<BackupExportResult> export() async {
    if (_state.isBusy) {
      return const BackupExportResult(status: BackupExportStatus.duplicate);
    }

    _publish(const BackupExportState(status: BackupExportStatus.busy));
    try {
      final snapshot = _snapshotRepository.readSnapshot();
      final bytes = _serializer.encodeUtf8(snapshot, exportedAt: _clock.now());
      final saveResult = await _fileGateway.save(
        fileName: fileName,
        bytes: bytes,
      );
      if (saveResult.cancelled) {
        const message = 'Export cancelled. Your saved data was not changed.';
        _publish(
          const BackupExportState(
            status: BackupExportStatus.cancelled,
            message: message,
          ),
        );
        return const BackupExportResult(
          status: BackupExportStatus.cancelled,
          message: message,
        );
      }

      const message = 'Backup exported successfully.';
      _publish(
        BackupExportState(
          status: BackupExportStatus.success,
          message: message,
          destination: saveResult.destination,
        ),
      );
      return BackupExportResult(
        status: BackupExportStatus.success,
        message: message,
        destination: saveResult.destination,
      );
    } catch (error, stackTrace) {
      final failure = _asExportFailure(error, stackTrace);
      _publish(
        BackupExportState(
          status: BackupExportStatus.error,
          message: failure.message,
          failure: failure,
        ),
      );
      return BackupExportResult(
        status: BackupExportStatus.error,
        message: failure.message,
        failure: failure,
      );
    }
  }

  Future<BackupExportResult> exportBackup() => export();

  void _publish(BackupExportState state) {
    _state = state;
    notifyListeners();
  }
}

ApplicationFailure _asExportFailure(Object error, StackTrace stackTrace) {
  final failure = mapApplicationFailure(error, operation: 'export backup');
  return ApplicationFailure(
    kind: failure.kind,
    operation: failure.operation,
    code: failure.code,
    field: failure.field,
    message: failure.message,
    cause: failure.cause,
    stackTrace: failure.stackTrace ?? stackTrace,
  );
}
