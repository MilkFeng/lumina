import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;

/// Optimized Service for streaming EPUB content
/// Uses a persistent background Isolate to avoid repeated ZIP parsing overhead.
class EpubStreamService {
  _EpubWorker? _worker;
  String? _currentBookPath;

  Completer<void>? _initCompleter;

  /// Warm up the service by spawning the background isolate.
  Future<void> warmUp() async {
    if (_worker != null) return;

    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();

    try {
      _worker = await _EpubWorker.spawn();
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
    }
  }

  /// Open a book session.
  /// Spawns a background isolate and parses the ZIP headers once.
  /// Must be called before [readFileFromEpub].
  Future<void> openBook(String epubPath) async {
    if (_worker == null) {
      await warmUp();
    }

    if (_currentBookPath == epubPath) return;

    try {
      await _worker!.loadBook(epubPath);
      _currentBookPath = epubPath;
    } catch (e) {
      _currentBookPath = null;
      rethrow;
    }
  }

  /// Read a specific file from the currently opened EPUB.
  /// Extremely fast as it uses the cached file index in the background isolate.
  Future<Either<String, Uint8List>> readFileFromEpub({
    required String targetFilePath,
    // Optional: allow passing path explicitly for one-off reads (slower fallback)
    String? epubPath,
  }) async {
    // Fallback: If no session is open or a different path is requested,
    // perform a "slow" one-off read using Isolate.run (Dart 2.19+)
    if (_worker == null || (epubPath != null && epubPath != _currentBookPath)) {
      final path = epubPath ?? _currentBookPath;
      if (path == null) return left('Book not opened and no path provided');
      return _oneOffRead(path, targetFilePath);
    }

    try {
      final data = await _worker!.requestFile(targetFilePath);
      if (data == null) {
        return left('File not found: $targetFilePath');
      }
      return right(data);
    } catch (e) {
      return left('Read error: $e');
    }
  }

  /// Close the background isolate and release resources.
  void dispose() {
    _worker?.dispose();
    _worker = null;
    _currentBookPath = null;
  }

  /// Fallback for one-off reads without a session
  Future<Either<String, Uint8List>> _oneOffRead(
    String path,
    String targetPath,
  ) async {
    try {
      return await Isolate.run(() {
        final file = File(path);
        if (!file.existsSync()) return left('EPUB file not found');

        final inputStream = InputFileStream(path);
        // verify: false speeds up parsing significantly
        final archive = ZipDecoder().decodeStream(inputStream, verify: false);
        final archiveFile = archive.findFile(targetPath);

        if (archiveFile == null) return left('File not found');

        final content = archiveFile.content as List<int>;
        // Explicitly close stream
        inputStream.close();
        return right(Uint8List.fromList(content));
      });
    } catch (e) {
      return left('One-off read failed: $e');
    }
  }

  /// Get MIME type (Helper method, unchanged logic but optimized structure)
  String getMimeType(String filePath) {
    final ext = p.extension(filePath).toLowerCase().replaceAll('.', '');
    return _mimeTypeMap[ext] ?? 'application/octet-stream';
  }

  static const _mimeTypeMap = {
    'html': 'text/html',
    'htm': 'text/html',
    'xhtml': 'application/xhtml+xml',
    'xml': 'application/xml',
    'css': 'text/css',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'svg': 'image/svg+xml',
    'webp': 'image/webp',
    'ttf': 'font/ttf',
    'otf': 'font/otf',
    'woff': 'font/woff',
    'woff2': 'font/woff2',
    'js': 'application/javascript',
  };
}

// =============================================================================
// Background Worker Implementation
// =============================================================================

/// Internal class to manage the background Isolate
class _EpubWorker {
  final Isolate _isolate;
  final SendPort _sendPort;
  final ReceivePort _receivePort;

  // Map to track pending requests: RequestID -> Completer
  final _pendingRequests = <int, Completer<dynamic>>{};
  int _nextRequestId = 0;

  _EpubWorker._(this._isolate, this._sendPort, this._receivePort) {
    _receivePort.listen(_handleResponse);
  }

  static Future<_EpubWorker> spawn() async {
    final receivePort = ReceivePort();
    // Start the isolate
    final isolate = await Isolate.spawn(
      _workerEntryPoint,
      receivePort.sendPort,
    );

    // Wait for the first message (the SendPort from the worker)
    final sendPort = await receivePort.first as SendPort;

    // Create a new ReceivePort for actual data handling so we don't consume the "first" event again
    final responsePort = ReceivePort();

    // Tell the worker where to send responses for data requests
    sendPort.send(responsePort.sendPort);

    return _EpubWorker._(isolate, sendPort, responsePort);
  }

  Future<void> loadBook(String path) {
    final completer = Completer<void>();
    final id = _nextRequestId++;
    _pendingRequests[id] = completer;
    _sendPort.send(_LoadMessage(id, path));
    return completer.future;
  }

  Future<Uint8List?> requestFile(String path) {
    final completer = Completer<Uint8List?>();
    final id = _nextRequestId++;
    _pendingRequests[id] = completer;
    _sendPort.send(_RequestMessage(id, path));
    return completer.future;
  }

  void _handleResponse(dynamic message) {
    if (message is _ResponseMessage) {
      final completer = _pendingRequests.remove(message.requestId);
      if (completer != null) {
        if (message.error != null) {
          completer.completeError(message.error!);
        } else {
          completer.complete(message.data);
        }
      }
    }
  }

  void dispose() {
    _sendPort.send('shutdown');
    _isolate.kill();
    _receivePort.close();
  }
}

// --- Messages ---

class _LoadMessage {
  final int id;
  final String path;
  _LoadMessage(this.id, this.path);
}

class _RequestMessage {
  final int id;
  final String path;
  _RequestMessage(this.id, this.path);
}

class _ResponseMessage {
  final int requestId;
  final Uint8List? data;
  final String? error;
  _ResponseMessage(this.requestId, this.data, {this.error});
}

// --- Isolate Entry Point ---

void _workerEntryPoint(SendPort mainSendPort) {
  final commandPort = ReceivePort();

  // 1. Send our command port back to the main thread
  mainSendPort.send(commandPort.sendPort);

  // Warm up the ZIP decoder by performing a dummy decode (JIT compilation)
  try {
    final dummyZipBytes = Uint8List.fromList([
      0x50,
      0x4B,
      0x05,
      0x06,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
    ]);
    ZipDecoder().decodeBytes(dummyZipBytes, verify: false);
    debugPrint("Background Worker: Code warmed up (JIT compiled).");
  } catch (e) {
    debugPrint("Background Worker: Warm-up failed: $e");
  }

  // 2. Open EPUB and Cache Headers (The expensive part, done once!)
  InputFileStream? inputStream;
  Archive? archive;
  SendPort? responsePort;

  commandPort.listen((message) {
    if (message is SendPort) {
      responsePort = message;
    } else if (message == 'shutdown') {
      inputStream?.close();
      commandPort.close();
    } else if (message is _LoadMessage) {
      if (responsePort == null) return;

      try {
        inputStream?.close();
        archive = null;

        inputStream = InputFileStream(message.path);
        archive = ZipDecoder().decodeStream(inputStream!, verify: false);

        responsePort!.send(_ResponseMessage(message.id, null));
      } catch (e) {
        responsePort!.send(
          _ResponseMessage(message.id, null, error: 'Failed to load book: $e'),
        );
      }
    } else if (message is _RequestMessage) {
      if (responsePort == null) return;

      if (archive == null) {
        responsePort!.send(
          _ResponseMessage(message.id, null, error: 'No book loaded'),
        );
        return;
      }

      try {
        final file = archive!.findFile(message.path);
        if (file != null) {
          final content = file.content as List<int>;
          final bytes = Uint8List.fromList(content);
          responsePort!.send(_ResponseMessage(message.id, bytes));
        } else {
          responsePort!.send(_ResponseMessage(message.id, null));
        }
      } catch (e) {
        responsePort!.send(
          _ResponseMessage(message.id, null, error: e.toString()),
        );
      }
    }
  });
}
