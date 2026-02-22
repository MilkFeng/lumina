import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Lumina'**
  String get appName;

  /// Settings tab label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Import book action
  ///
  /// In en, this message translates to:
  /// **'Import Book'**
  String get importBook;

  /// Delete book confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this book?'**
  String get deleteBookConfirm;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Confirm button label
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Table of contents label
  ///
  /// In en, this message translates to:
  /// **'Table of Contents'**
  String get tableOfContents;

  /// Chapter label
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get chapter;

  /// Page label
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// Progress label
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// WebDAV sync label
  ///
  /// In en, this message translates to:
  /// **'WebDAV Sync'**
  String get webdavSync;

  /// Sync now button label
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// Server URL label
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// Username label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Password label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Last read time label
  ///
  /// In en, this message translates to:
  /// **'Last Read'**
  String get lastRead;

  /// Empty library message
  ///
  /// In en, this message translates to:
  /// **'No books yet'**
  String get noBooks;

  /// Empty library hint
  ///
  /// In en, this message translates to:
  /// **'Add your first book to get started'**
  String get addYourFirstBook;

  /// Sort by label
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// Title sort option
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Recently added sort option
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get recentlyAdded;

  /// Recently read sort option
  ///
  /// In en, this message translates to:
  /// **'Recently Read'**
  String get recentlyRead;

  /// Error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success label
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Failed label
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// Loading label
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Back button label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Next button label
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Previous button label
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// All books tab label
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Uncategorized books tab label
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// Select all button label
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// Deselect all button label
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// Sort button tooltip
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Edit category dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// Category name input label
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// Sort books bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Sort Books by'**
  String get sortBooksBy;

  /// Sort by title ascending
  ///
  /// In en, this message translates to:
  /// **'Title (A-Z)'**
  String get titleAZ;

  /// Sort by title descending
  ///
  /// In en, this message translates to:
  /// **'Title (Z-A)'**
  String get titleZA;

  /// Sort by author ascending
  ///
  /// In en, this message translates to:
  /// **'Author (A-Z)'**
  String get authorAZ;

  /// Sort by author descending
  ///
  /// In en, this message translates to:
  /// **'Author (Z-A)'**
  String get authorZA;

  /// Sort by reading progress
  ///
  /// In en, this message translates to:
  /// **'Reading Progress'**
  String get readingProgress;

  /// Empty category message
  ///
  /// In en, this message translates to:
  /// **'No items in this Category'**
  String get noItemsInCategory;

  /// Selection count label
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selected(int count);

  /// Move button label
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// Deleted badge label
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// Move to dialog title
  ///
  /// In en, this message translates to:
  /// **'Move to ...'**
  String get moveTo;

  /// Create new category option
  ///
  /// In en, this message translates to:
  /// **'Create New Category'**
  String get createNewCategory;

  /// New category dialog title
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get newCategory;

  /// Create button label
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Delete books dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Books'**
  String get deleteBooks;

  /// Delete books confirmation message
  ///
  /// In en, this message translates to:
  /// **'Delete selected books permanently?'**
  String get deleteBooksConfirm;

  /// Successfully moved message
  ///
  /// In en, this message translates to:
  /// **'Moved to \"{name}\"'**
  String movedTo(String name);

  /// Failed to move error message
  ///
  /// In en, this message translates to:
  /// **'Failed to move items'**
  String get failedToMove;

  /// Failed to delete error message
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get failedToDelete;

  /// Invalid file error message
  ///
  /// In en, this message translates to:
  /// **'Invalid file selected'**
  String get invalidFileSelected;

  /// Importing progress message
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importing;

  /// Import completed message
  ///
  /// In en, this message translates to:
  /// **'Import completed'**
  String get importCompleted;

  /// Importing progress details
  ///
  /// In en, this message translates to:
  /// **'{success} success, {failed} failed, {remaining} remaining'**
  String importingProgress(int success, int failed, int remaining);

  /// Successfully imported message
  ///
  /// In en, this message translates to:
  /// **'Successfully imported \"{title}\"'**
  String successfullyImported(String title);

  /// Import failed error message
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// Importing file message
  ///
  /// In en, this message translates to:
  /// **'Importing \"{fileName}\"'**
  String importingFile(String fileName);

  /// Details button label
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Sync completed message
  ///
  /// In en, this message translates to:
  /// **'Sync completed'**
  String get syncCompleted;

  /// Sync failed error message
  ///
  /// In en, this message translates to:
  /// **'Sync failed (long press sync button for settings): {message}'**
  String syncFailed(String message);

  /// Sync error message
  ///
  /// In en, this message translates to:
  /// **'Sync error: {error}'**
  String syncError(String error);

  /// Sync button tooltip
  ///
  /// In en, this message translates to:
  /// **'Tap: Sync Now\nLong press: Settings'**
  String get tapSyncLongPressSettings;

  /// Error loading library message
  ///
  /// In en, this message translates to:
  /// **'Error loading library: {error}'**
  String errorLoadingLibrary(String error);

  /// Book not found error message
  ///
  /// In en, this message translates to:
  /// **'Book not found'**
  String get bookNotFound;

  /// Reading progress percentage
  ///
  /// In en, this message translates to:
  /// **'Progress: {percent}%'**
  String progressPercent(String percent);

  /// Book not started reading status
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get notStarted;

  /// Number of chapters
  ///
  /// In en, this message translates to:
  /// **'{count} chapters'**
  String chaptersCount(int count);

  /// EPUB version label
  ///
  /// In en, this message translates to:
  /// **'EPUB {version}'**
  String epubVersion(String version);

  /// Continue reading button label
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueReading;

  /// Start reading button label
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get startReading;

  /// Collapse button label
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// Expand all button label
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get expandAll;

  /// Book manifest not found error message
  ///
  /// In en, this message translates to:
  /// **'Book manifest not found'**
  String get bookManifestNotFound;

  /// Error loading book message
  ///
  /// In en, this message translates to:
  /// **'Error loading book: {error}'**
  String errorLoadingBook(String error);

  /// First chapter notification
  ///
  /// In en, this message translates to:
  /// **'This is the first chapter of the book'**
  String get firstChapterOfBook;

  /// Last chapter notification
  ///
  /// In en, this message translates to:
  /// **'This is the last chapter of the book'**
  String get lastChapterOfBook;

  /// Last page notification
  ///
  /// In en, this message translates to:
  /// **'This is the last page of the book'**
  String get lastPageOfBook;

  /// First page notification
  ///
  /// In en, this message translates to:
  /// **'This is the first page of the book'**
  String get firstPageOfBook;

  /// Empty chapter notification
  ///
  /// In en, this message translates to:
  /// **'This chapter has no content'**
  String get chapterHasNoContent;

  /// Server settings section title
  ///
  /// In en, this message translates to:
  /// **'Server Settings'**
  String get serverSettings;

  /// Server URL input hint
  ///
  /// In en, this message translates to:
  /// **'https://cloud.example.com/remote.php/dav/files/username/'**
  String get serverUrlHint;

  /// Server URL validation error
  ///
  /// In en, this message translates to:
  /// **'Server URL is required'**
  String get serverUrlRequired;

  /// URL format validation error
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get urlMustStartWith;

  /// Username validation error
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequired;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Remote folder path label
  ///
  /// In en, this message translates to:
  /// **'Remote Folder Path'**
  String get remoteFolderPath;

  /// Remote folder path hint
  ///
  /// In en, this message translates to:
  /// **'LuminaReader/'**
  String get remoteFolderHint;

  /// Folder path validation error
  ///
  /// In en, this message translates to:
  /// **'Folder path is required'**
  String get folderPathRequired;

  /// Testing connection status
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// Test connection button label
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// Sync information section title
  ///
  /// In en, this message translates to:
  /// **'Sync Information'**
  String get syncInformation;

  /// Last sync time label
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get lastSync;

  /// Never synced status
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// Just now time indicator
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Minutes ago time indicator
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// Hours ago time indicator
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// Days ago time indicator
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// Last error label
  ///
  /// In en, this message translates to:
  /// **'Last Error'**
  String get lastError;

  /// Fill all fields validation message
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get fillAllRequiredFields;

  /// Connection test success message
  ///
  /// In en, this message translates to:
  /// **'Connection successful!'**
  String get connectionSuccessful;

  /// Connection test failed message
  ///
  /// In en, this message translates to:
  /// **'Connection failed. Check your settings: {details}'**
  String connectionFailed(String details);

  /// Error message with details
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetails(String error);

  /// Failed to create category message
  ///
  /// In en, this message translates to:
  /// **'Failed to create category!'**
  String get failedToCreateCategory;

  /// Category name empty validation message
  ///
  /// In en, this message translates to:
  /// **'Category name cannot be empty'**
  String get categoryNameCannotBeEmpty;

  /// Category created success message
  ///
  /// In en, this message translates to:
  /// **'Category \"{name}\" created'**
  String categoryCreated(String name);

  /// Category deleted success message
  ///
  /// In en, this message translates to:
  /// **'Category \"{name}\" deleted'**
  String categoryDeleted(String name);

  /// Failed to delete category message
  ///
  /// In en, this message translates to:
  /// **'Failed to delete category!'**
  String get failedToDeleteCategory;

  /// Experimental feature title
  ///
  /// In en, this message translates to:
  /// **'Experimental Feature'**
  String get experimentalFeature;

  /// Experimental feature warning content
  ///
  /// In en, this message translates to:
  /// **'WebDAV sync is currently in experimental stage and may have some issues or instability.\n\nPlease ensure before using:\n• Important data is backed up\n• Understand WebDAV server configuration\n• Network connection is stable\n\nPlease provide feedback if you encounter any issues.'**
  String get experimentalFeatureWarning;

  /// I know button text
  ///
  /// In en, this message translates to:
  /// **'I Know'**
  String get iKnow;

  /// Invalid file type error message
  ///
  /// In en, this message translates to:
  /// **'Invalid file type. Please select an EPUB file.'**
  String get invalidFileType;

  /// File access error message
  ///
  /// In en, this message translates to:
  /// **'Unable to access file'**
  String get fileAccessError;

  /// About page title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Project information section title
  ///
  /// In en, this message translates to:
  /// **'Project Info'**
  String get projectInfo;

  /// GitHub label
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github;

  /// Author label
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// Tips section title
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tips;

  /// Tip for long pressing tab to edit category
  ///
  /// In en, this message translates to:
  /// **'Long press on tab to edit category'**
  String get tipLongPressTab;

  /// Tip for long pressing sync button
  ///
  /// In en, this message translates to:
  /// **'Long press sync button to access sync settings'**
  String get tipLongPressSync;

  /// Tip for long pressing previous/next button
  ///
  /// In en, this message translates to:
  /// **'Long press previous/next button to jump to previous/next chapter'**
  String get tipLongPressNextTrack;

  /// Tip for long pressing image to view original
  ///
  /// In en, this message translates to:
  /// **'Long press on image to view original'**
  String get longPressToViewImage;

  /// Import from folder option label
  ///
  /// In en, this message translates to:
  /// **'Scan Folder'**
  String get importFromFolder;

  /// Import files option label
  ///
  /// In en, this message translates to:
  /// **'Import Files'**
  String get importFiles;

  /// Backup saved success message with path
  ///
  /// In en, this message translates to:
  /// **'Backup successfully saved to Downloads: {path}'**
  String backupSavedToDownloads(String path);

  /// Backup ready for sharing message
  ///
  /// In en, this message translates to:
  /// **'Backup ready for sharing'**
  String get backupReadyToShare;

  /// Backup export failed message
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {message}'**
  String exportFailed(String message);

  /// Importing progress message with file name
  ///
  /// In en, this message translates to:
  /// **'Processing {fileName}'**
  String progressing(String fileName);

  /// All files processed message
  ///
  /// In en, this message translates to:
  /// **'All Processed'**
  String get progressedAll;

  /// Restore from backup option label
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreFromBackup;

  /// Backup library option label
  ///
  /// In en, this message translates to:
  /// **'Backup Library'**
  String get backupLibrary;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
