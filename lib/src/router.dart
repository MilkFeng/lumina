import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/detail/presentation/book_detail_screen.dart';
import 'package:lumina/src/features/library/domain/shelf_book.dart';
import 'package:lumina/src/features/library/presentation/library_screen.dart';
import 'package:lumina/src/features/library/presentation/shared_epub_handler.dart';
import 'package:lumina/src/features/reader/presentation/reader_screen.dart';
import 'package:lumina/src/features/settings/presentation/settings_screen.dart';

/// App Router Configuration
///
/// Lives at the `src/` root rather than under `core/` because a route table is
/// application assembly, not reusable infrastructure: it has to name every
/// feature's screen. Keeping it here is what lets `core/` hold its
/// "no `features/` imports" rule without an exemption.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: ToastService.navigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final location = state.uri.toString();
      if (location.startsWith('content://') || location.startsWith('file://')) {
        Future.microtask(() {
          ref.read(pendingRouteFileProvider.notifier).state = location;
        });
        return '/';
      } else if (location.startsWith('/-')) {
        return '/';
      }
      return null;
    },
    routes: [
      // Library Screen (Home)
      GoRoute(
        path: '/',
        name: 'library',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const LibraryScreen()),
      ),

      // Book Detail Screen
      GoRoute(
        path: '/book/:id',
        name: 'book-detail',
        pageBuilder: (context, state) {
          final fileHash = state.pathParameters['id']!;
          final book =
              state.extra as ShelfBook?; // Try to get the book from extra
          return MaterialPage(
            key: state.pageKey,
            child: BookDetailScreen(bookId: fileHash, initialBook: book),
          );
        },
      ),

      // Reader Screen (Stream-from-Zip)
      GoRoute(
        path: '/read/:id',
        name: 'reader',
        pageBuilder: (context, state) {
          final fileHash = state.pathParameters['id']!;
          return MaterialPage(
            key: state.pageKey,
            child: ReaderScreen(fileHash: fileHash),
          );
        },
      ),

      // Settings Screen
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) {
          return MaterialPage(
            key: state.pageKey,
            child: const SettingsScreen(),
          );
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route not found: ${state.uri}'))),
  );
});
