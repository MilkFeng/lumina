// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Lumina';

  @override
  String get settings => 'Settings';

  @override
  String get importBook => 'Import Book';

  @override
  String get deleteBookConfirm => 'Are you sure you want to delete this book?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get tableOfContents => 'Table of Contents';

  @override
  String get chapter => 'Chapter';

  @override
  String get page => 'Page';

  @override
  String get progress => 'Progress';

  @override
  String get webdavSync => 'WebDAV Sync';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get save => 'Save';

  @override
  String get lastRead => 'Last Read';

  @override
  String get noBooks => 'No books yet';

  @override
  String get addYourFirstBook => 'Add your first book to get started';

  @override
  String get sortBy => 'Sort by';

  @override
  String get title => 'Title';

  @override
  String get recentlyAdded => 'Recently Added';

  @override
  String get recentlyRead => 'Recently Read';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get failed => 'Failed';

  @override
  String get loading => 'Loading';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get close => 'Close';

  @override
  String get version => 'Version';

  @override
  String get all => 'All';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get sort => 'Sort';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get categoryName => 'Category name';

  @override
  String get sortBooksBy => 'Sort Books by';

  @override
  String get titleAZ => 'Title (A-Z)';

  @override
  String get titleZA => 'Title (Z-A)';

  @override
  String get authorAZ => 'Author (A-Z)';

  @override
  String get authorZA => 'Author (Z-A)';

  @override
  String get readingProgress => 'Reading Progress';

  @override
  String get noItemsInCategory => 'No items in this Category';

  @override
  String selected(int count) {
    return '$count selected';
  }

  @override
  String get move => 'Move';

  @override
  String get deleted => 'Deleted';

  @override
  String get moveTo => 'Move to ...';

  @override
  String get createNewCategory => 'Create New Category';

  @override
  String get newCategory => 'New Category';

  @override
  String get create => 'Create';

  @override
  String get deleteBooks => 'Delete Books';

  @override
  String get deleteBooksConfirm => 'Delete selected books permanently?';

  @override
  String movedTo(String name) {
    return 'Moved to \"$name\"';
  }

  @override
  String get failedToMove => 'Failed to move items';

  @override
  String get failedToDelete => 'Failed to delete';

  @override
  String get invalidFileSelected => 'Invalid file selected';

  @override
  String get importing => 'Importing...';

  @override
  String get importCompleted => 'Import completed';

  @override
  String importingProgress(int success, int failed, int remaining) {
    return '$success success, $failed failed, $remaining remaining';
  }

  @override
  String successfullyImported(String title) {
    return 'Successfully imported \"$title\"';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String importingFile(String fileName) {
    return 'Importing \"$fileName\"';
  }

  @override
  String get details => 'Details';

  @override
  String get syncCompleted => 'Sync completed';

  @override
  String syncFailed(String message) {
    return 'Sync failed (long press sync button for settings): $message';
  }

  @override
  String syncError(String error) {
    return 'Sync error: $error';
  }

  @override
  String get tapSyncLongPressSettings => 'Tap: Sync Now\nLong press: Settings';

  @override
  String errorLoadingLibrary(String error) {
    return 'Error loading library: $error';
  }

  @override
  String get bookNotFound => 'Book not found';

  @override
  String progressPercent(String percent) {
    return 'Progress: $percent%';
  }

  @override
  String get notStarted => 'Not started';

  @override
  String chaptersCount(int count) {
    return '$count chapters';
  }

  @override
  String epubVersion(String version) {
    return 'EPUB $version';
  }

  @override
  String get continueReading => 'Continue Reading';

  @override
  String get startReading => 'Start Reading';

  @override
  String get collapse => 'Collapse';

  @override
  String get expandAll => 'Expand all';

  @override
  String get bookManifestNotFound => 'Book manifest not found';

  @override
  String errorLoadingBook(String error) {
    return 'Error loading book: $error';
  }

  @override
  String get firstChapterOfBook => 'This is the first chapter of the book';

  @override
  String get lastChapterOfBook => 'This is the last chapter of the book';

  @override
  String get lastPageOfBook => 'This is the last page of the book';

  @override
  String get firstPageOfBook => 'This is the first page of the book';

  @override
  String get chapterHasNoContent => 'This chapter has no content';

  @override
  String get serverSettings => 'Server Settings';

  @override
  String get serverUrlHint =>
      'https://cloud.example.com/remote.php/dav/files/username/';

  @override
  String get serverUrlRequired => 'Server URL is required';

  @override
  String get urlMustStartWith => 'URL must start with http:// or https://';

  @override
  String get usernameRequired => 'Username is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get remoteFolderPath => 'Remote Folder Path';

  @override
  String get remoteFolderHint => 'LuminaReader/';

  @override
  String get folderPathRequired => 'Folder path is required';

  @override
  String get testing => 'Testing...';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get syncInformation => 'Sync Information';

  @override
  String get lastSync => 'Last Sync';

  @override
  String get never => 'Never';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get lastError => 'Last Error';

  @override
  String get fillAllRequiredFields => 'Please fill in all required fields';

  @override
  String get connectionSuccessful => 'Connection successful!';

  @override
  String connectionFailed(String details) {
    return 'Connection failed. Check your settings: $details';
  }

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get failedToCreateCategory => 'Failed to create category!';

  @override
  String get categoryNameCannotBeEmpty => 'Category name cannot be empty';

  @override
  String categoryCreated(String name) {
    return 'Category \"$name\" created';
  }

  @override
  String categoryDeleted(String name) {
    return 'Category \"$name\" deleted';
  }

  @override
  String get failedToDeleteCategory => 'Failed to delete category!';

  @override
  String get experimentalFeature => 'Experimental Feature';

  @override
  String get experimentalFeatureWarning =>
      'WebDAV sync is currently in experimental stage and may have some issues or instability.\n\nPlease ensure before using:\n• Important data is backed up\n• Understand WebDAV server configuration\n• Network connection is stable\n\nPlease provide feedback if you encounter any issues.';

  @override
  String get iKnow => 'I Know';

  @override
  String get invalidFileType =>
      'Invalid file type. Please select an EPUB file.';

  @override
  String get fileAccessError => 'Unable to access file';

  @override
  String get about => 'About';

  @override
  String get storage => 'Storage';

  @override
  String get cleanCache => 'Clean Cache';

  @override
  String get cleanCacheSubtitle => 'Remove unused orphan files from storage';

  @override
  String cleanCacheSuccessWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'files',
      one: 'file',
    );
    return 'Cache cleaned. Removed $count unused $_temp0.';
  }

  @override
  String get cleanCacheSuccess => 'Cache cleaned';

  @override
  String get projectInfo => 'Project Info';

  @override
  String get github => 'GitHub';

  @override
  String get author => 'Author';

  @override
  String get tips => 'Tips';

  @override
  String get tipLongPressTab => 'Long press on tab to edit category';

  @override
  String get tipLongPressSync =>
      'Long press sync button to access sync settings';

  @override
  String get tipLongPressNextTrack =>
      'Long press previous/next button to jump to previous/next chapter';

  @override
  String get longPressToViewImage => 'Long press on image to view original';

  @override
  String get importFromFolder => 'Scan Folder';

  @override
  String get importFiles => 'Import Files';

  @override
  String backupSavedToDownloads(String path) {
    return 'Backup successfully saved to Downloads: $path';
  }

  @override
  String get backupShared => 'Backup successfully shared';

  @override
  String exportFailed(String message) {
    return 'Backup failed: $message';
  }

  @override
  String progressing(String fileName) {
    return 'Processing $fileName';
  }

  @override
  String get progressedAll => 'All Processed';

  @override
  String get restoreFromBackup => 'Restore from Backup';

  @override
  String get backupLibrary => 'Backup Library';

  @override
  String get library => 'Library';

  @override
  String get backupLibraryDescription =>
      'Export your library data as a folder, including book files and database backup';

  @override
  String get restoringBackup => 'Restoring Backup…';

  @override
  String get restoreCompleted => 'Restore Completed';

  @override
  String restoreSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'books',
      one: 'book',
    );
    return 'Successfully restored $count $_temp0.';
  }

  @override
  String restoreFailed(String message) {
    return 'Failed to restore backup: $message';
  }

  @override
  String get restoring => 'Restoring...';

  @override
  String restoringProgress(int success, int failed, int remaining) {
    return '$success success, $failed failed, $remaining remaining';
  }

  @override
  String get viewMode => 'View Mode';

  @override
  String get viewModeCompact => 'Compact';

  @override
  String get viewModeRelaxed => 'Relaxed';

  @override
  String get spliter => ', ';

  @override
  String get shareEpub => 'Share EPUB';

  @override
  String shareEpubFailed(String error) {
    return 'Failed to share EPUB: $error';
  }

  @override
  String get editBook => 'Edit Book';

  @override
  String get authors => 'Authors';

  @override
  String get bookDescription => 'Description';

  @override
  String get bookSaved => 'Book updated';

  @override
  String bookSaveFailed(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get authorsTooltip => 'Separate multiple authors with commas';
}
