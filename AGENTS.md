# AGENTS.md — Lumina

Agent instructions and project context. This is the single source of truth for how to work on this repository; `CLAUDE.md` and other tool-specific files point here.

## 1. Project Overview

- **Name**: Lumina — a lightweight EPUB reader.
- **Platforms**: Android and iOS.
- **Framework**: Flutter (Dart SDK `^3.10.8`, Flutter `>=3.44.6`).
- **Native core**: Rust, bridged with `flutter_rust_bridge` (§5).

### Language requirement — CRITICAL

**All generated code, inline comments, doc comments, identifiers, commit messages and UI strings must be written in English.** The two exceptions are the localized payload files (`lib/l10n/app_localizations_zh.dart` and the `.arb` sources) and the architecture documents under `docs/AGENTS/`, which are written in Chinese.

## 2. Repository Layout

```text
lib/
  main.dart                     app entry: RustLib.init, AppStorage.init, Isar warm-up, WebView pre-warm
  l10n/                         generated localizations (en, zh)
  src/
    app.dart                    MaterialApp.router root
    router.dart                 GoRouter route table (app assembly — see layering rules)
    providers.dart              Isar schema list + keychain store (app assembly — see layering rules)
    core/                       shared infrastructure — must not know about any feature
      database/                 Isar lifecycle (schemas injected at the assembly root)
      platform/                 native file picking, PlatformPath, import cache
      providers/                app-wide providers
      services/                 ToastService, UrlLauncher, StorageCleanupService
      storage/                  AppStorage paths, AppStorageConstants
      theme/                    AppTheme, color schemes, theme notifier
      widgets/                  cross-feature widgets
    features/
      library/                  bookshelf, import pipeline, shelf data owner
        domain/ data/ application/ presentation/
      backup/                   library backup export, restore, storage cleanup
        data/ application/ presentation/
      fonts/                    imported custom fonts (import, list, delete)
        domain/ application/ presentation/
      external_sources/         remote book sources (WebDAV today)
        domain/ data/ application/ presentation/
      reader/                   WebView reading engine
      detail/                   book detail screen
      settings/                 settings UI only (no domain of its own)
        presentation/
    rust/                       flutter_rust_bridge generated Dart bindings
    web/                        generated web-asset bundle + WebView bridge
      api/
rust/                           Rust crate `lumina_rust`
rust_builder/                   Flutter FFI plugin shell around cargokit
web_assets/                     TypeScript/CSS sources inlined into lib/src/web/web_assets.dart
tool/                           repository scripts
docs/AGENTS/                    architecture deep-dives (see §9)
```

### Layering rules

- **`core/` must not import from `features/`.** This holds with **no exemptions**. When a `core/` service needs feature data, inject it as a callback or through a provider that lives in the feature. Code that inherently has to name features — the route table, the app root — belongs at the `src/` root (`app.dart`, `router.dart`) or inside a feature, not in `core/`.
- **`lib/src/` root is the assembly layer.** `main.dart`, `app.dart`, `router.dart` and `providers.dart` wire the app together and are allowed to import features. Keep it to those; anything reusable belongs in `core/`, anything domain-specific in a feature.
- Within a feature, dependencies flow `presentation → application → data → domain`. `domain/` depends on nothing but Isar annotations.
- **No dependency cycles between features.** The intended shape is acyclic and it currently is: `backup → library`, `detail → library`, `external_sources → library` (import pipeline only), `fonts → library`, `library → external_sources` (import menu entries only), `reader → library`, `reader → fonts`, `settings → {backup, external_sources, fonts, library}`. If you need an edge that would close a cycle, move the shared piece down into `core/`, move the *caller* into the feature that already owns the dependency, or — when two features genuinely have to name each other, as the schema list does — hoist that one piece to the `src/` assembly root.
- Cross-feature reuse goes through `core/` only for genuinely generic capability. Domain models are not "generic": `ShelfBook` lives in `features/library/domain/`.
- Feature modules use a four-layer split: `domain/` (Isar entities and pure models), `data/` (repositories, services, parsers), `application/` (notifiers and business logic), `presentation/` (screens, widgets, mixins). A feature creates only the layers it actually needs — `settings/` has just `presentation/`.
- A feature may expose a composable section widget (for example `BackupSection`, `FontsSection`) so a host screen can embed it without reaching into the feature's internals.

## 3. Reading Engine (Red Line)

The reader renders EPUB content in a **WebView driving three absolutely positioned iframes** (prev / curr / next) with z-index layering.

- **This is a hard architectural constraint.** Chapter preloading and smooth transitions depend on it.
- **DO NOT** attempt to replace this with native Flutter text widgets, or to collapse the three iframes into one.
- The HTML skeleton, pagination CSS and controller JS are injected from `lib/src/web/web_assets.dart`; the Dart side drives them through `lib/src/web/api/lumina_api.dart` (typed mirror of the TypeScript `LuminaApi`) and `lib/src/web/api/webview_bridge.dart` (token-based request and event matching).
- Frame content is fetched lazily through the custom `epub://` scheme (`epub://localhost/book/{fileHash}/{filePath}`), served by `EpubWebViewHandler` out of the still-compressed EPUB.

## 4. UI & UX Red Lines

1. **Never use the default `SnackBar` or `Toast` for user messages.** All success / error / info prompts go through `ToastService` (`lib/src/core/services/toast_service.dart`), which renders a floating, blurred pill bubble at the bottom of the screen via `ToastBubble`. Call `ToastService.showSuccess` / `showError` / `showInfo`.
2. **Serif-leaning, content-first, restrained design.** Minimal chrome, no shadows, typography-led layout. Reuse the existing primitives in `lib/src/core/widgets/` (`settings_section.dart`, `settings_section_title.dart`, `settings_sub_label.dart`, `labeled_switch_tile.dart`, `integer_stepper.dart`, …) before writing a new one.
3. **Never hardcode user-visible strings.** Every string goes through `AppLocalizations`; add new keys to the `.arb` files and regenerate.

## 5. Native Rust Layer

The EPUB read path runs in Rust, not Dart. `EpubStreamService` is a thin async facade over it.

- **Crate**: `rust/` → `lumina_rust` (edition 2021, `cdylib` + `staticlib`). Dependencies: `flutter_rust_bridge`, `rc-zip`, `positioned-io`, `once_cell`, `parking_lot`.
- **Exposed API** (`rust/src/api/epub.rs`, mirrors in `lib/src/rust/api/epub.dart`):
  - `loadEpub({epubPath})` — parse and cache the ZIP central directory only; idempotent, no decompression.
  - `readEpubFile({epubPath, filePath})` — decompress one entry; `null` when the entry is absent.
  - `closeEpub({epubPath})` — drop the cached metadata.
  - `greet({name})` in `simple.rs` is an unused FRB template leftover.
- **The cache holds metadata, never file contents.** It is keyed by the `epubPath` string, so the same book passed under two different path strings produces two cache entries.
- **Per-entry safety limits** live in Rust: 50 MiB uncompressed cap per ZIP entry (zip-bomb guard), and media extensions (`mp4`, `mp3`, `ogg`, `webm`, `wav`, `m4a`, `avi`, `mov`) return empty bytes instead of content.
- **Build**: `rust_builder/` is a Flutter FFI plugin shell that drives the vendored `cargokit` to compile the crate for every platform. Do not edit `rust_builder/cargokit/` unless you are upgrading cargokit itself.
- **After adding a Rust dependency**, regenerate `assets/licenses/rust_licenses.json` (from `rust/about.toml` + `rust/about.hbs`); `main.dart` feeds it into the Flutter `LicenseRegistry`.

## 6. State, Data & Persistence

- **State**: Riverpod 3 with code generation. Declare providers with `@riverpod` / `@Riverpod(keepAlive: true)` in `*_notifier.dart` or `*_provider.dart` files next to the feature they serve.
- **Long-running generators must be `keepAlive`.** See `LibraryNotifier.importPipelineStream` and `BackupNotifier.restoreFromBackup`: they keep using `ref` across many async gaps, and an `autoDispose` provider would throw once no widget is listening (for example while a progress dialog is the only thing on screen).
- **Database**: Isar (`isar_community`). Entities are annotated `@collection` in `features/*/domain/` and registered in the `appDatabaseSchemas` list in `lib/src/providers.dart` — a new collection must be added there or it will silently not persist. The list lives at the `src/` assembly root because it inherently names every entity-owning feature; `core/database/` takes it as a constructor argument so it stays feature-agnostic.
- **Storage**: `AppStorage` owns the documents / temp / support roots; `AppStorageConstants` owns the directory and file-name layout (`books/`, `covers/`, `manifests/`, `fonts/`, `shelf.json`).
- **Preferences**: `SharedPreferences` via `sharedPreferencesProvider`; `flutter_secure_storage` is reserved for secrets.
- **Errors**: use `fpdart` `Either` / `Option` in service and notifier boundaries rather than throwing across layers.

## 7. Code Generation

Generated files are committed. **Never hand-edit them** — regenerate and commit the result. `build.yaml` excludes `lib/src/rust/**` from the Riverpod and Isar generators.

| What | Command | Output |
| --- | --- | --- |
| Riverpod + Isar | `dart run build_runner build` | `*.g.dart` |
| Rust bridge | `flutter_rust_bridge_codegen generate` | `rust/src/frb_generated.rs`, `lib/src/rust/*` |
| Web assets | `dart run tool/build_web_assets.dart` | `lib/src/web/web_assets.dart` |
| Localizations | `flutter gen-l10n` (also runs automatically on build) | `lib/l10n/app_localizations*.dart` |
| Rust license JSON | `cargo about generate about.hbs` (see `rust/about.toml`) | `assets/licenses/rust_licenses.json` |

Notes:

- The web-asset build shells out to `npx esbuild`, so Node is required on the build machine. The sources are `web_assets/controller.js` (TypeScript), `web_assets/pagination.css/main.css` and `web_assets/skeleton.css`.
- The Rust bridge is pinned: `flutter_rust_bridge` must match across `pubspec.yaml`, `rust/Cargo.toml` and the generated file headers. Bump all three together.
- `dart run build_runner build` may rewrite `test/*.mocks.dart`; that is expected and safe to commit.

## 8. Verification Workflow

Run these before claiming any task is complete, and report the real output:

```bash
flutter analyze
flutter test
```

- Both must be clean. `flutter analyze` is the gate that catches broken imports and stale generated code after a refactor.
- The test suite is small (`test/epub_import_test.dart`, `test/epub_parser_test.dart`); if you move or rename code they touch, treat them as the regression guard and run them explicitly.
- **CI does not run `flutter analyze`.** `.github/workflows/flutter_ci.yml` only runs `flutter test` on pull requests and pushes to `main`/`master`, and it does not compile the Rust crate. Verify locally; do not assume CI will catch it.
- `.github/workflows/build_release.yml` builds release artifacts on `v*` tags: it installs the Rust toolchain with the three Android targets and `cargo-ndk`, so Android releases compile Rust from source. Keep `build.gradle` and native configuration changes compatible with it.
- `--dart-define=IS_STORE_VERSION=true` marks a store build (see `_isStoreVersion` in the settings screen); the release workflow uses it for the AAB and `false` for the APKs.

## 9. Documentation

Keep these in sync when you change the corresponding subsystem:

| File | Covers |
| --- | --- |
| `docs/AGENTS/MULTIPLATFORM_ARCHITECTURE.md` | Android Kotlin / iOS Swift plugins, MethodChannel & EventChannel contracts, file picking, page-turn animation, volume keys, DocumentsProvider. |
| `docs/AGENTS/RUST_ARCHITECTURE.md` | Rust crate, FRB generation, cargokit build chains per platform, license files. |
| `docs/AGENTS/WEB_ASSETS_ARCHITECTURE.md` | WebView asset pipeline, controller JS, page-turn/pagination internals. |
| `README.md` / `README_zh-CN.md` | User-facing feature list and screenshots. |
| `CHANGELOG.md` | Released changes. |

If your change alters a directory layout or a public class name, grep the docs for the old path before you finish.

## 10. Working Agreement

1. **Acknowledge and plan.** Before writing large blocks of code, state the plan and list the files you intend to change.
2. **Confirm architecture first.** For structural or cross-cutting changes, get agreement on the approach before implementing.
3. **Do not delete existing features or comments** unless explicitly asked.
4. **Verify, then report.** Run §8, then report actual results — including anything that failed or that you could not run.
5. **Keep changes reviewable.** Prefer focused, mechanical commits; call out any judgement call you made where the request was ambiguous.
6. **Stay inside your scope.** If you notice unrelated problems, report them instead of silently fixing them.

## 11. Known Gaps

Current known-incomplete areas, so you do not mistake them for finished work:

- **CI has no `flutter analyze` step and no Rust check** (§8).
- **WebDAV sync is not implemented.** `webdavSync` exists in the l10n files but nothing references it; there is no sync feature directory.
- **External sources support WebDAV only, with HTTP Basic auth.** `features/external_sources/` can add, edit, test and delete sources, browse their folders and import EPUBs into the library. Digest/NTLM auth, and importing anything other than EPUB, are not implemented.
- **External "open with EPUB" handling is incomplete.** Android and iOS declare EPUB document types, and `features/library/presentation/shared_epub_handler.dart` consumes whatever reaches it through the router, but the native `onNewIntent` / `application(_:open:)` hand-off is not implemented — so a document opened from the file manager may never arrive.
- **`greet()` in `rust/src/api/simple.rs`** is unused template code.
- **Platform support beyond Android/iOS** (Linux, macOS, Windows) is wired through `rust_builder` and Flutter's plugin manifests but not exercised or documented as supported.
