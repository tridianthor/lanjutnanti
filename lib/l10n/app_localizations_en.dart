// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System default';

  @override
  String get cancel => 'Cancel';

  @override
  String get addContent => 'Add Content';

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try again';

  @override
  String get close => 'Close';

  @override
  String get databaseError => 'Database error';

  @override
  String get noSavedContent => 'No saved content';

  @override
  String get loadContentFailed => 'Could not load content';

  @override
  String get emptyContent => 'No content yet';

  @override
  String get tryAgainMessage => 'Please try again.';

  @override
  String get emptyContentHint => 'Save something you want to continue later.';

  @override
  String get noSearchResults => 'No search results';

  @override
  String get noContentMatches => 'No content matches your search.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get searchContent => 'Search content';

  @override
  String get searchHint => 'Name, tag, or note';

  @override
  String get filterByTag => 'Filter by tag';

  @override
  String get allTags => 'All tags';

  @override
  String get dataUnchanged => 'Saved data was not changed';

  @override
  String get noDetail => 'No detail saved yet';

  @override
  String get openLatestLink => 'Open latest link';

  @override
  String get linkUnavailable => 'Link unavailable';

  @override
  String get openLinkFailed => 'Could not open this link.';

  @override
  String get editContent => 'Edit Content';

  @override
  String get editContentAction => 'Edit content';

  @override
  String get updateContentHint => 'Update your saved content';

  @override
  String get createContentHint => 'What do you want to continue?';

  @override
  String get contentName => 'Content name';

  @override
  String get contentNameHint => 'e.g. Doraemon';

  @override
  String get optionalTag => 'Tag (optional)';

  @override
  String get noTag => 'No tag';

  @override
  String get createTag => 'Create tag';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get saveContent => 'Save Content';

  @override
  String get contentNameRequired => 'Enter a content name.';

  @override
  String get tagName => 'Tag name';

  @override
  String get create => 'Create';

  @override
  String get tagNameRequired => 'Enter a tag name.';

  @override
  String get editDetail => 'Edit Detail';

  @override
  String get addDetail => 'Add Detail';

  @override
  String get editDetailHint => 'Correct this saved continuation point';

  @override
  String get createDetailHint => 'Save where you stopped';

  @override
  String get link => 'Link';

  @override
  String get optionalNote => 'Note (optional)';

  @override
  String get noteHint => 'Add a reminder for next time';

  @override
  String get saveDetail => 'Save Detail';

  @override
  String get validLinkRequired => 'Enter a valid absolute link.';

  @override
  String get contentDetails => 'Content details';

  @override
  String get deleteContent => 'Delete content';

  @override
  String get history => 'History';

  @override
  String get emptyHistory => 'No details saved yet. Add your first continuation link.';

  @override
  String get latest => 'Latest';

  @override
  String get editDetailAction => 'Edit detail';

  @override
  String get deleteDetail => 'Delete detail';

  @override
  String get openLink => 'Open link';

  @override
  String get deleteDetailTitle => 'Delete detail?';

  @override
  String get deleteDetailMessage => 'This saved checkpoint will be removed from history.';

  @override
  String get deleteContentTitle => 'Delete content?';

  @override
  String get deleteContentMessage => 'This removes the content and all of its saved history.';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get exportBackupTitle => 'Export backup?';

  @override
  String get export => 'Export';

  @override
  String get importBackup => 'Import backup';

  @override
  String get replaceLocalData => 'Replace local data?';

  @override
  String get replace => 'Replace';

  @override
  String get backupValidationFailed => 'Backup validation failed';

  @override
  String get languagePreferenceReadFailed => 'Could not read your language preference. Using System default.';

  @override
  String get languagePreferenceSaveFailed => 'Could not save your language preference. Try selecting it again.';

  @override
  String get exportPrivacy => 'This backup may contain private links and notes. The destination you choose controls who can access the file.';

  @override
  String detailCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count details',
      one: '1 detail',
      zero: '0 details',
    );
    return '$_temp0';
  }

  @override
  String updatedAt(String timestamp) {
    return 'Updated $timestamp';
  }

  @override
  String latestAt(String timestamp) {
    return 'Latest · $timestamp';
  }

  @override
  String get tagConflict => 'A tag with that name already exists.';

  @override
  String failureDatabase(String operation) {
    return 'Could not $operation. Your saved data was not changed.';
  }

  @override
  String failureUnknown(String operation) {
    return 'Could not $operation. Please try again.';
  }

  @override
  String failureNotFound(String operation) {
    return '$operation could not be completed because the record no longer exists.';
  }

  @override
  String failureValidation(String operation) {
    return 'Please check the entered values before trying to $operation.';
  }

  @override
  String failureField(String field, String operation) {
    return 'Enter a valid $field to $operation.';
  }

  @override
  String get savedReloadFailed => 'The detail was saved, but its content could not be reloaded.';

  @override
  String get contentNotFound => 'The requested content could not be found.';

  @override
  String get operationLoadContent => 'load content';

  @override
  String get operationLoadContentDetails => 'load content details';

  @override
  String get operationSaveContent => 'save content';

  @override
  String get operationSaveDetail => 'save detail';

  @override
  String get operationDeleteDetail => 'delete detail';

  @override
  String get operationDeleteContent => 'delete content';

  @override
  String get operationSaveChanges => 'save changes';

  @override
  String get operationLoadTags => 'load tags';

  @override
  String get operationSaveTag => 'save tag';

  @override
  String get operationRenameTag => 'rename tag';

  @override
  String get operationDeleteTag => 'delete tag';

  @override
  String get operationExportBackup => 'export backup';

  @override
  String get operationRestoreBackup => 'restore backup';

  @override
  String get exportSuccess => 'Backup exported successfully.';

  @override
  String get exportCancelled => 'Export cancelled. Your saved data was not changed.';

  @override
  String get exportFailed => 'Could not export backup. Please try again.';

  @override
  String get issueInvalidUtf8 => 'The file is not valid UTF-8 JSON.';

  @override
  String get issueInvalidJson => 'The file is not valid JSON.';

  @override
  String get issueRootObject => 'The backup top level must be a JSON object.';

  @override
  String get issueSchemaVersion => 'Only schema version 1 is supported.';

  @override
  String get issueTimestampRequired => 'A timestamp string is required.';

  @override
  String get issueTagNameEmpty => 'The tag name must not be empty.';

  @override
  String get issueOwnershipType => 'Ownership data must be a string or null.';

  @override
  String get issueMissingTag => 'The referenced tag does not exist in this backup.';

  @override
  String get issueContentNameEmpty => 'The content name must not be empty.';

  @override
  String get issueMissingContent => 'The referenced content does not exist in this backup.';

  @override
  String get issueAbsoluteLink => 'The link must be a non-empty absolute URI.';

  @override
  String get issueArrayRequired => 'A JSON array is required.';

  @override
  String get issueObjectRequired => 'A JSON object is required.';

  @override
  String get issueUuidRequired => 'A valid UUID is required.';

  @override
  String get issueStringRequired => 'A string value is required.';

  @override
  String get issueNullableRequired => 'The field is required and may be null.';

  @override
  String get issueNullableString => 'The value must be a string or null.';

  @override
  String get issueInvalidTimestamp => 'The timestamp must be a valid ISO 8601 timestamp.';

  @override
  String issueDuplicateId(String reference) {
    return 'This ID duplicates $reference and must be unique.';
  }

  @override
  String issueDuplicateTag(String reference) {
    return 'Tag names must be unique regardless of letter case (duplicate of $reference).';
  }

  @override
  String validationSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count validation errors.',
      one: '1 validation error.',
    );
    return '$_temp0 Your saved data was not changed.';
  }

  @override
  String additionalIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more issues.',
      one: '1 more issue.',
    );
    return '$_temp0';
  }

  @override
  String restorePreview(int tags, int contents, int details) {
    String _temp0 = intl.Intl.pluralLogic(
      tags,
      locale: localeName,
      other: '$tags tags',
      one: '1 tag',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contents,
      locale: localeName,
      other: '$contents content items',
      one: '1 content item',
    );
    String _temp2 = intl.Intl.pluralLogic(
      details,
      locale: localeName,
      other: '$details details',
      one: '1 detail',
    );
    return 'This valid backup contains $_temp0, $_temp1, and $_temp2. Confirming will replace all current local data.';
  }

  @override
  String restoreSuccess(int tags, int contents, int details) {
    String _temp0 = intl.Intl.pluralLogic(
      tags,
      locale: localeName,
      other: '$tags tags',
      one: '1 tag',
    );
    String _temp1 = intl.Intl.pluralLogic(
      contents,
      locale: localeName,
      other: '$contents content items',
      one: '1 content item',
    );
    String _temp2 = intl.Intl.pluralLogic(
      details,
      locale: localeName,
      other: '$details details',
      one: '1 detail',
    );
    return 'Restored $_temp0, $_temp1, and $_temp2.';
  }

  @override
  String get restoreCancelled => 'Import cancelled. Your saved data was not changed.';

  @override
  String get restoreUnreadable => 'The selected backup could not be read. Your saved data was not changed.';

  @override
  String get restoreMissingPreview => 'Select a valid backup and review its preview before restoring.';

  @override
  String get restoreFailed => 'Could not restore backup. Your saved data was not changed.';

  @override
  String get restoreBusy => 'An import is already in progress.';

  @override
  String get settings => 'Settings';

  @override
  String get backupAndRestore => 'Backup & Restore';

  @override
  String get exportDescription => 'Save tags, content, and details to a portable JSON file.';

  @override
  String get importDescription => 'Restore data from a JSON backup file. This replaces current local data.';

  @override
  String get manageTags => 'Manage tags';

  @override
  String get manageTagsDescription => 'Create, rename, and delete tags for organizing content.';

  @override
  String get emptyTags => 'No tags yet';

  @override
  String get emptyTagsHint => 'Create tags to categorize and filter your saved content.';

  @override
  String get renameTag => 'Rename tag';

  @override
  String get rename => 'Rename';

  @override
  String get deleteTagTitle => 'Delete tag?';

  @override
  String get deleteTagMessage => 'Content assigned to this tag will become untagged.';

  @override
  String get deleteTagAction => 'Delete tag';

  @override
  String get tagDeleted => 'Tag deleted.';

  @override
  String get tagCreated => 'Tag created.';

  @override
  String get tagRenamed => 'Tag renamed.';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themePreferenceReadFailed => 'Could not read theme preference. Using System default.';

  @override
  String get themePreferenceSaveFailed => 'Could not save theme preference.';
}
