
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- 优化性能和用户体验
- 修复设置界面滑动到屏幕外状态丢失的问题
- Android 端的音量键翻页功能
- 修复自定义字体相关 BUG
- 阅读界面常亮屏幕
- 添加检查更新功能
- 添加对脚注中图片的支持
- 主页的书籍标题过长时改为在中间省略
- 图片查看器增加对 SVG 的支持
- 优化书籍的渲染样式
- 优化书籍详情页面的 description 显示

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

### 简体中文

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