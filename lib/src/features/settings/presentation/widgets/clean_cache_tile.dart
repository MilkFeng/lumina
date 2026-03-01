import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/library/data/services/storage_cleanup_service_provider.dart';
import '../../../../../l10n/app_localizations.dart';

/// List tile that cleans cached and orphaned files when tapped.
/// Manages its own [_isCleaning] busy state so the parent screen stays lean.
class CleanCacheTile extends ConsumerStatefulWidget {
  const CleanCacheTile({super.key});

  @override
  ConsumerState<CleanCacheTile> createState() => _CleanCacheTileState();
}

class _CleanCacheTileState extends ConsumerState<CleanCacheTile> {
  bool _isCleaning = false;

  Future<void> _clean() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isCleaning = true);

    final service = ref.read(storageCleanupServiceProvider);
    await service.cleanCacheFiles();
    final deletedCount = await service.cleanOrphanFiles();
    await service.cleanShareFiles();

    await Future.delayed(const Duration(milliseconds: 200));

    setState(() => _isCleaning = false);

    if (!context.mounted) return;

    final message = deletedCount == 0
        ? l10n.cleanCacheSuccess
        : l10n.cleanCacheSuccessWithCount(deletedCount);

    ToastService.showSuccess(message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(
        Icons.cleaning_services_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(l10n.cleanCache),
      subtitle: Text(
        l10n.cleanCacheSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: _isCleaning
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _isCleaning ? null : _clean,
    );
  }
}
