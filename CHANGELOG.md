
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### English

#### Added

- **Continuous Scrolling**: The reader has a second layout, chosen under Reading Layout in the style sheet: instead of discrete pages, a chapter becomes one continuously scrolling column that follows the finger and keeps its momentum after a fling, like a web page. Scrolling stops at the chapter's own boundaries — the bottom bar's arrows move between chapters — and the status bar shows how far through the chapter you are as a percentage. Volume keys move by roughly one screen. Right-to-left and vertical-writing books always paginate, and the option is shown disabled with an explanation for them.
- **External Sources (WebDAV)**: Add a WebDAV server in Settings and browse its folders from the library to import EPUBs. The password is kept in the platform keychain, never in the library database.
- **Download Progress**: An import from an external source shows how far the file being downloaded has come.
- **Cover Editing**: A book's cover can be replaced from the detail screen — tap the cover while editing and pick an image from the device. The chosen image is converted with the same JPEG settings as imported covers, previewed while you edit, and only written to the library when you save; leaving edit mode drops it. If saving fails, the previous cover is restored and the draft is kept so the edit can be retried.

#### Changed

- **Restore Entry Point**: "Restore from Backup" moved from the library floating action menu to Settings → Library, next to "Backup Library".
- **Restore Behaviour**: Restoring now clears the current library (books, groups, reading progress and their files) and then applies the backup, instead of merging the backup book by book. The restored library is therefore an exact copy of the backup, with no risk of record conflicts.
- Restoring asks for confirmation before deleting anything and can no longer be interrupted halfway through.
- **Backup Format Version**: Backup packages are written with format version 2, and a restore now refuses a package that declares no version at all or a version newer than the app supports — the current library is left untouched in that case.
- **Library Reload**: Sorting, filtering, entering a group, refreshing and restoring now reload the shelf in place instead of dropping it to its loading state, so the grid no longer tears down and flashes a spinner while the books are re-read. A background reload that fails keeps the books already on screen instead of replacing them with an error, and a finished import no longer reloads the shelf a second time.
- **Library Sort & View Menu**: The sort and view options moved out of a bottom sheet into a menu hanging off the app bar's tune icon. The choice in effect is checked, and pressing the icon and dragging onto an entry chooses it without lifting the finger. A press off the panel only closes the menu — it is not passed on to the book, tab or shelf underneath.
- **Library Add Button**: The floating add button no longer flickers between "+" and "×" as the dial opens — the same glyph now rotates into the cross and grows a little on the way, so the cross reads at the size of the plus it replaced.
- **Library Selection**: Clearing the selection now leaves selection mode with it, instead of staying in selection mode with nothing selected.
- **Book Detail Editing**: Discarding edits after a back gesture now returns to the book's view mode, the same as the close button, instead of leaving the screen as well.
- **External Source Editor**: The editor is wider — it fills the width the screen has to give instead of a fixed phone-sized box — and the saved configuration is now read before the dialog opens, so a keychain that refuses to open is reported with a message rather than leaving the editor on its spinner.
- **Reader Table of Contents**: Tapping a chapter always jumps to it, including one that holds sections; expanding and collapsing moved to the chevron on its left.
- **External Sources**: A saved source keeps a single delete button, and long pressing the row tests the connection. The button turns into a progress spinner while the test runs.

#### Fixed

- **Font Import Naming**: Imported fonts no longer collapse into a single entry named "unknown". Font file names are now resolved by the platform (`getDisplayNames`) instead of being guessed from the picker's opaque handle, path separators and URL-breaking characters are stripped, and a font whose name cannot be resolved gets a unique generated name rather than a shared placeholder.
- **Backup Export**: A book's cover is now exported under the file name its record points at, so a cover that does not follow the `{hash}.{ext}` naming convention is no longer left out of the backup.

### Chinese

#### 新增

- **连续滚动阅读**：阅读器新增一种版式，可在样式面板的“阅读版式”中选择：章节不再切分为独立页面，而是渲染成一整列连续内容，像网页一样跟手拖动、松手后保留惯性滑动。滚动到章节首尾即停止——章节切换仍使用底部工具栏的左右箭头——状态栏右下角改为显示当前章节的阅读百分比。音量键每次滚动约一屏。从右到左和竖排书籍仍强制分页，该选项对这类书籍显示为禁用并附说明。
- **外部来源（WebDAV）**：可在设置中添加 WebDAV 服务器，并在书库中浏览其目录、导入 EPUB。密码保存在系统钥匙串，不写入书库数据库。
- **下载进度**：从外部来源导入时会显示当前文件的下载进度。
- **封面更换**：可在书籍详情页更换封面——编辑状态下点击封面，从设备中选择图片。所选图片按与导入封面相同的 JPEG 参数转换，编辑期间仅作为草稿预览，保存时才写入书库，退出编辑即丢弃。若保存失败，会恢复原封面并保留草稿，以便重试。

#### 变更与优化

- **恢复入口**：将“从备份恢复”从书库悬浮菜单移到设置 → 书库，与“备份书库”放在一起。
- **恢复行为**：恢复时会先清空当前书库（书籍、分组、阅读进度及对应文件），再应用备份中的书库，不再逐本合并导入，因此恢复结果与备份完全一致，也不会再出现记录冲突。
- 恢复前会先弹出确认提示，且恢复过程中无法中断。
- **备份格式版本**：备份包统一写入格式版本 2；恢复时若备份包未声明版本、或版本高于当前应用支持的版本，会在清空本地书库之前直接报错拒绝恢复。
- **书库刷新**：排序、按分组筛选、进入分组、刷新与恢复备份改为就地重新读取书库，不再先切回加载状态，因此书架不会整屏重建、也不会闪过加载圈；后台刷新失败时会保留屏幕上已有的书籍，而不是替换成错误页；导入结束后也不再重复刷新一次书库。
- **书库排序与视图菜单**：排序与视图选项由底部弹层改为挂在应用栏“调节”图标上的菜单，当前生效的选项带勾选标记，按住图标拖到某一项即可一次选定，无需抬手；点击菜单面板以外的区域只会关闭菜单，不会连带触发下层的书籍、标签页或书架。
- **书库添加按钮**：悬浮添加按钮展开时不再在“+”与“×”之间闪烁，改为同一个图标旋转成叉，并在旋转过程中略微放大，让叉看起来与加号一样大。
- **书库多选**：清除选择后会一并退出多选模式，不再停留在没有任何选中项的多选状态。
- **书籍详情编辑**：使用返回手势放弃编辑后，会回到详情查看状态（与关闭按钮一致），不再直接退出该页面。
- **外部来源编辑弹窗**：弹窗加宽，占满屏幕可用宽度，不再是固定手机尺寸的窄框；已保存的配置改为在弹窗打开前读取，钥匙串读取失败时会给出提示，而不是让弹窗卡在加载圈上。
- **阅读器目录**：点击章节任意位置都会直接跳转，含子章节的条目同样如此；展开与折叠改为点击条目左侧的箭头。
- **外部来源**：每条来源只保留一个删除按钮，长按整行可测试连接；测试期间该按钮变为进度圈。

#### 修复

- **字体导入命名**：导入字体不再全部显示为 “unknown” 且互相覆盖。字体文件名改由平台查询得到（`getDisplayNames`），不再从 picker 返回的不透明句柄里猜测；文件名会剔除路径分隔符与破坏 URL 的字符，实在取不到名字时使用唯一的生成名，而不是共用的占位名。
- **备份导出**：导出封面时优先使用书籍记录中保存的文件名，文件名不符合 `{hash}.{ext}` 约定的封面不再被漏掉。

## [v0.2.4] - 2026-09-19

### English

#### Added

- Add support for line height adjustment

#### Fixed

- Fixed footnote rendering issues to improve display accuracy and stability
- Upgraded the Flutter version for better compatibility
- Improved application performance and overall responsiveness

### Chinese

#### 新增

- 添加行高调整支持

#### 变更与优化

- 修复脚注渲染异常，提升内容显示的准确性与稳定性
- 升级 Flutter 版本，改善项目兼容性
- 优化应用性能，提升整体运行流畅度

## [v0.2.3] - 2026-03-13

### English

#### Added

* **Volume Key Paging**: Added support for turning pages using volume keys on Android devices.
* **Keep Awake**: Added a feature to keep the screen awake while on the reading interface.
* **Check for Updates**: Added a built-in check for updates feature.
* **Footnote Images**: Added support for displaying images embedded within footnotes.
* **SVG Viewer**: Added SVG format support to the image viewer.
* **Duokan Support**: Added broader support for Duokan platform-specific formatting features.

#### Changed

* **Performance & UX**: Optimized overall rendering performance and reading user experience.
* **Title Truncation**: Long book titles on the home page now truncate in the middle for better visual balance.
* **Rendering Styles**: Polished and optimized internal book rendering styles.
* **Book Details**: Optimized the text display for the description section on the book details page.

#### Fixed

* **Settings State**: Fixed an issue where UI state was lost when items in the settings interface were scrolled off-screen.
* **Custom Fonts**: Fixed various bugs related to the application of custom fonts.

### Chinese

#### 新增

* **音量键翻页**：新增 Android 端的音量键翻页功能。
* **屏幕常亮**：阅读界面新增保持屏幕常亮特性。
* **检查更新**：应用内新增检查更新功能。
* **脚注图片**：新增对书籍脚注中内嵌图片的支持。
* **SVG 支持**：图片查看器新增对 SVG 格式图片的支持。
* **多看特性**：添加了更多对多看平台特有排版特性的兼容支持。

#### 变更与优化

* **性能与体验**：全面优化了底层渲染性能与整体用户体验。
* **标题省略**：主页的书籍标题过长时，现已改为在中间省略，提升视觉平衡。
* **渲染优化**：优化了书籍的排版与渲染样式。
* **详情页优化**：优化了书籍详情页面的简介文本显示效果。

#### 修复

* **状态防丢**：修复了设置界面中组件滑动到屏幕外后导致状态丢失的问题。
* **字体修复**：修复了自定义字体相关的若干 BUG。

## [v0.2.2] - 2026-03-04

### English

#### Added

* **Font Selection**: Added font selection support.
* **Status Bar**: Added a bottom status bar to display the current chapter title and reading progress.
* **Animation Toggle**: Added a toggle switch for page-turning animations.

#### Changed

* **UI Consistency**: Improved the visual consistency of theme color blocks between the settings interface and the reader's dropdown menu.
* **Book Compatibility**: Improved compatibility with custom page colors defined within books.
* **Footnote Support**: Enhanced parsing and support for various footnote formats.
* **Performance & Animations**: Added transition animations and optimized the rendering performance of the bookshelf.
* **Bottom Sheet Interactions**: Made the 'A' icons next to the zoom slider in the bottom sheet clickable for easier text size adjustment.
* **Optimized page-turning experience**

#### Fixed

* **Import Dialog**: Fixed a bug related to the import dialog not functioning correctly.
* **Home Page UI**: Fixed a UI issue where a blank white bar appeared at the bottom of the home page.
* **Link Interactions**: Fixed issues related to clicking internal and external links within the reader.

### Chinese

#### 新增

* **字体选择**：新增字体选择功能。
* **底部状态栏**：阅读器底部新增状态栏，可实时显示当前标题与阅读进度。
* **动画开关**：新增翻页动画的开启与关闭选项。

#### 变更与优化

* **界面一致性**：统一了设置界面和阅读器下拉菜单中主题方块的视觉样式。
* **兼容性提升**：更好地兼容了书籍自带的自定义页面颜色。
* **脚注支持**：增加对更多书籍脚注格式的兼容与支持。
* **性能与动效**：增加部分过渡动画，并优化了书架列表的显示性能。
* **交互优化**：Bottom Sheet 中缩放调节滑块两端的“A”图标现在支持直接点击调节。
* **优化翻页体验**

#### 修复

* **导入修复**：修复了书籍导入 Dialog 相关的 BUG。
* **界面修复**：去除了主页底部异常显示的白条。
* **链接修复**：修复了阅读器内链接点击的相关问题。


## [v0.2.1] - 2026-03-01

### English
#### Added
- Launched a new global theme system with independent light/dark mode switching.
- Added 6 new reading theme presets.
- New Settings Center (replacing "About") with centralized configs and licenses.
- Added support for Duokan-style footnotes.

#### Changed
- Redesigned library UI: optimized checkbox styles and selection colors.
- Improved UI consistency: updated dialogs, drawers, and toast colors across all themes.
- Enhanced EPUB parsing: improved cover detection and NAV/NCX path resolution.
- Optimized theme panel interactions.

#### Fixed
- Fixed font-size and line-height application issues in certain books.
- Improved tap accuracy for links in the reader.

### Chinese

#### 新增
- 上线全新全局主题系统，支持独立的明暗模式切换
- 新增 6 款阅读主题预设
- 新增设置中心（替代原“关于”页面），集成配置项及开源协议说明
- 新增对多看平台脚注格式的支持

#### 变更与优化
- 书架界面视觉重构：优化多选模式下的复选框样式与选中颜色表现；重构顶部与底部导航栏，并添加过渡动画
- 全面提升 UI 一致性：优化应用内弹窗、下拉抽屉、提示条、按钮边框及阴影色彩，确保在所有主题下的视觉协调性
- EPUB 解析逻辑升级：大幅提升书籍封面解析成功率及目录相对路径识别准确率
- 交互细节优化：优化主题面板的交互体验

#### 修复
- 修复部分书籍中字体大小和行高无法被正确应用的问题
- 提升正文阅读中链接点击的精确度