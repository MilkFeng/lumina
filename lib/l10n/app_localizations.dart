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
  /// **'Move to'**
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
  /// **'Importing'**
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
  /// **'Testing'**
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

  /// I know button text
  ///
  /// In en, this message translates to:
  /// **'I Know'**
  String get iKnow;

  /// Invalid file type error message
  ///
  /// In en, this message translates to:
  /// **'Invalid file type. Please select an EPUB file'**
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

  /// Storage section title on About page
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// Clean cache button label
  ///
  /// In en, this message translates to:
  /// **'Clean Cache'**
  String get cleanCache;

  /// Clean cache subtitle
  ///
  /// In en, this message translates to:
  /// **'Remove unused orphan files from storage'**
  String get cleanCacheSubtitle;

  /// Clean cache success message
  ///
  /// In en, this message translates to:
  /// **'Cache cleaned. Removed {count} unused {count, plural, =1{file} other{files}}'**
  String cleanCacheSuccessWithCount(int count);

  /// Clean cache success message when no files were removed
  ///
  /// In en, this message translates to:
  /// **'Cache cleaned'**
  String get cleanCacheSuccess;

  /// Appearance section title in about screen
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appAppearance;

  /// Label for the app-wide theme mode selector
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appThemeMode;

  /// Theme mode option: follow system
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appThemeModeSystem;

  /// Theme mode option: always light
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appThemeModeLight;

  /// Theme mode option: always dark
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appThemeModeDark;

  /// Label for the theme variant selector
  ///
  /// In en, this message translates to:
  /// **'Theme Variant'**
  String get appThemeVariant;

  /// Theme variant: standard clean look
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get appThemeVariantStandard;

  /// Theme variant: warm-tinted eye-ease look
  ///
  /// In en, this message translates to:
  /// **'Eye Care'**
  String get appThemeVariantEyeCare;

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

  /// Open source licenses label
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// Open source licenses subtitle
  ///
  /// In en, this message translates to:
  /// **'View open source libraries used in the app and their licenses'**
  String get openSourceLicensesSubtitle;

  /// Check for updates label
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// Check for updates subtitle
  ///
  /// In en, this message translates to:
  /// **'Check if a new version is available'**
  String get checkForUpdatesSubtitle;

  /// Checking for updates progress message
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get checkingForUpdates;

  /// Up to date message
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get upToDate;

  /// New version available message
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get newVersionAvailable;

  /// Update via Lanzou cloud button label
  ///
  /// In en, this message translates to:
  /// **'Download via Lanzou'**
  String get updateViaChinaCloud;

  /// Update via GitHub button label
  ///
  /// In en, this message translates to:
  /// **'Download via GitHub'**
  String get updateViaGithub;

  /// Password copied toast message
  ///
  /// In en, this message translates to:
  /// **'Password copied'**
  String get passwordCopied;

  /// Update check failed message
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates'**
  String get updateCheckFailed;

  /// The name of the current language in English, used to select the matching section in update logs
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameInEnglish;

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

  /// Backup shared success message
  ///
  /// In en, this message translates to:
  /// **'Backup successfully shared'**
  String get backupShared;

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

  /// Restore library feature description
  ///
  /// In en, this message translates to:
  /// **'Replace the current library with the books stored in a backup folder'**
  String get restoreBackupDescription;

  /// Title of the dialog that confirms a destructive restore
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get restoreConfirmTitle;

  /// Warning shown before the current library is cleared by a restore
  ///
  /// In en, this message translates to:
  /// **'Your current library is erased first — every book, cover and reading progress — and then replaced by the backup. This cannot be undone.'**
  String get restoreConfirmMessage;

  /// Name of the backup folder that is about to be restored
  ///
  /// In en, this message translates to:
  /// **'Backup folder: {name}'**
  String restoreConfirmSource(String name);

  /// Confirm button of the destructive restore dialog
  ///
  /// In en, this message translates to:
  /// **'Erase and restore'**
  String get restoreConfirmAction;

  /// Title shown when a restore did not finish successfully
  ///
  /// In en, this message translates to:
  /// **'Restore Failed'**
  String get restoreFailedTitle;

  /// Backup library option label
  ///
  /// In en, this message translates to:
  /// **'Backup Library'**
  String get backupLibrary;

  /// Library section title
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// Backup library feature description
  ///
  /// In en, this message translates to:
  /// **'Export your library data as a folder, including book files and database backup'**
  String get backupLibraryDescription;

  /// Title shown while restore is in progress
  ///
  /// In en, this message translates to:
  /// **'Restoring Backup'**
  String get restoringBackup;

  /// Title shown when restore finishes
  ///
  /// In en, this message translates to:
  /// **'Restore Completed'**
  String get restoreCompleted;

  /// Restore success message with book count
  ///
  /// In en, this message translates to:
  /// **'Successfully restored {count} {count, plural, =1{book} other{books}}'**
  String restoreSuccess(int count);

  /// Restore failure message
  ///
  /// In en, this message translates to:
  /// **'Failed to restore backup: {message}'**
  String restoreFailed(String message);

  /// Restoring progress message
  ///
  /// In en, this message translates to:
  /// **'Restoring'**
  String get restoring;

  /// Restoring progress details
  ///
  /// In en, this message translates to:
  /// **'{success} success, {failed} failed, {remaining} remaining'**
  String restoringProgress(int success, int failed, int remaining);

  /// View mode section title in the style bottom sheet
  ///
  /// In en, this message translates to:
  /// **'View Mode'**
  String get viewMode;

  /// Compact view mode option
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get viewModeCompact;

  /// Relaxed view mode option
  ///
  /// In en, this message translates to:
  /// **'Relaxed'**
  String get viewModeRelaxed;

  /// Spliter used to separate multiple values in a single string
  ///
  /// In en, this message translates to:
  /// **', '**
  String get spliter;

  /// Share EPUB source file action label
  ///
  /// In en, this message translates to:
  /// **'Share EPUB'**
  String get shareEpub;

  /// Error message when sharing EPUB fails
  ///
  /// In en, this message translates to:
  /// **'Failed to share EPUB: {error}'**
  String shareEpubFailed(String error);

  /// Edit book dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit Book'**
  String get editBook;

  /// Authors field label
  ///
  /// In en, this message translates to:
  /// **'Authors'**
  String get authors;

  /// Book description field label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get bookDescription;

  /// Book saved success message
  ///
  /// In en, this message translates to:
  /// **'Book updated'**
  String get bookSaved;

  /// Book save failure message
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String bookSaveFailed(String error);

  /// Tooltip for authors field
  ///
  /// In en, this message translates to:
  /// **'Separate multiple authors with commas'**
  String get authorsTooltip;

  /// Open storage location action label
  ///
  /// In en, this message translates to:
  /// **'Open Storage Location'**
  String get openStorageLocation;

  /// Subtitle for open storage location action
  ///
  /// In en, this message translates to:
  /// **'Open the folder where Lumina stores its data (cache, books, etc.)'**
  String get openStorageLocationSubtitle;

  /// Error message when opening storage location fails
  ///
  /// In en, this message translates to:
  /// **'Failed to open storage location: {error}'**
  String openStorageLocationFailed(String error);

  /// Message shown on iOS when user tries to open storage location, since it's not possible to open it directly
  ///
  /// In en, this message translates to:
  /// **'Please open the \"Lumina\" folder under the \"On My iPhone/iPad\" section in the Files app to access your data'**
  String get openStorageLocationIOSMessage;

  /// Title of the dialog shown when the user tries to leave edit mode with unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChangesTitle;

  /// Body of the dialog shown when the user tries to leave edit mode with unsaved changes
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. What would you like to do?'**
  String get unsavedChangesMessage;

  /// Discard button label — discards unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Validation error shown below the title field when the user tries to save with an empty title
  ///
  /// In en, this message translates to:
  /// **'Title cannot be empty'**
  String get titleRequired;

  /// Reader style sheet section title for typography and layout
  ///
  /// In en, this message translates to:
  /// **'Typography & Layout'**
  String get readerTypographyLayout;

  /// Reader scale / zoom sub-label
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get readerScale;

  /// Reader line height
  ///
  /// In en, this message translates to:
  /// **'Line Height'**
  String get readerLineHeight;

  /// Reader change line height
  ///
  /// In en, this message translates to:
  /// **'Change Line Height'**
  String get readerChangeLineHeight;

  /// Reader margins sub-label
  ///
  /// In en, this message translates to:
  /// **'Margins'**
  String get readerMargins;

  /// Top margin stepper label
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get readerMarginTop;

  /// Bottom margin stepper label
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get readerMarginBottom;

  /// Left margin stepper label
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get readerMarginLeft;

  /// Right margin stepper label
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get readerMarginRight;

  /// Reader style sheet section title for appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get readerAppearance;

  /// Toggle label to make the reader follow the app-wide color scheme
  ///
  /// In en, this message translates to:
  /// **'Follow App Theme'**
  String get readerFollowAppTheme;

  /// Light reader theme chip label
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get readerThemeLight;

  /// Dark reader theme chip label
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get readerThemeDark;

  /// Reader style sheet section title for link handling
  ///
  /// In en, this message translates to:
  /// **'Link Handling'**
  String get readerLinkHandlingSection;

  /// Link handling option: ask before opening
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get readerLinkHandlingAsk;

  /// Link handling option: always open without asking
  ///
  /// In en, this message translates to:
  /// **'Always open'**
  String get readerLinkHandlingAlways;

  /// Link handling option: never open external links
  ///
  /// In en, this message translates to:
  /// **'Never open'**
  String get readerLinkHandlingNever;

  /// Switch label to enable/disable following intra-book (epub://) links
  ///
  /// In en, this message translates to:
  /// **'Follow in-book links'**
  String get readerHandleIntraLink;

  /// Reader style sheet section title for the chapter layout mode
  ///
  /// In en, this message translates to:
  /// **'Reading Layout'**
  String get readerScrollModeSection;

  /// Reader style sheet subsection label grouping the layout options (paged or scrolling)
  ///
  /// In en, this message translates to:
  /// **'Pagination Mode'**
  String get readerPaginationMode;

  /// Reading layout option: discrete pages turned horizontally
  ///
  /// In en, this message translates to:
  /// **'Paged'**
  String get readerScrollModePaginated;

  /// Reading layout option: continuous vertical scrolling
  ///
  /// In en, this message translates to:
  /// **'Scrolling'**
  String get readerScrollModeScrolling;

  /// Explanation shown when the scrolling layout is disabled because the book's page progression is not left-to-right
  ///
  /// In en, this message translates to:
  /// **'Scrolling is unavailable for vertical or right-to-left books'**
  String get readerScrollModeUnsupported;

  /// Reader style sheet subsection label for the page-turning animation, shown only while the layout is paged
  ///
  /// In en, this message translates to:
  /// **'Page Turn'**
  String get readerPageTurn;

  /// Page animation option: no animation
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get readerPageAnimationNone;

  /// Page animation option: the incoming page covers the current one
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get readerPageAnimationCover;

  /// Toggle label to use hardware volume keys for page turning
  ///
  /// In en, this message translates to:
  /// **'Volume Keys Turn Pages'**
  String get readerVolumeKeyTurnsPage;

  /// Reader style sheet subsection label grouping the system status bar options
  ///
  /// In en, this message translates to:
  /// **'Status Bar'**
  String get readerStatusBar;

  /// Switch label to hide the system status bar while reading; the control panel shows it back
  ///
  /// In en, this message translates to:
  /// **'Hide While Reading'**
  String get readerHideStatusBar;

  /// Reader style sheet subsection label for custom font settings
  ///
  /// In en, this message translates to:
  /// **'Custom Font'**
  String get readerFontSection;

  /// Font picker option meaning use the epub's own font
  ///
  /// In en, this message translates to:
  /// **'Book Default'**
  String get readerFontDefault;

  /// Switch label to force the selected custom font over the epub's own font
  ///
  /// In en, this message translates to:
  /// **'Override Book Font'**
  String get readerOverrideFontFamily;

  /// Hint shown in the font picker when no fonts have been imported
  ///
  /// In en, this message translates to:
  /// **'No custom fonts imported yet'**
  String get readerNoCustomFonts;

  /// Button/link label to navigate to the font management screen
  ///
  /// In en, this message translates to:
  /// **'Manage Fonts'**
  String get readerManageFonts;

  /// Tip shown in the reader font subsection directing users to the settings screen
  ///
  /// In en, this message translates to:
  /// **'Manage custom fonts in Settings'**
  String get readerFontManageTip;

  /// Title of the font management screen
  ///
  /// In en, this message translates to:
  /// **'Font Management'**
  String get fontManagement;

  /// Subtitle shown on the font management settings tile
  ///
  /// In en, this message translates to:
  /// **'Custom fonts (.ttf / .otf)'**
  String get fontManagementSubtitle;

  /// Button label to import a font file
  ///
  /// In en, this message translates to:
  /// **'Import Font'**
  String get importFont;

  /// Toast shown after successfully importing a single font
  ///
  /// In en, this message translates to:
  /// **'Font \"{name}\" imported'**
  String importFontSuccess(String name);

  /// Toast shown after importing multiple fonts at once
  ///
  /// In en, this message translates to:
  /// **'{count} fonts imported'**
  String importFontsSuccess(int count);

  /// Toast shown when font import fails
  ///
  /// In en, this message translates to:
  /// **'Failed to import font: {error}'**
  String importFontFailed(String error);

  /// Confirmation dialog title for deleting a font
  ///
  /// In en, this message translates to:
  /// **'Remove font'**
  String get deleteFontConfirm;

  /// Confirmation dialog message for deleting a font
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove the font \"{name}\"? This will not delete the original font file, only remove it from the app.'**
  String deleteFontConfirmText(String name);

  /// Placeholder text shown on the font management screen when no fonts exist
  ///
  /// In en, this message translates to:
  /// **'No custom fonts yet'**
  String get noFontsHint;

  /// Error message shown when the user tries to open a link that cannot be handled by the system
  ///
  /// In en, this message translates to:
  /// **'Cannot open this link: {url}'**
  String cannotOpenLink(String url);

  /// Label for the action to open a link in the system browser
  ///
  /// In en, this message translates to:
  /// **'Open External Link'**
  String get openExternalLink;

  /// Confirmation message shown before opening an external link
  ///
  /// In en, this message translates to:
  /// **'This link will be opened in your browser: {url}\n\nDo you want to proceed?'**
  String openExternalLinkConfirmation(String url);

  /// Open button label for opening external links
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// Error message shown when trying to navigate to a chapter that doesn't exist in the book spine
  ///
  /// In en, this message translates to:
  /// **'Chapter not found in book spine'**
  String get chapterNotFoundInSpine;

  /// Settings section title for the list of external book sources
  ///
  /// In en, this message translates to:
  /// **'External Sources'**
  String get externalSources;

  /// Placeholder shown when no external source has been configured
  ///
  /// In en, this message translates to:
  /// **'No external sources yet'**
  String get noExternalSources;

  /// Settings tile that opens the new external source dialog
  ///
  /// In en, this message translates to:
  /// **'Add external source'**
  String get addExternalSource;

  /// Subtitle of the add external source tile
  ///
  /// In en, this message translates to:
  /// **'Import books from WebDAV and other remote sources'**
  String get addExternalSourceSubtitle;

  /// Default name offered when creating an external source
  ///
  /// In en, this message translates to:
  /// **'External Source {number}'**
  String externalSourceDefaultName(int number);

  /// Label of the external source name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get externalSourceName;

  /// Validation error when the external source name is empty
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get externalSourceNameRequired;

  /// Validation error when the external source name is not unique
  ///
  /// In en, this message translates to:
  /// **'Name already in use'**
  String get externalSourceNameDuplicate;

  /// Validation error for an empty required field of an external source
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get externalSourceRequiredField;

  /// Label of the external source type selector
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get externalSourceType;

  /// Display name of the WebDAV external source type
  ///
  /// In en, this message translates to:
  /// **'WebDAV'**
  String get externalSourceTypeWebdav;

  /// Heading above the type-specific fields of the external source dialog
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get externalSourceConfiguration;

  /// Shown in the external source dialog when its stored configuration cannot be read
  ///
  /// In en, this message translates to:
  /// **'Could not read this source\'s configuration'**
  String get externalSourceConfigurationLoadFailed;

  /// Label of the WebDAV server URL field
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get externalSourceWebdavUrl;

  /// Example value shown in the WebDAV server URL field
  ///
  /// In en, this message translates to:
  /// **'https://dav.example.com'**
  String get externalSourceWebdavUrlHint;

  /// Label of the folder inside the WebDAV server
  ///
  /// In en, this message translates to:
  /// **'Folder (optional)'**
  String get externalSourceWebdavPath;

  /// Example value shown in the WebDAV folder field
  ///
  /// In en, this message translates to:
  /// **'books'**
  String get externalSourceWebdavPathHint;

  /// Label of the external source username field
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get externalSourceUsername;

  /// Label of the external source password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get externalSourcePassword;

  /// Label of the confirm button while the external source connection is being tested
  ///
  /// In en, this message translates to:
  /// **'Testing'**
  String get externalSourceTesting;

  /// Message shown when the external source connection test succeeds
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get externalSourceTestSuccess;

  /// Message shown when the external source connection test fails
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {reason}'**
  String externalSourceTestFailed(String reason);

  /// Message shown after an external source has been added
  ///
  /// In en, this message translates to:
  /// **'Added “{name}”'**
  String externalSourceAdded(String name);

  /// Message shown after an external source has been changed
  ///
  /// In en, this message translates to:
  /// **'Updated “{name}”'**
  String externalSourceUpdated(String name);

  /// Message shown after an external source has been deleted
  ///
  /// In en, this message translates to:
  /// **'Deleted “{name}”'**
  String externalSourceDeleted(String name);

  /// Message shown when deleting an external source fails
  ///
  /// In en, this message translates to:
  /// **'Could not delete the source'**
  String get externalSourceDeleteFailed;

  /// Title of the external source delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete source'**
  String get externalSourceDeleteConfirm;

  /// Body of the external source delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}” and its configuration? Imported books are not affected'**
  String externalSourceDeleteConfirmText(String name);

  /// Action that opens the external source editor
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get externalSourceEdit;

  /// Action that tests an external source connection
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get externalSourceTestConnection;

  /// Connection failure explanation for a rejected login
  ///
  /// In en, this message translates to:
  /// **'the server rejected the username or password'**
  String get externalSourceErrorAuth;

  /// Connection failure explanation for a missing folder
  ///
  /// In en, this message translates to:
  /// **'the folder was not found'**
  String get externalSourceErrorNotFound;

  /// Connection failure explanation for a malformed URL
  ///
  /// In en, this message translates to:
  /// **'the server URL is not a valid http(s) URL'**
  String get externalSourceErrorInvalidUrl;

  /// Connection failure explanation for an unusable response body
  ///
  /// In en, this message translates to:
  /// **'the server did not answer with WebDAV data'**
  String get externalSourceErrorInvalidResponse;

  /// Connection failure explanation for a request timeout
  ///
  /// In en, this message translates to:
  /// **'the server did not respond in time'**
  String get externalSourceErrorTimeout;

  /// Connection failure explanation for a network error
  ///
  /// In en, this message translates to:
  /// **'the server could not be reached'**
  String get externalSourceErrorNetwork;

  /// Connection failure explanation for a certificate error
  ///
  /// In en, this message translates to:
  /// **'the secure connection could not be established'**
  String get externalSourceErrorTls;

  /// Connection failure explanation for an oversized download
  ///
  /// In en, this message translates to:
  /// **'the file is too large to download'**
  String get externalSourceErrorTooLarge;

  /// Connection failure explanation carrying an HTTP status code
  ///
  /// In en, this message translates to:
  /// **'the server answered with error {status}'**
  String externalSourceErrorStatus(int status);

  /// Failure explanation for a name collision
  ///
  /// In en, this message translates to:
  /// **'another source already uses this name'**
  String get externalSourceErrorDuplicateName;

  /// Fallback explanation for an unrecognised failure
  ///
  /// In en, this message translates to:
  /// **'unexpected error'**
  String get externalSourceErrorUnknown;

  /// Home screen menu entry that opens an external source
  ///
  /// In en, this message translates to:
  /// **'Import files from “{name}”'**
  String importFromExternalSource(String name);

  /// Message shown when a source screen is opened for a deleted source
  ///
  /// In en, this message translates to:
  /// **'This external source no longer exists'**
  String get externalSourceNotFound;

  /// Tooltip of the back button while inside a folder of an external source
  ///
  /// In en, this message translates to:
  /// **'Up one folder'**
  String get externalSourceUp;

  /// Message shown when a folder of an external source has no entries
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get externalSourceFolderEmpty;

  /// Row subtitle marking a folder entry
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get externalSourceFolder;

  /// Row subtitle marking an entry that cannot be imported
  ///
  /// In en, this message translates to:
  /// **'Not an EPUB file'**
  String get externalSourceNotImportable;

  /// Message shown when the user tries to import a file that is not an EPUB
  ///
  /// In en, this message translates to:
  /// **'Only EPUB files can be imported'**
  String get externalSourceNotEpub;

  /// How many entries are selected for import
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String externalSourceSelectedCount(int count);

  /// Button that imports the selected books from an external source
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get externalSourceImportSelected;

  /// Tooltip of the button that adds an entry to the import selection
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get externalSourceSelect;

  /// Tooltip of the button that removes an entry from the import selection
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get externalSourceDeselect;

  /// Tooltip of the button that clears the whole import selection
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get externalSourceDeselectAll;

  /// Button that opens the cover picker
  ///
  /// In en, this message translates to:
  /// **'Change cover'**
  String get changeCover;

  /// Error message shown when the cover picker fails to load an image
  ///
  /// In en, this message translates to:
  /// **'Could not load this image. Please choose another image file'**
  String get coverPickFailed;
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
