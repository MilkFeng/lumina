# Agent Context & Instructions: Lumina Project

## 1. Project Overview
- **Name**: Lumina
- **Type**: Cross-platform Epub reader application.
- **Framework**: Flutter
- **Language Requirement**: **CRITICAL** - All generated code, inline comments, variable/function names, and git commit messages MUST be written strictly in English.

## 2. Architecture & Core Implementation

### Project Structure
- **Architecture Pattern**: Feature-based Clean Architecture
- **Feature Layers**: Each feature module contains:
  - `domain/`: Domain models (Isar entities with code generation)
  - `data/`: Repositories, services, and data sources
  - `application/`: Business logic and state management
  - `presentation/`: UI components and pages
- **Core Modules**: Shared infrastructure including database, routing, storage, theme, and widgets

### Rendering Engine
- **CRITICAL**: You must strictly use the `webview` + `multiple iframes` approach for chapter preloading and rendering
- **Implementation**: Three-iframe carousel pattern (prev, curr, next) with absolute positioning and z-index layering
- **Purpose**: Enables smooth chapter transitions and efficient preloading without full page reloads
- **DO NOT**: Attempt to replace this underlying rendering logic with native Flutter text widgets

### State Management
- **Framework**: Riverpod 2.x with code generation
- **Providers**: Using `riverpod_annotation` and `riverpod_generator` for type-safe state management
- **Pattern**: Providers are defined close to their feature modules for better encapsulation

### Navigation
- **Router**: GoRouter for declarative, type-safe routing
- **Location**: Router configuration in `lib/src/core/router/`

### Data Persistence
- **Database**: Isar (NoSQL embedded database) for structured data
  - Models use `@collection` annotation with code generation (.g.dart files)
  - Supports indexing, queries, and relationships
- **Storage Strategies**:
  - `AppStorage`: Path management and app directory initialization
  - `SharedPreferences`: Simple key-value persistence (user preferences)
  - `flutter_secure_storage`: Encrypted storage for sensitive data (e.g., WebDAV credentials)

### EPUB Handling Strategy
- **Architecture**: Stream-from-zip approach (EPUB files remain compressed on disk)
- **Service**: `EpubStreamService` uses Dart Isolates for background ZIP parsing and content extraction
- **Content Delivery**: Files served via custom URI scheme (`epub://localhost/book/{fileHash}/{filePath}`)
- **Handler**: `EpubWebViewHandler` intercepts WebView requests and streams content from compressed EPUBs
- **Performance**: Persistent isolate prevents repeated ZIP parsing overhead

### Key Design Patterns
- **Repository Pattern**: Data access abstraction (e.g., `ShelfBookRepository`, `BookManifestRepository`)
- **Service Layer**: Business logic encapsulation (e.g., `EpubImportService`, `EpubStreamService`)
- **Functional Programming**: Using `fpdart` for Either, Option types and functional error handling

## 3. Strict UI & UX Guidelines (Red Lines)
When writing UI components and interaction logic, adhere to the following constraints:
1. **Toasts/Snackbars (Message Prompts)**: NEVER use the default system styles for success/error messages. All prompts must be implemented as **floating bubble boxes at the bottom** of the screen.
2. **Visual Style**: The overall design language leans towards a **Serif-style** and **Clean-style** aesthetic to maintain an elegant and restrained reading experience. Keep the UI clean and typography-focused.

## 4. Current State & Work-In-Progress (WIP)
- **Ongoing Feature**: Implementing the bookshelf system with support for **multiple book import/export**. This is a critical feature currently in development, so any modifications to the file structure or state management related to the bookshelf should be approached with caution.
- **CI/CD**: The project utilizes a GitHub Actions workflow for Android builds, compiling for different CPU instruction sets (ABIs) as well as generating a universal build. Ensure any modifications to `build.gradle` or native configurations respect this setup.

## 5. Workflow Instructions for Copilot Agent
When receiving a new task from the user:
1. **Acknowledge & Plan**: Before generating large blocks of code, briefly outline your implementation plan and list the files you intend to modify in English.
2. **Step-by-Step**: For complex features, wait for user confirmation on the architecture before proceeding to write the code.
3. **Keep it Clean**: Do not remove existing features or comments unless explicitly instructed.
4. **Testing**: After code generation, run `flutter analyze` and `flutter test` to ensure no new issues are introduced. Report any warnings or errors back to the user.
5. **Update Documentation**: If your changes affect the project structure or usage, update the relevant documentation files accordingly.