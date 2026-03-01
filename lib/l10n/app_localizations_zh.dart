// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Lumina';

  @override
  String get settings => '设置';

  @override
  String get importBook => '导入书籍';

  @override
  String get deleteBookConfirm => '确定要删除这本书吗？';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get confirm => '确认';

  @override
  String get tableOfContents => '目录';

  @override
  String get chapter => '章节';

  @override
  String get page => '页面';

  @override
  String get progress => '进度';

  @override
  String get webdavSync => 'WebDAV 同步';

  @override
  String get syncNow => '立即同步';

  @override
  String get serverUrl => '服务器地址';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get save => '保存';

  @override
  String get lastRead => '最后阅读';

  @override
  String get noBooks => '还没有书籍';

  @override
  String get addYourFirstBook => '添加您的第一本书开始阅读';

  @override
  String get sortBy => '排序方式';

  @override
  String get title => '标题';

  @override
  String get recentlyAdded => '最近添加';

  @override
  String get recentlyRead => '最近阅读';

  @override
  String get error => '错误';

  @override
  String get success => '成功';

  @override
  String get failed => '失败';

  @override
  String get loading => '加载中';

  @override
  String get retry => '重试';

  @override
  String get back => '返回';

  @override
  String get next => '下一页';

  @override
  String get previous => '上一页';

  @override
  String get close => '关闭';

  @override
  String get version => '版本';

  @override
  String get all => '全部';

  @override
  String get uncategorized => '未分类';

  @override
  String get selectAll => '全选';

  @override
  String get deselectAll => '取消全选';

  @override
  String get sort => '排序';

  @override
  String get editCategory => '编辑分类';

  @override
  String get categoryName => '分类名称';

  @override
  String get sortBooksBy => '排序方式';

  @override
  String get titleAZ => '标题 (A-Z)';

  @override
  String get titleZA => '标题 (Z-A)';

  @override
  String get authorAZ => '作者 (A-Z)';

  @override
  String get authorZA => '作者 (Z-A)';

  @override
  String get readingProgress => '阅读进度';

  @override
  String get noItemsInCategory => '此分类中没有项目';

  @override
  String selected(int count) {
    return '已选择 $count 项';
  }

  @override
  String get move => '移动';

  @override
  String get deleted => '已删除';

  @override
  String get moveTo => '移动到';

  @override
  String get createNewCategory => '创建新分类';

  @override
  String get newCategory => '新分类';

  @override
  String get create => '创建';

  @override
  String get deleteBooks => '删除书籍';

  @override
  String get deleteBooksConfirm => '永久删除所选书籍？';

  @override
  String movedTo(String name) {
    return '已移动到“$name”';
  }

  @override
  String get failedToMove => '移动失败';

  @override
  String get failedToDelete => '删除失败';

  @override
  String get invalidFileSelected => '选择的文件无效';

  @override
  String get importing => '导入中';

  @override
  String get importCompleted => '导入完成';

  @override
  String importingProgress(int success, int failed, int remaining) {
    return '$success 成功，$failed 失败，$remaining 剩余';
  }

  @override
  String successfullyImported(String title) {
    return '成功导入“$title”';
  }

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String importingFile(String fileName) {
    return '正在导入“$fileName”';
  }

  @override
  String get details => '详情';

  @override
  String get syncCompleted => '同步完成';

  @override
  String syncFailed(String message) {
    return '同步失败（长按同步按钮进入设置）：$message';
  }

  @override
  String syncError(String error) {
    return '同步错误：$error';
  }

  @override
  String get tapSyncLongPressSettings => '点击：立即同步\n长按：设置';

  @override
  String errorLoadingLibrary(String error) {
    return '加载书库时出错：$error';
  }

  @override
  String get bookNotFound => '未找到图书';

  @override
  String progressPercent(String percent) {
    return '进度：$percent%';
  }

  @override
  String get notStarted => '未开始';

  @override
  String chaptersCount(int count) {
    return '$count 章节';
  }

  @override
  String epubVersion(String version) {
    return 'EPUB $version';
  }

  @override
  String get continueReading => '继续阅读';

  @override
  String get startReading => '开始阅读';

  @override
  String get collapse => '收起';

  @override
  String get expandAll => '展开全部';

  @override
  String get bookManifestNotFound => '未找到图书清单';

  @override
  String errorLoadingBook(String error) {
    return '加载图书时出错：$error';
  }

  @override
  String get firstChapterOfBook => '这是本书的第一章';

  @override
  String get lastChapterOfBook => '这是本书的最后一章';

  @override
  String get lastPageOfBook => '这是本书的最后一页';

  @override
  String get firstPageOfBook => '这是本书的第一页';

  @override
  String get chapterHasNoContent => '本章节没有内容';

  @override
  String get serverSettings => '服务器设置';

  @override
  String get serverUrlHint =>
      'https://cloud.example.com/remote.php/dav/files/username/';

  @override
  String get serverUrlRequired => '服务器 URL 为必填项';

  @override
  String get urlMustStartWith => 'URL 必须以 http:// 或 https:// 开头';

  @override
  String get usernameRequired => '用户名为必填项';

  @override
  String get passwordRequired => '密码为必填项';

  @override
  String get remoteFolderPath => '远程文件夹路径';

  @override
  String get remoteFolderHint => 'LuminaReader/';

  @override
  String get folderPathRequired => '文件夹路径为必填项';

  @override
  String get testing => '测试中...';

  @override
  String get testConnection => '测试连接';

  @override
  String get syncInformation => '同步信息';

  @override
  String get lastSync => '最后同步';

  @override
  String get never => '从未';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours小时前';
  }

  @override
  String daysAgo(int days) {
    return '$days天前';
  }

  @override
  String get lastError => '最后错误';

  @override
  String get fillAllRequiredFields => '请填写所有必填字段';

  @override
  String get connectionSuccessful => '连接成功！';

  @override
  String connectionFailed(String details) {
    return '连接失败，请检查您的设置：$details';
  }

  @override
  String errorWithDetails(String error) {
    return '错误：$error';
  }

  @override
  String get failedToCreateCategory => '创建分类失败！';

  @override
  String get categoryNameCannotBeEmpty => '分类名称不能为空';

  @override
  String categoryCreated(String name) {
    return '分类“$name”已创建';
  }

  @override
  String categoryDeleted(String name) {
    return '分类“$name”已删除';
  }

  @override
  String get failedToDeleteCategory => '删除分类失败！';

  @override
  String get experimentalFeature => '实验性功能';

  @override
  String get experimentalFeatureWarning =>
      'WebDAV同步功能目前处于实验阶段，可能存在一些问题或不稳定的情况。\n\n使用前请确保：\n• 已备份重要数据\n• 了解WebDAV服务器的配置\n• 网络连接稳定\n\n如遇到问题，请及时反馈。';

  @override
  String get iKnow => '我知道了';

  @override
  String get invalidFileType => '无效的文件类型，请选择一个 EPUB 文件';

  @override
  String get fileAccessError => '无法访问文件';

  @override
  String get about => '关于';

  @override
  String get storage => '存储';

  @override
  String get cleanCache => '清理缓存';

  @override
  String get cleanCacheSubtitle => '删除存储中无用的孤立文件';

  @override
  String cleanCacheSuccessWithCount(int count) {
    return '清理完成，已删除 $count 个无用文件';
  }

  @override
  String get cleanCacheSuccess => '清理完成';

  @override
  String get appAppearance => '外观';

  @override
  String get appThemeMode => '主题';

  @override
  String get appThemeModeSystem => '跟随系统';

  @override
  String get appThemeModeLight => '浅色';

  @override
  String get appThemeModeDark => '深色';

  @override
  String get appThemeVariant => '主题方案';

  @override
  String get appThemeVariantStandard => '标准';

  @override
  String get appThemeVariantEyeCare => '护眼';

  @override
  String get projectInfo => '项目信息';

  @override
  String get github => 'GitHub';

  @override
  String get author => '作者';

  @override
  String get openSourceLicenses => '开源许可证';

  @override
  String get openSourceLicensesSubtitle => '显示应用中使用的开源库及其许可证';

  @override
  String get tips => '使用提示';

  @override
  String get tipLongPressTab => '长按标签页可编辑分组';

  @override
  String get tipLongPressSync => '长按同步按钮进入同步设置';

  @override
  String get tipLongPressNextTrack => '长按上/下一页按钮跳到上/下一章节';

  @override
  String get longPressToViewImage => '长按图片查看原图';

  @override
  String get importFromFolder => '扫描文件夹';

  @override
  String get importFiles => '导入文件';

  @override
  String backupSavedToDownloads(String path) {
    return '备份已成功保存到下载文件夹：$path';
  }

  @override
  String get backupShared => '备份已通过分享功能导出';

  @override
  String exportFailed(String message) {
    return '备份失败：$message';
  }

  @override
  String progressing(String fileName) {
    return '正在处理：$fileName';
  }

  @override
  String get progressedAll => '全部处理完成';

  @override
  String get restoreFromBackup => '从备份恢复';

  @override
  String get backupLibrary => '备份书库';

  @override
  String get library => '书库';

  @override
  String get backupLibraryDescription => '将书库数据导出为一个文件夹，包括书籍文件和数据库备份';

  @override
  String get restoringBackup => '正在恢复备份';

  @override
  String get restoreCompleted => '恢复完成';

  @override
  String restoreSuccess(int count) {
    return '已成功恢复 $count 本书';
  }

  @override
  String restoreFailed(String message) {
    return '备份恢复失败：$message';
  }

  @override
  String get restoring => '正在恢复';

  @override
  String restoringProgress(int success, int failed, int remaining) {
    return '$success 成功，$failed 失败，$remaining 剩余';
  }

  @override
  String get viewMode => '显示模式';

  @override
  String get viewModeCompact => '紧凑';

  @override
  String get viewModeRelaxed => '宽松';

  @override
  String get spliter => '，';

  @override
  String get shareEpub => '分享 EPUB';

  @override
  String shareEpubFailed(String error) {
    return '分享 EPUB 失败：$error';
  }

  @override
  String get editBook => '编辑书籍';

  @override
  String get authors => '作者';

  @override
  String get bookDescription => '简介';

  @override
  String get bookSaved => '书籍已更新';

  @override
  String bookSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String get authorsTooltip => '多个作者请使用英文半角逗号分隔';

  @override
  String get openStorageLocation => '打开存储位置';

  @override
  String get openStorageLocationSubtitle => '在文件管理器中打开 Lumina 的存储目录';

  @override
  String openStorageLocationFailed(String error) {
    return '无法打开存储位置：$error';
  }

  @override
  String get openStorageLocationIOSMessage =>
      '请在文件应用中打开“我的 iPhone/iPad”下的“Lumina”文件夹来访问存储位置';

  @override
  String get unsavedChangesTitle => '未保存的修改';

  @override
  String get unsavedChangesMessage => '您有未保存的修改，请选择操作。';

  @override
  String get discard => '放弃修改';

  @override
  String get titleRequired => '标题不能为空';

  @override
  String get readerTypographyLayout => '字体与排版';

  @override
  String get readerScale => '缩放';

  @override
  String get readerMargins => '边距';

  @override
  String get readerMarginTop => '上';

  @override
  String get readerMarginBottom => '下';

  @override
  String get readerMarginLeft => '左';

  @override
  String get readerMarginRight => '右';

  @override
  String get readerAppearance => '外观与主题';

  @override
  String get readerFollowAppTheme => '跟随应用主题';

  @override
  String get readerThemeLight => '浅色';

  @override
  String get readerThemeDark => '深色';

  @override
  String get readerLinkHandlingSection => '链接处理';

  @override
  String get readerLinkHandlingAsk => '打开前询问';

  @override
  String get readerLinkHandlingAlways => '总是打开';

  @override
  String get readerLinkHandlingNever => '从不打开';

  @override
  String get readerHandleIntraLink => '跟随书内链接';

  @override
  String cannotOpenLink(String url) {
    return '无法打开链接：$url';
  }

  @override
  String get openExternalLink => '打开外部链接';

  @override
  String openExternalLinkConfirmation(String url) {
    return '您正在尝试打开一个外部链接：$url\n\n是否继续？';
  }

  @override
  String get open => '打开';
}
