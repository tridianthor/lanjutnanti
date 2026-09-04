import 'package:sqlite3/sqlite3.dart';

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
    this.cause,
    this.stackTrace,
  });

  final ApplicationFailureKind kind;
  final String message;
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
        cause: error,
      );
    }
    return ApplicationFailure(
      kind: ApplicationFailureKind.notFound,
      message:
          '$operation could not be completed because the record no longer exists.',
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
        cause: error,
      );
    }
    return ApplicationFailure(
      kind: ApplicationFailureKind.database,
      message: 'Could not $operation. Your saved data was not changed.',
      cause: error,
    );
  }

  return ApplicationFailure(
    kind: ApplicationFailureKind.unknown,
    message: 'Could not $operation. Please try again.',
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
