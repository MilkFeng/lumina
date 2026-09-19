import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/widgets/progress_dialog.dart';
import 'package:lumina/src/features/library/application/library_notifier.dart';
import 'package:lumina/src/features/library/presentation/widgets/import_progress_dialog.dart';

/// Widget tests for the dialog an import shows while it runs.
///
/// The notifier is not involved: the dialog is handed a stream the test drives
/// by hand, which is exactly the contract it has with whoever started the
/// import — local pipeline or remote source.
void main() {
  /// Pumps the dialog over a stream the test controls.
  Future<StreamController<ProgressLog>> pumpDialog(WidgetTester tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final controller = StreamController<ProgressLog>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ImportProgressDialog(stream: controller.stream, l10n: l10n),
      ),
    );
    return controller;
  }

  /// The event an import emits when it starts on a file.
  ImportProgress processing(String name, {int total = 1, int current = 0}) {
    return ImportProgress(
      totalCount: total,
      currentCount: current,
      currentFileName: name,
      status: ImportStatus.processing,
    );
  }

  testWidgets('shows the bytes and percentage of the file being downloaded', (
    tester,
  ) async {
    final controller = await pumpDialog(tester);
    controller.add(processing('book.epub'));
    controller.add(
      FileTransferProgress(
        fileName: 'book.epub',
        receivedBytes: 3355443,
        totalBytes: 10485760,
      ),
    );
    await tester.pump();

    expect(find.text('Processing book.epub'), findsOneWidget);
    expect(find.text('3.2 MB / 10.0 MB · 32%'), findsOneWidget);
  });

  testWidgets('shows the bytes alone when no total was declared', (
    tester,
  ) async {
    final controller = await pumpDialog(tester);
    controller.add(processing('book.epub'));
    controller.add(
      FileTransferProgress(fileName: 'book.epub', receivedBytes: 3355443),
    );
    await tester.pump();

    expect(find.text('3.2 MB'), findsOneWidget);
  });

  testWidgets('shows nothing extra for an import that reports no bytes', (
    tester,
  ) async {
    // A local import: the dialog behaves exactly as it did before downloads
    // could report progress.
    final controller = await pumpDialog(tester);
    controller.add(processing('book.epub'));
    await tester.pump();

    expect(find.text('Processing book.epub'), findsOneWidget);
    expect(find.textContaining('MB'), findsNothing);
  });

  testWidgets('drops the byte line once the file is finished', (tester) async {
    final controller = await pumpDialog(tester);
    controller.add(processing('book.epub'));
    controller.add(
      FileTransferProgress(
        fileName: 'book.epub',
        receivedBytes: 10485760,
        totalBytes: 10485760,
      ),
    );
    await tester.pump();
    expect(find.text('10.0 MB / 10.0 MB · 100%'), findsOneWidget);

    controller.add(
      ImportProgress(
        totalCount: 1,
        currentCount: 0,
        currentFileName: 'book.epub',
        status: ImportStatus.failed,
        errorMessage: 'network unreachable',
      ),
    );
    await tester.pump();

    expect(find.text('10.0 MB / 10.0 MB · 100%'), findsNothing);
  });

  testWidgets('keeps transfer ticks out of the details log', (tester) async {
    final controller = await pumpDialog(tester);
    controller.add(
      ProgressLog('Preparing to import 1 book(s)', ProgressLogType.info),
    );
    controller.add(processing('book.epub'));
    for (var step = 1; step <= 50; step++) {
      controller.add(
        FileTransferProgress(
          fileName: 'book.epub',
          receivedBytes: 1024 * step,
          totalBytes: 1024 * 50,
        ),
      );
    }
    await tester.pump();

    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    // A tick is live state, not a log line: fifty of them must not become fifty
    // entries in the panel.
    expect(find.textContaining('Transferring'), findsNothing);
    expect(find.text('Preparing to import 1 book(s)'), findsOneWidget);
    expect(find.text('Processing: book.epub'), findsOneWidget);
  });
}
