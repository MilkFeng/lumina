# web_assets 架构与接口说明

本文档总结 `web_assets` 目录的 Web 端功能、运行架构、对 Flutter 暴露的 JS 接口，以及 Web 端回调 Flutter 的事件接口。

## 目录职责

`web_assets` 是阅读器 WebView 内部使用的前端资源源码。它不直接作为静态文件发版，而是通过 `tool/build_web_assets.dart` 打包压缩到 `lib/src/web/web_assets.dart`，再由 Flutter 侧生成 WebView skeleton HTML 时内联使用。

主要文件：

| 路径 | 职责 |
| --- | --- |
| `web_assets/skeleton.css` | 外层 WebView skeleton 样式：全屏、隐藏滚动、三 iframe 覆盖布局。 |
| `web_assets/pagination.css/main.css` | iframe 内 EPUB 内容的分页、滚动、媒体约束和基础阅读样式。 |
| `web_assets/pagination.css/_font.css` | 自定义字体和多看字体族映射。 |
| `web_assets/pagination.css/_color.css` | 主题色覆盖规则。 |
| `web_assets/pagination.css/_footnote.css` | 隐藏脚注正文，并标记可点击脚注引用。 |
| `web_assets/pagination.css/_duokan_typ.css` | 目前为空，占位给多看排版 CSS。 |
| `web_assets/controller.js/index.ts` | JS 入口，创建 `Renderer` 并挂到 `window.api`。 |
| `web_assets/controller.js/api/lumina_api.ts` | Web 端对 Flutter 暴露的 `window.api` TypeScript 接口。 |
| `web_assets/controller.js/api/flutter_bridge.ts` | Web 端回调 Flutter handler 的封装。 |
| `web_assets/controller.js/renderer/*` | 渲染、分页、主题、交互命中、CSS polyfill、资源等待等核心逻辑。 |
| `web_assets/controller.js/typ/*` | 多看和 rendition 固定版式适配。 |
| `web_assets/controller.js/common/*` | 公共类型、颜色解析、四叉树命中索引。 |

## 运行模型

Flutter 侧在 `lib/src/features/reader/data/reader_scripts.dart` 中生成 skeleton HTML：

1. 内联 `kSkeletonCss` 到 `<style id="skeleton-style">`。
2. 内联 `kControllerJs` 到 `<script id="skeleton-script">`。
3. 构造 `initialConfig`，包含视口尺寸、方向、padding、主题和 `kPaginationCss`。
4. `DOMContentLoaded` 后执行 `window.api.init(initialConfig)`。
5. body 内创建三个 sandbox iframe：
   - `frame-prev`
   - `frame-curr`
   - `frame-next`

Web 端入口在 `web_assets/controller.js/index.ts`：

```ts
const api: LuminaApi = new Renderer();
window.api = api;
```

因此，Flutter 通过 `evaluateJavascript` 调用 `window.api.*`，Web 端通过 `window.flutter_inappwebview.callHandler(...)` 回调 Flutter。

## 核心功能

### 三帧章节渲染

阅读器始终维护 `prev/curr/next` 三个 iframe。当前页显示 `frame-curr`，相邻章节预加载在 `frame-prev` 和 `frame-next`。

翻章时 `FrameManager.cycleFramesDOMAndState(direction)` 不重新创建 iframe，而是交换 iframe 的 `id`、`zIndex`、`opacity`，并同步旋转每个 slot 对应的 anchors 与 spine properties。这减少了 WebView DOM 重建成本。

### 分页与滚动

分页逻辑在 `PaginationManager` 中：

- `direction === 1` 表示竖排/纵向滚动，用 `scrollHeight` 和 `safeHeight` 计算页数。
- 其他 direction 使用横向 CSS columns，用 `scrollWidth` 和 `safeWidth` 计算页数。
- 页间距固定为 `128px`，页数和滚动偏移都把这个 gap 计入公式。
- 当前页 iframe 会向 Flutter 上报总页数、当前页码和当前锚点。

`pagination.css/main.css` 负责实际分页布局：

- `body { column-width: var(--lumina-safe-width); column-gap: 128px; }`
- 根据方向设置 `overflow-x` / `overflow-y`。
- 隐藏滚动条、禁用选择、禁用 WebView 内原生点击高亮。
- 限制图片、SVG、视频不越过安全阅读区域。

### 主题与字体

`ThemeManager` 负责维护 CSS 变量和主题类：

- 视口与安全区域：`--lumina-safe-width`、`--lumina-safe-height`、`--lumina-padding-top`、`--lumina-padding-left`
- 缩放：`--lumina-zoom`
- 颜色：surface、onSurface、primary、container、outline 等
- 字体：有 `fontFileName` 时注入 `@font-face`，字体 URL 为 `epub://localhost/fonts/{fontFileName}`

页面会按配置切换以下 class：

- `lumina-override-color`
- `lumina-override-font`
- `lumina-force-override-font`
- `lumina-is-vertical`
- `lumina-spine-property-{property}`

当 EPUB 内容本身有 body 背景色或背景图时，Web 端会避免强制覆盖文本颜色；如果有背景图，还会给 body 补白色背景以保证可读性。

### CSS 兼容处理

`CssPolyfillManager` 在 iframe 内容加载后遍历可访问的 stylesheet rules：

- 将固定 `font-size` / `line-height` 的 `px`、`pt` 值包成 `calc(original * var(--lumina-zoom))`。
- 在允许主题覆盖时，把背景色改写为 `var(--lumina-surface-container-color, original)` 一类的 fallback。
- 把 `break-before` / `page-break-before` / `break-after` / `page-break-after` 映射到 WebKit column break 属性。

跨域或不可访问 stylesheet 会被捕获并跳过。

### 固定版式与特殊排版

`typ` 模块处理部分 spine property：

- `duokan-page-fullscreen`
- `duokan-page-fitwindow`
- `rendition-COLON-page-spread-center`
- `page-spread-center`

命中这些属性时，Web 端会移除页面 padding、margin 和 column 布局，将图片或 SVG 设成全屏居中 `contain`。如果祖先元素存在 90 度旋转，会保留旋转并修正居中尺寸。

### 交互命中

WebView iframe 本身设置 `pointer-events: none`，手势由 Flutter 捕获，再把坐标转给 Web 端 API。

`InteractionManager` 负责：

- 扫描当前 iframe 的脚注引用，构建四叉树命中索引。
- 点击时优先检查脚注，其次检查普通链接，最后回退为普通 tap。
- 长按时检查图片或 SVG image，并上报图片 URL 与矩形。

脚注支持的来源包括：

- `img[zy-footnote]`
- `.duokan-footnote` 图片或链接
- `a[title]` 且无有效 href
- `a[epub:type="noteref"]`
- `span.notes` / `.notes`
- `id` 或 `name` 指向的 footnote/endnote 容器

脚注命中优先级：

| 优先级 | 类型 |
| --- | --- |
| 3 | 标准链接脚注 |
| 2 | 图片脚注 |
| 1 | 青空文库 notes |

## `window.api` 暴露接口

类型定义位于 `web_assets/controller.js/api/lumina_api.ts`。Flutter 侧的 Dart 镜像在 `lib/src/web/api/lumina_api.dart`。

### `init(config: InitConfig): void`

初始化 Web 端状态：

- 保存 `safeWidth`、`safeHeight`、`direction`、`padding`、`theme`、`paginationCss`。
- 向 skeleton document 写入 CSS 变量。
- 注册 window resize 监听，尺寸变化后 120ms debounce 上报 `onViewportResize`。

### `loadFrame(token, slot, url, anchors?, properties?): void`

把 URL 加载到指定 iframe slot。

参数：

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `token` | `number` | 异步完成 token，完成后回调 `onEventFinished(token)`。 |
| `slot` | `'prev' \| 'curr' \| 'next'` | 目标 iframe。 |
| `url` | `string` | iframe 要加载的章节或资源 URL。 |
| `anchors` | `string[]?` | 用于滚动位置追踪的元素 id 列表，`top` 有特殊含义。 |
| `properties` | `string[]?` | spine properties，会转成 `lumina-spine-property-*` class。 |

加载完成后会：

1. 注入主题 CSS 变量和分页 CSS。
2. 等待图片和字体资源，单图最长 3 秒，整体最长 5 秒。
3. 应用主题 class、方向 class、spine property class。
4. 应用特殊排版适配。
5. 执行 CSS polyfill。
6. 计算页数和 hash anchor 对应页码。
7. 重建交互四叉树。
8. 若是 `curr`，上报 `onPageCountReady(pageCount)` 和 `onPageChanged(pageIndex)`。
9. 若是 `prev`，跳到该 frame 最后一页；若是 `next`，跳到第一页。
10. 上报 active anchors 和 `onEventFinished(token)`。

### `jumpToPage(token, pageIndex): void`

跳转当前 iframe 到指定 0-based 页码。

完成后依次上报：

- `onPageChanged(pageIndex)`
- `onScrollAnchors(anchors)`，如果当前 frame 配置了 anchors
- `onEventFinished(token)`

### `jumpToPageFor(token, slot, pageIndex): void`

跳转指定 iframe slot 到指定页码。只有目标 iframe 当前 id 是 `frame-curr` 时才上报 `onPageChanged(pageIndex)`。总会尝试检测 active anchors 并完成 token。

### `jumpToLastPageOfFrame(token, slot): void`

计算指定 iframe 的页数，并跳到 `pageCount - 1`。内部复用 `jumpToPageFor`。

### `restoreScrollPosition(token, ratio): void`

根据当前 iframe 的总页数和 `ratio` 恢复阅读位置：

```ts
pageIndex = Math.round(ratio * pageCount)
```

之后复用 `jumpToPage`。

### `cycleFrames(token, direction): void`

翻到上一章或下一章。

参数：

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `direction` | `'next' \| 'prev'` | `next` 让 next frame 成为 curr；`prev` 让 prev frame 成为 curr。 |

完成后会更新三个 frame 的页状态、重建当前 frame 的交互索引，并上报 `onEventFinished(token)`。

### `updateTheme(token, viewWidth, viewHeight, newTheme): void`

更新阅读区域尺寸、padding、主题和字体。

行为：

- 更新 skeleton document 的 CSS 变量。
- 对每个已加载 iframe 更新 CSS 变量。
- 按当前页百分比重新分页和恢复位置。
- 重建交互索引。
- 当前 frame 重新上报页数和页码。
- 完成后回调 `onEventFinished(token)`。

当前实现会对每个已加载 iframe 执行 reload 流程，因此同一个 token 可能收到多次完成回调；Dart 侧 `WebViewBridge.resolveToken` 对重复完成没有副作用。

### `checkTapElementAt(x, y): void`

检查当前 iframe 中坐标 `(x, y)` 对应的点击对象。

命中顺序：

1. 脚注：上报 `onFootnoteTap(innerHtml, left, top, width, height, baseUrl)`。
2. 链接：上报 `onLinkTap(href, x, y)`。
3. 普通点击：上报 `onTap(x, y)`。

该方法是 fire-and-forget，不使用 token。

### `checkLongPressElementAt(x, y): void`

检查当前 iframe 中坐标 `(x, y)` 是否命中图片或 SVG image。

命中后上报：

- `onImageLongPress(src, x, y, width, height)`

未命中时不回调。该方法是 fire-and-forget，不使用 token。

### `waitForRender(token): void`

等待两帧 `requestAnimationFrame` 后上报 `onEventFinished(token)`，用于 Flutter 侧等待 WebView 渲染趋于稳定。

## Web 端回调 Flutter 的接口

这些 handler 由 `web_assets/controller.js/api/flutter_bridge.ts` 发出，由 `reader_webview.dart` 中 `_setupJavaScriptHandlers` 注册。

| Handler | 参数 | 触发时机 |
| --- | --- | --- |
| `onViewportResize` | 无 | WebView window 尺寸变化，120ms debounce 后触发。 |
| `onPageCountReady` | `pageCount: number` | 当前 frame 完成分页或主题更新后触发。 |
| `onPageChanged` | `pageIndex: number` | 当前页码变化后触发。 |
| `onScrollAnchors` | `anchors: string[]` | 当前 frame active anchors 变化检测后触发。 |
| `onTap` | `x: number, y: number` | 点击未命中脚注或链接时触发。 |
| `onLinkTap` | `href: string, x: number, y: number` | 点击链接时触发。Flutter 可决定处理链接或回退为普通 tap。 |
| `onFootnoteTap` | `innerHtml: string, left: number, top: number, width: number, height: number, baseUrl: string` | 点击脚注引用时触发。 |
| `onImageLongPress` | `src: string, x: number, y: number, width: number, height: number` | 长按图片时触发。 |
| `onEventFinished` | `token: number` | token 异步调用完成时触发。`-1` 是内部哨兵，Dart 侧忽略。 |

## 关键数据结构

### `FrameSlot`

```ts
type FrameSlot = 'prev' | 'curr' | 'next';
```

### `Direction`

```ts
type Direction = 'next' | 'prev';
```

### `InitConfig`

```ts
interface InitConfig {
  safeWidth: number;
  safeHeight: number;
  direction: number;
  padding: { top: number; left: number };
  theme: ReaderTheme;
  paginationCss: string;
}
```

### `ReaderTheme`

```ts
interface ReaderTheme {
  zoom: number;
  surfaceColor: Color;
  onSurfaceColor: Color;
  shouldOverrideTextColor: boolean;
  primaryColor: Color;
  primaryContainerColor: Color;
  onSurfaceVariantColor: Color;
  outlineVariantColor: Color;
  surfaceContainerColor: Color;
  surfaceContainerHighColor: Color;
  overrideFontFamily?: boolean;
  fontFileName?: string | null;
}
```

### `ThemeUpdate`

```ts
interface ThemeUpdate {
  padding: { top: number; left: number };
  theme: ReaderTheme;
}
```

### `ReaderState`

内部状态集中在 `ReaderState`：

- `anchors`: 每个 frame slot 的锚点列表。
- `properties`: 每个 frame slot 的 spine properties。
- `quadTree`: 当前 frame 的交互命中索引。
- `config`: 当前阅读配置。

## 构建流程

构建脚本：`tool/build_web_assets.dart`

构建产物：`lib/src/web/web_assets.dart`

构建内容：

1. `web_assets/controller.js/index.ts` 通过 esbuild 打包成 IIFE，输出 `kControllerJs`。
2. `web_assets/pagination.css/main.css` 通过 esbuild 打包压缩，输出 `kPaginationCss`。
3. `web_assets/skeleton.css` 压缩，输出 `kSkeletonCss`。

esbuild target：

```text
es2015, chrome80, safari12, ios12
```

维护时应修改 `web_assets` 源文件，然后重新生成 `lib/src/web/web_assets.dart`。不要手动编辑生成文件。

TypeScript 类型检查命令位于 `web_assets/controller.js/package.json`：

```sh
npm run typecheck
```

## 维护注意事项

- `window.api` 是 Flutter 调用 Web 端的唯一稳定入口；新增能力时应先更新 `LuminaApi` TypeScript 接口，再同步 Dart 侧 `LuminaApi` 封装。
- 所有需要 Flutter 等待的 JS 方法都应接收 `token`，最终调用 `onEventFinished(token)`。
- `checkTapElementAt` 和 `checkLongPressElementAt` 是手势命中查询，不走 token。
- `cycleFrames` 隐含依赖 `frame-prev`、`frame-curr`、`frame-next` 三个 iframe 都存在。
- `loadFrame` 的 `properties` 会直接拼成 class 名，传入值需要与 typ 模块和 CSS 约定保持一致。
- 页面坐标基于当前 iframe 的 viewport；涉及特殊排版时，Web 端会按 `TypConfig.havePadding()` 补偿或扣除阅读 padding。
- 资源等待有超时兜底，图片加载慢或字体加载慢不会永久阻塞 token 完成。
