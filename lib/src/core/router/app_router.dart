import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/features/library/domain/shelf_book.dart';
import 'package:lumina/src/global_share_handler.dart';
import '../services/toast_service.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/detail/presentation/book_detail_screen.dart';
import '../../features/reader/presentation/reader_screen.dart';
import '../../features/about/presentation/about_screen.dart';

/// App Router Configuration
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

      // About Screen
      GoRoute(
        path: '/about',
        name: 'about',
        pageBuilder: (context, state) {
          return MaterialPage(key: state.pageKey, child: const AboutScreen());
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route not found: ${state.uri}'))),
  );
});
