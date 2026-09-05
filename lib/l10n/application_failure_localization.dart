import 'app_localizations.dart';
import 'package:lanjut_nanti/core/errors/application_failure.dart';

String localizeFailure(AppLocalizations l, ApplicationFailure failure) {
  if (failure.code == FailureCode.savedReloadFailed) return l.savedReloadFailed;
  if (failure.code == FailureCode.contentNotFound) return l.contentNotFound;
  final operation = switch (failure.operation) {
    FailureOperation.loadContent => l.operationLoadContent,
    FailureOperation.loadContentDetails => l.operationLoadContentDetails,
    FailureOperation.saveContent => l.operationSaveContent,
    FailureOperation.saveDetail => l.operationSaveDetail,
    FailureOperation.deleteDetail => l.operationDeleteDetail,
    FailureOperation.deleteContent => l.operationDeleteContent,
    FailureOperation.saveChanges => l.operationSaveChanges,
    FailureOperation.loadTags => l.operationLoadTags,
    FailureOperation.saveTag => l.operationSaveTag,
    FailureOperation.renameTag => l.operationRenameTag,
    FailureOperation.deleteTag => l.operationDeleteTag,
    FailureOperation.exportBackup => l.operationExportBackup,
    FailureOperation.restoreBackup => l.operationRestoreBackup,
  };
  return switch (failure.kind) {
    ApplicationFailureKind.conflict => l.tagConflict,
    ApplicationFailureKind.notFound => l.failureNotFound(operation),
    ApplicationFailureKind.database => l.failureDatabase(operation),
    ApplicationFailureKind.unknown => l.failureUnknown(operation),
    ApplicationFailureKind.validation =>
      failure.field == null
          ? l.failureValidation(operation)
          : l.failureField(switch (failure.field) {
            'name' => l.contentName,
            'link' => l.link,
            'note' => l.optionalNote,
            _ => failure.field!,
          }, operation),
  };
}
