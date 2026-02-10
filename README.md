[简体中文](./README_zh-CN.md) | **English**

# Lumina

[![Flutter](https://img.shields.io/badge/Flutter-3.38-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey.svg)]()

> A lightweight EPUB e-book reader built with Flutter, featuring cloud synchronization via WebDAV

## 🚧 Early Development Stage

Please note that this project is currently in Alpha. Breaking changes to the database schema may occur without migration scripts in early versions.

## ✨ Key Features

- 📚 **EPUB Reading** - Supports EPUB 2.0/3.0 formats with smooth page turning, automatic reading progress saving, and complete EPUB rendering based on WebView
- 🗂️ **Bookshelf Management** - Custom grouping, multi-dimensional sorting, and batch operations
- ☁️ **WebDAV Sync** - Cloud synchronization of books and reading progress, seamless switching across multiple devices
- 🎨 **Elegant Interface** - Light/dark theme switching, built-in Source Han Serif font for comfortable reading experience
- ⚡ **Efficient Architecture** - Streaming loading of EPUB compressed files for fast startup

## 📱 Screenshots

<table>
  <tr>
    <td align="center">
      <img src="docs/shelf.jpg" width="250px" />
      <br />
      <sub>Shelf</sub>
    </td>
    <td align="center">
      <img src="docs/webdav.jpg" width="250px" />
      <br />
      <sub>WebDAV Sync</sub>
    </td>
    <td align="center">
      <img src="docs/chinese.jpg" width="250px" />
      <br />
      <sub>Chinese</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="docs/toc.jpg" width="250px" />
      <br />
      <sub>Table of Contents</sub>
    </td>
    <td align="center">
      <img src="docs/dark.jpg" width="250px" />
      <br />
      <sub>Dark Mode</sub>
    </td>
    <td align="center">
      <img src="docs/about.jpg" width="250px" />
      <br />
      <sub>About</sub>
    </td>
  </tr>
</table>

## 🚀 Quick Start

Android Users: Visit the [Releases page](https://github.com/MilkFeng/lumina/releases) to download the latest `.apk` installation package

iOS Users: Lumina is not yet available on the App Store. iOS users currently need to install via:
- Build from source code (requires macOS and Xcode)
- Wait for future App Store release

### Getting Started

1. **Import Books**: Tap the "+" button in the bottom right corner of the home page, select local EPUB files to import
2. **Configure Sync (Optional)**: Long press the sync icon on the bookshelf page, fill in WebDAV server information, and start syncing after successful connection test
3. **Start Reading**: Tap the book cover to open book details, then tap "Start Reading" or "Continue Reading" to enter the reading interface

## 🔧 Developer Guide

### Requirements
- Flutter SDK ≥ 3.10.8
- Dart SDK ≥ 3.10.8
- iOS 12.0+ / Android 5.0+ (API Level 21+)

### Build from Source

1. **Clone the Repository**
```bash
git clone https://github.com/MilkFeng/lumina.git
cd lumina
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Font Subsetting (Optional)**

To optimize font file size, you can run the font subsetting script:

```bash
cd scripts
python generate_subsets.py
```

> Note: Requires Python 3 and the fonttools library (`pip install fonttools brotli`)

The project uses Source Han Serif font by default. To use other fonts, modify `./scripts/generate_subsets.py` for subsetting.

4. **Run the App**

```bash
flutter run
```

Or specify a device:
```bash
flutter run -d <device-id>
```

### Build Release Version

**Android APK**
```bash
flutter build apk --release
```

**iOS**
```bash
flutter build ios --release
```

## ⚠️ Important Notes

### Custom Font License
This project includes the "Source Han Serif" font, licensed under the [SIL Open Font License 1.1](./assets/fonts/LICENSE.txt).

### WebDAV Functionality
- WebDAV sync is currently an experimental feature. Backup important data before use
- Initial sync may take considerable time depending on the number of books and network conditions

### EPUB Format Support
- Supports standard EPUB 2.0 and EPUB 3.0 formats
- DRM-encrypted e-books are not currently supported
- Standard-compliant EPUB files are recommended for the best experience

## 🗺️ Roadmap

- [x] Basic EPUB parsing and rendering
- [x] Stream-from-Zip streaming loading
- [x] Smooth page turning animations
- [x] Automatic reading progress saving
- [x] Cloud sync (WebDAV)
- [x] Bookshelf grouping management
- [x] Table of contents navigation
- [x] Adaptive light/dark themes
- [x] Internationalization support (Chinese/English)
- [x] Avoid duplicate page turns when two NCX navigation points are on the same page
- [x] Long press images to view full-size
- [x] Simple swipe page turning mode
- [x] Optimize initial loading lag when opening the first book
- [ ] Edit book metadata (cover, title, author, etc.)
- [ ] Reading settings (font size, line spacing, background color, etc.)

## 🙏 Acknowledgements

This project uses the following excellent open-source projects:

- [Flutter](https://flutter.dev) - Google's UI toolkit
- [Riverpod](https://riverpod.dev) - Reactive state management
- [Isar](https://isar.dev) - High-performance NoSQL database
- [Source Han Serif](https://github.com/adobe-fonts/source-han-serif) - Adobe open-source font

Thanks to all contributors for their support!

---

**⭐ If this project helps you, feel free to star it!**

Issues and pull requests are welcome
