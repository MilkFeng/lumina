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
| `web_assets/controller.js/renderer/scroll_observer.ts` | 观察章节自身的原生滚动，向 Flutter 上报位置、锚点与停止滚动。 |
| `web_assets/controller.js/renderer/gesture_observer.ts` | 滚动模式下在页面内识别 tap 与图片长按，回报 Flutter（见"交互命中"）。 |
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

### 连续滚动模式

`InitConfig.scrollMode` 为 `true` 时，`curr` iframe 内部改为一整列连续内容，垂直滚动阅读，
章节之间**不**连续（章节切换走 `cycleFrames`）。三帧结构本身不变。

滚动模式下"翻一屏"只有一条路径：Dart 侧 `handleScrollTurn`
（`presentation/mixins/page_navigation_mixin.dart`）。音量键、底部工具栏箭头的单击、以及页面
左右各 30% 区域的点击都调用它，因此三者行为完全一致：

- 该方向还有内容可滚 → 调 `scrollByViewport` 滚一屏，不振动。
- 已经滚到该方向尽头（章节底部再往后 / 顶部再往前）→ 换成 `cycleFrames` 翻章；章节本身
  不足一屏（`maxOffset == 0`）时两端同时成立，所以一次按键就是翻章。
- 往回翻章落在**上一章的末尾**（`jumpToLastPageOfFrame` 在滚动模式下就是这一列的底部），
  往前翻章落在下一章的开头：倒着读是从上一章读完的地方接上的，工具栏箭头的长按同理
  （`onPreviousChapter` 在滚动模式下走 `previousSpineItem`）。
- 连续两次请求串行执行：后一次到来时先让前一次**立即落到目标位置**
  （`finishScrollByViewport`），隔 40ms 再开始自己的这一次。

长按箭头仍然直接翻章并保留 `HapticFeedback.selectionClick()`：那一下振动标记的是"落到另一
章"，与分页模式一致；翻一屏和分页模式里的翻一页一样不振动。

底部工具栏中间的位置指示两行，两种模式结构相同：第一行是 `当前章/总章数`，第二行分页模式是
`当前页/总页数`（只有一页的章节不显示），滚动模式是阅读进度百分比——取的就是
`_ProgressMixin` 里 `displayProgress` 那个字符串，与阅读区底部常驻状态栏右侧显示的是同一个值。

- `body` 上加 `lumina-is-scroll` class，`pagination.css/main.css` 中的
  `body.lumina-is-scroll` 规则把 `column-width` / `column-count` 还原成 `initial`，
  并强制 `overflow-y: auto` / `overflow-x: hidden`。
- `PaginationManager` 在滚动模式下短路：`calculatePageCount` 返回 `1`、
  `calculateCurrentPageIndex` 返回 `0`、`calculateScrollOffset` 返回 `0`，
  跳过所有 `+128` 的 column gap 运算；`detectActiveAnchor` 改用纵向轴。
- **滚动由页面自己完成，不走 JS 接口。** Flutter 在滚动模式下不声明任何手势识别器，
  框架的手势竞技场因此把整段指针序列转发给平台视图（原生 WebView），由浏览器自身的滚动器
  跟手滚动。这一点不可放宽：任何 Flutter 识别器抢下指针，框架就会把这次序列缓存后丢弃，
  页面连 touch-down 都收不到，惯性滚动便无法被打断（详见
  `MULTIPLATFORM_ARCHITECTURE.md` 的"为什么滚动模式下 Flutter 不能声明任何手势"）。
  Web 端几乎不提供"把偏移推给我"的接口：早期实现由 Flutter 每帧调用
  `scrollContentTo` 推绝对偏移，一次平台通道往返往往超过一帧，内容会明显落后于手指。
  唯一的例外是翻屏命令 `scrollByViewport`：它一次只推一个目标位置，由页面自己分帧走完
  （见下节），因此不在这条红线之内。
  手势因此也归页面：见"交互命中"里的 `GestureObserver`。
- Web 端只做**观察**（`ScrollObserver`）：监听当前 frame 的 `scroll` 事件，按
  `requestAnimationFrame` 合并成每帧一次 `onScrollProgress(offset, maxOffset)`，
  active anchor 按 250ms 节流，停止滚动 150ms 后上报一次 `onScrollSettled`。
  `scroll` 事件监听在 window 上以 **capture** 方式注册：章节的滚动容器是 `body` 元素，
  元素滚动事件不会冒泡到 window。
- 监听按**文档**去重，不能按 window 去重：frame 导航到新章节后 `contentWindow` 返回的
  window proxy 对象不变，而它当前指向的文档已经换了一个。以 window 作"这个页面我挂过了吗"
  的判断，会让每个 frame 只在打开时挂上一次监听，此后所有章节切换（TOC 跳转、`cycleFrames`
  翻章、预加载相邻章节）得到的新文档都不再有监听：滚动照常，但 `onScrollProgress`、
  `onScrollAnchors`、`onScrollSettled` 全部停报——表现为章节切换后进度百分比与章节名不再更新、
  阅读位置也不再落盘。判据与 `GestureObserver` 一致，用 `contentDocument`。
- 让原生滚动成立的四处前提：`InAppWebViewSettings.disableVerticalScroll` 在滚动模式下为
  `false`；`pagination.css` 用 `--lumina-reader-touch-action`（分页 `none` / 滚动 `pan-y`）放开
  纵向平移，且必须写在 `body` 上（有效 `touch-action` 只算到滚动容器为止，写在 `html`
  上不起作用）；`skeleton.css` 里 `body.lumina-scroll-mode iframe` 恢复
  `pointer-events`；iframe 的 `scrolling` 属性在滚动模式下为 `auto`。
- **章节两端不得露出系统 overscroll 效果。** `pagination.css` 与 `skeleton.css` 的
  `html, body` 都带 `overscroll-behavior: none`。`InAppWebViewSettings.overScrollMode =
  NEVER` 只是 WebView 这个 View 自身的属性，管不到 iframe 文档内部的滚动容器：章节滚到
  两端之后 Chromium 仍会画 Android 原生的辉光/拉伸效果，并把多出来的拖动链式传给后面的
  skeleton 文档。`none` 同时关掉本容器的溢出效果和向父级的传递；滚动模式下 `body` 就是
  滚动容器，这条规则必须跟着 `overflow` 一起写在它身上。
- `skeleton.css` 中滚动模式给**三个** frame 都开 `pointer-events`（叠放顺序由 z-index
  决定，只有最上层的 `frame-curr` 能被点到）。若只给 `#frame-curr` 开，`cycleFrames`
  把 `next` 提升为 `curr` 的那一刻会翻转该 frame 的 `pointer-events`，而这一帧在合成器里
  保留着过期的触摸命中信息，翻章后整个章节将完全无法拖动（已用无头 Chromium 验证）。
- 同理，iframe 的 `scrolling="auto"` 也必须给三个 frame：`cycleFrames` 靠交换 id 复用
  同一个 iframe 元素，被提升上来的那个可能是以 `next` 身份创建的。

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

分页模式下 WebView iframe 设置 `pointer-events: none`，手势全部由 Flutter 捕获，再把坐标
转给 Web 端 API（`checkTapElementAt` / `checkLongPressElementAt`，这两个接口从此只服务这一
模式）。滚动模式下 iframe 接收指针事件，Flutter 侧一个识别器都不声明（原因见
`MULTIPLATFORM_ARCHITECTURE.md` 的"为什么滚动模式下 Flutter 不能声明任何手势"），tap 与
图片长按因此由页面自己识别：

- `GestureObserver` 给每个 frame 的 **document**（不是 slot：`cycleFrames` 靠交换 id 复用
  同一批 iframe 元素）挂 `click` / `touchstart` / `touchmove` / `touchend` / `touchcancel`。
- tap 用 `click` 判定：Chromium 在触摸变成滚动或惯性之后不会派发 `click`，所以不需要自己写
  位移或时长阈值，而且落在惯性上的那次点击既打断了滚动、又仍然算一次 tap。每次 `click` 都
  `preventDefault()`（链接绝不能在页面内原生导航），再用 `event.clientX/clientY`（iframe
  视口坐标）走 `InteractionManager.checkTapElementAt` —— 链接、脚注与普通 tap 的判定与分页
  模式完全一致，区别只是 Flutter 不再需要把屏幕坐标传进来，命中用的滚动位置也不再滞后。
- 图片长按由页面自己的 500ms 定时器检测（位移超过 10px 或抬手即取消），命中后走
  `checkImageAt` 上报 `onImageLongPress`；紧随其后的那次抬手产生的 `click` 会被吞掉，
  不再重复算作 tap。页面只负责**识别与上报**，不负责振动：WebView 自身的长按振动已在
  Android 侧被关掉，振不振动、振多重由 Flutter 决定（见
  `MULTIPLATFORM_ARCHITECTURE.md` 的"长按振动归 Flutter"）。

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

- 保存 `safeWidth`、`safeHeight`、`direction`、`scrollMode`、`padding`、`theme`、`paginationCss`。
- 向 skeleton document 写入 CSS 变量。
- 注册 window resize 监听，尺寸变化后 120ms debounce 上报 `onViewportResize`。

### `loadFrame(token, slot, url, anchors?, properties?, initialScrollRatio?): void`

把 URL 加载到指定 iframe slot。

参数：

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| `token` | `number` | 异步完成 token，完成后回调 `onEventFinished(token)`。 |
| `slot` | `'prev' \| 'curr' \| 'next'` | 目标 iframe。 |
| `url` | `string` | iframe 要加载的章节或资源 URL。 |
| `anchors` | `string[]?` | 用于滚动位置追踪的元素 id 列表，`top` 有特殊含义。 |
| `properties` | `string[]?` | spine properties，会转成 `lumina-spine-property-*` class。 |
| `initialScrollRatio` | `number \| null?` | 起始位置：滚动模式下是滚动范围的比例，分页模式下是页数比例。 |

请求的 URL 与 frame 当前 URL 的 origin + pathname 相同时，frame **不会被重新加载**（fragment
不同则是文档内跳转）：`onFrameLoad` 会被直接调用一次，并按下文规则重新应用位置。所以"跳到
本章开头"这类请求必须靠位置应用来完成，不能指望重新加载把页面带回顶部。

加载完成后会：

1. 注入主题 CSS 变量和分页 CSS。
2. 等待图片和字体资源，单图最长 3 秒，整体最长 5 秒。
3. 应用主题 class、方向 class、spine property class。
4. 应用特殊排版适配。
5. 执行 CSS polyfill。
6. 计算页数，并按 URL hash anchor 或 `initialScrollRatio` 定位；**只有真实 anchor 才算 anchor**
   （`top` 是阅读器自己的默认 anchor，`EpubWebViewHandler.getFileUrl` 会给每个 frame URL
   追加它），带 `#top` 加载时仍然应用 `initialScrollRatio`。两者都没有时定位到本章开头
   （`scrollTo(0)`）：正在加载的文档本来就在开头，但**请求的 URL 与 frame 当前 URL 相同时
   浏览器不会重新加载它**，没有这一步的话"跳到正在阅读的这一章的开头"（TOC 项指向本章顶部、
   章节内链接指向本章开头）会毫无反应——URL 一模一样，`onFrameLoad` 里既没有 anchor 也没有
   `initialScrollRatio` 可应用，页面就停在原处。
7. 重建交互四叉树，并挂上滚动观察（滚动模式）。
8. 若是 `curr`，上报 `onPageCountReady(pageCount)`、`onPageChanged(pageIndex)` 和一次
   `onScrollProgress`。
9. 若是 `prev`，跳到该 frame 最后一页；若是 `next`，跳到第一页。
10. 上报 active anchors 和 `onEventFinished(token)`。

恢复阅读位置走的是这里的 `initialScrollRatio`：章节带着位置一起加载，不再需要加载完再补
一次滚动调用。

### `jumpToPage(token, pageIndex): void`

跳转当前 iframe 到指定 0-based 页码。

完成后依次上报：

- `onPageChanged(pageIndex)`
- `onScrollAnchors(anchors)`，如果当前 frame 配置了 anchors
- `onEventFinished(token)`

### `jumpToPageFor(token, slot, pageIndex): void`

跳转指定 iframe slot 到指定页码。只有目标 iframe 当前 id 是 `frame-curr` 时才上报 `onPageChanged(pageIndex)`。总会尝试检测 active anchors 并完成 token。

### `jumpToLastPageOfFrame(token, slot): void`

把指定 iframe 送到它这一章的末尾。

- 分页模式：计算页数，跳到 `pageCount - 1`，内部复用 `jumpToPageFor`。
- 滚动模式：一章就是一整列连续内容，它的"最后一页"就是这一列的底部（`maxOffset`），
  直接 `applyScrollOffset`，再走两帧 rAF 上报锚点并完成 token。

`prev` frame 一加载完就会被送到这里（见 `onFrameLoad` / `reloadFrame`），所以往回翻章时它
**已经停在上一章的末尾**，读者接上的正是上次读到的位置；`previousSpineItem()` 也会显式再调
一次，覆盖预加载之后位置被改动的可能。

### `scrollByViewport(token, direction): void`

把当前 iframe 滚动约一屏（视口高度减去 48px 重叠），仅滚动模式使用，`direction` 为
`'next' | 'prev'`。

这是**唯一**由 Flutter 发起的滚动命令，服务于没有自带手势的翻屏请求（音量键、工具栏箭头、
页面左右区域点击）。动画由页面自己做：`requestAnimationFrame` 逐帧把 `body.scrollTop` 从
当前位置推到目标位置（ease-out cubic，300ms）。没有沿用
`scrollBy({ behavior: 'smooth' })`，因为 Flutter 既要一屏**何时落定**，也要能把它**立即落到
目标位置**：

- 落定（自然结束，或被 `finishScrollByViewport` 提前结束）时先同步上报一次
  `onScrollProgress`，再 `onEventFinished(token)`。顺序不能反：Flutter 收到 token 后会立刻
  用这个位置判断"下一次请求还算不算滚动"，而程序化滚动产生的 `scroll` 事件要到下一帧才到
  `ScrollObserver`。
- 目标位置与当前位置相同（该方向已无可滚内容）时不启动动画，直接上报位置并完成 token；
  该翻哪一章由 Flutter 决定。
- 启动前先把上一个仍在动画中的翻屏落定：同一时刻只有一个 `ViewportScroll`。
- 手指按下页面时动画停在当前位置（token 照常完成）——JS 动画不能盖住读者的拖动；
  `cycleFrames` 同样会中止它，那一屏属于正在离场的章节。

### `finishScrollByViewport(): void`

把正在动画中的滚动立即落到目标位置，并完成它的 token。后一次翻屏请求到来时 Flutter 会先调
它，隔 40ms 再发起自己的请求，因此连续按键是"每一屏都完整走完"，而不是几次动画互相打断。
没有动画时是 no-op；fire-and-forget，不使用 token。

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
- 按 `newTheme.scrollMode` 切换分页模式与滚动模式的布局（`body.lumina-is-scroll`）。
- 按当前位置百分比重新分页和恢复位置；滚动模式下重新上报一次 `onScrollProgress`。
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

该方法是 fire-and-forget，不使用 token。分页模式由 Flutter 在拿到点击后调用；滚动模式没有
Flutter 手势，由 `GestureObserver` 在自己的 `click` 处理里调用同一个方法，命中逻辑因此只有
一份。

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
| `onScrollProgress` | `offset: number, maxOffset: number` | 滚动模式下上报当前 frame 的滚动位置与可滚动范围（CSS 像素）。页面自己滚动，因此这是位置信息唯一的方向。frame 加载完成、主题更新、翻章（`cycleFrames`）后各上报一次，滚动过程中按 `requestAnimationFrame` 合并为每帧一次；一次翻屏落定（含被提前落定）时还会同步再上报一次，见 `scrollByViewport`。Dart 侧据此计算章节进度百分比，并判断是否已到章节两端。 |
| `onScrollSettled` | 无 | 页面停止滚动约 150ms 后触发一次，Dart 侧据此落盘阅读进度。 |
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
  scrollMode: boolean;
  padding: { top: number; left: number };
  theme: ReaderTheme;
  paginationCss: string;
}
```

`scrollMode` 为 `true` 时，章节不再用 CSS multicol 切分成页，而是渲染成一整列并垂直滚动。
它与 `direction` 相互独立：`direction` 始终表示书籍自身的翻页方向，而滚动模式只对
`direction === 0` 的书籍开放（RTL / 竖排书籍强制分页，见
`ReaderSettings.supportsScrollMode`）。

### `ThemeUpdate`

```ts
interface ThemeUpdate {
  padding: ReaderPadding;
  theme: ReaderTheme;
  scrollMode: boolean;
}
```

### `ScrollPosition`

```ts
interface ScrollPosition {
  offset: number;
  maxOffset: number;
}
```

当前 frame 的滚动位置和它可以滚到的最远处，由 `FrameManager.getScrollPosition` 从章节
`body` 的 `scrollTop` / `scrollHeight` / `clientHeight` 算出，通过 `onScrollProgress`
上报给 Flutter。单位是 CSS 像素。

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
- 滚动模式下的滚动位置由页面自己产生，只通过 `onScrollProgress` / `onScrollSettled` 上报；
  除 `scrollByViewport` 外，不要再新增让 Flutter 推偏移的接口。它是唯一的例外，而且每次翻屏
  只推一个目标位置，绝不逐帧推偏移。
- `onScrollProgress` 上报的是 CSS 像素的 `(offset, maxOffset)`：Dart 侧同时用它算进度百分比和
  判断章节两端（`_ProgressMixin.handleScrollProgress`）。"滚到底后再按一次就翻章"依赖翻屏
  落定时那次同步上报。
- `checkTapElementAt` 和 `checkLongPressElementAt` 是手势命中查询，不走 token：分页模式由
  Flutter 调用，滚动模式由页面内的 `GestureObserver` 调用（`checkImageAt` 亦同）。
- `cycleFrames` 隐含依赖 `frame-prev`、`frame-curr`、`frame-next` 三个 iframe 都存在。
- `loadFrame` 的 `properties` 会直接拼成 class 名，传入值需要与 typ 模块和 CSS 约定保持一致。
- 每个 frame URL 都带 `#anchor`（默认 `#top`），判断"URL 里有没有 anchor"时必须排除 `top`；
  否则 `initialScrollRatio` 会被静默丢弃，表现为"阅读进度没被记住"。
- 页面坐标基于当前 iframe 的 viewport；涉及特殊排版时，Web 端会按 `TypConfig.havePadding()` 补偿或扣除阅读 padding。
- 资源等待有超时兜底，图片加载慢或字体加载慢不会永久阻塞 token 完成。
