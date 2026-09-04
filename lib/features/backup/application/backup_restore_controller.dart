import 'package:flutter/foundation.dart';
import 'package:lanjut_nanti/core/errors/application_failure.dart';
import 'package:lanjut_nanti/features/backup/data/backup_file_gateway.dart';
import 'package:lanjut_nanti/features/backup/data/backup_restore_repository.dart';
import 'package:lanjut_nanti/features/backup/domain/backup_restore.dart';

export 'package:lanjut_nanti/features/backup/data/backup_file_gateway.dart';
export 'package:lanjut_nanti/features/backup/domain/backup_restore.dart';

enum BackupRestoreStatus {
  idle,
  busy,
  preview,
  cancelled,
  success,
  validationError,
  error,
  duplicate,
}

class BackupRestoreState {
  const BackupRestoreState({
    this.status = BackupRestoreStatus.idle,
    this.preview,
    this.issues = const [],
    this.message,
    this.tagCount = 0,
    this.contentCount = 0,
    this.detailCount = 0,
  });

  final BackupRestoreStatus status;
  final BackupRestorePreview? preview;
  final List<BackupValidationIssue> issues;
  final String? message;
  final int tagCount;
  final int contentCount;
  final int detailCount;

  bool get isBusy => status == BackupRestoreStatus.busy;
  bool get hasPreview => preview != null;
  bool get hasValidationError => status == BackupRestoreStatus.validationError;
  bool get isSuccess => status == BackupRestoreStatus.success;
  bool get isCancelled => status == BackupRestoreStatus.cancelled;
  bool get hasError => status == BackupRestoreStatus.error;
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.status,
    this.preview,
    this.issues = const [],
    this.message,
    this.tagCount = 0,
    this.contentCount = 0,
    this.detailCount = 0,
  });

  final BackupRestoreStatus status;
  final BackupRestorePreview? preview;
  final List<BackupValidationIssue> issues;
  final String? message;
  final int tagCount;
  final int contentCount;
  final int detailCount;
}

/// Coordinates file selection, pure validation, and confirmed replacement.
class BackupRestoreController extends ChangeNotifier {
  BackupRestoreController({
    required BackupRestoreRepository restoreRepository,
    required BackupRestoreFileGateway fileGateway,
    BackupRestoreValidator validator = const BackupRestoreValidator(),
  }) : _restoreRepository = restoreRepository,
       _fileGateway = fileGateway,
       _validator = validator;

  final BackupRestoreRepository _restoreRepository;
  final BackupRestoreFileGateway _fileGateway;
  final BackupRestoreValidator _validator;
  BackupRestoreState _state = const BackupRestoreState();

  BackupRestoreState get state => _state;

  Future<BackupRestoreResult> selectAndValidate() async {
    if (_state.isBusy) return _duplicateResult();
    _publish(const BackupRestoreState(status: BackupRestoreStatus.busy));
    try {
      final file = await _fileGateway.pick();
      if (file.cancelled) {
        const message = 'Import cancelled. Your saved data was not changed.';
        _publish(
          const BackupRestoreState(
            status: BackupRestoreStatus.cancelled,
            message: message,
          ),
        );
        return const BackupRestoreResult(
          status: BackupRestoreStatus.cancelled,
          message: message,
        );
      }

      final bytes = file.bytes;
      if (bytes == null) {
        return _publishError(
          'The selected backup could not be read. Your saved data was not '
          'changed.',
        );
      }
      return _publishValidation(_validator.validateBytes(bytes));
    } catch (error, stackTrace) {
      final failure = _asRestoreFailure(error, stackTrace);
      return _publishError(failure.message);
    }
  }

  /// Validates supplied bytes without opening a platform file picker.
  BackupRestoreResult validateBytes(List<int> bytes) {
    if (_state.isBusy) return _duplicateResult();
    _publish(const BackupRestoreState(status: BackupRestoreStatus.busy));
    return _publishValidation(_validator.validateBytes(bytes));
  }

  BackupRestoreResult validateJson(String source) {
    if (_state.isBusy) return _duplicateResult();
    _publish(const BackupRestoreState(status: BackupRestoreStatus.busy));
    return _publishValidation(_validator.validateJson(source));
  }

  Future<BackupRestoreResult> restore({bool confirmed = false}) async {
    final preview = _state.preview;
    if (_state.isBusy) return _duplicateResult();
    if (preview == null) {
      return _publishError(
        'Select a valid backup and review its preview before restoring.',
      );
    }
    if (!confirmed) {
      const message = 'Import cancelled. Your saved data was not changed.';
      _publish(
        BackupRestoreState(
          status: BackupRestoreStatus.cancelled,
          preview: preview,
          message: message,
          tagCount: preview.tagCount,
          contentCount: preview.contentCount,
          detailCount: preview.detailCount,
        ),
      );
      return BackupRestoreResult(
        status: BackupRestoreStatus.cancelled,
        preview: preview,
        message: message,
        tagCount: preview.tagCount,
        contentCount: preview.contentCount,
        detailCount: preview.detailCount,
      );
    }

    _publish(
      BackupRestoreState(
        status: BackupRestoreStatus.busy,
        preview: preview,
        tagCount: preview.tagCount,
        contentCount: preview.contentCount,
        detailCount: preview.detailCount,
      ),
    );
    try {
      // Give Flutter a frame to paint the busy state before the synchronous
      // SQLite replacement begins. This keeps repeated submissions blocked
      // and makes progress visible for large local backups.
      await Future<void>.delayed(Duration.zero);
      _restoreRepository.replace(preview);
      final message =
          'Restored ${preview.tagCount} ${_pluralize('tag', preview.tagCount)}, '
          '${preview.contentCount} ${_pluralize('content item', preview.contentCount)}, '
          'and ${preview.detailCount} ${_pluralize('detail', preview.detailCount)}.';
      _publish(
        BackupRestoreState(
          status: BackupRestoreStatus.success,
          preview: preview,
          message: message,
          tagCount: preview.tagCount,
          contentCount: preview.contentCount,
          detailCount: preview.detailCount,
        ),
      );
      return BackupRestoreResult(
        status: BackupRestoreStatus.success,
        preview: preview,
        message: message,
        tagCount: preview.tagCount,
        contentCount: preview.contentCount,
        detailCount: preview.detailCount,
      );
    } catch (error, stackTrace) {
      final failure = _asRestoreFailure(error, stackTrace);
      return _publishError(failure.message, preview: preview);
    }
  }

  Future<BackupRestoreResult> importBackup() => selectAndValidate();

  Future<BackupRestoreResult> importFile() => selectAndValidate();

  Future<BackupRestoreResult> commit({bool confirmed = false}) =>
      restore(confirmed: confirmed);

  BackupRestoreResult _publishValidation(
    BackupRestoreValidationResult validation,
  ) {
    if (validation.isValid) {
      const message =
          'Backup is valid. Review the counts before replacing data.';
      _publish(
        BackupRestoreState(
          status: BackupRestoreStatus.preview,
          preview: validation.preview,
          message: message,
          tagCount: validation.tagCount,
          contentCount: validation.contentCount,
          detailCount: validation.detailCount,
        ),
      );
      return BackupRestoreResult(
        status: BackupRestoreStatus.preview,
        preview: validation.preview,
        message: message,
        tagCount: validation.tagCount,
        contentCount: validation.contentCount,
        detailCount: validation.detailCount,
      );
    }
    _publish(
      BackupRestoreState(
        status: BackupRestoreStatus.validationError,
        issues: validation.issues,
        message: validation.summary,
        tagCount: validation.tagCount,
        contentCount: validation.contentCount,
        detailCount: validation.detailCount,
      ),
    );
    return BackupRestoreResult(
      status: BackupRestoreStatus.validationError,
      issues: validation.issues,
      message: validation.summary,
      tagCount: validation.tagCount,
      contentCount: validation.contentCount,
      detailCount: validation.detailCount,
    );
  }

  BackupRestoreResult _publishError(
    String message, {
    BackupRestorePreview? preview,
  }) {
    _publish(
      BackupRestoreState(
        status: BackupRestoreStatus.error,
        preview: preview,
        message: message,
        tagCount: preview?.tagCount ?? 0,
        contentCount: preview?.contentCount ?? 0,
        detailCount: preview?.detailCount ?? 0,
      ),
    );
    return BackupRestoreResult(
      status: BackupRestoreStatus.error,
      preview: preview,
      message: message,
      tagCount: preview?.tagCount ?? 0,
      contentCount: preview?.contentCount ?? 0,
      detailCount: preview?.detailCount ?? 0,
    );
  }

  BackupRestoreResult _duplicateResult() {
    const message = 'An import is already in progress.';
    return const BackupRestoreResult(
      status: BackupRestoreStatus.duplicate,
      message: message,
    );
  }

  void _publish(BackupRestoreState state) {
    _state = state;
    notifyListeners();
  }
}

String _pluralize(String singular, int count) {
  if (count == 1) return singular;
  return '${singular}s';
}

ApplicationFailure _asRestoreFailure(Object error, StackTrace stackTrace) {
  final failure = mapApplicationFailure(error, operation: 'restore backup');
  return ApplicationFailure(
    kind: failure.kind,
    message: failure.message,
    cause: failure.cause,
    stackTrace: failure.stackTrace ?? stackTrace,
  );
}

typedef BackupImportController = BackupRestoreController;
typedef BackupImportStatus = BackupRestoreStatus;
typedef BackupImportState = BackupRestoreState;
typedef BackupImportResult = BackupRestoreResult;
