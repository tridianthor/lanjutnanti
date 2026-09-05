import 'package:sqlite3/sqlite3.dart';

enum FailureOperation {
  loadContent,
  loadContentDetails,
  saveContent,
  saveDetail,
  deleteDetail,
  deleteContent,
  saveChanges,
  loadTags,
  saveTag,
  renameTag,
  deleteTag,
  exportBackup,
  restoreBackup,
}

enum FailureCode { general, contentNotFound, savedReloadFailed }

enum ApplicationFailureKind {
  validation,
  conflict,
  notFound,
  database,
  unknown,
}

/// A recoverable error that can be shown by an application-facing controller.
class ApplicationFailure implements Exception {
  const ApplicationFailure({
    required this.kind,
    required this.message,
    this.operation = FailureOperation.saveChanges,
    this.code = FailureCode.general,
    this.field,
    this.cause,
    this.stackTrace,
  });

  final ApplicationFailureKind kind;
  final String message;
  final FailureOperation operation;
  final FailureCode code;
  final String? field;
  final Object? cause;
  final StackTrace? stackTrace;

  bool get isValidation => kind == ApplicationFailureKind.validation;
  bool get isConflict => kind == ApplicationFailureKind.conflict;
  bool get isNotFound => kind == ApplicationFailureKind.notFound;
  bool get isDatabase => kind == ApplicationFailureKind.database;

  @override
  String toString() => message;
}

ApplicationFailure mapApplicationFailure(
  Object error, {
  required String operation,
}) {
  if (error is ApplicationFailure) return error;

  if (error is ArgumentError) {
    return ApplicationFailure(
      kind: ApplicationFailureKind.validation,
      message: _validationMessage(error, operation),
      field: error.name,
      operation: _operation(operation),
      cause: error,
    );
  }

  if (error is StateError) {
    final description = error.toString().toLowerCase();
    if (!description.contains('does not exist') &&
        !description.contains('not found') &&
        !description.contains('no longer exists')) {
      return ApplicationFailure(
        kind: ApplicationFailureKind.database,
        message: 'Could not $operation. Your saved data was not changed.',
        operation: _operation(operation),
        cause: error,
      );
    }
    return ApplicationFailure(
      kind: ApplicationFailureKind.notFound,
      message:
          '$operation could not be completed because the record no longer exists.',
      operation: _operation(operation),
      cause: error,
    );
  }

  if (error is SqliteException) {
    final description = error.toString().toLowerCase();
    if ((description.contains('unique constraint') ||
            description.contains('idx_tags_name_nocase')) &&
        operation.contains('tag')) {
      return ApplicationFailure(
        kind: ApplicationFailureKind.conflict,
        message: 'A tag with that name already exists.',
        operation: _operation(operation),
        cause: error,
      );
    }
    return ApplicationFailure(
      kind: ApplicationFailureKind.database,
      message: 'Could not $operation. Your saved data was not changed.',
      operation: _operation(operation),
      cause: error,
    );
  }

  return ApplicationFailure(
    kind: ApplicationFailureKind.unknown,
    message: 'Could not $operation. Please try again.',
    operation: _operation(operation),
    cause: error,
  );
}

String _validationMessage(ArgumentError error, String operation) {
  final field = error.name;
  if (field is String && field.isNotEmpty) {
    return 'Enter a valid $field to $operation.';
  }
  return 'Please check the entered values before trying to $operation.';
}

FailureOperation _operation(String operation) => switch (operation) {
  'load content' => FailureOperation.loadContent,
  'load content details' => FailureOperation.loadContentDetails,
  'save content' => FailureOperation.saveContent,
  'save detail' => FailureOperation.saveDetail,
  'delete detail' => FailureOperation.deleteDetail,
  'delete content' => FailureOperation.deleteContent,
  'save changes' => FailureOperation.saveChanges,
  'load tags' => FailureOperation.loadTags,
  'save tag' => FailureOperation.saveTag,
  'rename tag' => FailureOperation.renameTag,
  'delete tag' => FailureOperation.deleteTag,
  'export backup' => FailureOperation.exportBackup,
  'restore backup' => FailureOperation.restoreBackup,
  _ => FailureOperation.saveChanges,
};
