import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'webdav_service.dart';

part 'webdav_service_provider.g.dart';

/// Provider for WebDavService
/// Each notifier that needs WebDAV should watch this provider
/// keepAlive ensures the service isn't disposed mid-operation
@Riverpod(keepAlive: true)
WebDavService webDavService(WebDavServiceRef ref) {
  final service = WebDavService();

  // Dispose when provider is disposed (only when app closes)
  ref.onDispose(() {
    service.dispose();
  });

  return service;
}
