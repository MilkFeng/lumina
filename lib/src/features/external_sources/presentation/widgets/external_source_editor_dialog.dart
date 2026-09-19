import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumina/l10n/app_localizations.dart';
import 'package:lumina/src/core/services/toast_service.dart';
import 'package:lumina/src/features/external_sources/application/external_sources_notifier.dart';
import 'package:lumina/src/features/external_sources/domain/external_source.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_config.dart';
import 'package:lumina/src/features/external_sources/domain/external_source_type.dart';
import 'package:lumina/src/features/external_sources/presentation/external_source_localizations.dart';

/// What the editor should open on.
sealed class ExternalSourceEditorRequest {
  const ExternalSourceEditorRequest();
}

/// Create a new source, pre-filled with [initialName].
class NewExternalSource extends ExternalSourceEditorRequest {
  const NewExternalSource({required this.initialName, required this.type});

  final String initialName;
  final ExternalSourceType type;
}

/// Edit an existing [source].
class EditExternalSource extends ExternalSourceEditorRequest {
  const EditExternalSource(this.source);

  final ExternalSource source;
}

/// Create-or-edit dialog for one external source.
///
/// One dialog for both, because the two flows differ only in where the initial
/// values come from. Everything type-specific is driven by
/// [ExternalSourceConfig.fields]: the dialog renders whatever a source type
/// declares, so adding a type never touches this file.
class ExternalSourceEditorDialog extends ConsumerStatefulWidget {
  const ExternalSourceEditorDialog({super.key, required this.request});

  final ExternalSourceEditorRequest request;

  /// Opens the dialog and returns the saved source, or `null` when cancelled.
  static Future<ExternalSource?> show(
    BuildContext context,
    ExternalSourceEditorRequest request,
  ) {
    return showDialog<ExternalSource>(
      context: context,
      builder: (context) => ExternalSourceEditorDialog(request: request),
    );
  }

  @override
  ConsumerState<ExternalSourceEditorDialog> createState() =>
      _ExternalSourceEditorDialogState();
}

class _ExternalSourceEditorDialogState
    extends ConsumerState<ExternalSourceEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  /// One controller per field key, rebuilt whenever the type changes.
  final Map<String, TextEditingController> _controllers = {};

  late ExternalSourceType _type;
  ExternalSourceConfigDraft? _draft;

  bool _busy = false;
  bool _nameTaken = false;

  /// Set when the initial configuration could not be loaded — an unreadable
  /// row, or a keychain the platform refused to open.
  bool _loadFailed = false;

  /// Guards against an out-of-order duplicate-name answer overwriting a newer
  /// one while the user is still typing.
  int _nameCheckToken = 0;

  ExternalSource? get _editing => switch (widget.request) {
    EditExternalSource(:final source) => source,
    NewExternalSource() => null,
  };

  @override
  void initState() {
    super.initState();
    _type = switch (widget.request) {
      NewExternalSource(:final type) => type,
      // A row whose type this build does not know cannot be edited through any
      // form; falling back to the first supported type at least opens a usable
      // dialog instead of failing on a stale row.
      EditExternalSource(:final source) =>
        externalSourceTypeOf(source) ?? ExternalSourceType.values.first,
    };
    switch (widget.request) {
      case NewExternalSource(:final initialName):
        _nameController.text = initialName;
      case EditExternalSource(:final source):
        _nameController.text = source.name;
    }
    _nameController.addListener(_onNameChanged);
    _loadDraft();
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Loads the initial configuration: the stored one when editing, an empty one
  /// of [_type] when creating.
  ///
  /// A failure here is reported in the dialog rather than thrown: reading the
  /// keychain can fail on a device (a locked or reset keystore), and a dialog
  /// that never leaves its spinner would be worse than one that says so.
  Future<void> _loadDraft() async {
    final notifier = ref.read(externalSourcesProvider.notifier);
    final source = _editing;

    try {
      final draft = source == null
          ? notifier.emptyDraft(_type)
          : await notifier.draftFor(source);
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _loadFailed = false;
        _rebuildControllers(draft);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadFailed = true);
    }
  }

  void _onNameChanged() {
    final token = ++_nameCheckToken;
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _nameTaken = false);
      // Re-runs the validator so an "already in use" error clears as soon as
      // the field is emptied, instead of lingering next to "required".
      _formKey.currentState?.validate();
      return;
    }

    // The answer arrives after the field's own validation pass, so the token
    // guards against a stale answer; `isNameAvailable` is advisory either way,
    // and the notifier re-checks on save.
    unawaited(() async {
      final available = await ref
          .read(externalSourcesProvider.notifier)
          .isNameAvailable(name, excludingId: _editing?.id);
      if (!mounted || token != _nameCheckToken) return;
      setState(() => _nameTaken = !available);
    }());
  }

  /// Rebuilds the per-field controllers for [draft], preserving any text the
  /// user already typed for fields that survived a type change.
  void _rebuildControllers(ExternalSourceConfigDraft draft) {
    final previous = Map<String, String>.fromEntries(
      _controllers.entries.map(
        (entry) => MapEntry(entry.key, entry.value.text),
      ),
    );

    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    for (final field in draft.fields) {
      _controllers[field.key] = TextEditingController(
        text: previous[field.key] ?? field.value,
      );
    }
  }

  /// Turns the controllers back into a draft.
  ExternalSourceConfigDraft _currentDraft() {
    var draft = _draft!;
    for (final entry in _controllers.entries) {
      draft = draft.copyWithField(entry.key, entry.value.text);
    }
    return draft;
  }

  void _onTypeChanged(ExternalSourceType type) {
    if (type == _type) return;
    final notifier = ref.read(externalSourcesProvider.notifier);
    final draft = notifier.emptyDraft(type);
    setState(() {
      _type = type;
      // A different type means different fields; carrying text across would
      // only produce nonsense (a WebDAV host inside a field another protocol
      // reads as a bucket name).
      _rebuildControllers(draft);
      _draft = draft;
    });
  }

  /// Handles the OK action: validate, test, then save.
  ///
  /// The test runs first on purpose — saving a source that cannot be reached
  /// would leave the home screen with an import entry that fails when used.
  Future<void> _confirm() async {
    final draft = _currentDraft();
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _formKey.currentState?.validate();
      return;
    }
    if (_nameTaken) return;
    if (!draft.isComplete) {
      // Surfaces the required-field errors the fields raise on validation.
      _formKey.currentState?.validate();
      return;
    }

    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(externalSourcesProvider.notifier);

    try {
      final failure = await notifier.testDraft(draft);
      if (!mounted) return;

      if (failure != null) {
        ToastService.showError(l10n.externalSourceFailureMessage(failure));
        return;
      }

      final source = _editing;
      final result = source == null
          ? await notifier.add(name: name, draft: draft)
          : await notifier.saveChanges(
              source: source,
              name: name,
              draft: draft,
            );
      if (!mounted) return;

      result.match(
        (error) =>
            ToastService.showError(l10n.externalSourceFailureMessage(error)),
        (saved) {
          Navigator.of(context).pop(saved);
          ToastService.showSuccess(
            source == null
                ? l10n.externalSourceAdded(saved.name)
                : l10n.externalSourceUpdated(saved.name),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final draft = _draft;

    return AlertDialog(
      title: Text(
        _editing == null ? l10n.addExternalSource : l10n.externalSourceEdit,
      ),
      content: SizedBox(
        width: 360,
        child: switch ((draft, _loadFailed)) {
          (_, true) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              l10n.externalSourceConfigurationLoadFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          (null, false) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          (final loaded?, false) => SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildNameField(l10n),
                  const SizedBox(height: 12),
                  _buildTypeField(l10n, theme),
                  const SizedBox(height: 20),
                  Text(
                    l10n.externalSourceConfiguration,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildConfigFields(context, loaded, l10n),
                ],
              ),
            ),
          ),
        },
      ),
      actions: _busy
          ? [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.externalSourceTesting,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(onPressed: _confirm, child: Text(l10n.confirm)),
            ],
    );
  }

  Widget _buildNameField(AppLocalizations l10n) {
    return TextFormField(
      controller: _nameController,
      autofocus: true,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: l10n.externalSourceName,
        isDense: true,
        errorText: _nameTaken ? l10n.externalSourceNameDuplicate : null,
      ),
      validator: (value) {
        final name = value?.trim() ?? '';
        if (name.isEmpty) return l10n.externalSourceNameRequired;
        if (_nameTaken) return l10n.externalSourceNameDuplicate;
        return null;
      },
    );
  }

  Widget _buildTypeField(AppLocalizations l10n, ThemeData theme) {
    final types = ref.watch(externalSourceRegistryProvider).supportedTypes;
    return DropdownButtonFormField<ExternalSourceType>(
      initialValue: _type,
      decoration: InputDecoration(
        labelText: l10n.externalSourceType,
        isDense: true,
      ),
      items: [
        for (final type in types)
          DropdownMenuItem(
            value: type,
            child: Text(l10n.externalSourceTypeName(type)),
          ),
      ],
      onChanged: _busy
          ? null
          : (type) {
              if (type != null) _onTypeChanged(type);
            },
    );
  }

  /// Builds one input per field the draft declares.
  ///
  /// Secret fields are declared among the others, so the form stays the same
  /// shape whoever declares them; only the input type differs.
  List<Widget> _buildConfigFields(
    BuildContext context,
    ExternalSourceConfigDraft draft,
    AppLocalizations l10n,
  ) {
    return [
      for (final field in draft.fields)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _controllers[field.key],
            keyboardType: switch (field.type) {
              ExternalSourceFieldType.url => TextInputType.url,
              _ => TextInputType.text,
            },
            obscureText: field.type == ExternalSourceFieldType.password,
            autocorrect: false,
            enableSuggestions: field.type != ExternalSourceFieldType.password,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.externalSourceFieldLabel(field.labelKey),
              hintText: l10n.externalSourceFieldHint(field.hint),
              isDense: true,
            ),
            validator: (value) {
              if (!field.required) return null;
              return (value?.trim().isEmpty ?? true)
                  ? l10n.externalSourceRequiredField
                  : null;
            },
          ),
        ),
    ];
  }
}
