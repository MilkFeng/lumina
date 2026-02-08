import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/toast_service.dart';
import '../../../sync/application/sync_notifier.dart';
import '../../../../../l10n/app_localizations.dart';

/// Sync button widget with animated icon
/// Shows sync status and allows long press to open settings
class SyncButton extends ConsumerStatefulWidget {
  final VoidCallback? onSync;

  const SyncButton({super.key, this.onSync});

  @override
  ConsumerState<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends ConsumerState<SyncButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _turns;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _turns = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (!_isAnimating) {
      setState(() => _isAnimating = true);
      _controller.repeat();
    }
  }

  void _stopAnimation() {
    if (!mounted) return;
    _controller.stop();
    _controller.reset();
    setState(() => _isAnimating = false);
  }

  Future<void> _performSync() async {
    if (_isAnimating) return;

    _startAnimation();

    try {
      final success = await ref
          .read(syncNotifierProvider.notifier)
          .performSync();

      if (mounted) {
        if (success.isRight()) {
          ToastService.showSuccess(AppLocalizations.of(context)!.syncCompleted);
          widget.onSync?.call();
        } else {
          final state = ref.read(syncNotifierProvider).valueOrNull;
          if (state is SyncFailureState) {
            ToastService.showError(state.userMessage);
            return;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(
          AppLocalizations.of(context)!.syncError(e.toString()),
        );
      }
    } finally {
      _stopAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to sync state to show real-time feedback
    ref.listen<AsyncValue<SyncState>>(syncNotifierProvider, (previous, next) {
      next.whenData((state) {
        if (state is SyncInProgress) {
          _startAnimation();
        } else {
          _stopAnimation();
        }
      });
    });

    return IconButton(
      onPressed: _isAnimating ? null : _performSync,
      onLongPress: () {
        context.push('/sync-settings');
      },
      tooltip: AppLocalizations.of(context)!.tapSyncLongPressSettings,
      icon: RotationTransition(
        turns: _turns,
        child: const Icon(Icons.sync_outlined),
      ),
    );
  }
}
