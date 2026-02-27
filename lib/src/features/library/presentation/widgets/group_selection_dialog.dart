import 'package:flutter/material.dart';
import '../../domain/shelf_group.dart';
import '../../../../../l10n/app_localizations.dart';

/// Dialog for selecting a group to move books to
/// Includes options to create a new group or move to uncategorized
class GroupSelectionDialog extends StatelessWidget {
  final List<ShelfGroup> groups;
  final int createGroupResult;

  const GroupSelectionDialog({
    super.key,
    required this.groups,
    required this.createGroupResult,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(AppLocalizations.of(context)!.moveTo),
      contentPadding: const EdgeInsets.all(12),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(
                AppLocalizations.of(context)!.createNewCategory,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              onTap: () => Navigator.pop(context, createGroupResult),
            ),
            ListTile(
              leading: const Icon(Icons.folder_off_outlined),
              title: Text(AppLocalizations.of(context)!.uncategorized),
              onTap: () => Navigator.pop(context, -1),
            ),
            ...groups.map(
              (group) => ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(group.name),
                onTap: () => Navigator.pop(context, group.id),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
      ],
    );
  }
}
