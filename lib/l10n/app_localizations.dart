import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  /// Home language action and dialog title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Follow device languages
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// Application message: cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Application message: addContent
  ///
  /// In en, this message translates to:
  /// **'Add Content'**
  String get addContent;

  /// Application message: retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Application message: tryAgain
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Application message: close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Application message: databaseError
  ///
  /// In en, this message translates to:
  /// **'Database error'**
  String get databaseError;

  /// Application message: noSavedContent
  ///
  /// In en, this message translates to:
  /// **'No saved content'**
  String get noSavedContent;

  /// Application message: loadContentFailed
  ///
  /// In en, this message translates to:
  /// **'Could not load content'**
  String get loadContentFailed;

  /// Application message: emptyContent
  ///
  /// In en, this message translates to:
  /// **'No content yet'**
  String get emptyContent;

  /// Application message: tryAgainMessage
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get tryAgainMessage;

  /// Application message: emptyContentHint
  ///
  /// In en, this message translates to:
  /// **'Save something you want to continue later.'**
  String get emptyContentHint;

  /// Application message: noSearchResults
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get noSearchResults;

  /// Application message: noContentMatches
  ///
  /// In en, this message translates to:
  /// **'No content matches your search.'**
  String get noContentMatches;

  /// Application message: clearSearch
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// Application message: searchContent
  ///
  /// In en, this message translates to:
  /// **'Search content'**
  String get searchContent;

  /// Application message: searchHint
  ///
  /// In en, this message translates to:
  /// **'Name, tag, or note'**
  String get searchHint;

  /// Application message: filterByTag
  ///
  /// In en, this message translates to:
  /// **'Filter by tag'**
  String get filterByTag;

  /// Application message: allTags
  ///
  /// In en, this message translates to:
  /// **'All tags'**
  String get allTags;

  /// Application message: dataUnchanged
  ///
  /// In en, this message translates to:
  /// **'Saved data was not changed'**
  String get dataUnchanged;

  /// Application message: noDetail
  ///
  /// In en, this message translates to:
  /// **'No detail saved yet'**
  String get noDetail;

  /// Application message: openLatestLink
  ///
  /// In en, this message translates to:
  /// **'Open latest link'**
  String get openLatestLink;

  /// Application message: linkUnavailable
  ///
  /// In en, this message translates to:
  /// **'Link unavailable'**
  String get linkUnavailable;

  /// Application message: openLinkFailed
  ///
  /// In en, this message translates to:
  /// **'Could not open this link.'**
  String get openLinkFailed;

  /// Application message: editContent
  ///
  /// In en, this message translates to:
  /// **'Edit Content'**
  String get editContent;

  /// Application message: editContentAction
  ///
  /// In en, this message translates to:
  /// **'Edit content'**
  String get editContentAction;

  /// Application message: updateContentHint
  ///
  /// In en, this message translates to:
  /// **'Update your saved content'**
  String get updateContentHint;

  /// Application message: createContentHint
  ///
  /// In en, this message translates to:
  /// **'What do you want to continue?'**
  String get createContentHint;

  /// Application message: contentName
  ///
  /// In en, this message translates to:
  /// **'Content name'**
  String get contentName;

  /// Application message: contentNameHint
  ///
  /// In en, this message translates to:
  /// **'e.g. Doraemon'**
  String get contentNameHint;

  /// Application message: optionalTag
  ///
  /// In en, this message translates to:
  /// **'Tag (optional)'**
  String get optionalTag;

  /// Application message: noTag
  ///
  /// In en, this message translates to:
  /// **'No tag'**
  String get noTag;

  /// Application message: createTag
  ///
  /// In en, this message translates to:
  /// **'Create tag'**
  String get createTag;

  /// Application message: saveChanges
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Application message: saveContent
  ///
  /// In en, this message translates to:
  /// **'Save Content'**
  String get saveContent;

  /// Application message: contentNameRequired
  ///
  /// In en, this message translates to:
  /// **'Enter a content name.'**
  String get contentNameRequired;

  /// Application message: tagName
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagName;

  /// Application message: create
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Application message: tagNameRequired
  ///
  /// In en, this message translates to:
  /// **'Enter a tag name.'**
  String get tagNameRequired;

  /// Application message: editDetail
  ///
  /// In en, this message translates to:
  /// **'Edit Detail'**
  String get editDetail;

  /// Application message: addDetail
  ///
  /// In en, this message translates to:
  /// **'Add Detail'**
  String get addDetail;

  /// Application message: editDetailHint
  ///
  /// In en, this message translates to:
  /// **'Correct this saved continuation point'**
  String get editDetailHint;

  /// Application message: createDetailHint
  ///
  /// In en, this message translates to:
  /// **'Save where you stopped'**
  String get createDetailHint;

  /// Application message: link
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// Application message: optionalNote
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get optionalNote;

  /// Application message: noteHint
  ///
  /// In en, this message translates to:
  /// **'Add a reminder for next time'**
  String get noteHint;

  /// Application message: saveDetail
  ///
  /// In en, this message translates to:
  /// **'Save Detail'**
  String get saveDetail;

  /// Application message: validLinkRequired
  ///
  /// In en, this message translates to:
  /// **'Enter a valid absolute link.'**
  String get validLinkRequired;

  /// Application message: contentDetails
  ///
  /// In en, this message translates to:
  /// **'Content details'**
  String get contentDetails;

  /// Application message: deleteContent
  ///
  /// In en, this message translates to:
  /// **'Delete content'**
  String get deleteContent;

  /// Application message: history
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Application message: emptyHistory
  ///
  /// In en, this message translates to:
  /// **'No details saved yet. Add your first continuation link.'**
  String get emptyHistory;

  /// Application message: latest
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// Application message: editDetailAction
  ///
  /// In en, this message translates to:
  /// **'Edit detail'**
  String get editDetailAction;

  /// Application message: deleteDetail
  ///
  /// In en, this message translates to:
  /// **'Delete detail'**
  String get deleteDetail;

  /// Application message: openLink
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get openLink;

  /// Application message: deleteDetailTitle
  ///
  /// In en, this message translates to:
  /// **'Delete detail?'**
  String get deleteDetailTitle;

  /// Application message: deleteDetailMessage
  ///
  /// In en, this message translates to:
  /// **'This saved checkpoint will be removed from history.'**
  String get deleteDetailMessage;

  /// Application message: deleteContentTitle
  ///
  /// In en, this message translates to:
  /// **'Delete content?'**
  String get deleteContentTitle;

  /// Application message: deleteContentMessage
  ///
  /// In en, this message translates to:
  /// **'This removes the content and all of its saved history.'**
  String get deleteContentMessage;

  /// Application message: exportBackup
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get exportBackup;

  /// Application message: exportBackupTitle
  ///
  /// In en, this message translates to:
  /// **'Export backup?'**
  String get exportBackupTitle;

  /// Application message: export
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Application message: importBackup
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importBackup;

  /// Application message: replaceLocalData
  ///
  /// In en, this message translates to:
  /// **'Replace local data?'**
  String get replaceLocalData;

  /// Application message: replace
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// Application message: backupValidationFailed
  ///
  /// In en, this message translates to:
  /// **'Backup validation failed'**
  String get backupValidationFailed;

  /// Application message: languagePreferenceReadFailed
  ///
  /// In en, this message translates to:
  /// **'Could not read your language preference. Using System default.'**
  String get languagePreferenceReadFailed;

  /// Application message: languagePreferenceSaveFailed
  ///
  /// In en, this message translates to:
  /// **'Could not save your language preference. Try selecting it again.'**
  String get languagePreferenceSaveFailed;

  /// Application message: exportPrivacy
  ///
  /// In en, this message translates to:
  /// **'This backup may contain private links and notes. The destination you choose controls who can access the file.'**
  String get exportPrivacy;

  /// Application message: detailCount
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 details} one{1 detail} other{{count} details}}'**
  String detailCount(int count);

  /// Application message: updatedAt
  ///
  /// In en, this message translates to:
  /// **'Updated {timestamp}'**
  String updatedAt(String timestamp);

  /// Application message: latestAt
  ///
  /// In en, this message translates to:
  /// **'Latest · {timestamp}'**
  String latestAt(String timestamp);

  /// Application message: tagConflict
  ///
  /// In en, this message translates to:
  /// **'A tag with that name already exists.'**
  String get tagConflict;

  /// Application message: failureDatabase
  ///
  /// In en, this message translates to:
  /// **'Could not {operation}. Your saved data was not changed.'**
  String failureDatabase(String operation);

  /// Application message: failureUnknown
  ///
  /// In en, this message translates to:
  /// **'Could not {operation}. Please try again.'**
  String failureUnknown(String operation);

  /// Application message: failureNotFound
  ///
  /// In en, this message translates to:
  /// **'{operation} could not be completed because the record no longer exists.'**
  String failureNotFound(String operation);

  /// Application message: failureValidation
  ///
  /// In en, this message translates to:
  /// **'Please check the entered values before trying to {operation}.'**
  String failureValidation(String operation);

  /// Application message: failureField
  ///
  /// In en, this message translates to:
  /// **'Enter a valid {field} to {operation}.'**
  String failureField(String field, String operation);

  /// Application message: savedReloadFailed
  ///
  /// In en, this message translates to:
  /// **'The detail was saved, but its content could not be reloaded.'**
  String get savedReloadFailed;

  /// Application message: contentNotFound
  ///
  /// In en, this message translates to:
  /// **'The requested content could not be found.'**
  String get contentNotFound;

  /// Application message: operationLoadContent
  ///
  /// In en, this message translates to:
  /// **'load content'**
  String get operationLoadContent;

  /// Application message: operationLoadContentDetails
  ///
  /// In en, this message translates to:
  /// **'load content details'**
  String get operationLoadContentDetails;

  /// Application message: operationSaveContent
  ///
  /// In en, this message translates to:
  /// **'save content'**
  String get operationSaveContent;

  /// Application message: operationSaveDetail
  ///
  /// In en, this message translates to:
  /// **'save detail'**
  String get operationSaveDetail;

  /// Application message: operationDeleteDetail
  ///
  /// In en, this message translates to:
  /// **'delete detail'**
  String get operationDeleteDetail;

  /// Application message: operationDeleteContent
  ///
  /// In en, this message translates to:
  /// **'delete content'**
  String get operationDeleteContent;

  /// Application message: operationSaveChanges
  ///
  /// In en, this message translates to:
  /// **'save changes'**
  String get operationSaveChanges;

  /// Application message: operationLoadTags
  ///
  /// In en, this message translates to:
  /// **'load tags'**
  String get operationLoadTags;

  /// Application message: operationSaveTag
  ///
  /// In en, this message translates to:
  /// **'save tag'**
  String get operationSaveTag;

  /// Application message: operationRenameTag
  ///
  /// In en, this message translates to:
  /// **'rename tag'**
  String get operationRenameTag;

  /// Application message: operationDeleteTag
  ///
  /// In en, this message translates to:
  /// **'delete tag'**
  String get operationDeleteTag;

  /// Application message: operationExportBackup
  ///
  /// In en, this message translates to:
  /// **'export backup'**
  String get operationExportBackup;

  /// Application message: operationRestoreBackup
  ///
  /// In en, this message translates to:
  /// **'restore backup'**
  String get operationRestoreBackup;

  /// Application message: exportSuccess
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully.'**
  String get exportSuccess;

  /// Application message: exportCancelled
  ///
  /// In en, this message translates to:
  /// **'Export cancelled. Your saved data was not changed.'**
  String get exportCancelled;

  /// Application message: exportFailed
  ///
  /// In en, this message translates to:
  /// **'Could not export backup. Please try again.'**
  String get exportFailed;

  /// Application message: issueInvalidUtf8
  ///
  /// In en, this message translates to:
  /// **'The file is not valid UTF-8 JSON.'**
  String get issueInvalidUtf8;

  /// Application message: issueInvalidJson
  ///
  /// In en, this message translates to:
  /// **'The file is not valid JSON.'**
  String get issueInvalidJson;

  /// Application message: issueRootObject
  ///
  /// In en, this message translates to:
  /// **'The backup top level must be a JSON object.'**
  String get issueRootObject;

  /// Application message: issueSchemaVersion
  ///
  /// In en, this message translates to:
  /// **'Only schema version 1 is supported.'**
  String get issueSchemaVersion;

  /// Application message: issueTimestampRequired
  ///
  /// In en, this message translates to:
  /// **'A timestamp string is required.'**
  String get issueTimestampRequired;

  /// Application message: issueTagNameEmpty
  ///
  /// In en, this message translates to:
  /// **'The tag name must not be empty.'**
  String get issueTagNameEmpty;

  /// Application message: issueOwnershipType
  ///
  /// In en, this message translates to:
  /// **'Ownership data must be a string or null.'**
  String get issueOwnershipType;

  /// Application message: issueMissingTag
  ///
  /// In en, this message translates to:
  /// **'The referenced tag does not exist in this backup.'**
  String get issueMissingTag;

  /// Application message: issueContentNameEmpty
  ///
  /// In en, this message translates to:
  /// **'The content name must not be empty.'**
  String get issueContentNameEmpty;

  /// Application message: issueMissingContent
  ///
  /// In en, this message translates to:
  /// **'The referenced content does not exist in this backup.'**
  String get issueMissingContent;

  /// Application message: issueAbsoluteLink
  ///
  /// In en, this message translates to:
  /// **'The link must be a non-empty absolute URI.'**
  String get issueAbsoluteLink;

  /// Application message: issueArrayRequired
  ///
  /// In en, this message translates to:
  /// **'A JSON array is required.'**
  String get issueArrayRequired;

  /// Application message: issueObjectRequired
  ///
  /// In en, this message translates to:
  /// **'A JSON object is required.'**
  String get issueObjectRequired;

  /// Application message: issueUuidRequired
  ///
  /// In en, this message translates to:
  /// **'A valid UUID is required.'**
  String get issueUuidRequired;

  /// Application message: issueStringRequired
  ///
  /// In en, this message translates to:
  /// **'A string value is required.'**
  String get issueStringRequired;

  /// Application message: issueNullableRequired
  ///
  /// In en, this message translates to:
  /// **'The field is required and may be null.'**
  String get issueNullableRequired;

  /// Application message: issueNullableString
  ///
  /// In en, this message translates to:
  /// **'The value must be a string or null.'**
  String get issueNullableString;

  /// Application message: issueInvalidTimestamp
  ///
  /// In en, this message translates to:
  /// **'The timestamp must be a valid ISO 8601 timestamp.'**
  String get issueInvalidTimestamp;

  /// Application message: issueDuplicateId
  ///
  /// In en, this message translates to:
  /// **'This ID duplicates {reference} and must be unique.'**
  String issueDuplicateId(String reference);

  /// Application message: issueDuplicateTag
  ///
  /// In en, this message translates to:
  /// **'Tag names must be unique regardless of letter case (duplicate of {reference}).'**
  String issueDuplicateTag(String reference);

  /// Application message: validationSummary
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 validation error.} other{{count} validation errors.}} Your saved data was not changed.'**
  String validationSummary(int count);

  /// Application message: additionalIssues
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 more issue.} other{{count} more issues.}}'**
  String additionalIssues(int count);

  /// Application message: restorePreview
  ///
  /// In en, this message translates to:
  /// **'This valid backup contains {tags, plural, one{1 tag} other{{tags} tags}}, {contents, plural, one{1 content item} other{{contents} content items}}, and {details, plural, one{1 detail} other{{details} details}}. Confirming will replace all current local data.'**
  String restorePreview(int tags, int contents, int details);

  /// Application message: restoreSuccess
  ///
  /// In en, this message translates to:
  /// **'Restored {tags, plural, one{1 tag} other{{tags} tags}}, {contents, plural, one{1 content item} other{{contents} content items}}, and {details, plural, one{1 detail} other{{details} details}}.'**
  String restoreSuccess(int tags, int contents, int details);

  /// Application message: restoreCancelled
  ///
  /// In en, this message translates to:
  /// **'Import cancelled. Your saved data was not changed.'**
  String get restoreCancelled;

  /// Application message: restoreUnreadable
  ///
  /// In en, this message translates to:
  /// **'The selected backup could not be read. Your saved data was not changed.'**
  String get restoreUnreadable;

  /// Application message: restoreMissingPreview
  ///
  /// In en, this message translates to:
  /// **'Select a valid backup and review its preview before restoring.'**
  String get restoreMissingPreview;

  /// Application message: restoreFailed
  ///
  /// In en, this message translates to:
  /// **'Could not restore backup. Your saved data was not changed.'**
  String get restoreFailed;

  /// Application message: restoreBusy
  ///
  /// In en, this message translates to:
  /// **'An import is already in progress.'**
  String get restoreBusy;

  /// Settings screen title and action tooltip
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Backup and restore section title in settings
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backupAndRestore;

  /// Description of export backup action in settings
  ///
  /// In en, this message translates to:
  /// **'Save tags, content, and details to a portable JSON file.'**
  String get exportDescription;

  /// Description of import backup action in settings
  ///
  /// In en, this message translates to:
  /// **'Restore data from a JSON backup file. This replaces current local data.'**
  String get importDescription;

  /// Manage tags screen title and settings tile
  ///
  /// In en, this message translates to:
  /// **'Manage tags'**
  String get manageTags;

  /// Description of manage tags action in settings
  ///
  /// In en, this message translates to:
  /// **'Create, rename, and delete tags for organizing content.'**
  String get manageTagsDescription;

  /// Title when no tags exist in tag management
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get emptyTags;

  /// Hint when no tags exist in tag management
  ///
  /// In en, this message translates to:
  /// **'Create tags to categorize and filter your saved content.'**
  String get emptyTagsHint;

  /// Action to rename an existing tag
  ///
  /// In en, this message translates to:
  /// **'Rename tag'**
  String get renameTag;

  /// Confirm button label in rename tag dialog
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Title of delete tag confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete tag?'**
  String get deleteTagTitle;

  /// Confirmation message when deleting a tag
  ///
  /// In en, this message translates to:
  /// **'Content assigned to this tag will become untagged.'**
  String get deleteTagMessage;

  /// Tooltip and action label for deleting a tag
  ///
  /// In en, this message translates to:
  /// **'Delete tag'**
  String get deleteTagAction;

  /// Feedback after tag deletion
  ///
  /// In en, this message translates to:
  /// **'Tag deleted.'**
  String get tagDeleted;

  /// Feedback after tag creation
  ///
  /// In en, this message translates to:
  /// **'Tag created.'**
  String get tagCreated;

  /// Feedback after tag rename
  ///
  /// In en, this message translates to:
  /// **'Tag renamed.'**
  String get tagRenamed;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'id': return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
