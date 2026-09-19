import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/src/core/utils/byte_size.dart';
import 'package:lumina/src/core/widgets/progress_dialog.dart';

/// Unit tests for the values the import progress dialog renders a download from:
/// the percentage a transfer event derives, and the byte sizes both the dialog
/// and the source browser print.
void main() {
  group('FileTransferProgress.percent', () {
    test('reports the received share of a declared total', () {
      expect(
        FileTransferProgress(
          fileName: 'book.epub',
          receivedBytes: 32,
          totalBytes: 100,
        ).percent,
        32,
      );
    });

    test('rounds to the nearest whole percent', () {
      expect(
        FileTransferProgress(
          fileName: 'book.epub',
          receivedBytes: 1,
          totalBytes: 3,
        ).percent,
        33,
      );
    });

    test('is null when no total was declared', () {
      expect(
        FileTransferProgress(fileName: 'book.epub', receivedBytes: 32).percent,
        isNull,
      );
    });

    test('is null for a total that cannot be a size', () {
      expect(
        FileTransferProgress(
          fileName: 'book.epub',
          receivedBytes: 32,
          totalBytes: 0,
        ).percent,
        isNull,
      );
      expect(
        FileTransferProgress(
          fileName: 'book.epub',
          receivedBytes: 32,
          totalBytes: -1,
        ).percent,
        isNull,
      );
    });

    test('never reports more than 100, however wrong the server was', () {
      // A server that under-declares `Content-Length` must not turn the counter
      // into nonsense.
      expect(
        FileTransferProgress(
          fileName: 'book.epub',
          receivedBytes: 120,
          totalBytes: 100,
        ).percent,
        100,
      );
    });
  });

  group('formatByteSize', () {
    test('keeps bytes exact', () {
      expect(formatByteSize(0), '0 B');
      expect(formatByteSize(1023), '1023 B');
    });

    test('steps up one unit at a time', () {
      expect(formatByteSize(1024), '1.0 KB');
      expect(formatByteSize(1024 * 1024), '1.0 MB');
      expect(formatByteSize(1024 * 1024 * 1024), '1.0 GB');
    });

    test('drops the decimal once the number is wide enough not to need it', () {
      expect(formatByteSize(100 * 1024 * 1024), '100 MB');
    });

    test('rounds a fraction to one decimal', () {
      expect(formatByteSize(3355443), '3.2 MB');
      expect(formatByteSize(10485760), '10.0 MB');
    });

    test('stays in the largest unit it knows', () {
      expect(formatByteSize(2 * 1024 * 1024 * 1024 * 1024), '2048 GB');
    });
  });
}
