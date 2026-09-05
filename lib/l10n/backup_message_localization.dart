import 'package:lanjut_nanti/features/backup/application/backup_restore_controller.dart';
import 'application_failure_localization.dart';
import 'app_localizations.dart';

String localizeBackupIssue(AppLocalizations l, BackupValidationIssue issue) {
  final message = switch (issue.code) {
    BackupIssueCode.invalidUtf8 => l.issueInvalidUtf8,
    BackupIssueCode.invalidJson => l.issueInvalidJson,
    BackupIssueCode.rootObject => l.issueRootObject,
    BackupIssueCode.schemaVersion => l.issueSchemaVersion,
    BackupIssueCode.timestampRequired => l.issueTimestampRequired,
    BackupIssueCode.tagNameEmpty => l.issueTagNameEmpty,
    BackupIssueCode.ownershipType => l.issueOwnershipType,
    BackupIssueCode.missingTag => l.issueMissingTag,
    BackupIssueCode.contentNameEmpty => l.issueContentNameEmpty,
    BackupIssueCode.missingContent => l.issueMissingContent,
    BackupIssueCode.absoluteLink => l.issueAbsoluteLink,
    BackupIssueCode.arrayRequired => l.issueArrayRequired,
    BackupIssueCode.objectRequired => l.issueObjectRequired,
    BackupIssueCode.uuidRequired => l.issueUuidRequired,
    BackupIssueCode.stringRequired => l.issueStringRequired,
    BackupIssueCode.nullableRequired => l.issueNullableRequired,
    BackupIssueCode.nullableString => l.issueNullableString,
    BackupIssueCode.invalidTimestamp => l.issueInvalidTimestamp,
    BackupIssueCode.duplicateId => l.issueDuplicateId(issue.reference!),
    BackupIssueCode.duplicateTag => l.issueDuplicateTag(issue.reference!),
  };
  return '${issue.path}: $message';
}

String localizeBackupIssues(
  AppLocalizations l,
  List<BackupValidationIssue> issues,
) => [
  l.validationSummary(issues.length),
  '',
  ...issues.take(5).map((issue) => localizeBackupIssue(l, issue)),
  if (issues.length > 5) l.additionalIssues(issues.length - 5),
].join('\n');

String localizeRestoreResult(
  AppLocalizations l,
  BackupRestoreResult result,
) => switch (result.status) {
  BackupRestoreStatus.success => l.restoreSuccess(
    result.tagCount,
    result.contentCount,
    result.detailCount,
  ),
  BackupRestoreStatus.cancelled => l.restoreCancelled,
  BackupRestoreStatus.preview => l.restorePreview(
    result.tagCount,
    result.contentCount,
    result.detailCount,
  ),
  BackupRestoreStatus.validationError => localizeBackupIssues(l, result.issues),
  BackupRestoreStatus.busy || BackupRestoreStatus.duplicate => l.restoreBusy,
  _ => switch (result.reason) {
    BackupRestoreFailureReason.unreadable => l.restoreUnreadable,
    BackupRestoreFailureReason.missingPreview => l.restoreMissingPreview,
    _ =>
      result.failure == null
          ? l.restoreFailed
          : localizeFailure(l, result.failure!),
  },
};
