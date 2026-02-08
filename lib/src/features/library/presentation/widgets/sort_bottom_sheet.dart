import 'package:flutter/material.dart';
import '../../data/shelf_book_repository.dart';
import '../../../../../l10n/app_localizations.dart';

/// Bottom sheet for selecting book sort order
class SortBottomSheet extends StatelessWidget {
  final ShelfBookSortBy currentSort;
  final Function(ShelfBookSortBy) onSortSelected;

  const SortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                AppLocalizations.of(context)!.sortBooksBy,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption(
              context,
              icon: Icons.access_time_outlined,
              label: AppLocalizations.of(context)!.recentlyAdded,
              sortBy: ShelfBookSortBy.recentlyAdded,
            ),
            _buildSortOption(
              context,
              icon: Icons.auto_stories_outlined,
              label: AppLocalizations.of(context)!.recentlyRead,
              sortBy: ShelfBookSortBy.recentlyRead,
            ),
            const Divider(height: 1),
            _buildSortOption(
              context,
              icon: Icons.sort_by_alpha_outlined,
              label: AppLocalizations.of(context)!.titleAZ,
              sortBy: ShelfBookSortBy.titleAsc,
            ),
            _buildSortOption(
              context,
              icon: Icons.sort_by_alpha_outlined,
              label: AppLocalizations.of(context)!.titleZA,
              sortBy: ShelfBookSortBy.titleDesc,
              iconRotation: true,
            ),
            const Divider(height: 1),
            _buildSortOption(
              context,
              icon: Icons.person_outline_outlined,
              label: AppLocalizations.of(context)!.authorAZ,
              sortBy: ShelfBookSortBy.authorAsc,
            ),
            _buildSortOption(
              context,
              icon: Icons.person_outline_outlined,
              label: AppLocalizations.of(context)!.authorZA,
              sortBy: ShelfBookSortBy.authorDesc,
              iconRotation: true,
            ),
            const Divider(height: 1),
            _buildSortOption(
              context,
              icon: Icons.show_chart_outlined,
              label: AppLocalizations.of(context)!.readingProgress,
              sortBy: ShelfBookSortBy.progress,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ShelfBookSortBy sortBy,
    bool iconRotation = false,
  }) {
    final isSelected = currentSort == sortBy;

    return ListTile(
      leading: Transform.rotate(
        angle: iconRotation ? 3.14159 : 0,
        child: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withAlpha(153),
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_outlined,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () => onSortSelected(sortBy),
    );
  }
}
