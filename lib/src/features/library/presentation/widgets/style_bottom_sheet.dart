import 'package:flutter/material.dart';
import '../../application/bookshelf_notifier.dart';
import '../../data/shelf_book_repository.dart';
import '../../../../../l10n/app_localizations.dart';

/// Bottom sheet for selecting sort order and view mode.
class StyleBottomSheet extends StatelessWidget {
  final ShelfBookSortBy currentSort;
  final Function(ShelfBookSortBy) onSortSelected;
  final ViewMode currentViewMode;
  final ValueChanged<ViewMode> onViewModeSelected;

  const StyleBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSortSelected,
    required this.currentViewMode,
    required this.onViewModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── View Mode ──────────────────────────────────────────────────
            _SectionTitle(label: 'View Mode'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _OptionChip(
                  icon: Icons.grid_on_outlined,
                  label: 'Compact',
                  isSelected: currentViewMode == ViewMode.compact,
                  onTap: () => onViewModeSelected(ViewMode.compact),
                ),
                _OptionChip(
                  icon: Icons.grid_view_outlined,
                  label: 'Comfortable',
                  isSelected: currentViewMode == ViewMode.comfortable,
                  onTap: () => onViewModeSelected(ViewMode.comfortable),
                ),
                _OptionChip(
                  icon: Icons.view_agenda_outlined,
                  label: 'Relaxed',
                  isSelected: currentViewMode == ViewMode.relaxed,
                  onTap: () => onViewModeSelected(ViewMode.relaxed),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Sort Order ─────────────────────────────────────────────────
            _SectionTitle(label: l10n.sortBooksBy),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _OptionChip(
                  icon: Icons.access_time_outlined,
                  label: l10n.recentlyAdded,
                  isSelected: currentSort == ShelfBookSortBy.recentlyAdded,
                  onTap: () => onSortSelected(ShelfBookSortBy.recentlyAdded),
                ),
                _OptionChip(
                  icon: Icons.auto_stories_outlined,
                  label: l10n.recentlyRead,
                  isSelected: currentSort == ShelfBookSortBy.recentlyRead,
                  onTap: () => onSortSelected(ShelfBookSortBy.recentlyRead),
                ),
                _OptionChip(
                  icon: Icons.sort_by_alpha_outlined,
                  label: l10n.titleAZ,
                  isSelected: currentSort == ShelfBookSortBy.titleAsc,
                  onTap: () => onSortSelected(ShelfBookSortBy.titleAsc),
                ),
                _OptionChip(
                  icon: Icons.sort_by_alpha_outlined,
                  label: l10n.titleZA,
                  isSelected: currentSort == ShelfBookSortBy.titleDesc,
                  onTap: () => onSortSelected(ShelfBookSortBy.titleDesc),
                  mirrorIcon: true,
                ),
                _OptionChip(
                  icon: Icons.person_outline_outlined,
                  label: l10n.authorAZ,
                  isSelected: currentSort == ShelfBookSortBy.authorAsc,
                  onTap: () => onSortSelected(ShelfBookSortBy.authorAsc),
                ),
                _OptionChip(
                  icon: Icons.person_outline_outlined,
                  label: l10n.authorZA,
                  isSelected: currentSort == ShelfBookSortBy.authorDesc,
                  onTap: () => onSortSelected(ShelfBookSortBy.authorDesc),
                  mirrorIcon: true,
                ),
                _OptionChip(
                  icon: Icons.show_chart_outlined,
                  label: l10n.readingProgress,
                  isSelected: currentSort == ShelfBookSortBy.progress,
                  onTap: () => onSortSelected(ShelfBookSortBy.progress),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Grey section-title label.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }
}

/// Custom rounded-rectangle chip used for both view-mode and sort options.
class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.mirrorIcon = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  /// Horizontally mirrors the icon (used for Z-A variants).
  final bool mirrorIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final bgColor = isSelected
        ? colorScheme.primaryContainer.withOpacity(0.3)
        : colorScheme.surfaceContainerHighest;

    final borderColor = isSelected
        ? colorScheme.primary.withOpacity(0.5)
        : Colors.transparent;

    final contentColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurface.withOpacity(0.8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Transform.scale(
                scaleX: mirrorIcon ? -1 : 1,
                child: Icon(icon, size: 18, color: contentColor),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
